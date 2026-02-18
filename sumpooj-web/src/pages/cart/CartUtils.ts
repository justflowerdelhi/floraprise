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

export const calcLineItem = (
  product: Product,
  qty: number,
  discountPercent: number,
  manualBatchAllocations?: BatchAllocation[],
): CartItem => {
  // Batch allocation
  const { allocations, expiryWarning } = manualBatchAllocations
    ? { allocations: manualBatchAllocations, expiryWarning: false }
    : allocateFIFO(product.batches, qty);

  const unitPrice = product.sellingPrice;
  const gross = unitPrice * qty;
  const discountAmount = Math.round(gross * discountPercent / 100 * 100) / 100;
  const lineTotal = gross - discountAmount;
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
  };
};

// ─── Cart Summary ───────────────────────────────────────────

export const calcCartSummary = (items: CartItem[]): CartSummary => {
  const subtotal      = items.reduce((s, i) => s + i.lineTotal, 0);
  const taxTotal      = items.reduce((s, i) => s + i.taxAmount, 0);
  const discountTotal = items.reduce((s, i) => s + i.discountAmount, 0);
  const grandTotal    = Math.round((subtotal + taxTotal) * 100) / 100;
  const totalCost     = items.reduce((s, i) => s + i.lineCost, 0);
  const marginPercent = subtotal > 0
    ? Math.round((1 - totalCost / subtotal) * 1000) / 10
    : 0;

  return {
    subtotal:      Math.round(subtotal * 100) / 100,
    taxTotal:      Math.round(taxTotal * 100) / 100,
    discountTotal: Math.round(discountTotal * 100) / 100,
    grandTotal,
    totalCost:     Math.round(totalCost * 100) / 100,
    marginPercent,
    marginWarning: marginPercent < 20,
    itemCount:     items.reduce((s, i) => s + i.quantity, 0),
    lineCount:     items.length,
  };
};

// ─── Formatters ─────────────────────────────────────────────

const INR = new Intl.NumberFormat('en-IN', {
  style: 'currency', currency: 'INR',
  minimumFractionDigits: 0, maximumFractionDigits: 2,
});

export const fmtCurrency = (v: number): string => INR.format(v);
export const fmtPercent  = (v: number): string => `${v.toFixed(1)}%`;
