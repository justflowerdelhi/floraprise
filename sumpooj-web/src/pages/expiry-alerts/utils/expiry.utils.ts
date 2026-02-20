/**
 * Expiry Alert Center — Utility Functions
 */

import type {
  InventoryBatch,
  ExpiryAlertBatch,
  ExpiryUrgency,
  SuggestedAction,
  ExpiryFilterState,
  ExpirySummary,
} from '../data/expiry.data';

// ─── Date Helpers ────────────────────────────────────────────

export const getDaysLeft = (expiryDate: string | null): number | null => {
  if (!expiryDate) return null;
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const exp = new Date(expiryDate);
  exp.setHours(0, 0, 0, 0);
  return Math.ceil((exp.getTime() - now.getTime()) / 86_400_000);
};

// ─── Urgency Logic ───────────────────────────────────────────

export const getUrgency = (daysLeft: number | null): ExpiryUrgency => {
  if (daysLeft === null) return 'safe';
  if (daysLeft < 0) return 'expired';
  if (daysLeft === 0) return 'today';
  if (daysLeft <= 3) return 'critical';
  if (daysLeft <= 7) return 'warning';
  return 'safe';
};

export const urgencyConfig: Record<
  ExpiryUrgency,
  { label: string; color: string; bg: string; textColor: string }
> = {
  expired:  { label: 'Expired',    color: '#616161', bg: '#f5f5f5', textColor: '#424242' },
  today:    { label: 'Today',      color: '#c62828', bg: '#ffebee', textColor: '#b71c1c' },
  critical: { label: '≤ 3 Days',   color: '#c62828', bg: '#ffebee', textColor: '#b71c1c' },
  warning:  { label: '≤ 7 Days',   color: '#e65100', bg: '#fff3e0', textColor: '#bf360c' },
  safe:     { label: '7+ Days',    color: '#2e7d32', bg: '#e8f5e9', textColor: '#1b5e20' },
};

// ─── Suggested Actions ───────────────────────────────────────

const getSuggestedActions = (daysLeft: number | null): SuggestedAction[] => {
  if (daysLeft === null) return [];

  if (daysLeft < 0) {
    // Expired
    return [
      { label: 'Adjust as Wastage', icon: 'wastage', color: '#c62828' },
      { label: 'Mark Disposed', icon: 'dispose', color: '#616161' },
    ];
  }

  if (daysLeft <= 3) {
    // Critical — expiring very soon
    return [
      { label: 'Discount for Quick Sale', icon: 'discount', color: '#e65100' },
      { label: 'Use in Promotion', icon: 'promo', color: '#6a1b9a' },
      { label: 'Prioritize in POS', icon: 'prioritize', color: '#00838f' },
    ];
  }

  // Warning range (4-7 days) — still actionable
  if (daysLeft <= 7) {
    return [
      { label: 'Prioritize in POS', icon: 'prioritize', color: '#00838f' },
    ];
  }

  return [];
};

// ─── Enrich batches with computed fields ─────────────────────

export const enrichBatch = (b: InventoryBatch): ExpiryAlertBatch => {
  const daysLeft = getDaysLeft(b.expiryDate);
  return {
    ...b,
    daysLeft,
    urgency: getUrgency(daysLeft),
    inventoryValue: b.quantityRemaining * b.costPerUnit,
    suggestedActions: getSuggestedActions(daysLeft),
  };
};

// ─── Summary Computation ─────────────────────────────────────

export const computeExpirySummary = (batches: ExpiryAlertBatch[]): ExpirySummary => {
  let expiringToday = 0, expiringTodayValue = 0;
  let exp3 = 0, exp3Value = 0;
  let exp7 = 0, exp7Value = 0;
  let expiredCount = 0, expiredValue = 0;

  for (const b of batches) {
    const d = b.daysLeft;
    if (d === null) continue;

    if (d < 0) {
      expiredCount++;
      expiredValue += b.inventoryValue;
    } else {
      if (d === 0) {
        expiringToday++;
        expiringTodayValue += b.inventoryValue;
      }
      if (d <= 3) {
        exp3++;
        exp3Value += b.inventoryValue;
      }
      if (d <= 7) {
        exp7++;
        exp7Value += b.inventoryValue;
      }
    }
  }

  return {
    expiringToday,
    expiringTodayValue,
    expiringIn3Days: exp3,
    expiringIn3DaysValue: exp3Value,
    expiringIn7Days: exp7,
    expiringIn7DaysValue: exp7Value,
    expiredCount,
    expiredValue,
    totalValueAtRisk: expiredValue + exp7Value,
  };
};

// ─── Filter & Sort ───────────────────────────────────────────

export const filterAndSort = (
  batches: ExpiryAlertBatch[],
  filters: ExpiryFilterState,
): ExpiryAlertBatch[] => {
  let result = [...batches];

  // Days left filter
  if (filters.daysLeftMax !== null) {
    if (filters.daysLeftMax === 0) {
      // expired only
      result = result.filter((b) => b.daysLeft !== null && b.daysLeft < 0);
    } else {
      result = result.filter(
        (b) => b.daysLeft !== null && b.daysLeft <= filters.daysLeftMax!,
      );
    }
  }

  // Supplier
  if (filters.supplier) {
    result = result.filter((b) => b.supplier === filters.supplier);
  }

  // Location
  if (filters.location) {
    result = result.filter((b) => b.storageLocation === filters.location);
  }

  // Fresh flowers only
  if (filters.freshFlowersOnly) {
    result = result.filter((b) => b.productType === 'Fresh Flowers');
  }

  // Sort by days left
  result.sort((a, b) => {
    const da = a.daysLeft ?? 9999;
    const db = b.daysLeft ?? 9999;
    return filters.sortDir === 'asc' ? da - db : db - da;
  });

  return result;
};

// ─── Export CSV ──────────────────────────────────────────────

export const exportCSV = (batches: ExpiryAlertBatch[]): void => {
  const header = [
    'Product',
    'Batch #',
    'Supplier',
    'Location',
    'Qty Remaining',
    'Expiry Date',
    'Days Left',
    'Inventory Value',
    'Urgency',
    'Suggested Actions',
  ].join(',');

  const rows = batches.map((b) =>
    [
      `"${b.productName}"`,
      b.batchCode,
      `"${b.supplier}"`,
      `"${b.storageLocation}"`,
      b.quantityRemaining,
      b.expiryDate ?? 'N/A',
      b.daysLeft ?? 'N/A',
      b.inventoryValue.toFixed(2),
      b.urgency,
      `"${b.suggestedActions.map((a) => a.label).join('; ')}"`,
    ].join(','),
  );

  const csv = [header, ...rows].join('\n');
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `expiry-alerts-${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
  URL.revokeObjectURL(url);
};

// ─── Formatters ──────────────────────────────────────────────

import { formatCurrency } from '../../../core/i18n';

export const fmt = (n: number): string => formatCurrency(n);

export const fmtDate = (d: string | null): string => {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
};
