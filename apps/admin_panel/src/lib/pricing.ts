// ============================================================================
// Pricing Engine — Backend authoritative pricing
// total = baseFare + distanceFare + timeFare + platformFee + surgeFee + tax - discount
// All pricing rules are configurable via the Service / PricingRule tables.
// ============================================================================

import { prisma } from './db';
import { haversineKm, estimateMinutes } from './utils';
import type { ServiceType, VehicleType } from '@prisma/client';

export interface FareBreakdown {
  quoteId: string;
  serviceId: string;
  serviceType: ServiceType;
  vehicleType: VehicleType;
  distanceKm: number;
  estimatedMinutes: number;
  baseFare: number;
  distanceFare: number;
  timeFare: number;
  platformFee: number;
  taxAmount: number;
  surgeFee: number;
  discountAmount: number;
  totalAmount: number;
  currency: string;
  expiresAt: Date;
}

export interface PricingInput {
  serviceType: ServiceType;
  vehicleType: VehicleType;
  pickupLat: number;
  pickupLng: number;
  dropLat: number;
  dropLng: number;
  userId?: string;
  couponCode?: string;
}

export async function computeFare(input: PricingInput): Promise<FareBreakdown> {
  const distanceKm = haversineKm(
    input.pickupLat,
    input.pickupLng,
    input.dropLat,
    input.dropLng
  );
  const estimatedMinutes = estimateMinutes(distanceKm);

  const service = await prisma.service.findUnique({
    where: { type: input.serviceType },
  });
  if (!service || !service.isActive) {
    throw new Error(`Service ${input.serviceType} is not available`);
  }

  // Find a service-specific pricing rule, else fall back to service defaults
  const rule = await prisma.pricingRule.findFirst({
    where: {
      OR: [
        { serviceId: service.id, vehicleType: input.vehicleType, isActive: true },
        { serviceId: service.id, vehicleType: null, isActive: true },
        { serviceId: null, vehicleType: input.vehicleType, isActive: true },
      ],
    },
    orderBy: [{ priority: 'desc' }],
  });

  // Find vehicle multiplier
  const vehicleConf = await prisma.vehicleTypeConfig.findUnique({
    where: { type: input.vehicleType },
  });
  const vehicleMultiplier = vehicleConf?.multiplier ?? 1.0;

  const baseFare = rule?.baseFare ?? service.baseFare;
  const perKm = rule?.perKm ?? service.perKm;
  const perMin = rule?.perMin ?? service.perMin;
  const platformFee = rule?.platformFee ?? service.platformFee;
  const taxPercent = rule?.taxPercent ?? service.taxPercent;
  const minFare = rule?.minFare ?? service.minFare;
  const surgeMultiplier = rule?.surgeMultiplier ?? 1.0;

  let distanceFare = Math.round(perKm * distanceKm * vehicleMultiplier);
  let timeFare = Math.round(perMin * estimatedMinutes * vehicleMultiplier);
  let baseWithVehicle = Math.round(baseFare * vehicleMultiplier);
  let surgeFee = Math.round((baseWithVehicle + distanceFare + timeFare) * (surgeMultiplier - 1));

  let subtotal = baseWithVehicle + distanceFare + timeFare + platformFee + surgeFee;
  let taxAmount = Math.round((subtotal * taxPercent) / 100);
  let total = subtotal + taxAmount;

  // Apply minimum fare
  if (total < minFare) total = minFare;

  // Coupon / discount
  let discountAmount = 0;
  if (input.couponCode) {
    const coupon = await prisma.coupon.findUnique({
      where: { code: input.couponCode },
    });
    if (coupon && coupon.isActive && (!coupon.expiresAt || coupon.expiresAt > new Date())) {
      if (total >= coupon.minOrderValue) {
        if (coupon.type === 'FLAT') {
          discountAmount = Math.min(coupon.value, coupon.maxDiscount ?? coupon.value);
        } else {
          // PERCENT
          const pct = Math.min(coupon.value, 100);
          discountAmount = Math.round((total * pct) / 100);
          if (coupon.maxDiscount) discountAmount = Math.min(discountAmount, coupon.maxDiscount);
        }
      }
    }
  }

  total = Math.max(0, total - discountAmount);

  const quoteId = `q_${Date.now().toString(36)}${Math.random().toString(36).slice(2, 8)}`;
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min

  // Persist the quote
  await prisma.fareQuote.create({
    data: {
      id: quoteId,
      userId: input.userId,
      serviceId: service.id,
      vehicleType: input.vehicleType,
      pickupLat: input.pickupLat,
      pickupLng: input.pickupLng,
      dropLat: input.dropLat,
      dropLng: input.dropLng,
      distanceKm,
      estimatedMinutes,
      baseFare: baseWithVehicle,
      distanceFare,
      timeFare,
      platformFee,
      taxAmount,
      surgeFee,
      discountAmount,
      totalAmount: total,
      expiresAt,
    },
  });

  return {
    quoteId,
    serviceId: service.id,
    serviceType: input.serviceType,
    vehicleType: input.vehicleType,
    distanceKm,
    estimatedMinutes,
    baseFare: baseWithVehicle,
    distanceFare,
    timeFare,
    platformFee,
    taxAmount,
    surgeFee,
    discountAmount,
    totalAmount: total,
    currency: 'INR',
    expiresAt,
  };
}
