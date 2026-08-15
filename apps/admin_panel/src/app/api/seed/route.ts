export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { prisma } from '@/lib/db';
import { hashPassword } from '@/lib/auth';

// GET /api/seed — bootstraps minimal demo data for testing.
// Keeps only what's needed: 1 owner, 1 demo user, 1 demo partner, a few orders.
// Idempotent: cleans up existing demo data first, then re-creates.
export async function GET() {
  const results: string[] = [];

  // 0. Clean up existing demo data (non-destructive to owner)
  await prisma.order.deleteMany({ where: { code: { startsWith: 'DP-' } } });
  await prisma.partner.deleteMany({});
  await prisma.user.deleteMany({ where: { phone: { contains: '99000' } } });
  await prisma.fareQuote.deleteMany({});
  results.push('Cleaned up existing demo data');

  // 1. OWNER account — raj998302@gmail.com / RAJ998302
  const ownerEmail = 'raj998302@gmail.com';
  const ownerPassword = 'RAJ998302';
  const existingOwner = await prisma.adminUser.findUnique({ where: { email: ownerEmail } });
  if (existingOwner) {
    // Update password + ensure OWNER role
    await prisma.adminUser.update({
      where: { id: existingOwner.id },
      data: {
        passwordHash: await hashPassword(ownerPassword),
        role: 'OWNER',
        name: 'ZENUS (Owner)',
        isActive: true,
      },
    });
    results.push(`Owner account updated: ${ownerEmail} (OWNER role)`);
  } else {
    await prisma.adminUser.create({
      data: {
        email: ownerEmail,
        passwordHash: await hashPassword(ownerPassword),
        name: 'ZENUS (Owner)',
        role: 'OWNER',
      },
    });
    results.push(`Owner account created: ${ownerEmail} / ${ownerPassword} (OWNER role)`);
  }

  // 2. Default admin (keep for backward compat)
  const existingAdmin = await prisma.adminUser.findUnique({ where: { email: 'admin@delivery.local' } });
  if (!existingAdmin) {
    await prisma.adminUser.create({
      data: {
        email: 'admin@delivery.local',
        passwordHash: await hashPassword('admin123'),
        name: 'Super Admin',
        role: 'SUPER_ADMIN',
      },
    });
    results.push('Created default admin: admin@delivery.local / admin123');
  } else {
    results.push('Default admin already exists');
  }

  // 3. Vehicle types + services (catalog — keep all)
  const vehicleTypes = [
    { type: 'BIKE', name: 'Bike', icon: 'motorcycle', capacityKg: 10, multiplier: 1.0 },
    { type: 'SCOOTER', name: 'Scooter', icon: 'bike', capacityKg: 15, multiplier: 1.0 },
    { type: 'AUTO', name: 'Auto Rickshaw', icon: 'car', capacityKg: 100, multiplier: 1.5 },
    { type: 'MINI_TRUCK', name: 'Mini Truck', icon: 'truck', capacityKg: 500, multiplier: 2.0 },
    { type: 'TRUCK', name: 'Truck', icon: 'truck', capacityKg: 1500, multiplier: 3.0 },
  ];
  for (const vt of vehicleTypes) {
    await prisma.vehicleTypeConfig.upsert({
      where: { type: vt.type as any },
      update: { name: vt.name, capacityKg: vt.capacityKg, multiplier: vt.multiplier },
      create: vt as any,
    });
  }

  const services = [
    { type: 'PARCEL', name: 'Parcel Delivery', baseFare: 30, perKm: 10, perMin: 1, platformFee: 8, taxPercent: 5, minFare: 50, sortOrder: 1 },
    { type: 'BIKE', name: 'Bike Taxi', baseFare: 25, perKm: 8, perMin: 1, platformFee: 5, taxPercent: 5, minFare: 40, sortOrder: 2 },
    { type: 'AUTO', name: 'Auto Ride', baseFare: 35, perKm: 12, perMin: 1, platformFee: 6, taxPercent: 5, minFare: 60, sortOrder: 3 },
    { type: 'MINI_TRUCK', name: 'Mini Truck', baseFare: 150, perKm: 25, perMin: 2, platformFee: 20, taxPercent: 5, minFare: 250, sortOrder: 4 },
    { type: 'TRUCK', name: 'Truck', baseFare: 300, perKm: 40, perMin: 3, platformFee: 40, taxPercent: 5, minFare: 500, sortOrder: 5 },
    { type: 'FOOD', name: 'Food Delivery', baseFare: 20, perKm: 8, perMin: 1, platformFee: 5, taxPercent: 5, minFare: 35, sortOrder: 6 },
    { type: 'GROCERY', name: 'Grocery Delivery', baseFare: 25, perKm: 9, perMin: 1, platformFee: 6, taxPercent: 5, minFare: 40, sortOrder: 7 },
    { type: 'MEDICINE', name: 'Medicine Delivery', baseFare: 20, perKm: 8, perMin: 1, platformFee: 4, taxPercent: 5, minFare: 30, sortOrder: 8 },
  ];
  for (const s of services) {
    const svc = await prisma.service.upsert({
      where: { type: s.type as any },
      update: { name: s.name, baseFare: s.baseFare, perKm: s.perKm, perMin: s.perMin, platformFee: s.platformFee, taxPercent: s.taxPercent, minFare: s.minFare },
      create: s as any,
    });
    const allVts = await prisma.vehicleTypeConfig.findMany();
    for (const vt of allVts) {
      await prisma.serviceVehicleType.upsert({
        where: { serviceId_vehicleType: { serviceId: svc.id, vehicleType: vt.type as any } },
        update: {},
        create: { serviceId: svc.id, vehicleType: vt.type },
      });
    }
  }
  results.push(`Catalog: ${vehicleTypes.length} vehicle types, ${services.length} services`);

  // 4. Service zone — Salt Lake Sector V
  const zone = await prisma.serviceZone.upsert({
    where: { name: 'Salt Lake Sector V' },
    update: {},
    create: {
      name: 'Salt Lake Sector V',
      city: 'Kolkata',
      minLat: 22.570, maxLat: 22.590,
      minLng: 88.420, maxLng: 88.440,
    },
  });

  // 5. ONE demo partner — near Nayapatti Main Road (within 500m)
  const CENTER_LAT = 22.5803;
  const CENTER_LNG = 88.4284;
  await prisma.partner.create({
    data: {
      firstName: 'Ramesh',
      lastName: 'Kumar',
      phone: '+919800000001',
      email: 'ramesh@delivery.local',
      status: 'ONLINE',
      isOnline: true,
      currentLat: 22.5808,  // ~50m from center
      currentLng: 88.4292,
      lastLocationAt: new Date(),
      rating: 4.8,
      totalRatings: 156,
      acceptanceRate: 0.92,
      completionRate: 0.98,
      totalDeliveries: 312,
      totalEarnings: 28450,
      serviceZoneId: zone.id,
      profile: { create: { upiId: 'ramesh@okhdfcbank', onboardedAt: new Date() } },
      vehicles: {
        create: [{
          type: 'BIKE',
          registrationNumber: 'WB01AB1234',
          model: 'Honda Activa 6G',
          capacityKg: 10,
          isPrimary: true,
        }],
      },
      wallets: { create: { balance: 3250 } },
    },
  });
  results.push('Created 1 demo partner: Ramesh Kumar (BIKE, online, 50m from Nayapatti)');

  // 6. ONE demo user
  await prisma.user.create({
    data: {
      phone: '+919900000001',
      name: 'Demo User',
      phoneVerified: new Date(),
      profile: { create: { firstName: 'Demo', lastName: 'User' } },
      wallets: { create: { balance: 500 } },
    },
  });
  results.push('Created 1 demo user: +919900000001 (Demo User)');

  // 7. THREE test orders — pickup/drop around Salt Lake Sector V
  const svc = await prisma.service.findUnique({ where: { type: 'PARCEL' } });
  const partner = await prisma.partner.findFirst();
  const user = await prisma.user.findFirst();

  if (svc && partner && user) {
    const testOrders = [
      {
        code: 'DP-TEST001',
        pickup: { addr: 'DN-21, Salt Lake Sector V, Kolkata', lat: 22.5800, lng: 88.4288 },
        drop: { addr: 'Webel Crossing, Sector V, Kolkata', lat: 22.5785, lng: 88.4295 },
        state: 'COMPLETED' as const,
        hoursAgo: 5,
      },
      {
        code: 'DP-TEST002',
        pickup: { addr: 'Nayapatti Main Road, Sector V, Kolkata', lat: 22.5803, lng: 88.4284 },
        drop: { addr: 'College More, Sector V, Kolkata', lat: 22.5820, lng: 88.4270 },
        state: 'IN_TRANSIT' as const,
        hoursAgo: 1,
      },
      {
        code: 'DP-TEST003',
        pickup: { addr: 'Karunamoyee, Sector V, Kolkata', lat: 22.5790, lng: 88.4300 },
        drop: { addr: 'Chingrighata, Sector V, Kolkata', lat: 22.5770, lng: 88.4250 },
        state: 'SEARCHING_PARTNER' as const,
        hoursAgo: 0,
      },
    ];

    for (const o of testOrders) {
      const distanceKm = Math.sqrt(
        Math.pow((o.pickup.lat - o.drop.lat) * 111, 2) +
        Math.pow((o.pickup.lng - o.drop.lng) * 102.5, 2)
      );
      const roundedDist = Math.max(0.5, Math.round(distanceKm * 10) / 10);
      const baseFare = svc.baseFare;
      const distanceFare = Math.round(svc.perKm * roundedDist);
      const timeFare = Math.round(svc.perMin * Math.max(5, roundedDist * 3));
      const platformFee = svc.platformFee;
      const taxAmount = Math.round(((baseFare + distanceFare + timeFare + platformFee) * svc.taxPercent) / 100);
      const total = baseFare + distanceFare + timeFare + platformFee + taxAmount;
      const createdAt = new Date(Date.now() - o.hoursAgo * 3600 * 1000);

      await prisma.order.create({
        data: {
          code: o.code,
          userId: user.id,
          partnerId: partner.id,
          serviceId: svc.id,
          state: o.state,
          packageType: 'SMALL_PARCEL',
          packageWeightKg: 2.5,
          pickupLat: o.pickup.lat,
          pickupLng: o.pickup.lng,
          pickupAddress: o.pickup.addr,
          dropLat: o.drop.lat,
          dropLng: o.drop.lng,
          dropAddress: o.drop.addr,
          distanceKm: roundedDist,
          estimatedMinutes: Math.max(5, Math.round(roundedDist * 3)),
          baseFare,
          distanceFare,
          timeFare,
          platformFee,
          taxAmount,
          totalAmount: total,
          paymentMethod: 'UPI',
          paymentStatus: o.state === 'COMPLETED' ? 'PAID' : ((o.state as string) === 'CANCELLED' ? 'FAILED' : 'PENDING'),
          completedAt: o.state === 'COMPLETED' ? new Date(createdAt.getTime() + 30 * 60 * 1000) : null,
          createdAt,
          updatedAt: createdAt,
          stateHistory: {
            create: [{ state: o.state, actor: 'system', createdAt }],
          },
        },
      });
    }
    results.push(`Created ${testOrders.length} test orders around Salt Lake Sector V`);
  }

  // 8. Coupons + feature flags
  const coupons = [
    { code: 'WELCOME50', type: 'FLAT', value: 50, maxDiscount: 50, minOrderValue: 100 },
    { code: 'SAVE10', type: 'PERCENT', value: 10, maxDiscount: 100, minOrderValue: 200 },
  ];
  for (const c of coupons) {
    await prisma.coupon.upsert({
      where: { code: c.code },
      update: {},
      create: { ...c, description: `${c.type === 'FLAT' ? `₹${c.value} off` : `${c.value}% off`} on orders above ₹${c.minOrderValue}` },
    });
  }

  const flags = [
    { key: 'parcel_service', name: 'Parcel Delivery', enabled: true },
    { key: 'food_service', name: 'Food Delivery', enabled: false },
    { key: 'scheduled_delivery', name: 'Scheduled Delivery', enabled: true },
  ];
  for (const f of flags) {
    await prisma.featureFlag.upsert({
      where: { key: f.key },
      update: {},
      create: f,
    });
  }
  results.push('Coupons + feature flags upserted');

  return NextResponse.json({
    ok: true,
    summary: {
      owner: { email: ownerEmail, password: ownerPassword, role: 'OWNER' },
      demoUser: { phone: '+919900000001', name: 'Demo User' },
      demoPartner: { phone: '+919800000001', name: 'Ramesh Kumar', vehicle: 'BIKE' },
      testOrders: 3,
    },
    results,
  });
}
