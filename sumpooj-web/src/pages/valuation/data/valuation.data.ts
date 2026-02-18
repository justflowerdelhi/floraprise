/**
 * Inventory Valuation Report — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 *
 * FIFO-based inventory valuation across all product categories.
 * Re-uses inventory batch data and aggregates per-product valuations.
 */

// ─── Types ──────────────────────────────────────────────────

export type ProductCategory =
  | 'Fresh Flowers'
  | 'Greens & Foliage'
  | 'Dried Flowers'
  | 'Supplies'
  | 'Vases & Containers'
  | 'Gift Items';

export interface FifoBatchLayer {
  batchNumber: string;
  purchaseDate: string;
  quantity: number;
  costPerUnit: number;
  totalCost: number;
}

export interface ValuationProduct {
  id: string;
  productName: string;
  category: ProductCategory;
  location: string;
  isPerishable: boolean;
  totalQuantity: number;
  averageCost: number;          // weighted average across FIFO layers
  totalValue: number;           // sum of all layers
  sellingPricePerUnit: number;
  marginPercent: number;
  pctOfTotalInventory: number;  // computed after aggregation
  fifoLayers: FifoBatchLayer[]; // individual batch layers (FIFO order)
  lastPurchaseDate: string;
}

export interface ValuationFilterState {
  search: string;
  category: ProductCategory | '';
  location: string;
  asOfDate: string;             // valuation as-of date
  perishableOnly: boolean;
  sortField: 'productName' | 'totalValue' | 'totalQuantity' | 'marginPercent';
  sortDir: 'asc' | 'desc';
}

export interface ValuationSummary {
  totalInventoryValue: number;
  freshFlowersValue: number;
  hardGoodsValue: number;       // everything non-perishable
  totalBatches: number;
  averageMarginPct: number;
  totalProducts: number;
  totalQuantity: number;
}

// ─── Constants ──────────────────────────────────────────────

export const CATEGORIES: ProductCategory[] = [
  'Fresh Flowers',
  'Greens & Foliage',
  'Dried Flowers',
  'Supplies',
  'Vases & Containers',
  'Gift Items',
];

export const LOCATIONS = [
  'Walk-in Cooler A',
  'Walk-in Cooler B',
  'Display Cooler',
  'Dry Storage',
  'Workshop',
  'Front Display',
] as const;

export const DEFAULT_VALUATION_FILTERS: ValuationFilterState = {
  search: '',
  category: '',
  location: '',
  asOfDate: '',
  perishableOnly: false,
  sortField: 'totalValue',
  sortDir: 'desc',
};

// ─── Mock Valuation Data (FIFO layers) ──────────────────────

const today = new Date();
const past = (daysAgo: number): string => {
  const d = new Date(today);
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString().slice(0, 10);
};

/**
 * Build realistic FIFO valuation data:
 *  - Each product may have 1–3 batch layers at different costs (FIFO principle)
 *  - Older layers have lower cost, newer layers may be higher due to price increases
 */
const buildMockProducts = (): ValuationProduct[] => {
  const raw: Omit<ValuationProduct, 'averageCost' | 'totalValue' | 'pctOfTotalInventory' | 'marginPercent'>[] = [
    {
      id: 'vp_001',
      productName: 'Red Roses (Premium)',
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler A',
      isPerishable: true,
      totalQuantity: 145,
      sellingPricePerUnit: 5.50,
      lastPurchaseDate: past(5),
      fifoLayers: [
        { batchNumber: 'BT-2026-0201', purchaseDate: past(12), quantity: 45, costPerUnit: 2.60, totalCost: 117 },
        { batchNumber: 'BT-2026-0245', purchaseDate: past(5), quantity: 100, costPerUnit: 2.80, totalCost: 280 },
      ],
    },
    {
      id: 'vp_002',
      productName: 'White Lilies',
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler A',
      isPerishable: true,
      totalQuantity: 110,
      sellingPricePerUnit: 7.00,
      lastPurchaseDate: past(3),
      fifoLayers: [
        { batchNumber: 'BT-2026-0202', purchaseDate: past(3), quantity: 110, costPerUnit: 3.50, totalCost: 385 },
      ],
    },
    {
      id: 'vp_003',
      productName: 'Sunflowers',
      category: 'Fresh Flowers',
      location: 'Display Cooler',
      isPerishable: true,
      totalQuantity: 25,
      sellingPricePerUnit: 4.50,
      lastPurchaseDate: past(6),
      fifoLayers: [
        { batchNumber: 'BT-2026-0203', purchaseDate: past(6), quantity: 25, costPerUnit: 1.90, totalCost: 47.50 },
      ],
    },
    {
      id: 'vp_004',
      productName: "Baby's Breath",
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler B',
      isPerishable: true,
      totalQuantity: 290,
      sellingPricePerUnit: 1.80,
      lastPurchaseDate: past(2),
      fifoLayers: [
        { batchNumber: 'BT-2026-0204', purchaseDate: past(8), quantity: 140, costPerUnit: 0.55, totalCost: 77 },
        { batchNumber: 'BT-2026-0251', purchaseDate: past(2), quantity: 150, costPerUnit: 0.60, totalCost: 90 },
      ],
    },
    {
      id: 'vp_005',
      productName: 'Pink Carnations',
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler A',
      isPerishable: true,
      totalQuantity: 60,
      sellingPricePerUnit: 3.00,
      lastPurchaseDate: past(7),
      fifoLayers: [
        { batchNumber: 'BT-2026-0205', purchaseDate: past(7), quantity: 60, costPerUnit: 1.20, totalCost: 72 },
      ],
    },
    {
      id: 'vp_006',
      productName: 'Orchids (Phalaenopsis)',
      category: 'Fresh Flowers',
      location: 'Display Cooler',
      isPerishable: true,
      totalQuantity: 12,
      sellingPricePerUnit: 18.00,
      lastPurchaseDate: past(10),
      fifoLayers: [
        { batchNumber: 'BT-2026-0206', purchaseDate: past(10), quantity: 12, costPerUnit: 8.50, totalCost: 102 },
      ],
    },
    {
      id: 'vp_007',
      productName: 'Eucalyptus Bunches',
      category: 'Greens & Foliage',
      location: 'Walk-in Cooler B',
      isPerishable: true,
      totalQuantity: 85,
      sellingPricePerUnit: 5.00,
      lastPurchaseDate: past(4),
      fifoLayers: [
        { batchNumber: 'BT-2026-0207', purchaseDate: past(10), quantity: 35, costPerUnit: 1.95, totalCost: 68.25 },
        { batchNumber: 'BT-2026-0260', purchaseDate: past(4), quantity: 50, costPerUnit: 2.10, totalCost: 105 },
      ],
    },
    {
      id: 'vp_008',
      productName: 'Tulips (Mixed)',
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler A',
      isPerishable: true,
      totalQuantity: 40,
      sellingPricePerUnit: 5.00,
      lastPurchaseDate: past(12),
      fifoLayers: [
        { batchNumber: 'BT-2026-0208', purchaseDate: past(12), quantity: 40, costPerUnit: 2.40, totalCost: 96 },
      ],
    },
    {
      id: 'vp_009',
      productName: 'Floral Foam Blocks',
      category: 'Supplies',
      location: 'Dry Storage',
      isPerishable: false,
      totalQuantity: 320,
      sellingPricePerUnit: 1.20,
      lastPurchaseDate: past(30),
      fifoLayers: [
        { batchNumber: 'BT-2026-0209', purchaseDate: past(60), quantity: 120, costPerUnit: 0.40, totalCost: 48 },
        { batchNumber: 'BT-2026-0270', purchaseDate: past(30), quantity: 200, costPerUnit: 0.45, totalCost: 90 },
      ],
    },
    {
      id: 'vp_010',
      productName: 'Glass Cylinder Vases',
      category: 'Vases & Containers',
      location: 'Dry Storage',
      isPerishable: false,
      totalQuantity: 45,
      sellingPricePerUnit: 12.00,
      lastPurchaseDate: past(20),
      fifoLayers: [
        { batchNumber: 'BT-2026-0210', purchaseDate: past(45), quantity: 20, costPerUnit: 4.20, totalCost: 84 },
        { batchNumber: 'BT-2026-0275', purchaseDate: past(20), quantity: 25, costPerUnit: 4.50, totalCost: 112.50 },
      ],
    },
    {
      id: 'vp_011',
      productName: 'Ribbon Rolls (Satin)',
      category: 'Supplies',
      location: 'Workshop',
      isPerishable: false,
      totalQuantity: 30,
      sellingPricePerUnit: 3.50,
      lastPurchaseDate: past(15),
      fifoLayers: [
        { batchNumber: 'BT-2026-0211', purchaseDate: past(15), quantity: 30, costPerUnit: 1.10, totalCost: 33 },
      ],
    },
    {
      id: 'vp_012',
      productName: 'Dried Lavender Bunches',
      category: 'Dried Flowers',
      location: 'Dry Storage',
      isPerishable: false,
      totalQuantity: 55,
      sellingPricePerUnit: 8.00,
      lastPurchaseDate: past(40),
      fifoLayers: [
        { batchNumber: 'BT-2026-0213', purchaseDate: past(40), quantity: 55, costPerUnit: 3.20, totalCost: 176 },
      ],
    },
    {
      id: 'vp_013',
      productName: 'Hydrangeas (Blue)',
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler B',
      isPerishable: true,
      totalQuantity: 58,
      sellingPricePerUnit: 9.00,
      lastPurchaseDate: past(3),
      fifoLayers: [
        { batchNumber: 'BT-2026-0214', purchaseDate: past(3), quantity: 58, costPerUnit: 4.20, totalCost: 243.60 },
      ],
    },
    {
      id: 'vp_014',
      productName: 'Peonies',
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler A',
      isPerishable: true,
      totalQuantity: 42,
      sellingPricePerUnit: 12.00,
      lastPurchaseDate: past(4),
      fifoLayers: [
        { batchNumber: 'BT-2026-0215', purchaseDate: past(4), quantity: 42, costPerUnit: 5.50, totalCost: 231 },
      ],
    },
    {
      id: 'vp_015',
      productName: 'Ruscus (Italian)',
      category: 'Greens & Foliage',
      location: 'Walk-in Cooler B',
      isPerishable: true,
      totalQuantity: 148,
      sellingPricePerUnit: 3.50,
      lastPurchaseDate: past(2),
      fifoLayers: [
        { batchNumber: 'BT-2026-0216', purchaseDate: past(2), quantity: 148, costPerUnit: 1.40, totalCost: 207.20 },
      ],
    },
    {
      id: 'vp_016',
      productName: 'Gift Wrapping Paper',
      category: 'Gift Items',
      location: 'Workshop',
      isPerishable: false,
      totalQuantity: 60,
      sellingPricePerUnit: 1.00,
      lastPurchaseDate: past(25),
      fifoLayers: [
        { batchNumber: 'BT-2026-0217', purchaseDate: past(50), quantity: 25, costPerUnit: 0.25, totalCost: 6.25 },
        { batchNumber: 'BT-2026-0280', purchaseDate: past(25), quantity: 35, costPerUnit: 0.30, totalCost: 10.50 },
      ],
    },
    {
      id: 'vp_017',
      productName: 'Spray Roses (Peach)',
      category: 'Fresh Flowers',
      location: 'Walk-in Cooler A',
      isPerishable: true,
      totalQuantity: 178,
      sellingPricePerUnit: 5.00,
      lastPurchaseDate: past(1),
      fifoLayers: [
        { batchNumber: 'BT-2026-0218', purchaseDate: past(1), quantity: 178, costPerUnit: 2.20, totalCost: 391.60 },
      ],
    },
    {
      id: 'vp_018',
      productName: 'Ceramic Bud Vases',
      category: 'Vases & Containers',
      location: 'Front Display',
      isPerishable: false,
      totalQuantity: 36,
      sellingPricePerUnit: 8.50,
      lastPurchaseDate: past(18),
      fifoLayers: [
        { batchNumber: 'BT-2026-0285', purchaseDate: past(35), quantity: 16, costPerUnit: 3.00, totalCost: 48 },
        { batchNumber: 'BT-2026-0290', purchaseDate: past(18), quantity: 20, costPerUnit: 3.40, totalCost: 68 },
      ],
    },
    {
      id: 'vp_019',
      productName: 'Floral Wire (Gauge 22)',
      category: 'Supplies',
      location: 'Workshop',
      isPerishable: false,
      totalQuantity: 200,
      sellingPricePerUnit: 0.80,
      lastPurchaseDate: past(22),
      fifoLayers: [
        { batchNumber: 'BT-2026-0295', purchaseDate: past(22), quantity: 200, costPerUnit: 0.25, totalCost: 50 },
      ],
    },
    {
      id: 'vp_020',
      productName: 'Preserved Rose Boxes',
      category: 'Gift Items',
      location: 'Front Display',
      isPerishable: false,
      totalQuantity: 18,
      sellingPricePerUnit: 25.00,
      lastPurchaseDate: past(14),
      fifoLayers: [
        { batchNumber: 'BT-2026-0300', purchaseDate: past(14), quantity: 18, costPerUnit: 12.00, totalCost: 216 },
      ],
    },
  ];

  // Compute derived fields
  const totalValue = raw.reduce(
    (sum, p) => sum + p.fifoLayers.reduce((s, l) => s + l.totalCost, 0),
    0,
  );

  return raw.map((p): ValuationProduct => {
    const value = p.fifoLayers.reduce((s, l) => s + l.totalCost, 0);
    const avgCost = p.totalQuantity > 0 ? value / p.totalQuantity : 0;
    const margin =
      p.sellingPricePerUnit > 0
        ? ((p.sellingPricePerUnit - avgCost) / p.sellingPricePerUnit) * 100
        : 0;

    return {
      ...p,
      totalValue: value,
      averageCost: Math.round(avgCost * 100) / 100,
      marginPercent: Math.round(margin * 10) / 10,
      pctOfTotalInventory:
        totalValue > 0
          ? Math.round((value / totalValue) * 1000) / 10
          : 0,
    };
  });
};

export const MOCK_VALUATION_PRODUCTS: ValuationProduct[] = buildMockProducts();

// ─── Mock API ───────────────────────────────────────────────

export const fetchValuationData = (): Promise<ValuationProduct[]> =>
  new Promise((resolve) =>
    setTimeout(() => resolve([...MOCK_VALUATION_PRODUCTS]), 600),
  );
