export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

// GET /api/support/me
// Auth: Bearer JWT
// Returns all support tickets for the authenticated user/partner.
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

    const isPartner = decoded.role === 'PARTNER';
    const where = isPartner
      ? { partnerId: decoded.userId }
      : { userId: decoded.userId };

    const tickets = await prisma.supportTicket.findMany({
      where,
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
          take: 1, // Just the latest message for preview
        },
        _count: { select: { messages: true } },
      },
      orderBy: { createdAt: 'desc' },
    });

    return NextResponse.json({
      tickets: tickets.map((t) => ({
        id: t.id,
        code: t.code,
        subject: t.subject,
        category: t.category,
        priority: t.priority,
        status: t.status,
        messageCount: t._count.messages,
        lastMessage: t.messages[0]?.body ?? null,
        createdAt: t.createdAt,
      })),
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
