export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';

const schema = z.object({
  phone: z.string().min(10).max(15),
  code: z.string().length(6),
});

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';
const ACCESS_TOKEN_EXPIRY = '24h';
const REFRESH_TOKEN_EXPIRY_DAYS = 30;

// POST /api/auth/otp/verify
// Public endpoint — verifies the OTP and returns user + access/refresh tokens.
export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const parsed = schema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid input' }, { status: 400 });
    }

    const { phone, code } = parsed.data;

    // Find the most recent unused OTP for this phone
    const otpReq = await prisma.otpRequest.findFirst({
      where: {
        phone,
        verified: false,
        expiresAt: { gte: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpReq) {
      return NextResponse.json({ error: 'OTP expired or not found. Request a new one.' }, { status: 404 });
    }

    if (otpReq.attempts >= 5) {
      return NextResponse.json({ error: 'Too many attempts. Request a new OTP.' }, { status: 429 });
    }

    // Increment attempt counter
    await prisma.otpRequest.update({
      where: { id: otpReq.id },
      data: { attempts: { increment: 1 } },
    });

    // Verify code
    const valid = await bcrypt.compare(code, otpReq.codeHash);
    if (!valid) {
      return NextResponse.json({ error: 'Invalid OTP' }, { status: 401 });
    }

    // Mark as verified
    await prisma.otpRequest.update({
      where: { id: otpReq.id },
      data: { verified: true },
    });

    // Get or create user
    let user = await prisma.user.findUnique({ where: { phone } });
    if (!user) {
      user = await prisma.user.create({ data: { phone } });
    }

    // Update phoneVerified timestamp
    await prisma.user.update({
      where: { id: user.id },
      data: { phoneVerified: new Date(), lastLoginAt: new Date() },
    });

    // Generate access token (JWT) — contains userId, phone, role
    const accessToken = jwt.sign(
      { userId: user.id, phone: user.phone, role: user.role },
      JWT_SECRET,
      { expiresIn: ACCESS_TOKEN_EXPIRY } as jwt.SignOptions
    );

    // Generate refresh token (random string, stored in DB)
    const refreshToken = require('crypto').randomBytes(40).toString('hex');
    const refreshExpiresAt = new Date(Date.now() + REFRESH_TOKEN_EXPIRY_DAYS * 24 * 60 * 60 * 1000);
    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt: refreshExpiresAt,
        userAgent: req.headers.get('user-agent') || undefined,
        ipAddress: req.headers.get('x-forwarded-for') || undefined,
      },
    });

    return NextResponse.json({
      ok: true,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        role: user.role,
        isGuest: user.isGuest,
      },
      tokens: {
        access: accessToken,
        refresh: refreshToken,
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      },
    });
  } catch (err: any) {
    return NextResponse.json({ error: 'OTP verify failed', message: err.message }, { status: 500 });
  }
}
