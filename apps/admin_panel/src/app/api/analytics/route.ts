
export const dynamic = 'force-dynamic';

import { NextRequest, NextResponse } from 'next/server';


import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';

// GET /api/analytics — KPI summary + time-series for the dashboard
export async function GET(req: NextRequest) {
  const session = await getSession();
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const now = new Date();
  const last24h = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const last7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
  const last30d = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);

  const [
    totalOrders,
    orders24h,
    completedOrders,
    cancelledOrders,
    totalRevenue,
    revenue30d,
    totalUsers,
    users24h,
    totalPartners,
    onlinePartners,
    activeOrders,
    avgRating,
  ] = await Promise.all([
    prisma.order.count(),
    prisma.order.count({ where: { createdAt: { gte: last24h } } }),
    prisma.order.count({ where: { state: 'COMPLETED' } }),
    prisma.order.count({ where: { state: 'CANCELLED' } }),
    prisma.order.aggregate({ _sum: { totalAmount: true }, where: { paymentStatus: 'PAID' } }),
    prisma.order.aggregate({ _sum: { totalAmount: true }, where: { createdAt: { gte: last30d }, paymentStatus: 'PAID' } }),
    prisma.user.count({ where: { deletedAt: null } }),
    prisma.user.count({ where: { createdAt: { gte: last24h } } }),
    prisma.partner.count({ where: { deletedAt: null } }),
    prisma.partner.count({ where: { isOnline: true } }),
    prisma.order.count({ where: { state: { in: ['SEARCHING_PARTNER', 'PARTNER_ASSIGNED', 'PARTNER_ACCEPTED', 'PICKED_UP', 'IN_TRANSIT', 'ARRIVING'] } } }),
    prisma.rating.aggregate({ _avg: { score: true } }),
  ]);

  // Hourly orders for the last 24 hours (time-series)
  const hourlyBuckets: { hour: string; count: number; revenue: number }[] = [];
  for (let h = 23; h >= 0; h--) {
    const start = new Date(now.getTime() - (h + 1) * 60 * 60 * 1000);
    const end = new Date(now.getTime() - h * 60 * 60 * 1000);
    const [cnt, rev] = await Promise.all([
      prisma.order.count({ where: { createdAt: { gte: start, lt: end } } }),
      prisma.order.aggregate({
        _sum: { totalAmount: true },
        where: { createdAt: { gte: start, lt: end }, paymentStatus: 'PAID' },
      }),
    ]);
    hourlyBuckets.push({
      hour: start.toISOString().slice(0, 16),
      count: cnt,
      revenue: rev._sum.totalAmount ?? 0,
    });
  }

  // Daily orders for the last 7 days
  const dailyBuckets: { day: string; count: number; revenue: number }[] = [];
  for (let d = 6; d >= 0; d--) {
    const start = new Date(now.getTime() - (d + 1) * 24 * 60 * 60 * 1000);
    start.setHours(0, 0, 0, 0);
    const end = new Date(start.getTime() + 24 * 60 * 60 * 1000);
    const [cnt, rev] = await Promise.all([
      prisma.order.count({ where: { createdAt: { gte: start, lt: end } } }),
      prisma.order.aggregate({
        _sum: { totalAmount: true },
        where: { createdAt: { gte: start, lt: end }, paymentStatus: 'PAID' },
      }),
    ]);
    dailyBuckets.push({
      day: start.toISOString().slice(0, 10),
      count: cnt,
      revenue: rev._sum.totalAmount ?? 0,
    });
  }

  // Orders by service type
  const ordersByService = await prisma.order.groupBy({
    by: ['serviceId'],
    _count: { _all: true },
    _sum: { totalAmount: true },
  });
  const services = await prisma.service.findMany();
  const byService = ordersByService.map((g) => {
    const s = services.find((x) => x.id === g.serviceId);
    return {
      service: s?.name ?? 'Unknown',
      type: s?.type ?? 'UNKNOWN',
      count: g._count._all,
      revenue: g._sum.totalAmount ?? 0,
    };
  });

  // Orders by state
  const ordersByState = await prisma.order.groupBy({
    by: ['state'],
    _count: { _all: true },
  });

  return NextResponse.json({
    kpis: {
      totalOrders,
      orders24h,
      completedOrders,
      cancelledOrders,
      cancellationRate: totalOrders > 0 ? (cancelledOrders / totalOrders) * 100 : 0,
      totalRevenue: totalRevenue._sum.totalAmount ?? 0,
      revenue30d: revenue30d._sum.totalAmount ?? 0,
      totalUsers,
      users24h,
      totalPartners,
      onlinePartners,
      activeOrders,
      avgRating: avgRating._avg.score ?? 0,
    },
    hourly: hourlyBuckets,
    daily: dailyBuckets,
    byService,
    byState: ordersByState.map((s) => ({ state: s.state, count: s._count._all })),
  });
}
