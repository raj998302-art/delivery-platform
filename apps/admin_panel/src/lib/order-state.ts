// ============================================================================
// Order State Machine — strict transitions
// ============================================================================

import { prisma } from './db';
import type { OrderState } from '@prisma/client';

export const ORDER_TRANSITIONS: Record<OrderState, OrderState[]> = {
  DRAFT: ['QUOTE_CREATED', 'CANCELLED'],
  QUOTE_CREATED: ['PAYMENT_PENDING', 'CANCELLED'],
  PAYMENT_PENDING: ['CONFIRMED', 'CANCELLED', 'FAILED'],
  CONFIRMED: ['SEARCHING_PARTNER', 'CANCELLED'],
  SEARCHING_PARTNER: ['PARTNER_ASSIGNED', 'CANCELLED', 'FAILED'],
  PARTNER_ASSIGNED: ['PARTNER_ACCEPTED', 'CANCELLED', 'SEARCHING_PARTNER'],
  PARTNER_ACCEPTED: ['PARTNER_ARRIVING', 'CANCELLED'],
  PARTNER_ARRIVING: ['PARTNER_ARRIVED', 'CANCELLED'],
  PARTNER_ARRIVED: ['PICKUP_VERIFICATION', 'CANCELLED'],
  PICKUP_VERIFICATION: ['PICKED_UP', 'CANCELLED'],
  PICKED_UP: ['IN_TRANSIT'],
  IN_TRANSIT: ['ARRIVING'],
  ARRIVING: ['DELIVERY_VERIFICATION'],
  DELIVERY_VERIFICATION: ['DELIVERED'],
  DELIVERED: ['COMPLETED'],
  COMPLETED: [],
  CANCELLED: [],
  FAILED: [],
  REFUNDED: [],
};

export function canTransition(from: OrderState, to: OrderState): boolean {
  return ORDER_TRANSITIONS[from]?.includes(to) ?? false;
}

export async function transitionOrder(
  orderId: string,
  to: OrderState,
  actor?: string,
  note?: string
): Promise<void> {
  const order = await prisma.order.findUnique({ where: { id: orderId } });
  if (!order) throw new Error('Order not found');
  if (!canTransition(order.state, to)) {
    throw new Error(`Invalid transition: ${order.state} -> ${to}`);
  }
  await prisma.$transaction([
    prisma.order.update({
      where: { id: orderId },
      data: {
        state: to,
        completedAt: to === 'COMPLETED' ? new Date() : null,
      },
    }),
    prisma.orderStatusHistory.create({
      data: { orderId, state: to, actor, note },
    }),
  ]);
}

export const ORDER_STATE_LABELS: Record<OrderState, string> = {
  DRAFT: 'Draft',
  QUOTE_CREATED: 'Quote Created',
  PAYMENT_PENDING: 'Payment Pending',
  CONFIRMED: 'Confirmed',
  SEARCHING_PARTNER: 'Searching Partner',
  PARTNER_ASSIGNED: 'Partner Assigned',
  PARTNER_ACCEPTED: 'Partner Accepted',
  PARTNER_ARRIVING: 'Partner Arriving',
  PARTNER_ARRIVED: 'Partner Arrived',
  PICKUP_VERIFICATION: 'Pickup Verification',
  PICKED_UP: 'Picked Up',
  IN_TRANSIT: 'In Transit',
  ARRIVING: 'Arriving',
  DELIVERY_VERIFICATION: 'Delivery Verification',
  DELIVERED: 'Delivered',
  COMPLETED: 'Completed',
  CANCELLED: 'Cancelled',
  FAILED: 'Failed',
  REFUNDED: 'Refunded',
};

export const ORDER_STATE_COLORS: Record<OrderState, string> = {
  DRAFT: 'bg-gray-100 text-gray-700',
  QUOTE_CREATED: 'bg-gray-100 text-gray-700',
  PAYMENT_PENDING: 'bg-amber-100 text-amber-700',
  CONFIRMED: 'bg-blue-100 text-blue-700',
  SEARCHING_PARTNER: 'bg-purple-100 text-purple-700',
  PARTNER_ASSIGNED: 'bg-indigo-100 text-indigo-700',
  PARTNER_ACCEPTED: 'bg-indigo-100 text-indigo-700',
  PARTNER_ARRIVING: 'bg-cyan-100 text-cyan-700',
  PARTNER_ARRIVED: 'bg-cyan-100 text-cyan-700',
  PICKUP_VERIFICATION: 'bg-orange-100 text-orange-700',
  PICKED_UP: 'bg-orange-100 text-orange-700',
  IN_TRANSIT: 'bg-blue-100 text-blue-700',
  ARRIVING: 'bg-cyan-100 text-cyan-700',
  DELIVERY_VERIFICATION: 'bg-teal-100 text-teal-700',
  DELIVERED: 'bg-green-100 text-green-700',
  COMPLETED: 'bg-green-100 text-green-700',
  CANCELLED: 'bg-red-100 text-red-700',
  FAILED: 'bg-red-100 text-red-700',
  REFUNDED: 'bg-amber-100 text-amber-700',
};
