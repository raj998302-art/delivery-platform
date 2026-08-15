
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { z } from 'zod';
import { authenticateAdmin, signSession, setSessionCookie } from '@/lib/auth';
import { prisma } from '@/lib/db';

const schema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const parsed = schema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json({ error: 'Invalid input', details: parsed.error.flatten() }, { status: 400 });
    }

    const admin = await authenticateAdmin(parsed.data.email, parsed.data.password);
    if (!admin) {
      return NextResponse.json({ error: 'Invalid credentials' }, { status: 401 });
    }

    const session = {
      userId: admin.id,
      email: admin.email,
      name: admin.name,
      role: admin.role,
    };
    const token = signSession(session);
    await setSessionCookie(token);

    await prisma.auditLog.create({
      data: {
        actorId: admin.id,
        actorRole: admin.role,
        action: 'ADMIN_LOGIN',
        entityType: 'AdminUser',
        entityId: admin.id,
        ipAddress: req.headers.get('x-forwarded-for') || undefined,
        userAgent: req.headers.get('user-agent') || undefined,
      },
    });

    return NextResponse.json({ user: session });
  } catch (err: any) {
    return NextResponse.json({ error: 'Login failed', message: err.message }, { status: 500 });
  }
}
