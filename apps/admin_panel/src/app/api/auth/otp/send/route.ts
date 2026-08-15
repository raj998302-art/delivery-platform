export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { prisma } from '@/lib/db';

const schema = z.object({
  phone: z.string().min(10).max(15),
  channel: z.enum(['sms', 'whatsapp', 'voice']).default('sms'),
});

// POST /api/auth/otp/send
// Public endpoint — used by Flutter apps to request an OTP.
// In production this would call MSG91 / Twilio. For MVP we generate
// a 6-digit code, hash it, and store it. The code is returned in the
// response (only in dev) so the Flutter app can auto-fill for testing.
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const parsed = schema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid input', details: parsed.error.flatten() }, { status: 400 });
    }

    const { phone, channel } = parsed.data;

    // Rate limit: max 3 OTP requests per phone in 10 minutes
    const recent = await prisma.otpRequest.count({
      where: {
        phone,
        createdAt: { gte: new Date(Date.now() - 10 * 60 * 1000) },
      },
    });
    if (recent >= 3) {
      return NextResponse.json({ error: 'Too many OTP requests. Try again later.' }, { status: 429 });
    }

    // Generate 6-digit code
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const codeHash = await bcrypt.hash(code, 10);

    // Find or create user by phone
    let user = await prisma.user.findUnique({ where: { phone } });
    if (!user) {
      user = await prisma.user.create({
        data: { phone, isGuest: false },
      });
    }

    // Store OTP request — expires in 5 minutes
    await prisma.otpRequest.create({
      data: {
        userId: user.id,
        phone,
        channel,
        codeHash,
        expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      },
    });

    // In production: send via MSG91 / Twilio here.
    // For MVP: return the code in the response so the Flutter app can auto-fill.
    return NextResponse.json({
      ok: true,
      phone,
      channel,
      // DEV ONLY: in production, remove `code` from the response.
      // The Flutter app should prompt the user to enter the OTP manually.
      code,
      expiresIn: 300,
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'OTP send failed', message: err.message }, { status: 500 });
  }
}
