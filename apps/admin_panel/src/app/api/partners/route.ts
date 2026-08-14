
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
  const status = searchParams.get('status');
  const q = searchParams.get('q');

  const where: any = { deletedAt: null };
  if (status && status !== 'ALL') where.status = status;
  if (q) {
    where.OR = [
      { firstName: { contains: q, mode: 'insensitive' } },
      { lastName: { contains: q, mode: 'insensitive' } },
      { phone: { contains: q, mode: 'insensitive' } },
    ];
  }

  const [total, partners] = await Promise.all([
    prisma.partner.count({ where }),
    prisma.partner.findMany({
      where,
      include: {
        vehicles: { select: { id: true, type: true, registrationNumber: true, isPrimary: true } },
      },
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * pageSize,
      take: pageSize,
    }),
  ]);

  return NextResponse.json({
    partners,
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
  const { id, status, isOnline } = body;
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 });

  const partner = await prisma.partner.update({
    where: { id },
    data: {
      ...(status && { status }),
      ...(typeof isOnline === 'boolean' && { isOnline }),
    },
  });

  await prisma.auditLog.create({
    data: {
      actorId: session.userId,
      actorRole: session.role,
      action: 'PARTNER_UPDATE',
      entityType: 'Partner',
      entityId: id,
      metadata: { status, isOnline },
    },
  });

  return NextResponse.json({ partner });
}
