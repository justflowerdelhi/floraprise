/**
 * Inventory Batch Mock Data
 * Test data for Inventory Batch Dashboard
 * Florist POS + ERP SaaS Platform
 */

import type { InventoryBatch, DashboardSummary, BatchStatus } from './inventory.data';

const today = new Date();
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const daysFrom = (n: number) => {
  const d = new Date(today);
  d.setDate(d.getDate() + n);
  return isoDate(d);
};
const daysAgo = (n: number) => daysFrom(-n);

// ─── Mock Inventory Batches ─────────────────────────────────

export const MOCK_INVENTORY_BATCHES: InventoryBatch[] = [
  // Fresh Flowers - Walk-in Cooler A
  {
    id: 'batch_001',
    productId: 'prod_001',
    productName: 'Red Rose',
    productType: 'Fresh Flowers',
    batchCode: 'ROSE-2026-0301-A',
    receivedDate: daysAgo(2),
    expiryDate: daysFrom(5),
    quantityReceived: 100,
    quantityRemaining: 85,
    stemsInStock: 85,
    usedUnits: 0,
    damagedUnits: 0,
    supplier: 'Holland Direct',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 60,
    sellingPricePerUnit: 120,
    isPerishable: true,
  },
  {
    id: 'batch_002',
    productId: 'prod_001',
    productName: 'Red Rose',
    productType: 'Fresh Flowers',
    batchCode: 'ROSE-2026-0228-A',
    receivedDate: daysAgo(4),
    expiryDate: daysFrom(3),
    quantityReceived: 80,
    quantityRemaining: 25,
    supplier: 'Holland Direct',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 58,
    sellingPricePerUnit: 120,
    isPerishable: true,
  },
  {
    id: 'batch_003',
    productId: 'prod_002',
    productName: 'White Lily',
    productType: 'Fresh Flowers',
    batchCode: 'LILY-2026-0302-A',
    receivedDate: daysAgo(1),
    expiryDate: daysFrom(9),
    quantityReceived: 50,
    quantityRemaining: 48,
    supplier: 'Holland Direct',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 90,
    sellingPricePerUnit: 180,
    isPerishable: true,
  },
  {
    id: 'batch_004',
    productId: 'prod_003',
    productName: 'Pink Carnation',
    productType: 'Fresh Flowers',
    batchCode: 'CARN-2026-0225-A',
    receivedDate: daysAgo(7),
    expiryDate: daysFrom(7),
    quantityReceived: 200,
    quantityRemaining: 120,
    supplier: 'FlowerFresh Imports',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 18,
    sellingPricePerUnit: 40,
    isPerishable: true,
  },
  // Critical/Warning batches
  {
    id: 'batch_005',
    productId: 'prod_004',
    productName: 'Yellow Tulip',
    productType: 'Fresh Flowers',
    batchCode: 'TULP-2026-0228-B',
    receivedDate: daysAgo(5),
    expiryDate: daysFrom(2),
    quantityReceived: 60,
    quantityRemaining: 45,
    supplier: 'Holland Direct',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler B',
    costPerUnit: 32,
    sellingPricePerUnit: 65,
    isPerishable: true,
  },
  {
    id: 'batch_006',
    productId: 'prod_005',
    productName: 'White Gerbera',
    productType: 'Fresh Flowers',
    batchCode: 'GERB-2026-0226-A',
    receivedDate: daysAgo(6),
    expiryDate: daysFrom(4),
    quantityReceived: 80,
    quantityRemaining: 35,
    supplier: 'Pacific Blooms',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 35,
    sellingPricePerUnit: 75,
    isPerishable: true,
  },
  // Expired batch
  {
    id: 'batch_007',
    productId: 'prod_004',
    productName: 'Yellow Tulip',
    productType: 'Fresh Flowers',
    batchCode: 'TULP-2026-0220-A',
    receivedDate: daysAgo(12),
    expiryDate: daysAgo(2),
    quantityReceived: 40,
    quantityRemaining: 8,
    supplier: 'Holland Direct',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 32,
    sellingPricePerUnit: 65,
    isPerishable: true,
  },
  // Greens & Foliage
  {
    id: 'batch_008',
    productId: 'prod_006',
    productName: 'Eucalyptus Silver Dollar',
    productType: 'Greens & Foliage',
    batchCode: 'EUCA-2026-0301-A',
    receivedDate: daysAgo(2),
    expiryDate: daysFrom(12),
    quantityReceived: 25,
    quantityRemaining: 22,
    supplier: 'Local Growers Co-op',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler B',
    costPerUnit: 140,
    sellingPricePerUnit: 280,
    isPerishable: true,
  },
  // Display Cooler items
  {
    id: 'batch_009',
    productId: 'prod_001',
    productName: 'Red Rose',
    productType: 'Fresh Flowers',
    batchCode: 'ROSE-2026-0303-D',
    receivedDate: daysAgo(0),
    expiryDate: daysFrom(7),
    quantityReceived: 30,
    quantityRemaining: 28,
    supplier: 'Holland Direct',
    locationId: 'loc_main',
    storageLocation: 'Display Cooler',
    costPerUnit: 60,
    sellingPricePerUnit: 120,
    isPerishable: true,
  },
  {
    id: 'batch_010',
    productId: 'prod_003',
    productName: 'Pink Carnation',
    productType: 'Fresh Flowers',
    batchCode: 'CARN-2026-0302-D',
    receivedDate: daysAgo(1),
    expiryDate: daysFrom(13),
    quantityReceived: 50,
    quantityRemaining: 42,
    supplier: 'FlowerFresh Imports',
    locationId: 'loc_main',
    storageLocation: 'Display Cooler',
    costPerUnit: 18,
    sellingPricePerUnit: 40,
    isPerishable: true,
  },
  // Non-perishable items - Dry Storage
  {
    id: 'batch_011',
    productId: 'prod_011',
    productName: 'Glass Cylinder Vase - Large',
    productType: 'Vases & Containers',
    batchCode: 'VASE-2026-0215-A',
    receivedDate: daysAgo(17),
    expiryDate: null,
    quantityReceived: 20,
    quantityRemaining: 12,
    supplier: 'Petal Perfect',
    locationId: 'loc_main',
    storageLocation: 'Dry Storage',
    costPerUnit: 280,
    sellingPricePerUnit: 650,
    isPerishable: false,
  },
  {
    id: 'batch_012',
    productId: 'prod_014',
    productName: 'Floral Foam Block - Fresh',
    productType: 'Supplies',
    batchCode: 'FOAM-2026-0220-A',
    receivedDate: daysAgo(12),
    expiryDate: null,
    quantityReceived: 100,
    quantityRemaining: 65,
    supplier: 'Petal Perfect',
    locationId: 'loc_main',
    storageLocation: 'Dry Storage',
    costPerUnit: 18,
    sellingPricePerUnit: 45,
    isPerishable: false,
  },
  // Gift items with long shelf life
  {
    id: 'batch_013',
    productId: 'prod_015',
    productName: 'Belgian Chocolate Box - Premium',
    productType: 'Gift Items',
    batchCode: 'CHOC-2026-0201-A',
    receivedDate: daysAgo(31),
    expiryDate: daysFrom(149),
    quantityReceived: 30,
    quantityRemaining: 18,
    supplier: 'FlowerFresh Imports',
    locationId: 'loc_main',
    storageLocation: 'Dry Storage',
    costPerUnit: 420,
    sellingPricePerUnit: 850,
    isPerishable: true,
  },
  // Dried Flowers - Workshop
  {
    id: 'batch_014',
    productId: 'prod_017',
    productName: 'Dried Lavender Bundle',
    productType: 'Dried Flowers',
    batchCode: 'DLAV-2026-0215-A',
    receivedDate: daysAgo(17),
    expiryDate: null,
    quantityReceived: 30,
    quantityRemaining: 22,
    supplier: 'Local Growers Co-op',
    locationId: 'loc_main',
    storageLocation: 'Workshop',
    costPerUnit: 150,
    sellingPricePerUnit: 350,
    isPerishable: false,
  },
  {
    id: 'batch_015',
    productId: 'prod_018',
    productName: 'Pampas Grass - Natural',
    productType: 'Dried Flowers',
    batchCode: 'PAMP-2026-0220-A',
    receivedDate: daysAgo(12),
    expiryDate: null,
    quantityReceived: 40,
    quantityRemaining: 32,
    supplier: 'GreenLeaf Distributors',
    locationId: 'loc_main',
    storageLocation: 'Workshop',
    costPerUnit: 120,
    sellingPricePerUnit: 280,
    isPerishable: false,
  },
  // Branch location batches
  {
    id: 'batch_016',
    productId: 'prod_001',
    productName: 'Red Rose',
    productType: 'Fresh Flowers',
    batchCode: 'ROSE-2026-0302-B1',
    receivedDate: daysAgo(1),
    expiryDate: daysFrom(6),
    quantityReceived: 50,
    quantityRemaining: 45,
    supplier: 'Holland Direct',
    locationId: 'loc_branch1',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 60,
    sellingPricePerUnit: 120,
    isPerishable: true,
  },
  {
    id: 'batch_017',
    productId: 'prod_003',
    productName: 'Pink Carnation',
    productType: 'Fresh Flowers',
    batchCode: 'CARN-2026-0228-B1',
    receivedDate: daysAgo(4),
    expiryDate: daysFrom(10),
    quantityReceived: 100,
    quantityRemaining: 75,
    supplier: 'FlowerFresh Imports',
    locationId: 'loc_branch1',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 18,
    sellingPricePerUnit: 40,
    isPerishable: true,
  },
  // Low stock batch
  {
    id: 'batch_018',
    productId: 'prod_002',
    productName: 'White Lily',
    productType: 'Fresh Flowers',
    batchCode: 'LILY-2026-0225-A',
    receivedDate: daysAgo(7),
    expiryDate: daysFrom(3),
    quantityReceived: 40,
    quantityRemaining: 5,
    supplier: 'Holland Direct',
    locationId: 'loc_main',
    storageLocation: 'Walk-in Cooler A',
    costPerUnit: 88,
    sellingPricePerUnit: 180,
    isPerishable: true,
  },
];

// ─── Batch Status Helper ────────────────────────────────────

export const getBatchStatus = (batch: InventoryBatch): BatchStatus => {
  if (!batch.expiryDate) return 'fresh'; // Non-perishable
  
  const today = new Date();
  const expiry = new Date(batch.expiryDate);
  const daysLeft = Math.ceil((expiry.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
  
  if (daysLeft < 0) return 'expired';
  if (daysLeft <= 2) return 'critical';
  if (daysLeft <= 4) return 'warning';
  if (daysLeft <= 7) return 'good';
  return 'fresh';
};

// ─── Dashboard Summary ──────────────────────────────────────

export const calculateDashboardSummary = (batches: InventoryBatch[]): DashboardSummary => {
  const today = new Date();
  const threeDaysFromNow = new Date(today);
  threeDaysFromNow.setDate(threeDaysFromNow.getDate() + 3);

  const expiringIn3Days = batches.filter(b => {
    if (!b.expiryDate) return false;
    const expiry = new Date(b.expiryDate);
    return expiry > today && expiry <= threeDaysFromNow;
  });

  const expired = batches.filter(b => {
    if (!b.expiryDate) return false;
    return new Date(b.expiryDate) < today;
  });

  const lowStock = batches.filter(b => {
    if (!b.isPerishable) return false;
    return b.quantityRemaining / b.quantityReceived < 0.2;
  });

  const freshFlowers = batches.filter(b => b.productType === 'Fresh Flowers');

  const perishableBatches = batches.filter(b => b.expiryDate && new Date(b.expiryDate) > today);
  const avgDaysRemaining = perishableBatches.length > 0
    ? perishableBatches.reduce((sum, b) => {
        const daysLeft = Math.ceil((new Date(b.expiryDate!).getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
        return sum + daysLeft;
      }, 0) / perishableBatches.length
    : 0;

  return {
    totalBatches: batches.length,
    totalProducts: new Set(batches.map(b => b.productId)).size,
    totalInventoryValue: batches.reduce((sum, b) => sum + (b.quantityRemaining * b.costPerUnit), 0),
    expiringIn3Days: expiringIn3Days.length,
    expiringIn3DaysValue: expiringIn3Days.reduce((sum, b) => sum + (b.quantityRemaining * b.costPerUnit), 0),
    expiredCount: expired.length,
    expiredValue: expired.reduce((sum, b) => sum + (b.quantityRemaining * b.costPerUnit), 0),
    lowStockCount: lowStock.length,
    freshFlowerValue: freshFlowers.reduce((sum, b) => sum + (b.quantityRemaining * b.costPerUnit), 0),
    averageDaysRemaining: Math.round(avgDaysRemaining * 10) / 10,
  };
};

export const MOCK_DASHBOARD_SUMMARY = calculateDashboardSummary(MOCK_INVENTORY_BATCHES);

// ─── Mock API Functions ─────────────────────────────────────

export const fetchInventoryBatches = (filters?: {
  status?: BatchStatus | 'all';
  storageLocation?: string;
  productType?: string;
  supplier?: string;
  locationId?: string;
  expiringWithinDays?: number;
}): Promise<InventoryBatch[]> =>
  new Promise(resolve => setTimeout(() => {
    let results = [...MOCK_INVENTORY_BATCHES];
    
    if (filters?.status && filters.status !== 'all') {
      results = results.filter(b => getBatchStatus(b) === filters.status);
    }
    if (filters?.storageLocation) {
      results = results.filter(b => b.storageLocation === filters.storageLocation);
    }
    if (filters?.productType) {
      results = results.filter(b => b.productType === filters.productType);
    }
    if (filters?.supplier) {
      results = results.filter(b => b.supplier === filters.supplier);
    }
    if (filters?.locationId) {
      results = results.filter(b => b.locationId === filters.locationId);
    }
    if (filters?.expiringWithinDays) {
      const threshold = new Date();
      threshold.setDate(threshold.getDate() + filters.expiringWithinDays);
      results = results.filter(b => {
        if (!b.expiryDate) return false;
        const expiry = new Date(b.expiryDate);
        return expiry <= threshold && expiry > new Date();
      });
    }
    
    resolve(results);
  }, 500));

export const fetchBatchById = (batchId: string): Promise<InventoryBatch | null> =>
  new Promise(resolve => setTimeout(() => {
    resolve(MOCK_INVENTORY_BATCHES.find(b => b.id === batchId) || null);
  }, 300));

export const fetchDashboardSummary = (): Promise<DashboardSummary> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_DASHBOARD_SUMMARY), 300));

export const fetchExpiringBatches = (days: number = 3): Promise<InventoryBatch[]> =>
  new Promise(resolve => setTimeout(() => {
    const threshold = new Date();
    threshold.setDate(threshold.getDate() + days);
    const today = new Date();
    
    const results = MOCK_INVENTORY_BATCHES.filter(b => {
      if (!b.expiryDate) return false;
      const expiry = new Date(b.expiryDate);
      return expiry <= threshold && expiry > today;
    });
    
    resolve(results);
  }, 400));

export const fetchExpiredBatches = (): Promise<InventoryBatch[]> =>
  new Promise(resolve => setTimeout(() => {
    const today = new Date();
    const results = MOCK_INVENTORY_BATCHES.filter(b => {
      if (!b.expiryDate) return false;
      return new Date(b.expiryDate) < today;
    });
    resolve(results);
  }, 400));
