export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

// GET /api/orders/[id]
// Auth: Bearer JWT (user must own the order)
// Returns detailed order info with partner + service + state history.
export async function GET(
  req: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Authorization required' }, { status: 401 });
    }
    const token = authHeader.slice(7);
    let decoded: any;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch {
      return NextResponse.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    const order = await prisma.order.findUnique({
      where: { id: params.id },
      include: {
        partner: {
          select: {
            id: true, firstName: true, lastName: true, phone: true,
            currentLat: true, currentLng: true, rating: true,
            vehicles: { select: { type: true, registrationNumber: true, model: true } },
          },
        },
        service: { select: { id: true, name: true, type: true } },
        stateHistory: {
          orderBy: { createdAt: 'asc' },
        },
        rating: { select: { score: true, comment: true } },
      },
    });

    if (!order) {
      return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    }

    // User can only see their own orders; admin can see any
    if (order.userId !== decoded.userId && decoded.role !== 'ADMIN' && decoded.role !== 'SUPER_ADMIN') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }

    return NextResponse.json({ order });
  } catch (err: any) {
    return NextResponse.json({ error: 'Failed to fetch order', message: err.message }, { status: 500 });
  }
}
