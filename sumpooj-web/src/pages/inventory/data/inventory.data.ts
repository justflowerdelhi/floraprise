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
  expiryDate?: string | null;   // null = non-perishable
  quantityReceived: number;
  quantityRemaining: number;
  supplier?: string;
  locationId: string;           // Business location (multi-location support)
  storageLocation: string;      // Storage location within the store
  costPerUnit: number;
  sellingPricePerUnit: number;
  isPerishable: boolean;
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

// ─── Mock Batches ─────────────────────────────────────────────

const today = new Date();
const d = (offset: number): string => {
  const dt = new Date(today);
  dt.setDate(dt.getDate() + offset);
  return dt.toISOString().slice(0, 10);
};
const past = (offset: number): string => d(-offset);

export const MOCK_BATCHES: InventoryBatch[] = [
  {
    id: 'bat_001',
    productId: 'prod_001',
    productName: 'Red Roses (Premium)',
    productType: 'Fresh Flowers',
    batchCode: 'FLW-RR-001-20260213-001',
    receivedDate: past(5),
    expiryDate: d(5),
    quantityReceived: 200,
    quantityRemaining: 145,
    supplier: 'Holland Direct',
    locationId: 'main_store',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 2.80,
    sellingPricePerUnit: 5.50,
    isPerishable: true,
  },
  {
    id: 'bat_002',
    productId: 'prod_002',
    productName: 'White Lilies',
    productType: 'Fresh Flowers',
    batchCode: 'FLW-WL-002-20260215-001',
    receivedDate: past(3),
    expiryDate: d(8),
    quantityReceived: 120,
    quantityRemaining: 110,
    supplier: 'FlowerFresh Imports',
    locationId: 'main_store',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 3.50,
    sellingPricePerUnit: 7.00,
    isPerishable: true,
  },
  {
    id: 'bat_003',
    productId: 'prod_003',
    productName: 'Sunflowers',
    productType: 'Fresh Flowers',
    batchCode: 'FLW-SF-003-20260212-001',
    receivedDate: past(6),
    expiryDate: d(1),
    quantityReceived: 80,
    quantityRemaining: 25,
    supplier: 'Local Growers Co-op',
    locationId: 'main_store',
    storageLocation: 'Display Cooler',
    costPerUnit: 1.90,
    sellingPricePerUnit: 4.50,
    isPerishable: true,
  },
  {
    id: 'bat_004',
    productId: 'prod_004',
    productName: "Baby's Breath",
    productType: 'Fresh Flowers',
    batchCode: 'FLW-BB-004-20260216-001',
    receivedDate: past(2),
    expiryDate: d(12),
    quantityReceived: 300,
    quantityRemaining: 290,
    supplier: 'Holland Direct',
    locationId: 'main_store',
    storageLocation: 'Walk-in Cooler B',
    costPerUnit: 0.60,
    sellingPricePerUnit: 1.80,
    isPerishable: true,
  },
  {
    id: 'bat_005',
    productId: 'prod_005',
    productName: 'Pink Carnations',
    productType: 'Fresh Flowers',
    batchCode: 'FLW-PC-005-20260211-001',
    receivedDate: past(7),
    expiryDate: d(4),
    quantityReceived: 150,
    quantityRemaining: 60,
    supplier: 'Pacific Blooms',
    locationId: 'main_store',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 1.20,
    sellingPricePerUnit: 3.00,
    isPerishable: true,
  },
  {
    id: 'bat_006',
    productId: 'prod_006',
    productName: 'Orchids (Phalaenopsis)',
    productType: 'Fresh Flowers',
    batchCode: 'FLW-OR-006-20260208-001',
    receivedDate: past(10),
    expiryDate: d(0),
    quantityReceived: 40,
    quantityRemaining: 12,
    supplier: 'FlowerFresh Imports',
    locationId: 'main_store',
    storageLocation: 'Display Cooler',
    costPerUnit: 8.50,
    sellingPricePerUnit: 18.00,
    isPerishable: true,
  },
  {
    id: 'bat_007',
    productId: 'prod_007',
    productName: 'Eucalyptus Bunches',
    productType: 'Greens & Foliage',
    batchCode: 'GRN-EU-007-20260214-001',
    receivedDate: past(4),
    expiryDate: d(10),
    quantityReceived: 100,
    quantityRemaining: 85,
    supplier: 'GreenLeaf Distributors',
    locationId: 'main_store',
    storageLocation: 'Walk-in Cooler B',
    costPerUnit: 2.10,
    sellingPricePerUnit: 5.00,
    isPerishable: true,
  },
  {
    id: 'bat_008',
    productId: 'prod_009',
    productName: 'Floral Foam Blocks',
    productType: 'Supplies',
    batchCode: 'SUP-FF-008-20260120-001',
    receivedDate: past(30),
    expiryDate: null,
    quantityReceived: 500,
    quantityRemaining: 320,
    supplier: 'Petal Perfect',
    locationId: 'main_store',
    storageLocation: 'Dry Storage',
    costPerUnit: 0.45,
    sellingPricePerUnit: 1.20,
    isPerishable: false,
  },
  {
    id: 'bat_009',
    productId: 'prod_010',
    productName: 'Glass Cylinder Vases',
    productType: 'Vases & Containers',
    batchCode: 'VAS-GC-009-20260129-001',
    receivedDate: past(20),
    expiryDate: null,
    quantityReceived: 60,
    quantityRemaining: 45,
    supplier: 'Petal Perfect',
    locationId: 'main_store',
    storageLocation: 'Dry Storage',
    costPerUnit: 4.50,
    sellingPricePerUnit: 12.00,
    isPerishable: false,
  },
  {
    id: 'bat_010',
    productId: 'prod_011',
    productName: 'Ribbon Rolls (Satin)',
    productType: 'Supplies',
    batchCode: 'SUP-RB-010-20260202-001',
    receivedDate: past(15),
    expiryDate: null,
    quantityReceived: 200,
    quantityRemaining: 30,
    supplier: 'Petal Perfect',
    locationId: 'main_store',
    storageLocation: 'Workshop',
    costPerUnit: 1.10,
    sellingPricePerUnit: 3.50,
    isPerishable: false,
  },
];

// ─── Mock API ─────────────────────────────────────────────────

export const fetchBatches = (): Promise<InventoryBatch[]> =>
  new Promise((resolve) =>
    setTimeout(() => resolve([...MOCK_BATCHES]), 800),
  );
