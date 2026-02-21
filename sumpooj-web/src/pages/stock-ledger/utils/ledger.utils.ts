/**
 * Stock Movement Ledger — Utility Functions
 */

import type {
  StockMovement,
  LedgerFilterState,
  LedgerSummary,
} from '../data/ledger.data';
import { formatCurrency, getCurrencySymbol } from '../../../core/i18n';

// ─── Formatters ─────────────────────────────────────────────

export const fmt = (n: number): string => formatCurrency(Math.abs(n));

export const fmtSigned = (n: number): string =>
  (n >= 0 ? '+' : '−') + formatCurrency(Math.abs(n));

export const fmtDate = (iso: string): string => {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

export const fmtDateTime = (iso: string): string => {
  const d = new Date(iso);
  return (
    d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) +
    ', ' +
    d.toLocaleTimeString('en-IN', { hour: '2-digit', minute: '2-digit', hour12: true })
  );
};

// ─── Reference Type Config ──────────────────────────────────

export const refTypeConfig: Record<
  string,
  { color: string; bg: string; textColor: string; icon: string }
> = {
  Purchase:   { color: '#2e7d32', bg: '#e8f5e9', textColor: '#1b5e20', icon: '📦' },
  Sale:       { color: '#1565c0', bg: '#e3f2fd', textColor: '#0d47a1', icon: '🛒' },
  Adjustment: { color: '#e65100', bg: '#fff3e0', textColor: '#bf360c', icon: '⚙️' },
  Transfer:   { color: '#6a1b9a', bg: '#f3e5f5', textColor: '#4a148c', icon: '🔄' },
};

// ─── Summary Computation ────────────────────────────────────

export const computeLedgerSummary = (movements: StockMovement[]): LedgerSummary => {
  if (movements.length === 0) {
    return {
      openingBalance: 0,
      totalIn: 0,
      totalOut: 0,
      closingBalance: 0,
      totalCostIn: 0,
      totalCostOut: 0,
    };
  }

  // Movements should already be sorted chronologically
  const sorted = [...movements].sort(
    (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime(),
  );

  const first = sorted[0];
  const last = sorted[sorted.length - 1];

  const openingBalance = first.balanceAfter - first.quantityIn + first.quantityOut;

  let totalIn = 0;
  let totalOut = 0;
  let totalCostIn = 0;
  let totalCostOut = 0;

  for (const mv of sorted) {
    totalIn += mv.quantityIn;
    totalOut += mv.quantityOut;
    if (mv.costImpact > 0) totalCostIn += mv.costImpact;
    if (mv.costImpact < 0) totalCostOut += Math.abs(mv.costImpact);
  }

  return {
    openingBalance,
    totalIn,
    totalOut,
    closingBalance: last.balanceAfter,
    totalCostIn,
    totalCostOut,
  };
};

// ─── Filter & Sort ──────────────────────────────────────────

export const filterAndSort = (
  movements: StockMovement[],
  filters: LedgerFilterState,
): StockMovement[] => {
  let result = [...movements];

  // Search — product name, reference number, batch, performed by, notes
  if (filters.search.trim()) {
    const q = filters.search.toLowerCase().trim();
    result = result.filter(
      (m) =>
        m.productName.toLowerCase().includes(q) ||
        m.referenceNumber.toLowerCase().includes(q) ||
        m.batchNumber.toLowerCase().includes(q) ||
        m.performedBy.toLowerCase().includes(q) ||
        m.notes.toLowerCase().includes(q),
    );
  }

  // Product filter
  if (filters.productId) {
    result = result.filter((m) => m.productId === filters.productId);
  }

  // Date range
  if (filters.dateFrom) {
    const from = new Date(filters.dateFrom);
    from.setHours(0, 0, 0, 0);
    result = result.filter((m) => new Date(m.date) >= from);
  }
  if (filters.dateTo) {
    const to = new Date(filters.dateTo);
    to.setHours(23, 59, 59, 999);
    result = result.filter((m) => new Date(m.date) <= to);
  }

  // Location filter
  if (filters.location) {
    result = result.filter((m) => m.location.includes(filters.location));
  }

  // Reference type filter
  if (filters.referenceType) {
    result = result.filter((m) => m.referenceType === filters.referenceType);
  }

  // Sort by date
  result.sort((a, b) => {
    const diff = new Date(a.date).getTime() - new Date(b.date).getTime();
    return filters.sortDir === 'asc' ? diff : -diff;
  });

  return result;
};

// ─── CSV Export ──────────────────────────────────────────────

export const exportCSV = (movements: StockMovement[]): void => {
  const headers = [
    'Date',
    'Reference Type',
    'Reference Number',
    'Product',
    'Batch #',
    'Location',
    'Qty In',
    'Qty Out',
    'Balance After',
    'Cost Impact',
    'Performed By',
    'Notes',
  ];

  const rows = movements.map((m) => [
    fmtDateTime(m.date),
    m.referenceType,
    m.referenceNumber,
    m.productName,
    m.batchNumber,
    m.location,
    m.quantityIn || '',
    m.quantityOut || '',
    m.balanceAfter,
    m.costImpact,
    m.performedBy,
    `"${m.notes.replace(/"/g, '""')}"`,
  ]);

  const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `stock-ledger-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
};
