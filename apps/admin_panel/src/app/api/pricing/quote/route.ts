
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { z } from 'zod';
import { prisma } from '@/lib/db';
import { computeFare } from '@/lib/pricing';

const schema = z.object({
  serviceType: z.enum(['PARCEL', 'FOOD', 'GROCERY', 'MEDICINE', 'BIKE', 'AUTO', 'MINI_TRUCK', 'TRUCK']),
  vehicleType: z.enum(['BIKE', 'SCOOTER', 'AUTO', 'MINI_TRUCK', 'TRUCK']),
  pickupLat: z.number(),
  pickupLng: z.number(),
  dropLat: z.number(),
  dropLng: z.number(),
  userId: z.string().optional(),
  couponCode: z.string().optional(),
});

// Public endpoint — used by Flutter apps to get a fare quote.
// Auth via X-API-Key header (or allow in dev when APP_API_KEYS is unset).
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const parsed = schema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid input', details: parsed.error.flatten() }, { status: 400 });
    }

    const fare = await computeFare(parsed.data);
    return NextResponse.json(fare);
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}

export async function GET() {
  const quotes = await prisma.fareQuote.findMany({
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
  return NextResponse.json({ quotes });
}
