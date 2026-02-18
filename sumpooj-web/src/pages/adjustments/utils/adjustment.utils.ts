/**
 * Inventory Adjustment — Utility Functions
 */

import type {
  AdjustmentProduct,
  AdjustmentRecord,
  WastageSummary,
} from '../data/adjustment.data';

// ─── Formatters ──────────────────────────────────────────────

export const fmt = (n: number): string =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    minimumFractionDigits: 2,
  }).format(n);

export const fmtDate = (d: string | null): string => {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};

// ─── Calculations ────────────────────────────────────────────

export const calcAdjustmentValue = (
  qty: number,
  costPerUnit: number,
): number => qty * costPerUnit;

export const calcBatchPercent = (
  qty: number,
  batchRemaining: number,
): number => (batchRemaining > 0 ? (qty / batchRemaining) * 100 : 0);

export const calcRemainingStock = (
  currentStock: number,
  qty: number,
): number => Math.max(0, currentStock - qty);

export const isHighValueAdjustment = (totalValue: number): boolean =>
  totalValue >= 100;

// ─── Summary Computation ─────────────────────────────────────

export const computeWastageSummary = (
  records: AdjustmentRecord[],
  totalInventoryValue: number,
): WastageSummary => {
  const now = new Date();
  const todayStr = now.toISOString().slice(0, 10);
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1)
    .toISOString()
    .slice(0, 10);

  let todayValue = 0;
  let todayCount = 0;
  let monthValue = 0;
  let monthCount = 0;

  const productWaste = new Map<string, number>();

  for (const r of records) {
    // Today
    if (r.adjustmentDate === todayStr) {
      todayValue += r.totalValue;
      todayCount++;
    }
    // This month
    if (r.adjustmentDate >= monthStart) {
      monthValue += r.totalValue;
      monthCount++;
    }
    // By product
    const prev = productWaste.get(r.productName) ?? 0;
    productWaste.set(r.productName, prev + r.totalValue);
  }

  // Top wasted product
  let topName = '—';
  let topValue = 0;
  for (const [name, val] of productWaste) {
    if (val > topValue) {
      topName = name;
      topValue = val;
    }
  }

  const totalShrinkagePercent =
    totalInventoryValue > 0 ? (monthValue / totalInventoryValue) * 100 : 0;

  return {
    todayTotalValue: todayValue,
    todayCount,
    monthTotalValue: monthValue,
    monthCount,
    topWastedProduct: topName,
    topWastedValue: topValue,
    totalShrinkagePercent,
  };
};

// ─── Build API payload ───────────────────────────────────────

export const buildPayload = (
  form: { productId: string; batchId: string; adjustmentType: string; quantity: number; reason: string; adjustedBy: string; adjustmentDate: string },
  product: AdjustmentProduct | undefined,
) => ({
  productId: form.productId,
  batchId: form.batchId,
  adjustmentType: form.adjustmentType,
  quantity: form.quantity,
  reason: form.reason,
  adjustedBy: form.adjustedBy,
  adjustmentDate: form.adjustmentDate,
  costPerUnit: product?.costPerUnit ?? 0,
  totalValue: (product?.costPerUnit ?? 0) * form.quantity,
});
