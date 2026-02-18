/**
 * Inventory Batch Dashboard — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 */

// ─── Types ────────────────────────────────────────────────────

export type BatchStatus = 'fresh' | 'good' | 'warning' | 'critical' | 'expired';

export interface InventoryBatch {
  id: string;
  productName: string;
  productType: string;          // Fresh Flowers, Greens, Dried, Supplies, etc.
  batchNumber: string;
  supplier: string;
  locationId?: string;          // Business location (multi-location support)
  storageLocation: string;      // Storage location within the store
  purchaseDate: string;         // ISO date
  expiryDate: string | null;    // null = non-perishable
  quantityOriginal: number;
  quantityRemaining: number;
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
    productName: 'Red Roses (Premium)',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0201',
    supplier: 'Holland Direct',
    storageLocation: 'Walk-in Cooler A',
    purchaseDate: past(5),
    expiryDate: d(5),
    quantityOriginal: 200,
    quantityRemaining: 145,
    costPerUnit: 2.80,
    sellingPricePerUnit: 5.50,
    isPerishable: true,
  },
  {
    id: 'bat_002',
    productName: 'White Lilies',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0202',
    supplier: 'FlowerFresh Imports',
    storageLocation: 'Walk-in Cooler A',
    purchaseDate: past(3),
    expiryDate: d(8),
    quantityOriginal: 120,
    quantityRemaining: 110,
    costPerUnit: 3.50,
    sellingPricePerUnit: 7.00,
    isPerishable: true,
  },
  {
    id: 'bat_003',
    productName: 'Sunflowers',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0203',
    supplier: 'Local Growers Co-op',
    storageLocation: 'Display Cooler',
    purchaseDate: past(6),
    expiryDate: d(1),
    quantityOriginal: 80,
    quantityRemaining: 25,
    costPerUnit: 1.90,
    sellingPricePerUnit: 4.50,
    isPerishable: true,
  },
  {
    id: 'bat_004',
    productName: 'Baby\'s Breath',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0204',
    supplier: 'Holland Direct',
    storageLocation: 'Walk-in Cooler B',
    purchaseDate: past(2),
    expiryDate: d(12),
    quantityOriginal: 300,
    quantityRemaining: 290,
    costPerUnit: 0.60,
    sellingPricePerUnit: 1.80,
    isPerishable: true,
  },
  {
    id: 'bat_005',
    productName: 'Pink Carnations',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0205',
    supplier: 'Pacific Blooms',
    storageLocation: 'Walk-in Cooler A',
    purchaseDate: past(7),
    expiryDate: d(4),
    quantityOriginal: 150,
    quantityRemaining: 60,
    costPerUnit: 1.20,
    sellingPricePerUnit: 3.00,
    isPerishable: true,
  },
  {
    id: 'bat_006',
    productName: 'Orchids (Phalaenopsis)',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0206',
    supplier: 'FlowerFresh Imports',
    storageLocation: 'Display Cooler',
    purchaseDate: past(10),
    expiryDate: d(0),
    quantityOriginal: 40,
    quantityRemaining: 12,
    costPerUnit: 8.50,
    sellingPricePerUnit: 18.00,
    isPerishable: true,
  },
  {
    id: 'bat_007',
    productName: 'Eucalyptus Bunches',
    productType: 'Greens & Foliage',
    batchNumber: 'BT-2026-0207',
    supplier: 'GreenLeaf Distributors',
    storageLocation: 'Walk-in Cooler B',
    purchaseDate: past(4),
    expiryDate: d(10),
    quantityOriginal: 100,
    quantityRemaining: 85,
    costPerUnit: 2.10,
    sellingPricePerUnit: 5.00,
    isPerishable: true,
  },
  {
    id: 'bat_008',
    productName: 'Tulips (Mixed)',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0208',
    supplier: 'Holland Direct',
    storageLocation: 'Walk-in Cooler A',
    purchaseDate: past(12),
    expiryDate: d(-2),
    quantityOriginal: 100,
    quantityRemaining: 40,
    costPerUnit: 2.40,
    sellingPricePerUnit: 5.00,
    isPerishable: true,
  },
  {
    id: 'bat_009',
    productName: 'Floral Foam Blocks',
    productType: 'Supplies',
    batchNumber: 'BT-2026-0209',
    supplier: 'Petal Perfect',
    storageLocation: 'Dry Storage',
    purchaseDate: past(30),
    expiryDate: null,
    quantityOriginal: 500,
    quantityRemaining: 320,
    costPerUnit: 0.45,
    sellingPricePerUnit: 1.20,
    isPerishable: false,
  },
  {
    id: 'bat_010',
    productName: 'Glass Cylinder Vases',
    productType: 'Vases & Containers',
    batchNumber: 'BT-2026-0210',
    supplier: 'Petal Perfect',
    storageLocation: 'Dry Storage',
    purchaseDate: past(20),
    expiryDate: null,
    quantityOriginal: 60,
    quantityRemaining: 45,
    costPerUnit: 4.50,
    sellingPricePerUnit: 12.00,
    isPerishable: false,
  },
  {
    id: 'bat_011',
    productName: 'Ribbon Rolls (Satin)',
    productType: 'Supplies',
    batchNumber: 'BT-2026-0211',
    supplier: 'Petal Perfect',
    storageLocation: 'Workshop',
    purchaseDate: past(15),
    expiryDate: null,
    quantityOriginal: 200,
    quantityRemaining: 30,
    costPerUnit: 1.10,
    sellingPricePerUnit: 3.50,
    isPerishable: false,
  },
  {
    id: 'bat_012',
    productName: 'Gerbera Daisies',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0212',
    supplier: 'Local Growers Co-op',
    storageLocation: 'Display Cooler',
    purchaseDate: past(8),
    expiryDate: d(-3),
    quantityOriginal: 90,
    quantityRemaining: 55,
    costPerUnit: 1.60,
    sellingPricePerUnit: 4.00,
    isPerishable: true,
  },
  {
    id: 'bat_013',
    productName: 'Dried Lavender Bunches',
    productType: 'Dried Flowers',
    batchNumber: 'BT-2026-0213',
    supplier: 'Local Growers Co-op',
    storageLocation: 'Dry Storage',
    purchaseDate: past(40),
    expiryDate: null,
    quantityOriginal: 70,
    quantityRemaining: 55,
    costPerUnit: 3.20,
    sellingPricePerUnit: 8.00,
    isPerishable: false,
  },
  {
    id: 'bat_014',
    productName: 'Hydrangeas (Blue)',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0214',
    supplier: 'Pacific Blooms',
    storageLocation: 'Walk-in Cooler B',
    purchaseDate: past(3),
    expiryDate: d(6),
    quantityOriginal: 60,
    quantityRemaining: 58,
    costPerUnit: 4.20,
    sellingPricePerUnit: 9.00,
    isPerishable: true,
  },
  {
    id: 'bat_015',
    productName: 'Peonies',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0215',
    supplier: 'Holland Direct',
    storageLocation: 'Walk-in Cooler A',
    purchaseDate: past(4),
    expiryDate: d(2),
    quantityOriginal: 50,
    quantityRemaining: 42,
    costPerUnit: 5.50,
    sellingPricePerUnit: 12.00,
    isPerishable: true,
  },
  {
    id: 'bat_016',
    productName: 'Ruscus (Italian)',
    productType: 'Greens & Foliage',
    batchNumber: 'BT-2026-0216',
    supplier: 'GreenLeaf Distributors',
    storageLocation: 'Walk-in Cooler B',
    purchaseDate: past(2),
    expiryDate: d(14),
    quantityOriginal: 150,
    quantityRemaining: 148,
    costPerUnit: 1.40,
    sellingPricePerUnit: 3.50,
    isPerishable: true,
  },
  {
    id: 'bat_017',
    productName: 'Gift Wrapping Paper',
    productType: 'Gift Items',
    batchNumber: 'BT-2026-0217',
    supplier: 'Petal Perfect',
    storageLocation: 'Workshop',
    purchaseDate: past(25),
    expiryDate: null,
    quantityOriginal: 400,
    quantityRemaining: 60,
    costPerUnit: 0.30,
    sellingPricePerUnit: 1.00,
    isPerishable: false,
  },
  {
    id: 'bat_018',
    productName: 'Spray Roses (Peach)',
    productType: 'Fresh Flowers',
    batchNumber: 'BT-2026-0218',
    supplier: 'Pacific Blooms',
    storageLocation: 'Walk-in Cooler A',
    purchaseDate: past(1),
    expiryDate: d(9),
    quantityOriginal: 180,
    quantityRemaining: 178,
    costPerUnit: 2.20,
    sellingPricePerUnit: 5.00,
    isPerishable: true,
  },
];

// ─── Mock API ─────────────────────────────────────────────────

export const fetchBatches = (): Promise<InventoryBatch[]> =>
  new Promise((resolve) =>
    setTimeout(() => resolve([...MOCK_BATCHES]), 800),
  );
