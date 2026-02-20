/**
 * CartUtils.ts — FIFO batch allocation, line calculations, summary
 */
import type {
  Product,
  CartItem,
  CartSummary,
  BatchAllocation,
  InventoryBatch,
} from '../orders/OrderTypes';

let _lineSeq = 0;
export const nextLineId = (): string => `ln_${String(++_lineSeq).padStart(4, '0')}`;

// ─── FIFO Batch Allocation ──────────────────────────────────

/**
 * Automatically allocate `qty` units using FIFO (oldest receivedDate first).
 * Returns allocations + expiry warning flag.
 */
export const allocateFIFO = (
  batches: InventoryBatch[],
  qty: number,
): { allocations: BatchAllocation[]; expiryWarning: boolean } => {
  // Sort by receivedDate ASC (oldest first = FIFO)
  const sorted = [...batches]
    .filter((b) => b.quantity > 0)
    .sort((a, b) => a.receivedDate.localeCompare(b.receivedDate));

  const allocations: BatchAllocation[] = [];
  let remaining = qty;
  let expiryWarning = false;

  const now = new Date();
  const warnDate = new Date(now);
  warnDate.setDate(warnDate.getDate() + 3);

  for (const batch of sorted) {
    if (remaining <= 0) break;
    const take = Math.min(remaining, batch.quantity);
    allocations.push({
      batchId: batch.batchId,
      quantity: take,
      costPerUnit: batch.costPerUnit,
      expiryDate: batch.expiryDate,
      isManualOverride: false,
    });
    if (new Date(batch.expiryDate) <= warnDate) {
      expiryWarning = true;
    }
    remaining -= take;
  }

  return { allocations, expiryWarning };
};

// ─── Line Total Calculations ────────────────────────────────

import type { LineItemDiscount } from '../orders/OrderTypes';

/**
 * Calculate line discount amount from LineItemDiscount.
 * Supports PERCENT and FLAT types. Ensures discount cannot exceed gross.
 */
export const calcLineDiscountAmount = (
  gross: number,
  lineDiscount: LineItemDiscount | null | undefined,
): { discountAmount: number; discountPercent: number } => {
  if (!lineDiscount || gross <= 0) {
    return { discountAmount: 0, discountPercent: 0 };
  }

  if (lineDiscount.type === 'PERCENT') {
    const discountAmount = Math.round(gross * (lineDiscount.value / 100) * 100) / 100;
    return {
      discountAmount: Math.min(discountAmount, gross),
      discountPercent: lineDiscount.value,
    };
  }

  // FLAT discount
  const discountAmount = Math.min(lineDiscount.value, gross);
  const discountPercent = gross > 0 ? Math.round((discountAmount / gross) * 1000) / 10 : 0;
  return { discountAmount, discountPercent };
};

export const calcLineItem = (
  product: Product,
  qty: number,
  discountPercentOrLineDiscount: number | LineItemDiscount | null,
  manualBatchAllocations?: BatchAllocation[],
): CartItem => {
  // Batch allocation
  const { allocations, expiryWarning } = manualBatchAllocations
    ? { allocations: manualBatchAllocations, expiryWarning: false }
    : allocateFIFO(product.batches, qty);

  const unitPrice = product.sellingPrice;
  const gross = unitPrice * qty;

  // Support both legacy discountPercent (number) and new LineItemDiscount object
  let lineDiscount: LineItemDiscount | null = null;
  let discountAmount: number;
  let discountPercent: number;

  if (typeof discountPercentOrLineDiscount === 'number') {
    // Legacy: percentage-based discount
    discountPercent = discountPercentOrLineDiscount;
    discountAmount = Math.round(gross * discountPercent / 100 * 100) / 100;
    if (discountPercent > 0) {
      lineDiscount = { type: 'PERCENT', value: discountPercent };
    }
  } else {
    // New: LineItemDiscount object
    lineDiscount = discountPercentOrLineDiscount;
    const calc = calcLineDiscountAmount(gross, lineDiscount);
    discountAmount = calc.discountAmount;
    discountPercent = calc.discountPercent;
  }

  const lineTotal = Math.max(0, gross - discountAmount);
  const taxAmount = Math.round(lineTotal * product.taxRate * 100) / 100;

  // FIFO cost
  const lineCost = allocations.reduce((s, a) => s + a.quantity * a.costPerUnit, 0);
  const marginPercent = lineTotal > 0
    ? Math.round((1 - lineCost / lineTotal) * 1000) / 10
    : 0;

  // Stock warning
  const stockWarning = qty > product.availableStock;

  return {
    id: nextLineId(),
    productId: product.id,
    productName: product.name,
    sku: product.sku,
    category: product.category,
    quantity: qty,
    unitPrice,
    discountPercent,
    discountAmount,
    lineTotal,
    taxRate: product.taxRate,
    taxAmount,
    lineCost,
    marginPercent,
    batchAllocations: allocations,
    expiryWarning,
    stockWarning,
    lineDiscount,
  };
};

// ─── Cart Summary ───────────────────────────────────────────

import type { OrderDiscount } from '../orders/OrderTypes';

/**
 * Calculate order-level discount amount.
 * Ensures discount cannot exceed subtotal.
 */
export const calcOrderDiscountAmount = (
  subtotal: number,
  orderDiscount: OrderDiscount | null,
): number => {
  if (!orderDiscount || subtotal <= 0) return 0;

  if (orderDiscount.type === 'PERCENT') {
    const amount = Math.round(subtotal * (orderDiscount.value / 100) * 100) / 100;
    return Math.min(amount, subtotal); // Cannot exceed subtotal
  }

  // FLAT discount
  return Math.min(orderDiscount.value, subtotal); // Cannot exceed subtotal
};

export const calcCartSummary = (
  items: CartItem[],
  orderDiscount: OrderDiscount | null = null,
): CartSummary => {
  const subtotal      = items.reduce((s, i) => s + i.lineTotal, 0);
  const taxTotal      = items.reduce((s, i) => s + i.taxAmount, 0);
  const discountTotal = items.reduce((s, i) => s + i.discountAmount, 0);

  // Order-level discount calculation
  const orderDiscountAmount = calcOrderDiscountAmount(subtotal, orderDiscount);

  // New calculation order: Subtotal - Discount = Discounted Subtotal, then + Tax = Final Total
  const discountedSubtotal = subtotal - orderDiscountAmount;
  const grandTotal = Math.round((discountedSubtotal + taxTotal) * 100) / 100;

  const totalCost     = items.reduce((s, i) => s + i.lineCost, 0);
  const marginPercent = discountedSubtotal > 0
    ? Math.round((1 - totalCost / discountedSubtotal) * 1000) / 10
    : 0;

  return {
    subtotal:           Math.round(subtotal * 100) / 100,
    taxTotal:           Math.round(taxTotal * 100) / 100,
    discountTotal:      Math.round(discountTotal * 100) / 100,
    orderDiscountAmount: Math.round(orderDiscountAmount * 100) / 100,
    grandTotal:         Math.max(0, grandTotal), // Ensure non-negative
    totalCost:          Math.round(totalCost * 100) / 100,
    marginPercent,
    marginWarning:      marginPercent < 20,
    itemCount:          items.reduce((s, i) => s + i.quantity, 0),
    lineCount:          items.length,
  };
};

// ─── Formatters (tenant-aware) ───────────────────────────────

import { formatCurrency, formatPercent } from '../../core/i18n';

export const fmtCurrency = (v: number): string => formatCurrency(v);
export const fmtPercent  = (v: number): string => formatPercent(v);
