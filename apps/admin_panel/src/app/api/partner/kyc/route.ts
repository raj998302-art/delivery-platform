export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

const schema = z.object({
  aadhaarNumber: z.string().optional(),
  panNumber: z.string().optional(),
  drivingLicense: z.string().optional(),
  bankAccount: z.string().optional(),
  ifsc: z.string().optional(),
  upiId: z.string().optional(),
  documents: z.array(z.object({
    type: z.enum(['LICENSE', 'AADHAAR', 'PAN', 'RC', 'INSURANCE', 'PUC', 'PHOTO']),
    url: z.string(),
  })).default([]),
});

// POST /api/partner/kyc
// Auth: Bearer JWT (partner)
// Submits KYC documents for verification.
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
      return NextResponse.json({ error: 'Invalid token' }, { status: 401 });
    }

    const body = await req.json();
    const parsed = schema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid input', details: parsed.error.flatten() }, { status: 400 });
    }

    // Find partner by phone
    const partner = await prisma.partner.findFirst({ where: { phone: decoded.phone } });
    if (!partner) {
      return NextResponse.json({ error: 'Partner profile not found' }, { status: 404 });
    }

    const { aadhaarNumber, panNumber, drivingLicense, bankAccount, ifsc, upiId, documents } = parsed.data;

    // Update partner profile with KYC data
    await prisma.partnerProfile.upsert({
      where: { partnerId: partner.id },
      update: { aadhaarNumber, panNumber, drivingLicense, bankAccount, ifsc, upiId },
      create: { partnerId: partner.id, aadhaarNumber, panNumber, drivingLicense, bankAccount, ifsc, upiId },
    });

    // Create document records
    if (documents.length > 0) {
      // Delete old documents first
      await prisma.partnerDocument.deleteMany({ where: { partnerId: partner.id } });
      // Create new ones
      await prisma.partnerDocument.createMany({
        data: documents.map((d) => ({
          partnerId: partner.id,
          type: d.type,
          url: d.url,
          status: 'PENDING',
        })),
      });
    }

    // Update partner status to PENDING (awaiting verification)
    await prisma.partner.update({
      where: { id: partner.id },
      data: { status: 'PENDING' },
    });

    return NextResponse.json({
      ok: true,
      message: 'KYC submitted successfully. Verification in progress.',
      kycStatus: 'PENDING',
      documentsSubmitted: documents.length,
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
