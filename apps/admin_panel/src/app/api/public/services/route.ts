export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { prisma } from '@/lib/db';

// GET /api/public/services
// Public endpoint — used by Flutter apps to fetch the list of active services
// and vehicle types for the home screen + booking flow.
// No auth required (read-only catalog data).
export async function GET() {
  const [services, vehicleTypes] = await Promise.all([
    prisma.service.findMany({
      where: { isActive: true },
      select: {
        id: true,
        type: true,
        name: true,
        description: true,
        icon: true,
        baseFare: true,
        perKm: true,
        perMin: true,
        platformFee: true,
        taxPercent: true,
        minFare: true,
        sortOrder: true,
      },
      orderBy: { sortOrder: 'asc' },
    }),
    prisma.vehicleTypeConfig.findMany({
      where: { isActive: true },
      select: {
        type: true,
        name: true,
        icon: true,
        capacityKg: true,
        multiplier: true,
      },
      orderBy: { type: 'asc' },
    }),
  ]);

  return NextResponse.json({ services, vehicleTypes });
}
