export const dynamic = 'force-dynamic';

import { NextResponse } from 'next/server';
import { prisma } from '@/lib/db';
import { getSession } from '@/lib/auth';

// POST /api/cleanup
// Auth: admin/owner session cookie
// ERASES ALL demo data — keeps only:
//   - Admin/owner accounts (admin_users collection)
//   - Service catalog (services, vehicle_types, service_vehicle_types, service_zones)
//   - Coupons, feature flags, settings (configuration)
//
// Deletes:
//   - All orders + state history + locations + assignments
//   - All users (demo users)
//   - All partners + profiles + documents + vehicles
//   - All wallets + transactions + withdrawals
//   - All ratings
//   - All notifications
//   - All support tickets + messages
//   - All tracking sessions + location updates
//   - All fare quotes
//   - All OTP requests + refresh tokens
//   - All audit logs (except this cleanup action)
export async function POST() {
  const session = await getSession();
  if (!session) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  const results: string[] = [];

  // Delete in dependency order (children first)
  await prisma.locationUpdate.deleteMany({});
  results.push('Deleted all location updates');

  await prisma.trackingSession.deleteMany({});
  results.push('Deleted all tracking sessions');

  await prisma.partnerAssignment.deleteMany({});
  results.push('Deleted all partner assignments');

  await prisma.orderStatusHistory.deleteMany({});
  results.push('Deleted all order status history');

  await prisma.orderItem.deleteMany({});
  results.push('Deleted all order items');

  await prisma.orderLocation.deleteMany({});
  results.push('Deleted all order locations');

  await prisma.rating.deleteMany({});
  results.push('Deleted all ratings');

  await prisma.payment.deleteMany({});
  results.push('Deleted all payments');

  await prisma.withdrawalRequest.deleteMany({});
  results.push('Deleted all withdrawal requests');

  await prisma.walletTransaction.deleteMany({});
  results.push('Deleted all wallet transactions');

  await prisma.wallet.deleteMany({});
  results.push('Deleted all wallets');

  await prisma.supportMessage.deleteMany({});
  results.push('Deleted all support messages');

  await prisma.supportTicket.deleteMany({});
  results.push('Deleted all support tickets');

  await prisma.notification.deleteMany({});
  results.push('Deleted all notifications');

  await prisma.fareQuote.deleteMany({});
  results.push('Deleted all fare quotes');

  await prisma.partnerVehicleDocument.deleteMany({});
  results.push('Deleted all partner vehicle documents');

  await prisma.partnerVehicle.deleteMany({});
  results.push('Deleted all partner vehicles');

  await prisma.partnerDocument.deleteMany({});
  results.push('Deleted all partner documents');

  await prisma.partnerProfile.deleteMany({});
  results.push('Deleted all partner profiles');

  await prisma.partner.deleteMany({});
  results.push('Deleted all partners');

  await prisma.userAddress.deleteMany({});
  results.push('Deleted all user addresses');

  await prisma.userProfile.deleteMany({});
  results.push('Deleted all user profiles');

  await prisma.refreshToken.deleteMany({});
  results.push('Deleted all refresh tokens');

  await prisma.otpRequest.deleteMany({});
  results.push('Deleted all OTP requests');

  await prisma.order.deleteMany({});
  results.push('Deleted all orders');

  await prisma.user.deleteMany({});
  results.push('Deleted all users');

  await prisma.auditLog.deleteMany({});
  results.push('Cleared audit logs');

  // Log this cleanup action
  await prisma.auditLog.create({
    data: {
      actorId: session.userId,
      actorRole: session.role,
      action: 'DATA_CLEANUP',
      entityType: 'System',
      metadata: { note: 'Erased all demo data — kept admin accounts + catalog only' },
    },
  });

  // Verify what remains
  const remaining = {
    adminUsers: await prisma.adminUser.count(),
    services: await prisma.service.count(),
    vehicleTypes: await prisma.vehicleTypeConfig.count(),
    serviceVehicleTypes: await prisma.serviceVehicleType.count(),
    serviceZones: await prisma.serviceZone.count(),
    coupons: await prisma.coupon.count(),
    featureFlags: await prisma.featureFlag.count(),
    settings: await prisma.setting.count(),
    pricingRules: await prisma.pricingRule.count(),
    surgeRules: await prisma.surgeRule.count(),
    // These should all be 0
    users: await prisma.user.count(),
    partners: await prisma.partner.count(),
    orders: await prisma.order.count(),
    wallets: await prisma.wallet.count(),
    ratings: await prisma.rating.count(),
    supportTickets: await prisma.supportTicket.count(),
    fareQuotes: await prisma.fareQuote.count(),
  };

  return NextResponse.json({
    ok: true,
    message: 'All demo data erased. System is now clean.',
    deleted: results,
    remaining,
  });
}
