export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { prisma } from '@/lib/db';
import { hashPassword } from '@/lib/auth';

// GET /api/seed — bootstraps demo data with Kolkata (Salt Lake Sector V) coordinates.
// Idempotent: deletes existing demo data first, then re-creates.
export async function GET() {
  const results: string[] = [];

  // 0. Clean up existing demo data (non-destructive to admin users)
  await prisma.order.deleteMany({ where: { code: { startsWith: 'DP-' } } });
  await prisma.partner.deleteMany({});
  await prisma.user.deleteMany({ where: { phone: { startsWith: '+9199' } } });
  await prisma.fareQuote.deleteMany({});
  results.push('Cleaned up existing demo data');

  // 1. Admin user (upsert — don't delete)
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
    const allVts = await prisma.vehicleTypeConfig.findMany();
    for (const vt of allVts) {
      await prisma.serviceVehicleType.upsert({
        where: { serviceId_vehicleType: { serviceId: svc.id, vehicleType: vt.type as any } },
        update: {},
        create: { serviceId: svc.id, vehicleType: vt.type },
      });
    }
  }
  results.push(`Upserted ${services.length} services`);

  // 4. Demo service zone (Salt Lake Sector V, Kolkata)
  // Center: 22.5803, 88.4284
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
  results.push('Upserted Salt Lake Sector V service zone');

  // 5. Demo partners — ALL within 1km of Nayapatti Main Road, Salt Lake Sector V
  // Center point: 22.5803, 88.4284 (Nayapatti Main Road)
  // 1 degree lat ≈ 111km, 1 degree lng at 22.58°N ≈ 102.5km
  // So 1km ≈ 0.009 degrees lat, 0.0098 degrees lng
  const CENTER_LAT = 22.5803;
  const CENTER_LNG = 88.4284;

  const partnerSeed = [
    // All within ~300m of center — well within 1km
    { firstName: 'Ramesh', lastName: 'Kumar', phone: '+919800000001', lat: 22.5808, lng: 88.4292, vehicle: 'BIKE' as const, reg: 'WB01AB1234', model: 'Honda Activa 6G' },
    { firstName: 'Suresh', lastName: 'Patel', phone: '+919800000002', lat: 22.5797, lng: 88.4278, vehicle: 'BIKE' as const, reg: 'WB02CD5678', model: 'TVS Jupiter' },
    { firstName: 'Anil', lastName: 'Singh', phone: '+919800000003', lat: 22.5815, lng: 88.4281, vehicle: 'AUTO' as const, reg: 'WB03EF9012', model: 'Bajaj RE' },
    { firstName: 'Vijay', lastName: 'Sharma', phone: '+919800000004', lat: 22.5792, lng: 88.4295, vehicle: 'MINI_TRUCK' as const, reg: 'WB04GH3456', model: 'Tata Ace' },
    { firstName: 'Pradeep', lastName: 'Reddy', phone: '+919800000005', lat: 22.5820, lng: 88.4275, vehicle: 'BIKE' as const, reg: 'WB05IJ7890', model: 'Hero Splendor' },
  ];

  for (const ps of partnerSeed) {
    const distKm = Math.sqrt(
      Math.pow((ps.lat - CENTER_LAT) * 111, 2) +
      Math.pow((ps.lng - CENTER_LNG) * 102.5, 2)
    );
    await prisma.partner.create({
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
            model: ps.model,
            capacityKg: ps.vehicle === 'BIKE' ? 10 : ps.vehicle === 'AUTO' ? 100 : 500,
            isPrimary: true,
          }],
        },
        wallets: { create: { balance: Math.floor(Math.random() * 5000) + 500 } },
      },
    });
    results.push(`Created partner ${ps.firstName} ${ps.lastName} at (${ps.lat}, ${ps.lng}) — ${distKm.toFixed(2)}km from center`);
  }

  // 6. Demo users — near Salt Lake Sector V
  const userSeed = [
    { phone: '+919900000001', name: 'Aarav Mehta', lat: 22.5800, lng: 88.4288 },
    { phone: '+919900000002', name: 'Priya Nair', lat: 22.5810, lng: 88.4275 },
    { phone: '+919900000003', name: 'Karthik Iyer', lat: 22.5795, lng: 88.4290 },
  ];
  for (const us of userSeed) {
    await prisma.user.create({
      data: {
        phone: us.phone,
        name: us.name,
        phoneVerified: new Date(),
        profile: { create: { firstName: us.name.split(' ')[0], lastName: us.name.split(' ')[1] } },
        wallets: { create: { balance: 500 } },
      },
    });
  }
  results.push(`Created ${userSeed.length} demo users`);

  // 7. Demo coupons
  const coupons = [
    { code: 'WELCOME50', type: 'FLAT', value: 50, maxDiscount: 50, minOrderValue: 100 },
    { code: 'SAVE10', type: 'PERCENT', value: 10, maxDiscount: 100, minOrderValue: 200 },
    { code: 'SALT50', type: 'FLAT', value: 50, maxDiscount: 50, minOrderValue: 80 },
  ];
  for (const c of coupons) {
    await prisma.coupon.upsert({
      where: { code: c.code },
      update: {},
      create: { ...c, description: `${c.type === 'FLAT' ? `₹${c.value} off` : `${c.value}% off`} on orders above ₹${c.minOrderValue}` },
    });
  }
  results.push(`Upserted ${coupons.length} coupons`);

  // 8. Demo orders — pickup/drop around Salt Lake Sector V
  const servicesDb = await prisma.service.findMany();
  const partnersDb = await prisma.partner.findMany();
  const usersDb = await prisma.user.findMany();

  const kolkataAddresses = [
    { addr: 'DN-21, Salt Lake Sector V, Kolkata', lat: 22.5800, lng: 88.4288 },
    { addr: 'Webel Crossing, Sector V, Kolkata', lat: 22.5785, lng: 88.4295 },
    { addr: 'College More, Sector V, Kolkata', lat: 22.5820, lng: 88.4270 },
    { addr: 'Karunamoyee, Sector V, Kolkata', lat: 22.5790, lng: 88.4300 },
    { addr: 'Nayapatti Main Road, Sector V, Kolkata', lat: 22.5803, lng: 88.4284 },
    { addr: 'Chingrighata, Sector V, Kolkata', lat: 22.5770, lng: 88.4250 },
    { addr: 'Subhash Sarovar, Sector V, Kolkata', lat: 22.5750, lng: 88.4320 },
    { addr: 'Wipro Campus, Sector V, Kolkata', lat: 22.5830, lng: 88.4265 },
  ];

  const states = ['COMPLETED', 'IN_TRANSIT', 'SEARCHING_PARTNER', 'PARTNER_ASSIGNED', 'CANCELLED', 'DELIVERED', 'PICKED_UP', 'CONFIRMED'];

  for (let i = 0; i < 10; i++) {
    const svc = servicesDb[i % servicesDb.length];
    const user = usersDb[i % usersDb.length];
    const partner = partnersDb[i % partnersDb.length];
    const pickupIdx = i % kolkataAddresses.length;
    const dropIdx = (i + 3) % kolkataAddresses.length;
    const pickup = kolkataAddresses[pickupIdx];
    const drop = kolkataAddresses[dropIdx];

    const distanceKm = Math.sqrt(
      Math.pow((pickup.lat - drop.lat) * 111, 2) +
      Math.pow((pickup.lng - drop.lng) * 102.5, 2)
    );
    const roundedDist = Math.round(distanceKm * 10) / 10;

    const baseFare = svc.baseFare;
    const distanceFare = Math.round(svc.perKm * Math.max(1, roundedDist));
    const timeFare = Math.round(svc.perMin * Math.max(5, roundedDist * 3));
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
        pickupLat: pickup.lat,
        pickupLng: pickup.lng,
        pickupAddress: pickup.addr,
        dropLat: drop.lat,
        dropLng: drop.lng,
        dropAddress: drop.addr,
        distanceKm: roundedDist,
        estimatedMinutes: Math.max(5, Math.round(roundedDist * 3)),
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
  }
  results.push('Created 10 demo orders around Salt Lake Sector V');

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

  return NextResponse.json({
    ok: true,
    center: { name: 'Nayapatti Main Road, Salt Lake Sector V, Kolkata', lat: CENTER_LAT, lng: CENTER_LNG },
    results,
  });
}
