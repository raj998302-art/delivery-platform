export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

const schema = z.object({
  orderId: z.string(),
  score: z.number().int().min(1).max(5),
  comment: z.string().optional(),
});

// POST /api/ratings
// Auth: Bearer JWT
// Submits a rating for a completed order.
export async function POST(req: NextRequest) {
  try {
    const authHeader = req.headers.get('authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return NextResponse.json({ error: 'Authorization required' }, { status: 401 });
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

    const { orderId, score, comment } = parsed.data;

    // Verify the order belongs to the user and is in a rateable state
    const order = await prisma.order.findUnique({ where: { id: orderId } });
    if (!order) {
      return NextResponse.json({ error: 'Order not found' }, { status: 404 });
    }
    if (order.userId !== decoded.userId) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 403 });
    }
    if (!['COMPLETED', 'DELIVERED'].includes(order.state)) {
      return NextResponse.json({ error: 'Order must be completed before rating' }, { status: 400 });
    }

    // Check if already rated
    const existingRating = await prisma.rating.findUnique({ where: { orderId } });
    if (existingRating) {
      return NextResponse.json({ error: 'Order already rated' }, { status: 400 });
    }

    // Create the rating
    const rating = await prisma.rating.create({
      data: {
        orderId,
        fromUserId: decoded.userId,
        toPartnerId: order.partnerId,
        score,
        comment,
      },
    });

    // Update partner's aggregate rating
    if (order.partnerId) {
      const partner = await prisma.partner.findUnique({ where: { id: order.partnerId } });
      if (partner) {
        const newTotalRatings = partner.totalRatings + 1;
        const newRating = (partner.rating * partner.totalRatings + score) / newTotalRatings;
        await prisma.partner.update({
          where: { id: order.partnerId },
          data: {
            rating: Math.round(newRating * 100) / 100,
            totalRatings: newTotalRatings,
          },
        });
      }
    }

    return NextResponse.json({
      ok: true,
      rating: {
        id: rating.id,
        score: rating.score,
        comment: rating.comment,
      },
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'Rating submission failed', message: err.message }, { status: 500 });
  }
}
