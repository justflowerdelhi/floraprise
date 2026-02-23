/**
 * Inventory Batch Dashboard — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 */

// ─── Types ────────────────────────────────────────────────────

export type BatchStatus = 'fresh' | 'good' | 'warning' | 'critical' | 'expired';

export interface InventoryBatch {
  id: string;
  productId: string;
  productName: string;
  productType: string;          // Fresh Flowers, Greens, Dried, Supplies, etc.
  batchCode: string;
  receivedDate: string;         // ISO date
  expiryDate: string | null;    // null = non-perishable
  quantityReceived: number;
  quantityRemaining: number;
  supplier?: string;
  locationId: string;           // Business location (multi-location support)
  storageLocation: string;      // Storage location within the store
  costPerUnit: number;
  sellingPricePerUnit: number;
  isPerishable: boolean;
  // Multi-unit flower support
  stemsInStock?: number; // Number of stems in this batch
  usedUnits?: number; // Units used from this batch (default 0)
  damagedUnits?: number; // Units damaged in this batch (default 0)
}

export interface DashboardSummary {
  totalBatches: number;
  totalProducts: number;
  totalInventoryValue: number;
  expiringIn3Days: number;
  expiringIn3DaysValue: number;
  expiredCount: number;
  expiredValue: number;
  lowStockCount: number;
  freshFlowerValue: number;
  averageDaysRemaining: number;
}

export interface FilterState {
  search: string;
  status: BatchStatus | 'all';
  storageLocation: string; // Storage location within store
  supplier: string;
  productType: string;
  expiringWithinDays: number | null;
  sortField: 'expiryDate' | 'daysLeft' | 'productName' | 'value';
  sortDir: 'asc' | 'desc';
}

// ─── Constants ────────────────────────────────────────────────

export const STORAGE_LOCATIONS = [
  'Walk-in Cooler A',
  'Walk-in Cooler B',
  'Display Cooler',
  'Dry Storage',
  'Workshop',
  'Front Display',
] as const;

export const PRODUCT_TYPES = [
  'Fresh Flowers',
  'Greens & Foliage',
  'Dried Flowers',
  'Supplies',
  'Vases & Containers',
  'Gift Items',
] as const;

export const SUPPLIERS = [
  'Holland Direct',
  'Local Growers Co-op',
  'FlowerFresh Imports',
  'GreenLeaf Distributors',
  'Pacific Blooms',
  'Petal Perfect',
] as const;

export const LOW_STOCK_THRESHOLD = 0.2; // 20% remaining

export const DEFAULT_FILTERS: FilterState = {
  search: '',
  status: 'all',
  storageLocation: '',
  supplier: '',
  productType: '',
  expiringWithinDays: null,
  sortField: 'expiryDate',
  sortDir: 'asc',
};

// Note: Mock data removed. Use real API via ../../api/inventory.api.ts
// Functions: searchBatches, createBatch, getBatchById, getBatchesByProduct,
//            getExpiryAlerts, getInventorySummary, searchAdjustments,
//            createAdjustment, getRecentAdjustments
