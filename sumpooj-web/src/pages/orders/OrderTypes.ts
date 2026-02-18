/**
 * OrderTypes.ts — Unified Order Model & Cart Types
 * Florist ERP SaaS — Hybrid POS + Unified Order System
 *
 * Supports: Walk-In POS, Phone Orders, Website Orders,
 *           BloomNation eCommerce, FTD / External Floral Network
 * Integrates with batch-based inventory engine (FIFO logic)
 * Payment model is SEPARATE — see PaymentTypes.ts
 */

// ─── Order Source & Statuses ────────────────────────────────

export type OrderSource = 'WALK_IN' | 'PHONE' | 'WEBSITE' | 'BLOOMNATION' | 'FTD';

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
  barcode: string;
  category: ProductCategory;
  sellingPrice: number;
  costPrice: number;       // weighted avg FIFO cost
  taxRate: number;         // e.g. 0.05 = 5%
  availableStock: number;
  isPerishable: boolean;
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
}

export interface CartSummary {
  subtotal: number;
  taxTotal: number;
  discountTotal: number;
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

  // Delivery
  deliveryDate?: string;
  deliveryTime?: string;
  deliveryAddress?: string;
  deliveryInstructions?: string;
  cardMessage?: string;
  occasion?: string;

  // Commission (for BLOOMNATION / FTD)
  externalCommission?: number;
  externalFees?: number;
  netPayout?: number;

  // Status
  fulfillmentStatus: FulfillmentStatus;
  paymentStatus: OrderPaymentStatus;

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
  color: 'default' | 'primary' | 'secondary' | 'error' | 'info' | 'success' | 'warning';
}

export const FULFILLMENT_STATUS_CONFIG: Record<FulfillmentStatus, StatusConfig> = {
  DRAFT:            { label: 'Draft',            color: 'default' },
  CONFIRMED:        { label: 'Confirmed',        color: 'primary' },
  IN_DESIGN:        { label: 'In Design',        color: 'secondary' },
  READY:            { label: 'Ready',            color: 'info' },
  OUT_FOR_DELIVERY: { label: 'Out for Delivery', color: 'warning' },
  COMPLETED:        { label: 'Completed',        color: 'success' },
  CANCELLED:        { label: 'Cancelled',        color: 'error' },
};

export const PAYMENT_STATUS_CONFIG: Record<OrderPaymentStatus, StatusConfig> = {
  PAID:   { label: 'Paid',   color: 'success' },
  UNPAID: { label: 'Unpaid', color: 'error' },
  PARTIAL:{ label: 'Partial',color: 'info' },
};

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
