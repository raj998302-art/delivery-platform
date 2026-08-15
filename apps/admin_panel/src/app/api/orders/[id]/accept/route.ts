export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';
import { transitionOrder } from '@/lib/order-state';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

// POST /api/orders/[id]/accept
// Partner accepts an order. Transitions state from SEARCHING_PARTNER → PARTNER_ASSIGNED.
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
    let decoded: any;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch {
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const order = await prisma.order.findUnique({ where: { id: params.id } });
    if (!order) {
      return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    }

    if (order.state !== 'SEARCHING_PARTNER' && order.state !== 'PARTNER_ASSIGNED') {
      return NextResponse.json({ error: `Order cannot be accepted in state ${order.state}` }, { status: 400 });
    }

    // Find the partner record for this user
    const partner = await prisma.partner.findFirst({ where: { phone: decoded.phone } });
    if (!partner) {
      return NextResponse.json({ error: 'Partner profile not found' }, { status: 404 });
    }

    // Assign partner to order
    await prisma.order.update({
      where: { id: params.id },
      data: { partnerId: partner.id },
    });

    // Transition state
    await transitionOrder(params.id, 'PARTNER_ASSIGNED', decoded.userId, `Accepted by ${partner.firstName}`);

    // Create tracking session
    await prisma.trackingSession.upsert({
      where: { orderId: params.id },
      update: { partnerId: partner.id, isActive: true },
      create: { orderId: params.id, partnerId: partner.id },
    });

    // Expire all other assignments for this order
    await prisma.partnerAssignment.updateMany({
      where: { orderId: params.id, status: 'PENDING' },
      data: { status: 'EXPIRED', respondedAt: new Date() },
    });

    return NextResponse.json({
      ok: true,
      message: 'Order accepted',
      order: { id: params.id, state: 'PARTNER_ASSIGNED' },
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
