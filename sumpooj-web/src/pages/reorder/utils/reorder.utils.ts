/**
 * Reorder Intelligence — Utility Functions
 */
import type {
  ReorderProduct,
  ReorderFilterState,
  ReorderSummary,
  StockRisk,
} from '../data/reorder.data';

// ─── Risk badge config ──────────────────────────────────────

interface RiskConfig {
  label: string;
  color: 'error' | 'warning' | 'success' | 'info';
  sortPriority: number;
}

export const RISK_CONFIG: Record<StockRisk, RiskConfig> = {
  stockout: { label: 'Stock-Out Risk', color: 'error', sortPriority: 0 },
  low:      { label: 'Low Stock',      color: 'warning', sortPriority: 1 },
  optimal:  { label: 'Optimal',        color: 'success', sortPriority: 2 },
  overstock:{ label: 'Overstock',      color: 'info',    sortPriority: 3 },
};

// ─── Filtering & Sorting ────────────────────────────────────

export const filterAndSort = (
  products: ReorderProduct[],
  f: ReorderFilterState,
): ReorderProduct[] => {
  let data = [...products];

  // Text search
  if (f.search.trim()) {
    const q = f.search.toLowerCase();
    data = data.filter(
      (p) =>
        p.productName.toLowerCase().includes(q) ||
        p.supplier.toLowerCase().includes(q) ||
        p.category.toLowerCase().includes(q),
    );
  }

  // Filters
  if (f.risk) {
    data = data.filter((p) => p.risk === f.risk);
  }
  if (f.supplier) {
    data = data.filter((p) => p.supplier === f.supplier);
  }
  if (f.category) {
    data = data.filter((p) => p.category === f.category);
  }

  // Sort
  data.sort((a, b) => {
    const dir = f.sortDir === 'asc' ? 1 : -1;
    const field = f.sortField;

    if (field === 'productName') {
      return dir * a.productName.localeCompare(b.productName);
    }
    return dir * ((a[field] as number) - (b[field] as number));
  });

  return data;
};

// ─── Summary computation ────────────────────────────────────

export const computeSummary = (products: ReorderProduct[]): ReorderSummary => ({
  stockoutRiskCount: products.filter((p) => p.risk === 'stockout').length,
  lowStockCount: products.filter((p) => p.risk === 'low').length,
  optimalCount: products.filter((p) => p.risk === 'optimal').length,
  overstockCount: products.filter((p) => p.risk === 'overstock').length,
  totalSuggestedCost: products.reduce((sum, p) => sum + p.estimatedOrderCost, 0),
  totalProducts: products.length,
});

// ─── Formatters (tenant-aware) ───────────────────────────────

import { formatCurrency } from '../../../core/i18n';

export const fmtCurrency = (v: number): string => formatCurrency(v);

export const fmtDays = (d: number): string =>
  d >= 999 ? '∞' : `${d.toFixed(1)} days`;

export const fmtDate = (iso: string): string => {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

// ─── PO generation (mock) ───────────────────────────────────

export interface PurchaseOrderLine {
  productId: string;
  productName: string;
  supplier: string;
  qty: number;
  unitCost: number;
  lineCost: number;
}

export interface GeneratedPO {
  poNumber: string;
  createdAt: string;
  lines: PurchaseOrderLine[];
  totalCost: number;
  supplierCount: number;
}

export const generatePO = (items: ReorderProduct[]): Promise<GeneratedPO> => {
  const lines: PurchaseOrderLine[] = items
    .filter((i) => i.suggestedOrderQty > 0)
    .map((i) => ({
      productId: i.id,
      productName: i.productName,
      supplier: i.supplier,
      qty: i.suggestedOrderQty,
      unitCost: i.costPerUnit,
      lineCost: i.estimatedOrderCost,
    }));

  const totalCost = lines.reduce((s, l) => s + l.lineCost, 0);
  const supplierCount = new Set(lines.map((l) => l.supplier)).size;
  const poNumber = `PO-${Date.now().toString(36).toUpperCase()}`;

  return new Promise((resolve) =>
    setTimeout(
      () =>
        resolve({
          poNumber,
          createdAt: new Date().toISOString(),
          lines,
          totalCost,
          supplierCount,
        }),
      800,
    ),
  );
};
