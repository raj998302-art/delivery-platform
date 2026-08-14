
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';

// GET /api/tracking — list active tracking sessions with last known partner location
export async function GET(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const sessions = await prisma.trackingSession.findMany({
    where: { isActive: true },
    include: {
      order: {
        select: {
          id: true, code: true, state: true,
          pickupLat: true, pickupLng: true, pickupAddress: true,
          dropLat: true, dropLng: true, dropAddress: true,
          user: { select: { id: true, name: true, phone: true } },
          partner: { select: { id: true, firstName: true, lastName: true, phone: true, currentLat: true, currentLng: true, rating: true, vehicles: { select: { type: true, registrationNumber: true } } } },
        },
      },
    },
    orderBy: { startedAt: 'desc' },
    take: 100,
  });

  // Also include all online partners for the live map view
  const onlinePartners = await prisma.partner.findMany({
    where: { isOnline: true, currentLat: { not: null }, currentLng: { not: null } },
    select: {
      id: true, firstName: true, lastName: true, phone: true,
      currentLat: true, currentLng: true, lastLocationAt: true,
      rating: true, status: true,
      vehicles: { select: { type: true, registrationNumber: true, isPrimary: true } },
    },
  });

  return NextResponse.json({ sessions, onlinePartners });
}

// POST /api/tracking — partner pushes a location update
export async function POST(req: NextRequest) {
  const body = await req.json();
  const { partnerId, orderId, latitude, longitude, heading, speed } = body;
  if (!partnerId || typeof latitude !== 'number' || typeof longitude !== 'number') {
    return NextResponse.json({ error: 'partnerId, latitude, longitude required' }, { status: 400 });
  }

  // Update partner's current location
  await prisma.partner.update({
    where: { id: partnerId },
    data: { currentLat: latitude, currentLng: longitude, lastLocationAt: new Date() },
  });

  // If an order is active, append to its tracking session
  if (orderId) {
    const session = await prisma.trackingSession.findUnique({ where: { orderId } });
    if (session) {
      await prisma.locationUpdate.create({
        data: {
          sessionId: session.id,
          partnerId,
          latitude,
          longitude,
          heading,
          speed,
        },
      });
    }
  }

  return NextResponse.json({ ok: true });
}
