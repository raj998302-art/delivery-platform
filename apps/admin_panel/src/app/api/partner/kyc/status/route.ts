export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

// GET /api/partner/kyc/status
// Auth: Bearer JWT (partner)
// Returns the partner's KYC verification status + document list.
export async function GET(req: NextRequest) {
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

    const partner = await prisma.partner.findFirst({
      where: { phone: decoded.phone },
      include: {
        profile: true,
        documents: true,
        vehicles: true,
      },
    });

    if (!partner) {
      return NextResponse.json({ error: 'Partner profile not found' }, { status: 404 });
    }

    // Calculate verification progress
    const requiredDocs = ['LICENSE', 'AADHAAR', 'PAN', 'RC', 'INSURANCE', 'PHOTO'];
    const submittedDocs = partner.documents.map((d) => d.type);
    const verifiedDocs = partner.documents.filter((d) => d.status === 'VERIFIED').map((d) => d.type);
    const pendingDocs = partner.documents.filter((d) => d.status === 'PENDING').map((d) => d.type);
    const rejectedDocs = partner.documents.filter((d) => d.status === 'REJECTED').map((d) => d.type);
    const missingDocs = requiredDocs.filter((r) => !submittedDocs.includes(r as any));

    const progress = Math.round((verifiedDocs.length / requiredDocs.length) * 100);
    const isVerified = partner.status === 'APPROVED' || partner.status === 'ONLINE' || partner.status === 'ON_DELIVERY';

    return NextResponse.json({
      kycStatus: partner.status,
      isVerified,
      progress,
      profile: partner.profile ? {
        aadhaarNumber: partner.profile.aadhaarNumber,
        panNumber: partner.profile.panNumber,
        drivingLicense: partner.profile.drivingLicense,
        bankAccount: partner.profile.bankAccount,
        ifsc: partner.profile.ifsc,
        upiId: partner.profile.upiId,
      } : null,
      documents: partner.documents.map((d) => ({
        id: d.id,
        type: d.type,
        url: d.url,
        status: d.status,
      })),
      summary: {
        total: requiredDocs.length,
        verified: verifiedDocs.length,
        pending: pendingDocs.length,
        rejected: rejectedDocs.length,
        missing: missingDocs.length,
        missingTypes: missingDocs,
      },
      vehicles: partner.vehicles.map((v) => ({
        id: v.id,
        type: v.type,
        registrationNumber: v.registrationNumber,
        model: v.model,
        isPrimary: v.isPrimary,
      })),
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
