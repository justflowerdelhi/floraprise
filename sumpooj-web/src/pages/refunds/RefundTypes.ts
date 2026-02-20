/**
 * RefundTypes.ts — Refund & Return Data Model
 * Florist ERP SaaS — Phase 1 Core Safe Version
 *
 * Supports: partial / full refund, per-item selection,
 *           inventory restock toggle (perishable-aware),
 *           audit trail, original-method or store-credit refund
 */

// ─── Refund Method ──────────────────────────────────────────

/** How the money is returned to the customer */
export type RefundMethod = 'ORIGINAL' | 'STORE_CREDIT';

/** Refund processing status */
export type RefundStatus = 'PENDING' | 'PROCESSED' | 'FAILED';

// ─── Refund Item ────────────────────────────────────────────

/** A single line-item being refunded */
export interface RefundItem {
  /** References CartItem.id (line-item ID on the order) */
  lineItemId: string;
  productId: string;
  productName: string;
  sku: string;
  /** Max refundable = ordered qty − previously refunded qty */
  maxRefundableQty: number;
  /** Quantity selected for this refund */
  quantity: number;
  /** Original unit selling price */
  unitPrice: number;
  /** Line refund amount = quantity × unitPrice (auto-calculated) */
  refundAmount: number;
  /** Whether this product CAN be restocked (non-perishable) */
  isRestockable: boolean;
  /** Whether the user chose to restock (default: true for non-perishable) */
  restock: boolean;
}

// ─── Refund Entry (persisted on Order) ──────────────────────

/** A single refund transaction stored in Order.refunds[] */
export interface RefundEntry {
  refundId: string;
  /** Total money refunded in this entry */
  refundedAmount: number;
  /** Items included in this refund */
  items: RefundItem[];
  /** How money was returned */
  method: RefundMethod;
  /** Reason for refund (required by sensitive action config) */
  reason: string;
  /** ISO timestamp */
  createdAt: string;
  /** User ID who processed */
  processedBy: string;
  /** Display name */
  processedByName: string;
  status: RefundStatus;
}

// ─── Refund Form State ──────────────────────────────────────

/** UI state for the refund processing screen */
export interface RefundFormState {
  orderId: string;
  orderNumber: string;
  /** Selectable items with quantity pickers */
  items: RefundItem[];
  /** Chosen refund method */
  method: RefundMethod;
  /** Refund reason text */
  reason: string;
  /** Auto-computed total refund amount */
  totalRefundAmount: number;
  /** Maximum amount that can be refunded (paid − already refunded) */
  maxRefundableAmount: number;
}

// ─── Refund Helpers ─────────────────────────────────────────

let _refundSeq = 0;

/** Generate a unique refund ID */
export const nextRefundId = (): string =>
  `ref_${Date.now()}_${String(++_refundSeq).padStart(4, '0')}`;

/**
 * Calculate the total refund amount from selected items.
 * Caps at maxRefundableAmount to prevent exceeding paid amount.
 */
export function calculateRefundTotal(
  items: RefundItem[],
  maxRefundableAmount: number,
): number {
  const raw = items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
  return Math.min(raw, maxRefundableAmount);
}

/**
 * Build initial RefundItem[] from order cart items,
 * accounting for previously refunded quantities.
 */
export function buildRefundableItems(
  orderItems: Array<{
    id: string;
    productId: string;
    productName: string;
    sku: string;
    quantity: number;
    unitPrice: number;
    category: string;
  }>,
  previousRefunds: RefundEntry[],
  isPerishableMap: Record<string, boolean>,
): RefundItem[] {
  // Sum previously refunded qty per line-item
  const refundedQtyMap: Record<string, number> = {};
  for (const refund of previousRefunds) {
    for (const ri of refund.items) {
      refundedQtyMap[ri.lineItemId] = (refundedQtyMap[ri.lineItemId] ?? 0) + ri.quantity;
    }
  }

  return orderItems
    .map((item) => {
      const prevRefunded = refundedQtyMap[item.id] ?? 0;
      const maxQty = item.quantity - prevRefunded;
      const isPerishable = isPerishableMap[item.productId] ?? false;
      return {
        lineItemId: item.id,
        productId: item.productId,
        productName: item.productName,
        sku: item.sku,
        maxRefundableQty: maxQty,
        quantity: 0,          // user starts with 0 selected
        unitPrice: item.unitPrice,
        refundAmount: 0,
        isRestockable: !isPerishable,
        restock: !isPerishable, // default ON for non-perishable
      };
    })
    .filter((item) => item.maxRefundableQty > 0); // hide fully-refunded items
}

/**
 * Determine whether the order should be REFUNDED or PARTIALLY_REFUNDED
 * based on total paid vs total refunded (including this new refund).
 */
export function deriveRefundOrderStatus(
  totalPaid: number,
  previouslyRefunded: number,
  thisRefundAmount: number,
): 'REFUNDED' | 'PARTIALLY_REFUNDED' {
  const totalRefunded = previouslyRefunded + thisRefundAmount;
  // Allow small floating-point tolerance
  return totalRefunded >= totalPaid - 0.01 ? 'REFUNDED' : 'PARTIALLY_REFUNDED';
}

/**
 * Sum the total amount already refunded on an order.
 */
export function getTotalRefunded(refunds: RefundEntry[]): number {
  return refunds
    .filter((r) => r.status === 'PROCESSED')
    .reduce((sum, r) => sum + r.refundedAmount, 0);
}

// ─── Config Maps ────────────────────────────────────────────

export const REFUND_METHOD_CONFIG: Record<RefundMethod, { label: string; description: string }> = {
  ORIGINAL: {
    label: 'Original Payment Method',
    description: 'Refund to the same method used to pay (cash back, card reversal, etc.)',
  },
  STORE_CREDIT: {
    label: 'Store Credit',
    description: 'Issue store credit to the customer\'s account',
  },
};

export const REFUND_STATUS_CONFIG: Record<RefundStatus, { label: string; color: string }> = {
  PENDING:   { label: 'Pending',   color: '#ed6c02' },
  PROCESSED: { label: 'Processed', color: '#2e7d32' },
  FAILED:    { label: 'Failed',    color: '#d32f2f' },
};
