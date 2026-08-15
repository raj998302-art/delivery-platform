export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';
import jwt from 'jsonwebtoken';
import { prisma } from '@/lib/db';
import { generateTicketCode } from '@/lib/utils';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';

const schema = z.object({
  subject: z.string().min(5),
  category: z.enum(['ORDER_ISSUE', 'PAYMENT', 'PARTNER', 'APP_BUG', 'ACCOUNT', 'OTHER']).default('OTHER'),
  priority: z.enum(['LOW', 'NORMAL', 'HIGH', 'URGENT']).default('NORMAL'),
  message: z.string().min(5),
  orderId: z.string().optional(),
});

// POST /api/support
// Auth: Bearer JWT (user or partner)
// Creates a support ticket + first message. Available 24/7.
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

    const { subject, category, priority, message, orderId } = parsed.data;

    // Determine if user or partner based on role
    const isPartner = decoded.role === 'PARTNER';

    const ticket = await prisma.supportTicket.create({
      data: {
        code: generateTicketCode(),
        userId: isPartner ? null : decoded.userId,
        partnerId: isPartner ? decoded.userId : null,
        orderId,
        subject,
        category,
        priority,
        status: 'OPEN',
        messages: {
          create: {
            fromId: decoded.userId,
            fromRole: isPartner ? 'PARTNER' : 'USER',
            body: message,
          },
        },
      },
      include: {
        messages: true,
      },
    });

    return NextResponse.json({
      ok: true,
      ticket: {
        id: ticket.id,
        code: ticket.code,
        subject: ticket.subject,
        status: ticket.status,
        createdAt: ticket.createdAt,
      },
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
