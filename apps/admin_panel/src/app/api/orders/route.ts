
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';
import { ORDER_STATE_LABELS } from '@/lib/order-state';

export async function GET(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { searchParams } = new URL(req.url);
  const page = Number(searchParams.get('page') || '1');
  const pageSize = Number(searchParams.get('pageSize') || '20');
  const state = searchParams.get('state');
  const q = searchParams.get('q');

  const where: any = {};
  if (state && state !== 'ALL') where.state = state;
  if (q) {
    where.OR = [
      { code: { contains: q } },
      { pickupAddress: { contains: q } },
      { dropAddress: { contains: q } },
    ];
  }

  const [total, orders] = await Promise.all([
    prisma.order.count({ where }),
    prisma.order.findMany({
      where,
      include: {
        user: { select: { id: true, name: true, phone: true } },
        partner: { select: { id: true, firstName: true, lastName: true, phone: true } },
        service: { select: { id: true, name: true, type: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
    }),
  ]);

  return NextResponse.json({
    orders,
    total,
    page,
    pageSize,
    pageCount: Math.ceil(total / pageSize),
    stateLabels: ORDER_STATE_LABELS,
  });
}
