/**
 * Reorder Intelligence — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 *
 * Predicts reorder needs based on average daily usage, current stock,
 * lead times, and safety stock calculations.
 */

// ─── Types ──────────────────────────────────────────────────

export type StockRisk = 'stockout' | 'low' | 'optimal' | 'overstock';

export type ProductCategory =
  | 'Fresh Flowers'
  | 'Greens & Foliage'
  | 'Dried Flowers'
  | 'Supplies'
  | 'Vases & Containers'
  | 'Gift Items';

export interface ReorderProduct {
  id: string;
  productName: string;
  category: ProductCategory;
  currentStock: number;
  avgDailyUsage: number;        // units/day (rolling 30-day avg)
  daysOfStockLeft: number;      // currentStock / avgDailyUsage
  reorderLevel: number;         // safety stock threshold
  suggestedOrderQty: number;    // computed from usage + lead time + safety
  supplier: string;
  leadTimeDays: number;         // supplier lead time in days
  lastOrderDate: string;        // ISO date
  costPerUnit: number;
  estimatedOrderCost: number;   // suggestedOrderQty × costPerUnit
  risk: StockRisk;
  isPerishable: boolean;
  location: string;
}

export interface ReorderFilterState {
  search: string;
  risk: StockRisk | '';
  supplier: string;
  category: ProductCategory | '';
  sortField: 'daysOfStockLeft' | 'productName' | 'suggestedOrderQty' | 'estimatedOrderCost';
  sortDir: 'asc' | 'desc';
}

export interface ReorderSummary {
  stockoutRiskCount: number;
  lowStockCount: number;
  optimalCount: number;
  overstockCount: number;
  totalSuggestedCost: number;
  totalProducts: number;
}

// ─── Constants ──────────────────────────────────────────────

export const SUPPLIERS = [
  'Holland Direct',
  'Local Growers Co-op',
  'FlowerFresh Imports',
  'GreenLeaf Distributors',
  'Pacific Blooms',
  'Petal Perfect',
] as const;

export const CATEGORIES: ProductCategory[] = [
  'Fresh Flowers',
  'Greens & Foliage',
  'Dried Flowers',
  'Supplies',
  'Vases & Containers',
  'Gift Items',
];

export const DEFAULT_REORDER_FILTERS: ReorderFilterState = {
  search: '',
  risk: '',
  supplier: '',
  category: '',
  sortField: 'daysOfStockLeft',
  sortDir: 'asc',
};

// ─── Safety stock multiplier: leadTime × avgDailyUsage × factor
const SAFETY_FACTOR = 1.5;
const REORDER_WINDOW_DAYS = 14; // order enough for 14 days + lead time

// ─── Mock Data ──────────────────────────────────────────────

const today = new Date();
const past = (daysAgo: number): string => {
  const d = new Date(today);
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString().slice(0, 10);
};

interface RawProduct {
  id: string;
  productName: string;
  category: ProductCategory;
  currentStock: number;
  avgDailyUsage: number;
  reorderLevel: number;
  supplier: string;
  leadTimeDays: number;
  lastOrderDate: string;
  costPerUnit: number;
  isPerishable: boolean;
  location: string;
}

const rawProducts: RawProduct[] = [
  { id: 'rp_001', productName: 'Red Roses (Premium)',       category: 'Fresh Flowers',      currentStock: 45,  avgDailyUsage: 28, reorderLevel: 80,  supplier: 'Holland Direct',       leadTimeDays: 2, lastOrderDate: past(5),  costPerUnit: 2.80, isPerishable: true,  location: 'Walk-in Cooler A' },
  { id: 'rp_002', productName: 'White Lilies',              category: 'Fresh Flowers',      currentStock: 85,  avgDailyUsage: 12, reorderLevel: 40,  supplier: 'FlowerFresh Imports',  leadTimeDays: 3, lastOrderDate: past(3),  costPerUnit: 3.50, isPerishable: true,  location: 'Walk-in Cooler A' },
  { id: 'rp_003', productName: 'Sunflowers',                category: 'Fresh Flowers',      currentStock: 8,   avgDailyUsage: 10, reorderLevel: 30,  supplier: 'Local Growers Co-op',  leadTimeDays: 1, lastOrderDate: past(6),  costPerUnit: 1.90, isPerishable: true,  location: 'Display Cooler' },
  { id: 'rp_004', productName: "Baby's Breath",             category: 'Fresh Flowers',      currentStock: 210, avgDailyUsage: 22, reorderLevel: 70,  supplier: 'Holland Direct',       leadTimeDays: 2, lastOrderDate: past(2),  costPerUnit: 0.60, isPerishable: true,  location: 'Walk-in Cooler B' },
  { id: 'rp_005', productName: 'Pink Carnations',           category: 'Fresh Flowers',      currentStock: 18,  avgDailyUsage: 14, reorderLevel: 45,  supplier: 'Pacific Blooms',       leadTimeDays: 2, lastOrderDate: past(7),  costPerUnit: 1.20, isPerishable: true,  location: 'Walk-in Cooler A' },
  { id: 'rp_006', productName: 'Orchids (Phalaenopsis)',    category: 'Fresh Flowers',      currentStock: 5,   avgDailyUsage: 3,  reorderLevel: 10,  supplier: 'FlowerFresh Imports',  leadTimeDays: 4, lastOrderDate: past(10), costPerUnit: 8.50, isPerishable: true,  location: 'Display Cooler' },
  { id: 'rp_007', productName: 'Eucalyptus Bunches',        category: 'Greens & Foliage',   currentStock: 65,  avgDailyUsage: 8,  reorderLevel: 25,  supplier: 'GreenLeaf Distributors', leadTimeDays: 2, lastOrderDate: past(4), costPerUnit: 2.10, isPerishable: true, location: 'Walk-in Cooler B' },
  { id: 'rp_008', productName: 'Tulips (Mixed)',            category: 'Fresh Flowers',      currentStock: 0,   avgDailyUsage: 15, reorderLevel: 50,  supplier: 'Holland Direct',       leadTimeDays: 2, lastOrderDate: past(12), costPerUnit: 2.40, isPerishable: true,  location: 'Walk-in Cooler A' },
  { id: 'rp_009', productName: 'Floral Foam Blocks',        category: 'Supplies',           currentStock: 320, avgDailyUsage: 18, reorderLevel: 60,  supplier: 'Petal Perfect',        leadTimeDays: 5, lastOrderDate: past(30), costPerUnit: 0.45, isPerishable: false, location: 'Dry Storage' },
  { id: 'rp_010', productName: 'Glass Cylinder Vases',      category: 'Vases & Containers', currentStock: 45,  avgDailyUsage: 2,  reorderLevel: 10,  supplier: 'Petal Perfect',        leadTimeDays: 7, lastOrderDate: past(20), costPerUnit: 4.50, isPerishable: false, location: 'Dry Storage' },
  { id: 'rp_011', productName: 'Ribbon Rolls (Satin)',      category: 'Supplies',           currentStock: 12,  avgDailyUsage: 5,  reorderLevel: 20,  supplier: 'Petal Perfect',        leadTimeDays: 5, lastOrderDate: past(15), costPerUnit: 1.10, isPerishable: false, location: 'Workshop' },
  { id: 'rp_012', productName: 'Dried Lavender Bunches',    category: 'Dried Flowers',      currentStock: 55,  avgDailyUsage: 1,  reorderLevel: 15,  supplier: 'Local Growers Co-op',  leadTimeDays: 3, lastOrderDate: past(40), costPerUnit: 3.20, isPerishable: false, location: 'Dry Storage' },
  { id: 'rp_013', productName: 'Hydrangeas (Blue)',         category: 'Fresh Flowers',      currentStock: 38,  avgDailyUsage: 6,  reorderLevel: 20,  supplier: 'Pacific Blooms',       leadTimeDays: 3, lastOrderDate: past(3),  costPerUnit: 4.20, isPerishable: true,  location: 'Walk-in Cooler B' },
  { id: 'rp_014', productName: 'Peonies',                   category: 'Fresh Flowers',      currentStock: 22,  avgDailyUsage: 8,  reorderLevel: 25,  supplier: 'Holland Direct',       leadTimeDays: 2, lastOrderDate: past(4),  costPerUnit: 5.50, isPerishable: true,  location: 'Walk-in Cooler A' },
  { id: 'rp_015', productName: 'Ruscus (Italian)',          category: 'Greens & Foliage',   currentStock: 130, avgDailyUsage: 10, reorderLevel: 35,  supplier: 'GreenLeaf Distributors', leadTimeDays: 2, lastOrderDate: past(2), costPerUnit: 1.40, isPerishable: true, location: 'Walk-in Cooler B' },
  { id: 'rp_016', productName: 'Gift Wrapping Paper',       category: 'Gift Items',         currentStock: 350, avgDailyUsage: 8,  reorderLevel: 50,  supplier: 'Petal Perfect',        leadTimeDays: 5, lastOrderDate: past(25), costPerUnit: 0.30, isPerishable: false, location: 'Workshop' },
  { id: 'rp_017', productName: 'Spray Roses (Peach)',       category: 'Fresh Flowers',      currentStock: 120, avgDailyUsage: 16, reorderLevel: 50,  supplier: 'Pacific Blooms',       leadTimeDays: 2, lastOrderDate: past(1),  costPerUnit: 2.20, isPerishable: true,  location: 'Walk-in Cooler A' },
  { id: 'rp_018', productName: 'Ceramic Bud Vases',         category: 'Vases & Containers', currentStock: 36,  avgDailyUsage: 1,  reorderLevel: 8,   supplier: 'Petal Perfect',        leadTimeDays: 7, lastOrderDate: past(18), costPerUnit: 3.40, isPerishable: false, location: 'Front Display' },
  { id: 'rp_019', productName: 'Floral Wire (Gauge 22)',    category: 'Supplies',           currentStock: 80,  avgDailyUsage: 12, reorderLevel: 40,  supplier: 'Petal Perfect',        leadTimeDays: 5, lastOrderDate: past(22), costPerUnit: 0.25, isPerishable: false, location: 'Workshop' },
  { id: 'rp_020', productName: 'Preserved Rose Boxes',      category: 'Gift Items',         currentStock: 6,   avgDailyUsage: 2,  reorderLevel: 8,   supplier: 'Petal Perfect',        leadTimeDays: 7, lastOrderDate: past(14), costPerUnit: 12.00, isPerishable: false, location: 'Front Display' },
];

/**
 * Compute derived fields for each product:
 *  - daysOfStockLeft
 *  - suggestedOrderQty (covers lead time + reorder window + safety)
 *  - risk classification
 */
const buildReorderProducts = (): ReorderProduct[] =>
  rawProducts.map((p): ReorderProduct => {
    const daysLeft =
      p.avgDailyUsage > 0
        ? Math.round((p.currentStock / p.avgDailyUsage) * 10) / 10
        : p.currentStock > 0
          ? 999
          : 0;

    // Suggested qty: enough for (reorder window + lead time) minus current stock, with safety buffer
    const coverageDays = REORDER_WINDOW_DAYS + p.leadTimeDays;
    const targetStock = Math.ceil(p.avgDailyUsage * coverageDays * SAFETY_FACTOR);
    const suggestedRaw = targetStock - p.currentStock;
    const suggestedOrderQty = Math.max(0, Math.ceil(suggestedRaw / 10) * 10); // round up to nearest 10

    // Risk classification
    let risk: StockRisk;
    if (p.currentStock === 0 || daysLeft <= p.leadTimeDays) {
      risk = 'stockout';
    } else if (daysLeft <= p.leadTimeDays + 3 || p.currentStock < p.reorderLevel) {
      risk = 'low';
    } else if (daysLeft > 30 && p.currentStock > p.reorderLevel * 3) {
      risk = 'overstock';
    } else {
      risk = 'optimal';
    }

    return {
      ...p,
      daysOfStockLeft: daysLeft,
      suggestedOrderQty,
      estimatedOrderCost: Math.round(suggestedOrderQty * p.costPerUnit * 100) / 100,
      risk,
    };
  });

export const MOCK_REORDER_PRODUCTS: ReorderProduct[] = buildReorderProducts();

// ─── Mock API ───────────────────────────────────────────────

export const fetchReorderData = (): Promise<ReorderProduct[]> =>
  new Promise((resolve) =>
    setTimeout(() => resolve([...MOCK_REORDER_PRODUCTS]), 550),
  );
