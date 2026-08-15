
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';
import { dispatchOrder } from '@/lib/dispatch';

// POST /api/dispatch — trigger dispatch for an order
export async function POST(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { orderId } = await req.json();
  if (!orderId) return NextResponse.json({ error: 'orderId required' }, { status: 400 });

  try {
    const candidates = await dispatchOrder(orderId);
    return NextResponse.json({ candidates });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

// GET /api/dispatch?orderId=... — fetch current assignment state for an order
export async function GET(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { searchParams } = new URL(req.url);
  const orderId = searchParams.get('orderId');
  if (!orderId) return NextResponse.json({ error: 'orderId required' }, { status: 400 });

  const assignments = await prisma.partnerAssignment.findMany({
    where: { orderId },
    include: { partner: { select: { id: true, firstName: true, lastName: true, phone: true, rating: true } } },
    orderBy: { createdAt: 'asc' },
  });

  return NextResponse.json({ assignments });
}
