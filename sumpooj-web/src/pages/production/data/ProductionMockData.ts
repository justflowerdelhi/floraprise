/**
 * ProductionMockData.ts — Mock Data for Floral Production Engine
 *
 * Provides realistic sample data for all production modules.
 */

import type {
  FloralRecipe,
  FinishedGoodsBatch,
  ProductionMaintenanceLog,
  WastageLog,
  InventoryProduct,
} from '../types/ProductionTypes';

// ─── Helper ─────────────────────────────────────────────────

const now = new Date();
const isoOffset = (days: number, hours = 0): string => {
  const d = new Date(now);
  d.setDate(d.getDate() + days);
  d.setHours(d.getHours() + hours);
  return d.toISOString();
};

// ─── Inventory Products (Raw Materials) ─────────────────────

export const MOCK_INVENTORY_PRODUCTS: InventoryProduct[] = [
  { id: 'prod-001', name: 'Red Roses', productType: 'Fresh Flowers', quantityAvailable: 200, unitCost: 45, locationId: 'loc-001' },
  { id: 'prod-002', name: 'White Lilies', productType: 'Fresh Flowers', quantityAvailable: 80, unitCost: 65, locationId: 'loc-001' },
  { id: 'prod-003', name: 'Baby\'s Breath', productType: 'Fresh Flowers', quantityAvailable: 300, unitCost: 15, locationId: 'loc-001' },
  { id: 'prod-004', name: 'Eucalyptus', productType: 'Greens & Foliage', quantityAvailable: 150, unitCost: 25, locationId: 'loc-001' },
  { id: 'prod-005', name: 'Fern Leaves', productType: 'Greens & Foliage', quantityAvailable: 120, unitCost: 12, locationId: 'loc-001' },
  { id: 'prod-006', name: 'Pink Carnations', productType: 'Fresh Flowers', quantityAvailable: 160, unitCost: 30, locationId: 'loc-001' },
  { id: 'prod-007', name: 'Sunflowers', productType: 'Fresh Flowers', quantityAvailable: 60, unitCost: 55, locationId: 'loc-001' },
  { id: 'prod-008', name: 'Lavender Sprigs', productType: 'Fresh Flowers', quantityAvailable: 90, unitCost: 35, locationId: 'loc-001' },
  { id: 'prod-009', name: 'Ribbon Satin (m)', productType: 'Supplies', quantityAvailable: 500, unitCost: 8, locationId: 'loc-001' },
  { id: 'prod-010', name: 'Floral Foam Block', productType: 'Supplies', quantityAvailable: 40, unitCost: 20, locationId: 'loc-001' },
  { id: 'prod-011', name: 'Clear Cellophane (m)', productType: 'Supplies', quantityAvailable: 200, unitCost: 5, locationId: 'loc-001' },
  { id: 'prod-012', name: 'Yellow Tulips', productType: 'Fresh Flowers', quantityAvailable: 100, unitCost: 40, locationId: 'loc-002' },
  { id: 'prod-013', name: 'White Roses', productType: 'Fresh Flowers', quantityAvailable: 140, unitCost: 48, locationId: 'loc-002' },
  { id: 'prod-014', name: 'Orchids', productType: 'Fresh Flowers', quantityAvailable: 50, unitCost: 120, locationId: 'loc-002' },
  { id: 'prod-015', name: 'Peonies', productType: 'Fresh Flowers', quantityAvailable: 45, unitCost: 85, locationId: 'loc-001' },
];

// ─── Floral Recipes ─────────────────────────────────────────

export const MOCK_RECIPES: FloralRecipe[] = [
  {
    id: 'recipe-001',
    tenantId: 'tenant-001',
    name: 'Classic Red Rose Bouquet',
    category: 'Bouquet',
    sellingPrice: 1200,
    laborCost: 100,
    components: [
      { productId: 'prod-001', productName: 'Red Roses', quantityRequired: 12, unitCost: 45 },
      { productId: 'prod-003', productName: 'Baby\'s Breath', quantityRequired: 8, unitCost: 15 },
      { productId: 'prod-004', productName: 'Eucalyptus', quantityRequired: 4, unitCost: 25 },
      { productId: 'prod-009', productName: 'Ribbon Satin (m)', quantityRequired: 2, unitCost: 8 },
      { productId: 'prod-011', productName: 'Clear Cellophane (m)', quantityRequired: 1, unitCost: 5 },
    ],
    sampleImages: [],
    isActive: true,
    createdAt: isoOffset(-30),
    updatedAt: isoOffset(-5),
  },
  {
    id: 'recipe-002',
    tenantId: 'tenant-001',
    name: 'Elegant Lily Arrangement',
    category: 'Arrangement',
    sellingPrice: 1800,
    laborCost: 150,
    components: [
      { productId: 'prod-002', productName: 'White Lilies', quantityRequired: 6, unitCost: 65 },
      { productId: 'prod-005', productName: 'Fern Leaves', quantityRequired: 10, unitCost: 12 },
      { productId: 'prod-010', productName: 'Floral Foam Block', quantityRequired: 1, unitCost: 20 },
    ],
    sampleImages: [],
    isActive: true,
    createdAt: isoOffset(-25),
    updatedAt: isoOffset(-3),
  },
  {
    id: 'recipe-003',
    tenantId: 'tenant-001',
    name: 'Sunshine Sunflower Bouquet',
    category: 'Bouquet',
    sellingPrice: 950,
    laborCost: 80,
    components: [
      { productId: 'prod-007', productName: 'Sunflowers', quantityRequired: 5, unitCost: 55 },
      { productId: 'prod-004', productName: 'Eucalyptus', quantityRequired: 6, unitCost: 25 },
      { productId: 'prod-003', productName: 'Baby\'s Breath', quantityRequired: 10, unitCost: 15 },
      { productId: 'prod-009', productName: 'Ribbon Satin (m)', quantityRequired: 1.5, unitCost: 8 },
    ],
    sampleImages: [],
    isActive: true,
    createdAt: isoOffset(-20),
    updatedAt: isoOffset(-1),
  },
  {
    id: 'recipe-004',
    tenantId: 'tenant-001',
    name: 'Romantic Carnation Mix',
    category: 'Bouquet',
    sellingPrice: 750,
    laborCost: 60,
    components: [
      { productId: 'prod-006', productName: 'Pink Carnations', quantityRequired: 15, unitCost: 30 },
      { productId: 'prod-003', productName: 'Baby\'s Breath', quantityRequired: 12, unitCost: 15 },
      { productId: 'prod-011', productName: 'Clear Cellophane (m)', quantityRequired: 1, unitCost: 5 },
    ],
    sampleImages: [],
    isActive: true,
    createdAt: isoOffset(-15),
    updatedAt: isoOffset(-2),
  },
  {
    id: 'recipe-005',
    tenantId: 'tenant-001',
    name: 'Lavender Dreams Centerpiece',
    category: 'Centerpiece',
    sellingPrice: 2200,
    laborCost: 200,
    components: [
      { productId: 'prod-008', productName: 'Lavender Sprigs', quantityRequired: 20, unitCost: 35 },
      { productId: 'prod-004', productName: 'Eucalyptus', quantityRequired: 8, unitCost: 25 },
      { productId: 'prod-005', productName: 'Fern Leaves', quantityRequired: 6, unitCost: 12 },
      { productId: 'prod-010', productName: 'Floral Foam Block', quantityRequired: 2, unitCost: 20 },
    ],
    sampleImages: [],
    isActive: true,
    createdAt: isoOffset(-10),
    updatedAt: isoOffset(-1),
  },
  {
    id: 'recipe-006',
    tenantId: 'tenant-001',
    name: 'Premium Peony Bouquet',
    category: 'Bouquet',
    sellingPrice: 2800,
    laborCost: 180,
    components: [
      { productId: 'prod-015', productName: 'Peonies', quantityRequired: 8, unitCost: 85 },
      { productId: 'prod-001', productName: 'Red Roses', quantityRequired: 4, unitCost: 45 },
      { productId: 'prod-004', productName: 'Eucalyptus', quantityRequired: 5, unitCost: 25 },
      { productId: 'prod-009', productName: 'Ribbon Satin (m)', quantityRequired: 3, unitCost: 8 },
    ],
    sampleImages: [],
    isActive: false,
    createdAt: isoOffset(-40),
    updatedAt: isoOffset(-10),
  },
];

// ─── Finished Goods Batches ─────────────────────────────────

export const MOCK_FINISHED_BATCHES: FinishedGoodsBatch[] = [
  {
    id: 'fb-001',
    recipeId: 'recipe-001',
    recipeName: 'Classic Red Rose Bouquet',
    batchCode: 'FG-20260219-001',
    barcode: '8901234560001',
    quantityProduced: 10,
    quantityAvailable: 7,
    expectedExpiry: isoOffset(3),
    locationId: 'loc-001',
    locationName: 'Florist Hub - Bandra',
    status: 'ACTIVE',
    producedAt: isoOffset(-1),
  },
  {
    id: 'fb-002',
    recipeId: 'recipe-002',
    recipeName: 'Elegant Lily Arrangement',
    batchCode: 'FG-20260218-002',
    barcode: '8901234560002',
    quantityProduced: 5,
    quantityAvailable: 3,
    expectedExpiry: isoOffset(2),
    locationId: 'loc-001',
    locationName: 'Florist Hub - Bandra',
    status: 'ACTIVE',
    producedAt: isoOffset(-2),
  },
  {
    id: 'fb-003',
    recipeId: 'recipe-003',
    recipeName: 'Sunshine Sunflower Bouquet',
    batchCode: 'FG-20260217-003',
    barcode: '8901234560003',
    quantityProduced: 8,
    quantityAvailable: 0,
    expectedExpiry: isoOffset(1),
    locationId: 'loc-002',
    locationName: 'Florist Hub - Andheri',
    status: 'ACTIVE',
    producedAt: isoOffset(-3),
  },
  {
    id: 'fb-004',
    recipeId: 'recipe-004',
    recipeName: 'Romantic Carnation Mix',
    batchCode: 'FG-20260215-004',
    barcode: '8901234560004',
    quantityProduced: 12,
    quantityAvailable: 2,
    expectedExpiry: isoOffset(-1),
    locationId: 'loc-001',
    locationName: 'Florist Hub - Bandra',
    status: 'EXPIRED',
    producedAt: isoOffset(-5),
  },
  {
    id: 'fb-005',
    recipeId: 'recipe-005',
    recipeName: 'Lavender Dreams Centerpiece',
    batchCode: 'FG-20260219-005',
    barcode: '8901234560005',
    quantityProduced: 3,
    quantityAvailable: 3,
    expectedExpiry: isoOffset(5),
    locationId: 'loc-001',
    locationName: 'Florist Hub - Bandra',
    status: 'ACTIVE',
    producedAt: isoOffset(0),
  },
];

// ─── Maintenance Logs ───────────────────────────────────────

export const MOCK_MAINTENANCE_LOGS: ProductionMaintenanceLog[] = [
  {
    id: 'maint-001',
    finishedBatchId: 'fb-001',
    batchCode: 'FG-20260219-001',
    replacements: [
      { productId: 'prod-001', productName: 'Red Roses', quantityReplaced: 3, reason: 'WILTED' },
      { productId: 'prod-003', productName: 'Baby\'s Breath', quantityReplaced: 2, reason: 'SPOILED' },
    ],
    performedAt: isoOffset(0, -4),
    performedBy: 'Priya Designer',
    notes: 'Replaced wilted roses and spoiled baby\'s breath after overnight storage',
  },
];

// ─── Wastage Logs ───────────────────────────────────────────

export const MOCK_WASTAGE_LOGS: WastageLog[] = [
  {
    id: 'waste-001',
    productId: 'prod-001',
    productName: 'Red Roses',
    quantity: 3,
    reason: 'WILTED',
    relatedFinishedBatchId: 'fb-001',
    relatedBatchCode: 'FG-20260219-001',
    createdAt: isoOffset(0, -4),
    createdBy: 'Priya Designer',
  },
  {
    id: 'waste-002',
    productId: 'prod-003',
    productName: 'Baby\'s Breath',
    quantity: 2,
    reason: 'SPOILED',
    relatedFinishedBatchId: 'fb-001',
    relatedBatchCode: 'FG-20260219-001',
    createdAt: isoOffset(0, -4),
    createdBy: 'Priya Designer',
  },
  {
    id: 'waste-003',
    productId: 'prod-007',
    productName: 'Sunflowers',
    quantity: 5,
    reason: 'DAMAGED',
    createdAt: isoOffset(-2),
    createdBy: 'Raj Manager',
  },
  {
    id: 'waste-004',
    productId: 'prod-002',
    productName: 'White Lilies',
    quantity: 8,
    reason: 'WILTED',
    createdAt: isoOffset(-4),
    createdBy: 'Anita Staff',
  },
  {
    id: 'waste-005',
    productId: 'prod-006',
    productName: 'Pink Carnations',
    quantity: 10,
    reason: 'SPOILED',
    relatedFinishedBatchId: 'fb-004',
    relatedBatchCode: 'FG-20260215-004',
    createdAt: isoOffset(-1),
    createdBy: 'Priya Designer',
  },
];

// ─── Simulated async fetchers (will be replaced by API) ─────

const delay = (ms: number) => new Promise((res) => setTimeout(res, ms));

export const fetchRecipes = async (): Promise<FloralRecipe[]> => {
  await delay(400);
  return [...MOCK_RECIPES];
};

export const fetchFinishedBatches = async (): Promise<FinishedGoodsBatch[]> => {
  await delay(350);
  return [...MOCK_FINISHED_BATCHES];
};

export const fetchMaintenanceLogs = async (): Promise<ProductionMaintenanceLog[]> => {
  await delay(300);
  return [...MOCK_MAINTENANCE_LOGS];
};

export const fetchWastageLogs = async (): Promise<WastageLog[]> => {
  await delay(300);
  return [...MOCK_WASTAGE_LOGS];
};

export const fetchInventoryProducts = async (locationId?: string): Promise<InventoryProduct[]> => {
  await delay(250);
  if (locationId) {
    return MOCK_INVENTORY_PRODUCTS.filter((p) => p.locationId === locationId);
  }
  return [...MOCK_INVENTORY_PRODUCTS];
};
