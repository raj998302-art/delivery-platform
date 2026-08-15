export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';
import { transitionOrder } from '@/lib/order-state';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

// POST /api/orders/[id]/reject
// Partner rejects an order. Returns to SEARCHING_PARTNER for re-dispatch.
export async function POST(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Authorization required' }, { status: 401 });
    }
    const token = authHeader.slice(7);
    try {
      jwt.verify(token, JWT_SECRET);
    } catch {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const body = await req.json().catch(() => ({}));
    const { reason } = body;

    // Mark assignment as rejected
    await prisma.partnerAssignment.updateMany({
      where: { orderId: params.id, status: 'PENDING' },
      data: { status: 'REJECTED', respondedAt: new Date() },
    });

    // Order stays in SEARCHING_PARTNER for re-dispatch
    return NextResponse.json({
      ok: true,
      message: 'Order rejected',
      reason: reason || 'Partner declined',
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
