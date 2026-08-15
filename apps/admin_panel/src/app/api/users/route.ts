
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';

export async function GET(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { searchParams } = new URL(req.url);
  const page = Number(searchParams.get('page') || '1');
  const pageSize = Number(searchParams.get('pageSize') || '20');
  const q = searchParams.get('q');

  const where: any = { deletedAt: null };
  if (q) {
    where.OR = [
      { name: { contains: q } },
      { phone: { contains: q } },
      { email: { contains: q } },
    ];
  }

  const [total, users] = await Promise.all([
    prisma.user.count({ where }),
    prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        phone: true,
        email: true,
        role: true,
        isBlocked: true,
        phoneVerified: true,
        createdAt: true,
        lastLoginAt: true,
        _count: { select: { orders: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
    }),
  ]);

  return NextResponse.json({
    users,
    total,
    page,
    pageSize,
    pageCount: Math.ceil(total / pageSize),
  });
}

export async function PATCH(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { id, isBlocked } = body;
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 });

  const user = await prisma.user.update({
    where: { id },
    data: { isBlocked: !!isBlocked },
  });

  await prisma.auditLog.create({
    data: {
      actorId: session.userId,
      actorRole: session.role,
      action: 'USER_BLOCK_TOGGLE',
      entityType: 'User',
      entityId: id,
      metadata: { isBlocked: !!isBlocked },
    },
  });

  return NextResponse.json({ user });
}
