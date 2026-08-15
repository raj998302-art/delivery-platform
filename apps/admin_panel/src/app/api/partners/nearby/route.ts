export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { prisma } from '@/lib/db';
import { findNearbyPartners } from '@/lib/dispatch';

// GET /api/partners/nearby?lat=12.97&lng=77.59&vehicleType=BIKE&radiusKm=5
// Public endpoint — used by Flutter apps during the booking flow
// to show how many partners are nearby and the estimated arrival time.
export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const lat = Number(searchParams.get('lat'));
  const lng = Number(searchParams.get('lng'));
  const vehicleType = searchParams.get('vehicleType') as any;
  const radiusKm = Number(searchParams.get('radiusKm') || '5');

  if (!lat || !lng) {
    return NextResponse.json({ error: 'lat and lng query params required' }, { status: 400 });
  }

  const partners = await findNearbyPartners(lat, lng, vehicleType, radiusKm, 10);

  return NextResponse.json({
    count: partners.length,
    partners: partners.map((p) => ({
      id: p.partnerId,
      name: p.name,
      distanceKm: Math.round(p.distanceKm * 10) / 10,
      estimatedArrivalMin: Math.max(2, Math.round(p.distanceKm * 3)),
      rating: Math.round(p.rating * 10) / 10,
    })),
  });
}
