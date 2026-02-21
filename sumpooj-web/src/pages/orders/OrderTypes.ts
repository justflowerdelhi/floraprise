/**
 * OrderTypes.ts — Unified Order Model & Cart Types
 * Florist ERP SaaS — Hybrid POS + Unified Order System
 *
 * Supports: Walk-In POS, Phone Orders, Website Orders,
 *           BloomNation eCommerce, FTD / External Floral Network
 * Integrates with batch-based inventory engine (FIFO logic)
 * Payment model is SEPARATE — see PaymentTypes.ts
 */

import type { DeliveryAddress, FulfillmentType } from './DeliveryZoneTypes';
import type { RefundEntry } from '../refunds/RefundTypes';

// ─── Order Source & Statuses ────────────────────────────────

export type OrderSource = 'WALK_IN' | 'PHONE' | 'WEBSITE' | 'BLOOMNATION' | 'FTD';

export type OrderType = 'LOCAL' | 'OUTGOING_NETWORK' | 'INCOMING_NETWORK';

/** @deprecated Use OUTGOING_NETWORK / INCOMING_NETWORK instead */
export const LEGACY_ORDER_TYPE_MAP: Record<string, OrderType> = {
  OUTGOING_WIRE: 'OUTGOING_NETWORK',
  INCOMING_WIRE: 'INCOMING_NETWORK',
};

export type FulfillmentStatus =
  | 'DRAFT'
  | 'CONFIRMED'
  | 'IN_DESIGN'
  | 'READY'
  | 'OUT_FOR_DELIVERY'
  | 'COMPLETED'
  | 'CANCELLED';

/**
 * Order-level payment status — derived from Payment records.
 * See PaymentUtils.deriveOrderPaymentStatus().
 */
export type OrderPaymentStatus = 'UNPAID' | 'PARTIAL' | 'PAID';

export type OrderPaymentMethod = 'CASH' | 'CARD' | 'UPI' | 'STORE_CREDIT';

export type OrderStatus = 'DRAFT' | 'PARTIALLY_PAID' | 'PAID' | 'CANCELLED' | 'PARTIALLY_REFUNDED' | 'REFUNDED';

export interface OrderPaymentEntry {
  method: OrderPaymentMethod;
  amount: number;
}

export type SettlementStatus = 'PENDING' | 'SENT' | 'CLEARED';

// ─── Order Fulfillment Mode (controls inventory timing) ────

/**
 * Controls WHEN inventory is deducted for an order.
 * - IMMEDIATE: deduct on order save (walk-in, ready-made)
 * - SCHEDULED: reserve on save, deduct at dispatch/production
 * - EVENT:     reserve on save, deduct at production stage
 */
export type OrderFulfillmentMode = 'IMMEDIATE' | 'SCHEDULED' | 'EVENT';

/**
 * Tracks what happened to inventory for this order.
 * - NONE:     no action taken yet
 * - RESERVED: items reserved but inventory not deducted
 * - DEDUCTED: inventory physically deducted
 * - RELEASED: reservation cancelled (order cancelled/refunded)
 */
export type InventoryActionStatus = 'NONE' | 'RESERVED' | 'DEDUCTED' | 'RELEASED';

/** A single inventory reservation for a line item */
export interface InventoryReservation {
  id: string;
  orderId: string;
  productId: string;
  productName: string;
  quantity: number;
  locationId: string;
  batchAllocations: { batchId: string; quantity: number }[];
  status: 'ACTIVE' | 'FULFILLED' | 'RELEASED';
  reservedAt: string; // ISO timestamp
  fulfilledAt?: string;
  releasedAt?: string;
}

export const ORDER_FULFILLMENT_MODE_CONFIG: Record<OrderFulfillmentMode, { label: string; description: string; icon: string }> = {
  IMMEDIATE: {
    label: 'Immediate',
    description: 'Inventory deducted immediately when order is saved',
    icon: '⚡',
  },
  SCHEDULED: {
    label: 'Scheduled',
    description: 'Items reserved; deducted when dispatched or produced',
    icon: '📅',
  },
  EVENT: {
    label: 'Event',
    description: 'Items reserved; deducted during event production stage',
    icon: '🎉',
  },
};

export const INVENTORY_STATUS_CONFIG: Record<InventoryActionStatus, { label: string; color: string }> = {
  NONE:     { label: 'Pending',  color: '#9e9e9e' },
  RESERVED: { label: 'Reserved', color: '#ff9800' },
  DEDUCTED: { label: 'Deducted', color: '#4caf50' },
  RELEASED: { label: 'Released', color: '#0288d1' },
};

export interface VendorFlorist {
  id: string;
  name: string;
  city: string;
  state: string;
  phone?: string;
  email?: string;
  defaultCommissionRate?: number;
  isActive: boolean;
}

// ─── Inventory Batch (FIFO Integration) ─────────────────────

export interface InventoryBatch {
  batchId: string;
  productId: string;
  quantity: number;
  costPerUnit: number;
  receivedDate: string;    // ISO date
  expiryDate: string;      // ISO date
  supplier: string;
}

// ─── Product Catalog ────────────────────────────────────────

export type ProductCategory =
  | 'Fresh Flowers'
  | 'Arrangements'
  | 'Bouquets'
  | 'Plants'
  | 'Greens & Foliage'
  | 'Supplies'
  | 'Add-Ons'
  | 'Gift Items';

export interface Product {
  id: string;
  name: string;
  sku: string;
  /** External/manufacturer barcode (UPC, EAN) */
  barcode?: string;
  /** Internal auto-generated barcode */
  internalBarcode?: string;
  /** Batch-specific barcode (for perishables) */
  batchBarcode?: string;
  /** Finished goods barcode (for production) */
  finishedBarcode?: string;
  category: ProductCategory;
  sellingPrice: number;
  costPrice: number;       // weighted avg FIFO cost
  taxRate: number;         // e.g. 0.05 = 5%
  availableStock: number;
  isPerishable: boolean;
  trackBatch: boolean;
  imageUrl?: string;
  batches: InventoryBatch[];
}

// ─── Cart Types ─────────────────────────────────────────────

export interface BatchAllocation {
  batchId: string;
  quantity: number;
  costPerUnit: number;
  expiryDate: string;
  isManualOverride: boolean;
}

export interface CartItem {
  id: string;               // line item ID
  productId: string;
  productName: string;
  sku: string;
  category: ProductCategory;
  quantity: number;
  unitPrice: number;        // selling price
  discountPercent: number;
  discountAmount: number;
  lineTotal: number;        // (unitPrice × qty) - discountAmount
  taxRate: number;
  taxAmount: number;
  lineCost: number;         // total FIFO cost for this line
  marginPercent: number;
  batchAllocations: BatchAllocation[];
  expiryWarning: boolean;   // true if any batch expiry ≤ 3 days
  stockWarning: boolean;    // true if requested > available
  lineDiscount?: LineItemDiscount | null; // Enhanced line discount with type
}

// ─── Line-Item Discount ─────────────────────────────────────

export interface LineItemDiscount {
  type: 'PERCENT' | 'FLAT';
  value: number;
}

// ─── Order-Level Discount ───────────────────────────────────

export interface OrderDiscount {
  type: 'PERCENT' | 'FLAT';
  value: number;
  reason?: string;
}

export interface CartSummary {
  subtotal: number;
  taxTotal: number;
  discountTotal: number;      // Line-level discounts
  orderDiscountAmount: number; // Order-level discount amount
  grandTotal: number;
  totalCost: number;
  marginPercent: number;
  marginWarning: boolean;   // true if margin < 20%
  itemCount: number;
  lineCount: number;
}

// ─── Order Model ────────────────────────────────────────────

export interface Order {
  id: string;
  orderNumber: string;
  orderSource: OrderSource;
  locationId?: string; // Multi-location support

  orderType?: OrderType;

  // External platform metadata
  externalOrderId?: string;
  externalPlatform?: string;
  isExternallyPaid?: boolean;
  isPriceEditable: boolean;

  // Sender / Customer
  senderName?: string;
  customerName?: string;
  customerPhone?: string;

  // Recipient
  recipientName?: string;
  recipientPhone?: string;

  // Fulfillment (NEW: Pickup vs Delivery)
  fulfillmentType?: FulfillmentType;  // 'PICKUP' | 'DELIVERY'
  
  // Pickup details
  pickupDate?: string;
  pickupTimeSlot?: TimeSlot;
  
  // Delivery (legacy single-string field for backward compatibility)
  deliveryDate?: string;
  deliveryTime?: string;
  deliveryAddress?: string;  // Legacy string address
  deliveryInstructions?: string;
  
  // Delivery (NEW: structured address with zone info)
  structuredDeliveryAddress?: DeliveryAddress;
  deliveryTimeSlot?: TimeSlot;
  
  // Message & occasion
  cardMessage?: string;
  occasion?: string;

  // Commission (for BLOOMNATION / FTD)
  externalCommission?: number;
  externalFees?: number;
  netPayout?: number;

  // Wire management
  vendorFloristId?: string;
  vendorFloristName?: string;
  vendorAmount?: number;
  wireFee?: number;
  sourceNetwork?: string;
  commissionPercent?: number;
  netReceived?: number;
  settlementStatus?: SettlementStatus;

  // Status
  fulfillmentStatus: FulfillmentStatus;
  paymentStatus: OrderPaymentStatus;

  // Order-level payment status for advance / partial orders
  orderStatus?: OrderStatus;

  // Financial summary for advance / partial payments
  totalAmount?: number;
  totalPaid?: number;
  balanceDue?: number;

  // Split payments captured at checkout
  payments?: OrderPaymentEntry[];

  // Inventory movement
  orderFulfillmentMode?: OrderFulfillmentMode;
  inventoryStatus?: InventoryActionStatus;
  reservations?: InventoryReservation[];

  // Refund history
  refunds?: RefundEntry[];
  totalRefunded?: number;

  // Line items & totals
  items: CartItem[];
  totals: CartSummary;

  // Assignments
  assignedDesigner?: string;
  assignedDriver?: string;
  notes?: string;

  createdAt: string;
  updatedAt: string;
}

// ─── Held Order (for POS Hold/Resume) ───────────────────────

export interface HeldOrder {
  id: string;
  label: string;
  items: CartItem[];
  totals: CartSummary;
  heldAt: string;
  customerName?: string;
}

// ─── External Order (FTD Inbox) ─────────────────────────────

export type ExternalOrderStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED';

export interface ExternalOrder {
  id: string;
  externalOrderId: string;
  platform: 'FTD' | 'BLOOMNATION';
  senderName: string;
  recipientName: string;
  recipientPhone: string;
  deliveryDate: string;
  deliveryAddress: string;
  deliveryInstructions?: string;
  cardMessage: string;
  grossAmount: number;
  commission: number;
  fees: number;
  netPayout: number;
  items: { productName: string; quantity: number; unitPrice: number }[];
  status: ExternalOrderStatus;
  receivedAt: string;
  isExternallyPaid: boolean;
}

// ─── Wire Settlement ───────────────────────────────────────

export interface WireSettlement {
  orderNumber: string;
  vendorName: string;
  amount: number;
  status: SettlementStatus;
}

// ─── Delivery Slot ──────────────────────────────────────────

export type TimeSlot =
  | '9:00 AM - 11:00 AM'
  | '11:00 AM - 1:00 PM'
  | '1:00 PM - 3:00 PM'
  | '3:00 PM - 5:00 PM'
  | '5:00 PM - 7:00 PM';

export interface DeliveryEntry {
  orderId: string;
  orderNumber: string;
  recipientName: string;
  deliveryDate: string;
  timeSlot: TimeSlot;
  address: string;
  assignedDriver: string;
  fulfillmentStatus: FulfillmentStatus;
  orderSource: OrderSource;
}

// ─── Fulfillment status config ──────────────────────────────

export interface StatusConfig {
  label: string;
  color: string;
}

export const FULFILLMENT_STATUS_CONFIG: Record<FulfillmentStatus, StatusConfig> = {
  DRAFT:            { label: 'Draft',            color: '#9e9e9e' },
  CONFIRMED:        { label: 'Confirmed',        color: '#2196f3' },
  IN_DESIGN:        { label: 'In Design',        color: '#9c27b0' },
  READY:            { label: 'Ready',            color: '#00bcd4' },
  OUT_FOR_DELIVERY: { label: 'Out for Delivery', color: '#ff9800' },
  COMPLETED:        { label: 'Completed',        color: '#4caf50' },
  CANCELLED:        { label: 'Cancelled',        color: '#f44336' },
};

export const PAYMENT_STATUS_CONFIG: Record<OrderPaymentStatus, StatusConfig> = {
  PAID:   { label: 'Paid',   color: '#4caf50' },
  UNPAID: { label: 'Unpaid', color: '#f44336' },
  PARTIAL:{ label: 'Partial',color: '#00bcd4' },
};

export const ORDER_STATUS_CONFIG: Record<OrderStatus, StatusConfig> = {
  DRAFT:              { label: 'Draft',              color: '#9e9e9e' },
  PARTIALLY_PAID:     { label: 'Partially Paid',     color: '#ff9800' },
  PAID:               { label: 'Paid',               color: '#4caf50' },
  CANCELLED:          { label: 'Cancelled',          color: '#f44336' },
  PARTIALLY_REFUNDED: { label: 'Partially Refunded', color: '#ff9800' },
  REFUNDED:           { label: 'Refunded',           color: '#0288d1' },
};

/** Derive effective OrderStatus from an order, falling back to paymentStatus when orderStatus is unset. */
export function resolveOrderStatus(order: { orderStatus?: OrderStatus; paymentStatus: OrderPaymentStatus }): OrderStatus {
  if (order.orderStatus) return order.orderStatus;
  switch (order.paymentStatus) {
    case 'PAID':    return 'PAID';
    case 'PARTIAL': return 'PARTIALLY_PAID';
    case 'UNPAID':
    default:        return 'DRAFT';
  }
}

export const ORDER_SOURCE_CONFIG: Record<OrderSource, { label: string; color: string }> = {
  WALK_IN:     { label: 'Walk-In',      color: '#4caf50' },
  PHONE:       { label: 'Phone',        color: '#2196f3' },
  WEBSITE:     { label: 'Website',      color: '#9c27b0' },
  BLOOMNATION: { label: 'BloomNation',  color: '#e91e63' },
  FTD:         { label: 'FTD',          color: '#ff9800' },
};

export const TIME_SLOTS: TimeSlot[] = [
  '9:00 AM - 11:00 AM',
  '11:00 AM - 1:00 PM',
  '1:00 PM - 3:00 PM',
  '3:00 PM - 5:00 PM',
  '5:00 PM - 7:00 PM',
];

export const DESIGNERS = ['Anita Sharma', 'Priya Patel', 'Neha Gupta', 'Rohit Verma'];
export const DRIVERS   = ['Ravi Kumar', 'Sameer Das', 'Vikram Singh', 'Amit Thakur'];
export const OCCASIONS = ['Birthday', 'Anniversary', 'Wedding', 'Get Well', 'Sympathy', 'Congratulations', 'Thank You', 'Just Because'];
