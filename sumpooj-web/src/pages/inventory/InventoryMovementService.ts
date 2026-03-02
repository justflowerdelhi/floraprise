/**
 * InventoryMovementService.ts — Inventory Movement Logic Based on Order Fulfillment Mode
 * Florist ERP SaaS
 *
 * Controls WHEN inventory is deducted:
 *   IMMEDIATE  → Deduct on order save (walk-in, ready-made)
 *   SCHEDULED  → Reserve on save, deduct at dispatch/production
 *   EVENT      → Reserve on save, deduct at event production stage
 *
 * Exports pure functions — no React dependency.
 * In production these call the backend API; for now they operate on in-memory data.
 */

import type {
  Order,
  CartItem,
  OrderFulfillmentMode,
  InventoryActionStatus,
  InventoryReservation,
} from '../orders/OrderTypes';

// ─── ID Generator ────────────────────────────────────────────

let _resSeq = 0;
export const nextReservationId = (): string =>
  `res_${Date.now()}_${String(++_resSeq).padStart(4, '0')}`;

// ─── Core Helpers ────────────────────────────────────────────

/**
 * Determine the default fulfillment mode based on order characteristics.
 * - Walk-In fully-paid → IMMEDIATE
 * - Phone/Website with future delivery → SCHEDULED
 * - Event linked → EVENT
 * - Fallback → SCHEDULED
 */
export function inferFulfillmentMode(order: Partial<Order>): OrderFulfillmentMode {
  // Walk-in orders that are fully paid default to IMMEDIATE
  if (order.orderSource === 'WALK_IN' && order.paymentStatus === 'PAID') {
    return 'IMMEDIATE';
  }

  // Orders with a future delivery date → SCHEDULED
  if (order.deliveryDate || order.structuredDeliveryAddress || order.pickupDate) {
    return 'SCHEDULED';
  }

  // Event-linked orders → EVENT fulfillment mode
  if ((order as any).eventId) return 'EVENT';

  // Walk-in partial → IMMEDIATE (customer takes items)
  if (order.orderSource === 'WALK_IN') {
    return 'IMMEDIATE';
  }

  return 'SCHEDULED';
}

/**
 * Determine what inventory action to take when an order is saved.
 */
export function resolveInventoryAction(
  mode: OrderFulfillmentMode,
): { action: 'DEDUCT' | 'RESERVE'; status: InventoryActionStatus } {
  if (mode === 'IMMEDIATE') {
    return { action: 'DEDUCT', status: 'DEDUCTED' };
  }
  // SCHEDULED and EVENT both reserve first
  return { action: 'RESERVE', status: 'RESERVED' };
}

// ─── Reservation Builder ─────────────────────────────────────

/**
 * Build InventoryReservation records for each line item in the cart.
 * These represent "soft holds" — inventory is earmarked but not yet physically removed.
 */
export function buildReservations(
  orderId: string,
  items: CartItem[],
  locationId: string,
): InventoryReservation[] {
  const now = new Date().toISOString();

  return items.map((item) => ({
    id: nextReservationId(),
    orderId,
    productId: item.productId,
    productName: item.productName,
    quantity: item.quantity,
    locationId,
    batchAllocations: item.batchAllocations.map((ba) => ({
      batchId: ba.batchId,
      quantity: ba.quantity,
    })),
    status: 'ACTIVE' as const,
    reservedAt: now,
  }));
}

// ─── Deduction (Immediate) ───────────────────────────────────

/**
 * Simulate immediate inventory deduction.
 * In production this would call the backend inventory API.
 * Returns the list of product+quantity pairs deducted.
 */
export function deductInventory(
  items: CartItem[],
  _locationId: string,
): { productId: string; productName: string; quantity: number; batchAllocations: { batchId: string; quantity: number }[] }[] {
  console.log('📦 Inventory DEDUCTED (IMMEDIATE):', items.map((i) => ({
    productId: i.productId,
    productName: i.productName,
    quantity: i.quantity,
    batches: i.batchAllocations.map((b) => `${b.batchId}:${b.quantity}`),
  })));

  return items.map((item) => ({
    productId: item.productId,
    productName: item.productName,
    quantity: item.quantity,
    batchAllocations: item.batchAllocations.map((ba) => ({
      batchId: ba.batchId,
      quantity: ba.quantity,
    })),
  }));
}

// ─── Fulfillment: Convert Reservation → Deduction ───────────

/**
 * Fulfill (convert) active reservations to actual deductions.
 * Called during dispatch/production stage for SCHEDULED/EVENT orders.
 */
export function fulfillReservations(
  reservations: InventoryReservation[],
): InventoryReservation[] {
  const now = new Date().toISOString();

  const fulfilled = reservations.map((res) =>
    res.status === 'ACTIVE'
      ? { ...res, status: 'FULFILLED' as const, fulfilledAt: now }
      : res,
  );

  console.log('📦 Reservations FULFILLED → Inventory DEDUCTED:', fulfilled.filter((r) => r.fulfilledAt === now).map((r) => ({
    productId: r.productId,
    productName: r.productName,
    quantity: r.quantity,
  })));

  return fulfilled;
}

// ─── Release Reservations (cancellation / refund) ────────────

/**
 * Release active reservations — returns inventory back to available pool.
 * Called when an order with RESERVED status is cancelled or fully refunded.
 */
export function releaseReservations(
  reservations: InventoryReservation[],
): InventoryReservation[] {
  const now = new Date().toISOString();

  const released = reservations.map((res) =>
    res.status === 'ACTIVE'
      ? { ...res, status: 'RELEASED' as const, releasedAt: now }
      : res,
  );

  console.log('📦 Reservations RELEASED — inventory returned:', released.filter((r) => r.releasedAt === now).map((r) => ({
    productId: r.productId,
    productName: r.productName,
    quantity: r.quantity,
  })));

  return released;
}

// ─── Order Inventory Processor ───────────────────────────────

/**
 * Main entry point: process inventory for a new order.
 * Returns the fields to merge into the Order object.
 */
export function processOrderInventory(
  orderId: string,
  items: CartItem[],
  mode: OrderFulfillmentMode,
  locationId: string,
): {
  orderFulfillmentMode: OrderFulfillmentMode;
  inventoryStatus: InventoryActionStatus;
  reservations?: InventoryReservation[];
} {
  const { action, status } = resolveInventoryAction(mode);

  if (action === 'DEDUCT') {
    // Immediate deduction — no reservation records needed
    deductInventory(items, locationId);
    return {
      orderFulfillmentMode: mode,
      inventoryStatus: status,
    };
  }

  // Reserve — create reservation records
  const reservations = buildReservations(orderId, items, locationId);
  console.log('📋 Inventory RESERVED:', reservations.map((r) => ({
    productId: r.productId,
    productName: r.productName,
    quantity: r.quantity,
    batches: r.batchAllocations.map((b) => `${b.batchId}:${b.quantity}`),
  })));

  return {
    orderFulfillmentMode: mode,
    inventoryStatus: status,
    reservations,
  };
}

/**
 * Transition an order to DEDUCTED status — used when a SCHEDULED/EVENT order
 * reaches its dispatch or production stage.
 */
export function deductReservedOrder(
  order: Order,
): {
  inventoryStatus: InventoryActionStatus;
  reservations: InventoryReservation[];
} {
  if (order.inventoryStatus !== 'RESERVED') {
    console.warn('⚠️ Cannot deduct — order is not in RESERVED state:', order.inventoryStatus);
    return {
      inventoryStatus: order.inventoryStatus ?? 'NONE',
      reservations: order.reservations ?? [],
    };
  }

  // Deduct the actual inventory
  deductInventory(order.items, order.locationId ?? 'loc_default');

  // Mark reservations as fulfilled
  const fulfilled = fulfillReservations(order.reservations ?? []);

  return {
    inventoryStatus: 'DEDUCTED',
    reservations: fulfilled,
  };
}

/**
 * Release inventory for a cancelled/refunded order.
 */
export function releaseOrderInventory(
  order: Order,
): {
  inventoryStatus: InventoryActionStatus;
  reservations: InventoryReservation[];
} {
  if (order.inventoryStatus === 'RELEASED' || order.inventoryStatus === 'NONE') {
    return {
      inventoryStatus: order.inventoryStatus ?? 'NONE',
      reservations: order.reservations ?? [],
    };
  }

  if (order.inventoryStatus === 'RESERVED') {
    // Release reservations — items go back to available pool
    const released = releaseReservations(order.reservations ?? []);
    return { inventoryStatus: 'RELEASED', reservations: released };
  }

  // DEDUCTED orders would need a refund_restock adjustment
  console.warn('⚠️ Order inventory already deducted — use refund_restock adjustment to return stock');
  return {
    inventoryStatus: order.inventoryStatus ?? 'NONE',
    reservations: order.reservations ?? [],
  };
}
