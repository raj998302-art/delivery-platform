export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';
import { generateOrderCode } from '@/lib/utils';
import { transitionOrder } from '@/lib/order-state';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

const schema = z.object({
  quoteId: z.string(),
  // Allow client to pass the quote details they got (server re-verifies)
  serviceType: z.enum(['PARCEL', 'FOOD', 'GROCERY', 'MEDICINE', 'BIKE', 'AUTO', 'MINI_TRUCK', 'TRUCK']),
  vehicleType: z.enum(['BIKE', 'SCOOTER', 'AUTO', 'MINI_TRUCK', 'TRUCK']),
  pickupLat: z.number(),
  pickupLng: z.number(),
  pickupAddress: z.string().min(5),
  pickupInstructions: z.string().optional(),
  dropLat: z.number(),
  dropLng: z.number(),
  dropAddress: z.string().min(5),
  dropInstructions: z.string().optional(),
  packageType: z.enum(['DOCUMENT', 'SMALL_PARCEL', 'MEDIUM_PARCEL', 'LARGE_PARCEL', 'FOOD', 'OTHER']).default('SMALL_PARCEL'),
  packageDescription: z.string().optional(),
  packageWeightKg: z.number().default(0),
  fragile: z.boolean().default(false),
  photoUrl: z.string().optional(),
  paymentMethod: z.enum(['CASH', 'UPI', 'CARD', 'WALLET', 'NETBANKING']).default('UPI'),
  isInstant: z.boolean().default(true),
  scheduledAt: z.string().optional(),
});

// POST /api/orders/create
// Auth: X-API-Key header (for app-level auth) + Bearer token (for user auth)
// Creates an order from a fare quote. The quote is verified server-side
// and the actual prices come from the quote record (not the client).
export async function POST(req: NextRequest) {
  try {
    // Verify user auth
    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Authorization header required' }, { status: 401 });
    }
    const token = authHeader.slice(7);
    let decoded: any;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch {
      return NextResponse.json({ error: 'Invalid or expired token' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = schema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid input', details: parsed.error.flatten() }, { status: 400 });
    }
    const input = parsed.data;

    // Fetch the quote — verify it's not expired and not already consumed
    const quote = await prisma.fareQuote.findUnique({ where: { id: input.quoteId } });
    if (!quote) {
      return NextResponse.json({ error: 'Quote not found' }, { status: 404 });
    }
    if (quote.consumedAt) {
      return NextResponse.json({ error: 'Quote already used' }, { status: 400 });
    }
    if (quote.expiresAt < new Date()) {
      return NextResponse.json({ error: 'Quote expired' }, { status: 400 });
    }

    // Verify the quote matches what the client claims
    const service = await prisma.service.findUnique({ where: { type: input.serviceType } });
    if (!service || service.id !== quote.serviceId) {
      return NextResponse.json({ error: 'Service mismatch with quote' }, { status: 400 });
    }
    if (quote.vehicleType !== input.vehicleType) {
      return NextResponse.json({ error: 'Vehicle type mismatch with quote' }, { status: 400 });
    }

    // Mark quote as consumed
    await prisma.fareQuote.update({
      where: { id: quote.id },
      data: { consumedAt: new Date() },
    });

    // Create the order — prices come from the QUOTE, not from client input
    const order = await prisma.order.create({
      data: {
        code: generateOrderCode(),
        userId: decoded.userId,
        serviceId: service.id,
        state: 'CONFIRMED',
        packageType: input.packageType,
        packageDescription: input.packageDescription,
        packageWeightKg: input.packageWeightKg,
        fragile: input.fragile,
        photoUrl: input.photoUrl,
        pickupLat: input.pickupLat,
        pickupLng: input.pickupLng,
        pickupAddress: input.pickupAddress,
        pickupInstructions: input.pickupInstructions,
        dropLat: input.dropLat,
        dropLng: input.dropLng,
        dropAddress: input.dropAddress,
        dropInstructions: input.dropInstructions,
        distanceKm: quote.distanceKm,
        estimatedMinutes: quote.estimatedMinutes,
        baseFare: quote.baseFare,
        distanceFare: quote.distanceFare,
        timeFare: quote.timeFare,
        platformFee: quote.platformFee,
        taxAmount: quote.taxAmount,
        surgeFee: quote.surgeFee,
        discountAmount: quote.discountAmount,
        totalAmount: quote.totalAmount,
        paymentMethod: input.paymentMethod,
        paymentStatus: 'PENDING',
        isInstant: input.isInstant,
        scheduledAt: input.scheduledAt ? new Date(input.scheduledAt) : null,
        stateHistory: {
          create: [{ state: 'CONFIRMED', actor: decoded.userId, note: 'Order created' }],
        },
      },
      include: {
        service: { select: { id: true, name: true, type: true } },
      },
    });

    // Auto-transition to SEARCHING_PARTNER (will trigger dispatch)
    await transitionOrder(order.id, 'SEARCHING_PARTNER', decoded.userId, 'Looking for delivery partner');

    return NextResponse.json({
      ok: true,
      order: {
        id: order.id,
        code: order.code,
        state: order.state,
        totalAmount: order.totalAmount,
        currency: order.currency,
        distanceKm: order.distanceKm,
        estimatedMinutes: order.estimatedMinutes,
        pickupAddress: order.pickupAddress,
        dropAddress: order.dropAddress,
        service: order.service,
      },
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'Order creation failed', message: err.message }, { status: 500 });
  }
}
