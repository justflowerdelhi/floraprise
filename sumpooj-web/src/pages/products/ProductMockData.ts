/**
 * Product Mock Data
 * Test data for Product catalog module
 * Florist POS + ERP SaaS Platform
 */

import type { 
  ProductType, 
  UnitOfMeasure, 
  TaxCategory, 
  FlowerGrade, 
  CountryCode, 
  Seasonality,
  Supplier 
} from './types/product.types';

// ─── Mock product type for full product list ────────────────

export interface Product {
  id: string;
  productName: string;
  productType: ProductType;
  sku: string;
  barcode?: string;
  internalBarcode?: string;
  brand?: string;
  description?: string;
  unitOfMeasure: UnitOfMeasure;
  retailPrice: number;
  costPrice: number;
  wholesalePrice?: number;
  weddingEventPrice?: number;
  taxCategory: TaxCategory;
  trackInventory: boolean;
  trackBatch: boolean;
  currentStock: number;
  reorderLevel?: number;
  isPerishable: boolean;
  shelfLifeDays?: number;
  expiryAlertDays?: number;
  temperatureNotes?: string;
  color?: string;
  variety?: string;
  grade?: FlowerGrade;
  countryOfOrigin?: CountryCode;
  seasonality?: Seasonality[];
  supplierId?: string;
  supplierName?: string;
  leadTimeDays?: number;
  incomeAccount: string;
  expenseAccount: string;
  status: 'active' | 'inactive';
  allowAsRawMaterial: boolean;
  availableOnline: boolean;
  commissionEligible: boolean;
  tags?: string[];
  imageUrl?: string;
  createdAt: string;
  updatedAt: string;
  // Multi-unit flower configuration
  isMultiUnit?: boolean; // If true, product supports multi-unit consumption
  baseUnit?: 'STEM'; // Always STEM for flowers, default STEM
  consumptionUnit?: 'STEM' | 'BUD' | 'BLOOM'; // Allowed values
  avgUnitsPerStem?: number; // Default 1, >1 if isMultiUnit
  allowPartialConsumption?: boolean; // If true, partial consumption allowed
}

// ─── Mock Suppliers ─────────────────────────────────────────

export const MOCK_SUPPLIERS: Supplier[] = [
  { id: 'sup_001', name: 'Holland Direct', code: 'HOL', email: 'orders@hollanddirect.com', phone: '+31 20 555 1234', leadTime: 3 },
  { id: 'sup_002', name: 'Local Growers Co-op', code: 'LGC', email: 'supply@localgrowers.in', phone: '+91 80 5555 2345', leadTime: 1 },
  { id: 'sup_003', name: 'FlowerFresh Imports', code: 'FFI', email: 'sales@flowerfresh.com', phone: '+91 22 5555 3456', leadTime: 5 },
  { id: 'sup_004', name: 'GreenLeaf Distributors', code: 'GLD', email: 'info@greenleaf.in', phone: '+91 11 5555 4567', leadTime: 2 },
  { id: 'sup_005', name: 'Pacific Blooms', code: 'PAC', email: 'orders@pacificblooms.com', phone: '+1 503 555 5678', leadTime: 7 },
  { id: 'sup_006', name: 'Petal Perfect Supplies', code: 'PPS', email: 'contact@petalperfect.in', phone: '+91 40 5555 6789', leadTime: 2 },
];

// ─── Mock Products ──────────────────────────────────────────

export const MOCK_PRODUCTS: Product[] = [
  // Fresh Flowers
  {
    id: 'prod_001',
    productName: 'Red Rose',
    productType: 'fresh_flower',
    sku: 'FL-ROSE-RED-01',
    barcode: '8901234567001',
    internalBarcode: 'INT-001',
    brand: 'Holland Direct',
    description: 'Premium long-stemmed red roses, ideal for romantic arrangements',
    unitOfMeasure: 'stem',
    retailPrice: 120,
    costPrice: 60,
    wholesalePrice: 90,
    weddingEventPrice: 100,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: true,
    currentStock: 250,
    reorderLevel: 100,
    isPerishable: true,
    shelfLifeDays: 7,
    expiryAlertDays: 3,
    temperatureNotes: 'Store at 2-4°C',
    color: 'Red',
    variety: 'Freedom',
    grade: 'premium',
    countryOfOrigin: 'ECU',
    seasonality: ['year_round', 'valentines'],
    supplierId: 'sup_001',
    supplierName: 'Holland Direct',
    leadTimeDays: 3,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: true,
    tags: ['bestseller', 'romantic', 'premium'],
    imageUrl: '/images/products/red-rose.jpg',
    createdAt: '2024-01-15T10:00:00Z',
    updatedAt: '2026-03-01T14:30:00Z',
  },
  {
    id: 'prod_002',
    productName: 'White Lily',
    productType: 'fresh_flower',
    sku: 'FL-LILY-WHT-01',
    barcode: '8901234567002',
    internalBarcode: 'INT-002',
    description: 'Elegant white oriental lilies with intense fragrance',
    unitOfMeasure: 'stem',
    retailPrice: 180,
    costPrice: 90,
    wholesalePrice: 140,
    weddingEventPrice: 160,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: true,
    currentStock: 85,
    reorderLevel: 50,
    isPerishable: true,
    shelfLifeDays: 10,
    expiryAlertDays: 3,
    temperatureNotes: 'Store at 4-6°C, keep away from fruits',
    color: 'White',
    variety: 'Oriental',
    grade: 'premium',
    countryOfOrigin: 'NLD',
    seasonality: ['year_round', 'wedding_season'],
    supplierId: 'sup_001',
    supplierName: 'Holland Direct',
    leadTimeDays: 3,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: true,
    tags: ['wedding', 'fragrant', 'sympathy'],
    createdAt: '2024-01-15T10:00:00Z',
    updatedAt: '2026-02-28T11:00:00Z',
  },
  {
    id: 'prod_003',
    productName: 'Pink Carnation',
    productType: 'fresh_flower',
    sku: 'FL-CARN-PNK-01',
    barcode: '8901234567003',
    internalBarcode: 'INT-003',
    description: 'Standard pink carnations, long-lasting and versatile',
    unitOfMeasure: 'stem',
    retailPrice: 40,
    costPrice: 18,
    wholesalePrice: 30,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: true,
    currentStock: 320,
    reorderLevel: 150,
    isPerishable: true,
    shelfLifeDays: 14,
    expiryAlertDays: 4,
    temperatureNotes: 'Store at 2-4°C',
    color: 'Pink',
    variety: 'Standard',
    grade: 'standard',
    countryOfOrigin: 'COL',
    seasonality: ['year_round', 'mothers_day'],
    supplierId: 'sup_003',
    supplierName: 'FlowerFresh Imports',
    leadTimeDays: 5,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: false,
    tags: ['budget', 'everyday'],
    createdAt: '2024-02-01T10:00:00Z',
    updatedAt: '2026-03-05T09:00:00Z',
  },
  {
    id: 'prod_004',
    productName: 'Yellow Tulip',
    productType: 'fresh_flower',
    sku: 'FL-TULP-YEL-01',
    barcode: '8901234567004',
    internalBarcode: 'INT-004',
    description: 'Bright yellow Dutch tulips, spring favorite',
    unitOfMeasure: 'stem',
    retailPrice: 65,
    costPrice: 32,
    wholesalePrice: 50,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: true,
    currentStock: 45,
    reorderLevel: 60,
    isPerishable: true,
    shelfLifeDays: 7,
    expiryAlertDays: 2,
    temperatureNotes: 'Store upright at 2°C, continue growing in vase',
    color: 'Yellow',
    variety: 'Dutch',
    grade: 'select',
    countryOfOrigin: 'NLD',
    seasonality: ['spring'],
    supplierId: 'sup_001',
    supplierName: 'Holland Direct',
    leadTimeDays: 3,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: true,
    tags: ['seasonal', 'spring', 'cheerful'],
    createdAt: '2024-01-20T10:00:00Z',
    updatedAt: '2026-03-01T10:00:00Z',
  },
  {
    id: 'prod_005',
    productName: 'White Gerbera',
    productType: 'fresh_flower',
    sku: 'FL-GERB-WHT-01',
    barcode: '8901234567005',
    internalBarcode: 'INT-005',
    description: 'Large white gerbera daisies with sturdy stems',
    unitOfMeasure: 'stem',
    retailPrice: 75,
    costPrice: 35,
    wholesalePrice: 58,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: true,
    currentStock: 120,
    reorderLevel: 80,
    isPerishable: true,
    shelfLifeDays: 10,
    expiryAlertDays: 3,
    temperatureNotes: 'Store at 4-6°C, support stem if drooping',
    color: 'White',
    variety: 'Mini',
    grade: 'premium',
    countryOfOrigin: 'KEN',
    seasonality: ['year_round'],
    supplierId: 'sup_005',
    supplierName: 'Pacific Blooms',
    leadTimeDays: 7,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: true,
    tags: ['modern', 'clean', 'wedding'],
    createdAt: '2024-03-01T10:00:00Z',
    updatedAt: '2026-03-02T15:00:00Z',
  },
  // Greens & Foliage
  {
    id: 'prod_006',
    productName: 'Eucalyptus Silver Dollar',
    productType: 'fresh_flower',
    sku: 'GR-EUCA-SIL-01',
    barcode: '8901234567006',
    internalBarcode: 'INT-006',
    description: 'Popular silver dollar eucalyptus for arrangements and bouquets',
    unitOfMeasure: 'bunch',
    retailPrice: 280,
    costPrice: 140,
    wholesalePrice: 220,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: true,
    currentStock: 35,
    reorderLevel: 25,
    isPerishable: true,
    shelfLifeDays: 14,
    expiryAlertDays: 4,
    temperatureNotes: 'Store at 4-8°C, can be dried',
    color: 'Green/Silver',
    variety: 'Silver Dollar',
    grade: 'premium',
    countryOfOrigin: 'USA',
    seasonality: ['year_round'],
    supplierId: 'sup_002',
    supplierName: 'Local Growers Co-op',
    leadTimeDays: 1,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: false,
    tags: ['foliage', 'wedding', 'fragrant'],
    createdAt: '2024-02-15T10:00:00Z',
    updatedAt: '2026-03-03T12:00:00Z',
  },
  // Plants
  {
    id: 'prod_007',
    productName: 'White Orchid Phalaenopsis',
    productType: 'plant',
    sku: 'PL-ORCH-WHT-01',
    barcode: '8901234567007',
    internalBarcode: 'INT-007',
    description: 'Elegant white phalaenopsis orchid in ceramic pot',
    unitOfMeasure: 'each',
    retailPrice: 2500,
    costPrice: 1200,
    wholesalePrice: 2000,
    weddingEventPrice: 2200,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 18,
    reorderLevel: 10,
    isPerishable: false,
    supplierId: 'sup_004',
    supplierName: 'GreenLeaf Distributors',
    leadTimeDays: 2,
    incomeAccount: '4020',
    expenseAccount: '5020',
    status: 'active',
    allowAsRawMaterial: false,
    availableOnline: true,
    commissionEligible: true,
    tags: ['premium', 'gift', 'long-lasting'],
    createdAt: '2024-01-10T10:00:00Z',
    updatedAt: '2026-03-01T10:00:00Z',
  },
  {
    id: 'prod_008',
    productName: 'Money Plant Golden',
    productType: 'plant',
    sku: 'PL-MONY-GLD-01',
    barcode: '8901234567008',
    internalBarcode: 'INT-008',
    description: 'Golden pothos money plant in decorative pot',
    unitOfMeasure: 'each',
    retailPrice: 450,
    costPrice: 180,
    wholesalePrice: 350,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 42,
    reorderLevel: 20,
    isPerishable: false,
    supplierId: 'sup_002',
    supplierName: 'Local Growers Co-op',
    leadTimeDays: 1,
    incomeAccount: '4020',
    expenseAccount: '5020',
    status: 'active',
    allowAsRawMaterial: false,
    availableOnline: true,
    commissionEligible: false,
    tags: ['indoor', 'easy-care', 'budget'],
    createdAt: '2024-04-01T10:00:00Z',
    updatedAt: '2026-03-04T08:00:00Z',
  },
  // Arrangements
  {
    id: 'prod_009',
    productName: 'Classic Rose Bouquet - 12 stems',
    productType: 'bouquet',
    sku: 'BQ-ROSE-CLX-12',
    barcode: '8901234567009',
    internalBarcode: 'INT-009',
    description: 'Classic arrangement of 12 premium roses with filler greens',
    unitOfMeasure: 'each',
    retailPrice: 1800,
    costPrice: 850,
    wholesalePrice: 1500,
    weddingEventPrice: 1650,
    taxCategory: 'standard',
    trackInventory: false,
    trackBatch: false,
    currentStock: 0,
    isPerishable: true,
    shelfLifeDays: 5,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: false,
    availableOnline: true,
    commissionEligible: true,
    tags: ['bestseller', 'romantic', 'classic'],
    createdAt: '2024-01-01T10:00:00Z',
    updatedAt: '2026-03-05T10:00:00Z',
  },
  {
    id: 'prod_010',
    productName: 'Mixed Seasonal Basket',
    productType: 'arrangement',
    sku: 'AR-MIX-SEA-01',
    barcode: '8901234567010',
    internalBarcode: 'INT-010',
    description: 'Beautiful mixed arrangement in decorative basket',
    unitOfMeasure: 'each',
    retailPrice: 2200,
    costPrice: 1000,
    wholesalePrice: 1800,
    taxCategory: 'standard',
    trackInventory: false,
    trackBatch: false,
    currentStock: 0,
    isPerishable: true,
    shelfLifeDays: 5,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: false,
    availableOnline: true,
    commissionEligible: true,
    tags: ['gift', 'birthday', 'get-well'],
    createdAt: '2024-02-10T10:00:00Z',
    updatedAt: '2026-03-01T10:00:00Z',
  },
  // Containers & Vases
  {
    id: 'prod_011',
    productName: 'Glass Cylinder Vase - Large',
    productType: 'container',
    sku: 'VS-CYL-CLR-L',
    barcode: '8901234567011',
    internalBarcode: 'INT-011',
    description: 'Clear glass cylinder vase, 30cm height',
    unitOfMeasure: 'each',
    retailPrice: 650,
    costPrice: 280,
    wholesalePrice: 520,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 28,
    reorderLevel: 15,
    isPerishable: false,
    supplierId: 'sup_006',
    supplierName: 'Petal Perfect Supplies',
    leadTimeDays: 2,
    incomeAccount: '4030',
    expenseAccount: '5030',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: false,
    tags: ['vase', 'modern', 'versatile'],
    createdAt: '2024-03-15T10:00:00Z',
    updatedAt: '2026-02-28T10:00:00Z',
  },
  {
    id: 'prod_012',
    productName: 'Ceramic Pot - White Matte',
    productType: 'container',
    sku: 'PT-CER-WHT-M',
    barcode: '8901234567012',
    internalBarcode: 'INT-012',
    description: 'Medium white matte ceramic pot for plants',
    unitOfMeasure: 'each',
    retailPrice: 480,
    costPrice: 200,
    wholesalePrice: 380,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 35,
    reorderLevel: 20,
    isPerishable: false,
    supplierId: 'sup_006',
    supplierName: 'Petal Perfect Supplies',
    leadTimeDays: 2,
    incomeAccount: '4030',
    expenseAccount: '5030',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: false,
    tags: ['planter', 'modern', 'minimalist'],
    createdAt: '2024-03-20T10:00:00Z',
    updatedAt: '2026-03-02T10:00:00Z',
  },
  // Supplies & Ribbons
  {
    id: 'prod_013',
    productName: 'Satin Ribbon - Red 25mm',
    productType: 'ribbon',
    sku: 'RB-SAT-RED-25',
    barcode: '8901234567013',
    internalBarcode: 'INT-013',
    description: 'Premium satin ribbon, 25mm width, 25m roll',
    unitOfMeasure: 'roll',
    retailPrice: 220,
    costPrice: 95,
    wholesalePrice: 180,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 48,
    reorderLevel: 25,
    isPerishable: false,
    supplierId: 'sup_006',
    supplierName: 'Petal Perfect Supplies',
    leadTimeDays: 2,
    incomeAccount: '4030',
    expenseAccount: '5030',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: false,
    commissionEligible: false,
    tags: ['ribbon', 'supply', 'wrapping'],
    createdAt: '2024-01-05T10:00:00Z',
    updatedAt: '2026-03-01T10:00:00Z',
  },
  {
    id: 'prod_014',
    productName: 'Floral Foam Block - Fresh',
    productType: 'supply',
    sku: 'SP-FOAM-FRH-01',
    barcode: '8901234567014',
    internalBarcode: 'INT-014',
    description: 'Standard floral foam brick for fresh arrangements',
    unitOfMeasure: 'each',
    retailPrice: 45,
    costPrice: 18,
    wholesalePrice: 35,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 185,
    reorderLevel: 100,
    isPerishable: false,
    supplierId: 'sup_006',
    supplierName: 'Petal Perfect Supplies',
    leadTimeDays: 2,
    incomeAccount: '4030',
    expenseAccount: '5030',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: false,
    commissionEligible: false,
    tags: ['supply', 'essential'],
    createdAt: '2024-01-02T10:00:00Z',
    updatedAt: '2026-03-04T10:00:00Z',
  },
  // Gift Items
  {
    id: 'prod_015',
    productName: 'Belgian Chocolate Box - Premium',
    productType: 'gift_item',
    sku: 'GF-CHOC-BLG-01',
    barcode: '8901234567015',
    internalBarcode: 'INT-015',
    description: 'Premium Belgian chocolate assortment, 200g box',
    unitOfMeasure: 'each',
    retailPrice: 850,
    costPrice: 420,
    wholesalePrice: 680,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: true,
    currentStock: 25,
    reorderLevel: 15,
    isPerishable: true,
    shelfLifeDays: 180,
    expiryAlertDays: 30,
    temperatureNotes: 'Store in cool, dry place below 22°C',
    supplierId: 'sup_003',
    supplierName: 'FlowerFresh Imports',
    leadTimeDays: 5,
    incomeAccount: '4030',
    expenseAccount: '5030',
    status: 'active',
    allowAsRawMaterial: false,
    availableOnline: true,
    commissionEligible: true,
    tags: ['gift', 'premium', 'add-on'],
    createdAt: '2024-02-20T10:00:00Z',
    updatedAt: '2026-03-01T10:00:00Z',
  },
  // Service
  {
    id: 'prod_016',
    productName: 'Same-Day Delivery',
    productType: 'service',
    sku: 'SV-DEL-SAME-01',
    barcode: '8901234567016',
    internalBarcode: 'INT-016',
    description: 'Same-day delivery service within city limits',
    unitOfMeasure: 'each',
    retailPrice: 150,
    costPrice: 80,
    taxCategory: 'standard',
    trackInventory: false,
    trackBatch: false,
    currentStock: 0,
    isPerishable: false,
    incomeAccount: '4040',
    expenseAccount: '5040',
    status: 'active',
    allowAsRawMaterial: false,
    availableOnline: true,
    commissionEligible: false,
    tags: ['service', 'delivery'],
    createdAt: '2024-01-01T10:00:00Z',
    updatedAt: '2026-01-15T10:00:00Z',
  },
  // Dried Flowers
  {
    id: 'prod_017',
    productName: 'Dried Lavender Bundle',
    productType: 'dried_flower',
    sku: 'DF-LAV-PRP-01',
    barcode: '8901234567017',
    internalBarcode: 'INT-017',
    description: 'Natural dried lavender bundle, fragrant',
    unitOfMeasure: 'bunch',
    retailPrice: 350,
    costPrice: 150,
    wholesalePrice: 280,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 42,
    reorderLevel: 25,
    isPerishable: false,
    color: 'Purple',
    supplierId: 'sup_002',
    supplierName: 'Local Growers Co-op',
    leadTimeDays: 1,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: false,
    tags: ['dried', 'fragrant', 'long-lasting'],
    createdAt: '2024-05-01T10:00:00Z',
    updatedAt: '2026-03-02T10:00:00Z',
  },
  {
    id: 'prod_018',
    productName: 'Pampas Grass - Natural',
    productType: 'dried_flower',
    sku: 'DF-PAMP-NAT-01',
    barcode: '8901234567018',
    internalBarcode: 'INT-018',
    description: 'Natural pampas grass plumes, trending decor item',
    unitOfMeasure: 'stem',
    retailPrice: 280,
    costPrice: 120,
    wholesalePrice: 220,
    taxCategory: 'standard',
    trackInventory: true,
    trackBatch: false,
    currentStock: 65,
    reorderLevel: 30,
    isPerishable: false,
    color: 'Natural/Cream',
    supplierId: 'sup_004',
    supplierName: 'GreenLeaf Distributors',
    leadTimeDays: 2,
    incomeAccount: '4010',
    expenseAccount: '5010',
    status: 'active',
    allowAsRawMaterial: true,
    availableOnline: true,
    commissionEligible: true,
    tags: ['trending', 'boho', 'decor'],
    createdAt: '2024-06-01T10:00:00Z',
    updatedAt: '2026-03-03T10:00:00Z',
  },
];

// ─── Product Summary Stats ──────────────────────────────────

export interface ProductSummary {
  totalProducts: number;
  activeProducts: number;
  inactiveProducts: number;
  totalStockValue: number;
  lowStockCount: number;
  outOfStockCount: number;
  byType: Record<ProductType, number>;
}

export const calculateProductSummary = (products: Product[]): ProductSummary => {
  const summary: ProductSummary = {
    totalProducts: products.length,
    activeProducts: products.filter(p => p.status === 'active').length,
    inactiveProducts: products.filter(p => p.status === 'inactive').length,
    totalStockValue: products.reduce((sum, p) => sum + (p.currentStock * p.costPrice), 0),
    lowStockCount: products.filter(p => p.trackInventory && p.reorderLevel && p.currentStock <= p.reorderLevel).length,
    outOfStockCount: products.filter(p => p.trackInventory && p.currentStock === 0).length,
    byType: {} as Record<ProductType, number>,
  };

  products.forEach(p => {
    summary.byType[p.productType] = (summary.byType[p.productType] || 0) + 1;
  });

  return summary;
};

export const MOCK_PRODUCT_SUMMARY = calculateProductSummary(MOCK_PRODUCTS);

// ─── Mock API Functions ─────────────────────────────────────

export const fetchProducts = (filters?: {
  search?: string;
  productType?: ProductType;
  status?: 'active' | 'inactive';
  lowStock?: boolean;
  perishableOnly?: boolean;
}): Promise<Product[]> =>
  new Promise(resolve => setTimeout(() => {
    let results = [...MOCK_PRODUCTS];
    if (filters?.search) {
      const searchLower = filters.search.toLowerCase();
      results = results.filter(p => 
        p.productName.toLowerCase().includes(searchLower) ||
        p.sku.toLowerCase().includes(searchLower) ||
        p.barcode?.includes(filters.search!) ||
        p.tags?.some(t => t.toLowerCase().includes(searchLower))
      );
    }
    if (filters?.productType) results = results.filter(p => p.productType === filters.productType);
    if (filters?.status) results = results.filter(p => p.status === filters.status);
    if (filters?.lowStock) results = results.filter(p => p.trackInventory && p.reorderLevel && p.currentStock <= p.reorderLevel);
    if (filters?.perishableOnly) results = results.filter(p => p.isPerishable);
    resolve(results);
  }, 500));

export const fetchProductById = (productId: string): Promise<Product | null> =>
  new Promise(resolve => setTimeout(() => {
    resolve(MOCK_PRODUCTS.find(p => p.id === productId) || null);
  }, 300));

export const fetchProductBySku = (sku: string): Promise<Product | null> =>
  new Promise(resolve => setTimeout(() => {
    resolve(MOCK_PRODUCTS.find(p => p.sku === sku) || null);
  }, 300));

export const fetchProductByBarcode = (barcode: string): Promise<Product | null> =>
  new Promise(resolve => setTimeout(() => {
    resolve(MOCK_PRODUCTS.find(p => p.barcode === barcode || p.internalBarcode === barcode) || null);
  }, 300));

export const fetchSuppliers = (): Promise<Supplier[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_SUPPLIERS]), 300));

export const fetchProductSummary = (): Promise<ProductSummary> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_PRODUCT_SUMMARY), 300));
