
export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';


import { prisma } from '@/lib/db';
import { hashPassword } from '@/lib/auth';

// GET /api/seed — bootstraps demo data (admin user + services + vehicle types + sample partners/orders)
// Safe to call multiple times: idempotent for unique fields.
export async function GET() {
  const results: string[] = [];

  // 1. Admin user
  const existing = await prisma.adminUser.findUnique({ where: { email: 'admin@delivery.local' } });
  if (!existing) {
    await prisma.adminUser.create({
      data: {
        email: 'admin@delivery.local',
        passwordHash: await hashPassword('admin123'),
        name: 'Super Admin',
        role: 'SUPER_ADMIN',
      },
    });
    results.push('Created admin user admin@delivery.local / admin123');
  } else {
    results.push('Admin user already exists');
  }

  // 2. Vehicle types
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
  results.push(`Upserted ${vehicleTypes.length} vehicle types`);

  // 3. Services
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
    // Link service to all vehicle types
    const allVts = await prisma.vehicleTypeConfig.findMany();
    for (const vt of allVts) {
      await prisma.serviceVehicleType.upsert({
        where: { serviceId_vehicleType: { serviceId: svc.id, vehicleType: vt.type } },
        update: {},
        create: { serviceId: svc.id, vehicleType: vt.type },
      });
    }
  }
  results.push(`Upserted ${services.length} services`);

  // 4. Demo service zone (Bengaluru)
  const zone = await prisma.serviceZone.upsert({
    where: { name: 'Bengaluru Central' },
    update: {},
    create: {
      name: 'Bengaluru Central',
      city: 'Bengaluru',
      minLat: 12.85, maxLat: 13.05,
      minLng: 77.50, maxLng: 77.75,
    },
  });
  results.push('Upserted Bengaluru Central service zone');

  // 5. Demo partners (5)
  const partnerSeed = [
    { firstName: 'Ramesh', lastName: 'Kumar', phone: '+919800000001', lat: 12.9719, lng: 77.5937, vehicle: 'BIKE' as const, reg: 'KA01AB1234' },
    { firstName: 'Suresh', lastName: 'Patel', phone: '+919800000002', lat: 12.9352, lng: 77.6245, vehicle: 'BIKE' as const, reg: 'KA02CD5678' },
    { firstName: 'Anil', lastName: 'Singh', phone: '+919800000003', lat: 12.9698, lng: 77.7500, vehicle: 'AUTO' as const, reg: 'KA03EF9012' },
    { firstName: 'Vijay', lastName: 'Sharma', phone: '+919800000004', lat: 12.9279, lng: 77.5419, vehicle: 'MINI_TRUCK' as const, reg: 'KA04GH3456' },
    { firstName: 'Pradeep', lastName: 'Reddy', phone: '+919800000005', lat: 13.0298, lng: 77.5654, vehicle: 'BIKE' as const, reg: 'KA05IJ7890' },
  ];
  let partnersCreated = 0;
  for (const ps of partnerSeed) {
    const existing = await prisma.partner.findUnique({ where: { phone: ps.phone } });
    if (existing) continue;
    const p = await prisma.partner.create({
      data: {
        firstName: ps.firstName,
        lastName: ps.lastName,
        phone: ps.phone,
        email: `${ps.firstName.toLowerCase()}@delivery.local`,
        status: 'ONLINE',
        isOnline: true,
        currentLat: ps.lat,
        currentLng: ps.lng,
        lastLocationAt: new Date(),
        rating: 4.5 + Math.random() * 0.5,
        totalRatings: Math.floor(Math.random() * 200) + 20,
        acceptanceRate: 0.7 + Math.random() * 0.3,
        completionRate: 0.8 + Math.random() * 0.2,
        totalDeliveries: Math.floor(Math.random() * 500) + 50,
        totalEarnings: Math.floor(Math.random() * 50000) + 5000,
        serviceZoneId: zone.id,
        profile: { create: { upiId: `${ps.firstName.toLowerCase()}@okhdfcbank`, onboardedAt: new Date() } },
        vehicles: {
          create: [{
            type: ps.vehicle,
            registrationNumber: ps.reg,
            model: ps.vehicle === 'BIKE' ? 'Honda Activa' : ps.vehicle === 'AUTO' ? 'Bajaj RE' : 'Tata Ace',
            capacityKg: ps.vehicle === 'BIKE' ? 10 : ps.vehicle === 'AUTO' ? 100 : 500,
            isPrimary: true,
          }],
        },
        wallet: { create: { balance: Math.floor(Math.random() * 5000) + 500 } },
      },
    });
    partnersCreated++;
  }
  results.push(`Created ${partnersCreated} demo partners (5 total in seed)`);

  // 6. Demo users (3)
  const userSeed = [
    { phone: '+919900000001', name: 'Aarav Mehta' },
    { phone: '+919900000002', name: 'Priya Nair' },
    { phone: '+919900000003', name: 'Karthik Iyer' },
  ];
  let usersCreated = 0;
  for (const us of userSeed) {
    const existing = await prisma.user.findUnique({ where: { phone: us.phone } });
    if (existing) continue;
    await prisma.user.create({
      data: {
        phone: us.phone,
        name: us.name,
        phoneVerified: new Date(),
        profile: { create: { firstName: us.name.split(' ')[0], lastName: us.name.split(' ')[1] } },
        wallet: { create: { balance: 500 } },
      },
    });
    usersCreated++;
  }
  results.push(`Created ${usersCreated} demo users (3 total in seed)`);

  // 7. Demo coupons
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
  results.push(`Upserted ${coupons.length} coupons`);

  // 8. Demo orders (10)
  const services_db = await prisma.service.findMany();
  const partners_db = await prisma.partner.findMany();
  const users_db = await prisma.user.findMany();
  const states = ['COMPLETED', 'IN_TRANSIT', 'SEARCHING_PARTNER', 'PARTNER_ASSIGNED', 'CANCELLED', 'DELIVERED', 'PICKED_UP', 'CONFIRMED'];

  let ordersCreated = 0;
  for (let i = 0; i < 10; i++) {
    const svc = services_db[i % services_db.length];
    const user = users_db[i % users_db.length];
    const partner = partners_db[i % partners_db.length];
    const pickupLat = 12.95 + Math.random() * 0.1;
    const pickupLng = 77.55 + Math.random() * 0.2;
    const dropLat = 12.95 + Math.random() * 0.1;
    const dropLng = 77.55 + Math.random() * 0.2;
    const distanceKm = Math.round((Math.sqrt((pickupLat - dropLat) ** 2 + (pickupLng - dropLng) ** 2) * 111) * 10) / 10;
    const baseFare = svc.baseFare;
    const distanceFare = Math.round(svc.perKm * distanceKm);
    const timeFare = Math.round(svc.perMin * Math.max(5, distanceKm * 3));
    const platformFee = svc.platformFee;
    const taxAmount = Math.round(((baseFare + distanceFare + timeFare + platformFee) * svc.taxPercent) / 100);
    const total = baseFare + distanceFare + timeFare + platformFee + taxAmount;
    const state = states[i % states.length] as any;
    const createdAt = new Date(Date.now() - i * 3600 * 1000);

    await prisma.order.create({
      data: {
        code: `DP-DEMO${String(i + 1).padStart(3, '0')}`,
        userId: user.id,
        partnerId: partner.id,
        serviceId: svc.id,
        state,
        packageType: 'SMALL_PARCEL',
        packageWeightKg: Math.round(Math.random() * 5 * 10) / 10,
        pickupLat, pickupLng,
        pickupAddress: `${100 + i} MG Road, Bengaluru`,
        dropLat, dropLng,
        dropAddress: `${200 + i} Brigade Road, Bengaluru`,
        distanceKm,
        estimatedMinutes: Math.max(5, Math.round(distanceKm * 3)),
        baseFare,
        distanceFare,
        timeFare,
        platformFee,
        taxAmount,
        totalAmount: total,
        paymentMethod: 'UPI',
        paymentStatus: state === 'COMPLETED' || state === 'DELIVERED' ? 'PAID' : (state === 'CANCELLED' ? 'FAILED' : 'PENDING'),
        completedAt: state === 'COMPLETED' ? new Date(createdAt.getTime() + 30 * 60 * 1000) : null,
        createdAt,
        updatedAt: createdAt,
        stateHistory: {
          create: [{ state, actor: 'system', createdAt }],
        },
      },
    });
    ordersCreated++;
  }
  results.push(`Created ${ordersCreated} demo orders`);

  // 9. Feature flags
  const flags = [
    { key: 'parcel_service', name: 'Parcel Delivery', enabled: true },
    { key: 'food_service', name: 'Food Delivery', enabled: false },
    { key: 'grocery_service', name: 'Grocery Delivery', enabled: false },
    { key: 'multi_stop', name: 'Multi-stop Delivery', enabled: false },
    { key: 'scheduled_delivery', name: 'Scheduled Delivery', enabled: true },
  ];
  for (const f of flags) {
    await prisma.featureFlag.upsert({
      where: { key: f.key },
      update: {},
      create: f,
    });
  }
  results.push(`Upserted ${flags.length} feature flags`);

  return NextResponse.json({ ok: true, results });
}
