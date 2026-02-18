/**
 * Inventory Dashboard — Utility Functions
 * Florist POS + ERP SaaS Platform
 */

import type {
  InventoryBatch,
  DashboardSummary,
  FilterState,
  BatchStatus,
} from '../data/inventory.data';
import { LOW_STOCK_THRESHOLD } from '../data/inventory.data';

// ─── Date Helpers ─────────────────────────────────────────────

export const getDaysLeft = (expiryDate: string | null): number | null => {
  if (!expiryDate) return null; // non-perishable
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const exp = new Date(expiryDate);
  exp.setHours(0, 0, 0, 0);
  return Math.ceil((exp.getTime() - now.getTime()) / 86_400_000);
};

// ─── Status Logic ─────────────────────────────────────────────

export const getBatchStatus = (batch: InventoryBatch): BatchStatus => {
  if (!batch.isPerishable || !batch.expiryDate) return 'fresh';
  const days = getDaysLeft(batch.expiryDate);
  if (days === null) return 'fresh';
  if (days < 0) return 'expired';
  if (days <= 2) return 'critical';
  if (days <= 6) return 'warning';
  return 'good';
};

export const statusConfig: Record<
  BatchStatus,
  { label: string; color: string; bg: string; textColor: string }
> = {
  fresh:    { label: 'Fresh',    color: '#2e7d32', bg: '#e8f5e9', textColor: '#1b5e20' },
  good:     { label: 'Good',     color: '#2e7d32', bg: '#e8f5e9', textColor: '#1b5e20' },
  warning:  { label: 'Warning',  color: '#e65100', bg: '#fff3e0', textColor: '#bf360c' },
  critical: { label: 'Critical', color: '#c62828', bg: '#ffebee', textColor: '#b71c1c' },
  expired:  { label: 'Expired',  color: '#616161', bg: '#f5f5f5', textColor: '#424242' },
};

// ─── Calculations ─────────────────────────────────────────────

export const getRemainingValue = (b: InventoryBatch): number =>
  b.quantityRemaining * b.costPerUnit;

export const getExpiryProgress = (b: InventoryBatch): number => {
  if (!b.isPerishable || !b.expiryDate) return 100;
  const purchase = new Date(b.purchaseDate).getTime();
  const expiry = new Date(b.expiryDate).getTime();
  const now = Date.now();
  const totalLife = expiry - purchase;
  if (totalLife <= 0) return 0;
  const remaining = expiry - now;
  return Math.max(0, Math.min(100, (remaining / totalLife) * 100));
};

export const getStockPercent = (b: InventoryBatch): number =>
  b.quantityOriginal > 0
    ? (b.quantityRemaining / b.quantityOriginal) * 100
    : 0;

export const isLowStock = (b: InventoryBatch): boolean =>
  b.quantityOriginal > 0 &&
  b.quantityRemaining / b.quantityOriginal <= LOW_STOCK_THRESHOLD;

// ─── Dashboard Summary ───────────────────────────────────────

export const computeSummary = (batches: InventoryBatch[]): DashboardSummary => {
  let totalValue = 0;
  let exp3Count = 0;
  let exp3Value = 0;
  let expiredCount = 0;
  let expiredValue = 0;
  let lowStock = 0;
  let freshFlowerValue = 0;
  let perishDaysTotal = 0;
  let perishCount = 0;
  const productSet = new Set<string>();

  for (const b of batches) {
    const val = getRemainingValue(b);
    totalValue += val;
    productSet.add(b.productName);

    if (b.productType === 'Fresh Flowers') {
      freshFlowerValue += val;
    }

    if (isLowStock(b)) lowStock++;

    const days = getDaysLeft(b.expiryDate);
    if (days !== null && b.isPerishable) {
      if (days < 0) {
        expiredCount++;
        expiredValue += val;
      } else if (days <= 3) {
        exp3Count++;
        exp3Value += val;
      }
      perishDaysTotal += Math.max(0, days);
      perishCount++;
    }
  }

  return {
    totalBatches: batches.length,
    totalProducts: productSet.size,
    totalInventoryValue: totalValue,
    expiringIn3Days: exp3Count,
    expiringIn3DaysValue: exp3Value,
    expiredCount,
    expiredValue,
    lowStockCount: lowStock,
    freshFlowerValue,
    averageDaysRemaining: perishCount > 0 ? perishDaysTotal / perishCount : 0,
  };
};

// ─── Filter & Sort ────────────────────────────────────────────

export const filterAndSort = (
  batches: InventoryBatch[],
  filters: FilterState,
): InventoryBatch[] => {
  let result = [...batches];

  // Search
  if (filters.search) {
    const q = filters.search.toLowerCase();
    result = result.filter(
      (b) =>
        b.productName.toLowerCase().includes(q) ||
        b.batchNumber.toLowerCase().includes(q) ||
        b.supplier.toLowerCase().includes(q),
    );
  }

  // Status filter
  if (filters.status !== 'all') {
    result = result.filter((b) => getBatchStatus(b) === filters.status);
  }

  // Location
  if (filters.location) {
    result = result.filter((b) => b.location === filters.location);
  }

  // Supplier
  if (filters.supplier) {
    result = result.filter((b) => b.supplier === filters.supplier);
  }

  // Product type
  if (filters.productType) {
    result = result.filter((b) => b.productType === filters.productType);
  }

  // Expiring within X days
  if (filters.expiringWithinDays !== null) {
    result = result.filter((b) => {
      const days = getDaysLeft(b.expiryDate);
      return days !== null && days >= 0 && days <= filters.expiringWithinDays!;
    });
  }

  // Sort
  result.sort((a, b) => {
    const dir = filters.sortDir === 'asc' ? 1 : -1;
    switch (filters.sortField) {
      case 'expiryDate': {
        const da = getDaysLeft(a.expiryDate) ?? 9999;
        const db = getDaysLeft(b.expiryDate) ?? 9999;
        return (da - db) * dir;
      }
      case 'daysLeft': {
        const da = getDaysLeft(a.expiryDate) ?? 9999;
        const db = getDaysLeft(b.expiryDate) ?? 9999;
        return (da - db) * dir;
      }
      case 'productName':
        return a.productName.localeCompare(b.productName) * dir;
      case 'value':
        return (getRemainingValue(a) - getRemainingValue(b)) * dir;
      default:
        return 0;
    }
  });

  return result;
};

// ─── Export CSV ───────────────────────────────────────────────

export const exportCSV = (batches: InventoryBatch[]): void => {
  const header = [
    'Product Name',
    'Batch Number',
    'Supplier',
    'Location',
    'Purchase Date',
    'Expiry Date',
    'Days Left',
    'Qty Remaining',
    'Original Qty',
    'Remaining Value',
    'Status',
  ].join(',');

  const rows = batches.map((b) => {
    const days = getDaysLeft(b.expiryDate);
    return [
      `"${b.productName}"`,
      b.batchNumber,
      `"${b.supplier}"`,
      `"${b.location}"`,
      b.purchaseDate,
      b.expiryDate ?? 'N/A',
      days !== null ? days : 'N/A',
      b.quantityRemaining,
      b.quantityOriginal,
      getRemainingValue(b).toFixed(2),
      getBatchStatus(b),
    ].join(',');
  });

  const csv = [header, ...rows].join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `inventory-batches-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
};

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
