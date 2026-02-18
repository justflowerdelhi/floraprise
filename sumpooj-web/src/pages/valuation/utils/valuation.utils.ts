/**
 * Inventory Valuation Report — Utility Functions
 */

import type {
  ValuationProduct,
  ValuationFilterState,
  ValuationSummary,
} from '../data/valuation.data';

// ─── Formatters ─────────────────────────────────────────────

export const fmt = (n: number): string =>
  '₹' +
  n.toLocaleString('en-IN', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });

export const fmtPct = (n: number): string => `${n.toFixed(1)}%`;

export const fmtDate = (iso: string): string => {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};

// ─── Category helpers ───────────────────────────────────────

export const categoryConfig: Record<
  string,
  { color: string; bg: string; textColor: string }
> = {
  'Fresh Flowers':      { color: '#c62828', bg: '#ffebee', textColor: '#b71c1c' },
  'Greens & Foliage':   { color: '#2e7d32', bg: '#e8f5e9', textColor: '#1b5e20' },
  'Dried Flowers':      { color: '#e65100', bg: '#fff3e0', textColor: '#bf360c' },
  'Supplies':           { color: '#616161', bg: '#f5f5f5', textColor: '#424242' },
  'Vases & Containers': { color: '#1565c0', bg: '#e3f2fd', textColor: '#0d47a1' },
  'Gift Items':         { color: '#6a1b9a', bg: '#f3e5f5', textColor: '#4a148c' },
};

// ─── Summary Computation ────────────────────────────────────

const HARD_GOODS_CATEGORIES = new Set([
  'Supplies',
  'Vases & Containers',
  'Gift Items',
  'Dried Flowers',
]);

export const computeValuationSummary = (
  products: ValuationProduct[],
): ValuationSummary => {
  let totalInventoryValue = 0;
  let freshFlowersValue = 0;
  let hardGoodsValue = 0;
  let totalBatches = 0;
  let totalQuantity = 0;
  let marginSum = 0;

  for (const p of products) {
    totalInventoryValue += p.totalValue;
    totalQuantity += p.totalQuantity;
    totalBatches += p.fifoLayers.length;
    marginSum += p.marginPercent;

    if (p.isPerishable) {
      freshFlowersValue += p.totalValue;
    }
    if (HARD_GOODS_CATEGORIES.has(p.category)) {
      hardGoodsValue += p.totalValue;
    }
  }

  return {
    totalInventoryValue,
    freshFlowersValue,
    hardGoodsValue,
    totalBatches,
    averageMarginPct:
      products.length > 0
        ? Math.round((marginSum / products.length) * 10) / 10
        : 0,
    totalProducts: products.length,
    totalQuantity,
  };
};

// ─── Filter & Sort ──────────────────────────────────────────

export const filterAndSort = (
  products: ValuationProduct[],
  filters: ValuationFilterState,
): ValuationProduct[] => {
  let result = [...products];

  // Search — product name
  if (filters.search.trim()) {
    const q = filters.search.toLowerCase().trim();
    result = result.filter((p) =>
      p.productName.toLowerCase().includes(q),
    );
  }

  // Category
  if (filters.category) {
    result = result.filter((p) => p.category === filters.category);
  }

  // Location
  if (filters.location) {
    result = result.filter((p) => p.location === filters.location);
  }

  // As-of date — only include products with batches purchased on or before
  if (filters.asOfDate) {
    const cutoff = new Date(filters.asOfDate);
    cutoff.setHours(23, 59, 59, 999);
    result = result.filter((p) =>
      p.fifoLayers.some((l) => new Date(l.purchaseDate) <= cutoff),
    );
  }

  // Perishable only
  if (filters.perishableOnly) {
    result = result.filter((p) => p.isPerishable);
  }

  // Sort
  result.sort((a, b) => {
    let diff = 0;
    switch (filters.sortField) {
      case 'productName':
        diff = a.productName.localeCompare(b.productName);
        break;
      case 'totalValue':
        diff = a.totalValue - b.totalValue;
        break;
      case 'totalQuantity':
        diff = a.totalQuantity - b.totalQuantity;
        break;
      case 'marginPercent':
        diff = a.marginPercent - b.marginPercent;
        break;
    }
    return filters.sortDir === 'asc' ? diff : -diff;
  });

  return result;
};

// ─── CSV Export ──────────────────────────────────────────────

export const exportCSV = (products: ValuationProduct[]): void => {
  const headers = [
    'Product',
    'Category',
    'Location',
    'Quantity',
    'Avg Cost',
    'Total Value',
    '% of Total',
    'Selling Price',
    'Margin %',
    'Perishable',
    'FIFO Layers',
    'Last Purchase',
  ];

  const rows = products.map((p) => [
    p.productName,
    p.category,
    p.location,
    p.totalQuantity,
    p.averageCost,
    p.totalValue.toFixed(2),
    p.pctOfTotalInventory.toFixed(1),
    p.sellingPricePerUnit,
    p.marginPercent.toFixed(1),
    p.isPerishable ? 'Yes' : 'No',
    p.fifoLayers.length,
    fmtDate(p.lastPurchaseDate),
  ]);

  const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `inventory-valuation-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
};

// ─── Print View ─────────────────────────────────────────────

export const printReport = (): void => {
  window.print();
};
