
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';

export async function GET() {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const [services, vehicleTypes, pricingRules, coupons, flags] = await Promise.all([
    prisma.service.findMany({
      include: { vehicleTypes: { include: { vehicleTypeConf: true } } },
      orderBy: { sortOrder: 'asc' },
    }),
    prisma.vehicleTypeConfig.findMany({ orderBy: { type: 'asc' } }),
    prisma.pricingRule.findMany({ orderBy: { priority: 'desc' } }),
    prisma.coupon.findMany({ orderBy: { createdAt: 'desc' } }),
    prisma.featureFlag.findMany({ orderBy: { key: 'asc' } }),
  ]);

  return NextResponse.json({ services, vehicleTypes, pricingRules, coupons, flags });
}

export async function PATCH(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const { id, isActive, baseFare, perKm, perMin, platformFee, taxPercent, minFare } = body;
  if (!id) return NextResponse.json({ error: 'id required' }, { status: 400 });

  const service = await prisma.service.update({
    where: { id },
    data: {
      ...(typeof isActive === 'boolean' && { isActive }),
      ...(baseFare !== undefined && { baseFare }),
      ...(perKm !== undefined && { perKm }),
      ...(perMin !== undefined && { perMin }),
      ...(platformFee !== undefined && { platformFee }),
      ...(taxPercent !== undefined && { taxPercent }),
      ...(minFare !== undefined && { minFare }),
    },
  });

  await prisma.auditLog.create({
    data: {
      actorId: session.userId,
      actorRole: session.role,
      action: 'SERVICE_UPDATE',
      entityType: 'Service',
      entityId: id,
      metadata: body,
    },
  });

  return NextResponse.json({ service });
}
