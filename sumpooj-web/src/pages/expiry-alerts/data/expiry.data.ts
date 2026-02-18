/**
 * Expiry Alert Center — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 *
 * Re-exports inventory batch data and adds expiry-specific types.
 */

import type { InventoryBatch } from '../../inventory/data/inventory.data';
import {
  MOCK_BATCHES,
  STORAGE_LOCATIONS,
  SUPPLIERS,
} from '../../inventory/data/inventory.data';

// Re-export for convenience
export type { InventoryBatch };
export { STORAGE_LOCATIONS, SUPPLIERS };

// ─── Expiry-specific types ───────────────────────────────────

export type ExpiryUrgency = 'expired' | 'today' | 'critical' | 'warning' | 'safe';

export interface SuggestedAction {
  label: string;
  icon: 'discount' | 'promo' | 'prioritize' | 'wastage' | 'dispose';
  color: string;
}

export interface ExpiryAlertBatch extends InventoryBatch {
  daysLeft: number | null;
  urgency: ExpiryUrgency;
  inventoryValue: number;
  suggestedActions: SuggestedAction[];
}

export interface ExpiryFilterState {
  daysLeftMax: number | null;    // null = all
  supplier: string;
  location: string;
  freshFlowersOnly: boolean;
  sortDir: 'asc' | 'desc';
}

export interface ExpirySummary {
  expiringToday: number;
  expiringTodayValue: number;
  expiringIn3Days: number;
  expiringIn3DaysValue: number;
  expiringIn7Days: number;
  expiringIn7DaysValue: number;
  expiredCount: number;
  expiredValue: number;
  totalValueAtRisk: number;
}

// ─── Defaults ────────────────────────────────────────────────

export const DEFAULT_EXPIRY_FILTERS: ExpiryFilterState = {
  daysLeftMax: null,
  supplier: '',
  location: '',
  freshFlowersOnly: false,
  sortDir: 'asc',
};

export const DAYS_LEFT_OPTIONS = [
  { value: '', label: 'All Batches' },
  { value: '0', label: 'Expired Only' },
  { value: '1', label: 'Today' },
  { value: '3', label: 'Within 3 Days' },
  { value: '7', label: 'Within 7 Days' },
  { value: '14', label: 'Within 14 Days' },
] as const;

// ─── Mock API ────────────────────────────────────────────────

export const fetchExpiryBatches = (): Promise<InventoryBatch[]> =>
  new Promise((resolve) =>
    setTimeout(() => {
      // Only return perishable batches (ones with expiry dates)
      const perishable = MOCK_BATCHES.filter((b) => b.isPerishable && b.expiryDate !== null);
      resolve([...perishable]);
    }, 700),
  );
