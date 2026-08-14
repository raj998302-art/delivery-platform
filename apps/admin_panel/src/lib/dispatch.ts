// ============================================================================
// Mock Dispatch Engine — finds nearby eligible partners and ranks them.
// In production this would be backed by PostGIS + Redis geospatial.
// ============================================================================

import { prisma } from './db';
import { haversineKm } from './utils';
import type { VehicleType, PartnerStatus } from '@prisma/client';

export interface RankedPartner {
  partnerId: string;
  name: string;
  phone: string;
  distanceKm: number;
  rating: number;
  acceptanceRate: number;
  completionRate: number;
  currentLoad: number;
  score: number;
}

export async function findNearbyPartners(
  pickupLat: number,
  pickupLng: number,
  vehicleType?: VehicleType,
  radiusKm: number = 5,
  limit: number = 10
): Promise<RankedPartner[]> {
  // Pull all online partners (in production this is a PostGIS/Redis query)
  const partners = await prisma.partner.findMany({
    where: {
      status: { in: ['ONLINE' as PartnerStatus] },
      isOnline: true,
      currentLat: { not: null },
      currentLng: { not: null },
      deletedAt: null,
      ...(vehicleType
        ? { vehicles: { some: { type: vehicleType } } }
        : {}),
    },
    include: {
      vehicles: true,
      assignments: {
        where: { status: 'PENDING' },
        select: { id: true },
      },
    },
    take: 200,
  });

  const ranked: RankedPartner[] = partners
    .map((p) => {
      const distance = haversineKm(
        pickupLat,
        pickupLng,
        p.currentLat!,
        p.currentLng!
      );
      return { p, distance };
    })
    .filter((x) => x.distance <= radiusKm)
    .map(({ p, distance }) => {
      // Weighted ranking: distance (40%), rating (25%), acceptance (15%), completion (10%), load (10%)
      const loadScore = Math.max(0, 1 - p.assignments.length / 3);
      const distanceScore = Math.max(0, 1 - distance / radiusKm);
      const ratingScore = p.rating / 5;
      const acceptanceScore = p.acceptanceRate;
      const completionScore = p.completionRate;
      const score =
        distanceScore * 0.4 +
        ratingScore * 0.25 +
        acceptanceScore * 0.15 +
        completionScore * 0.1 +
        loadScore * 0.1;

      return {
        partnerId: p.id,
        name: `${p.firstName} ${p.lastName}`,
        phone: p.phone,
        distanceKm: distance,
        rating: p.rating,
        acceptanceRate: p.acceptanceRate,
        completionRate: p.completionRate,
        currentLoad: p.assignments.length,
        score,
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);

  return ranked;
}

export async function dispatchOrder(orderId: string): Promise<RankedPartner[]> {
  const order = await prisma.order.findUnique({
    where: { id: orderId },
    include: { service: true },
  });
  if (!order) throw new Error('Order not found');

  // Get vehicle type from service config — fallback to BIKE
  const vehicleType: VehicleType | undefined = (order as any).vehicleType ?? 'BIKE';

  const candidates = await findNearbyPartners(
    order.pickupLat,
    order.pickupLng,
    vehicleType
  );

  // Create assignment records for top N (default 3) — first to accept wins
  const top = candidates.slice(0, 3);
  const expiresAt = new Date(Date.now() + 15 * 1000); // 15-second window

  await prisma.partnerAssignment.createMany({
    data: top.map((c) => ({
      orderId,
      partnerId: c.partnerId,
      expiresAt,
    })),
    skipDuplicates: true,
  });

  return top;
}
