/**
 * Inventory Health Dashboard — Types, Constants & Mock Data
 * Florist POS + ERP SaaS Platform
 *
 * Provides executive-level KPIs and chart data for inventory health:
 *  - Aging distribution (fresh, acceptable, aging, expired)
 *  - Wastage trend (30-day daily wastage ₹)
 *  - Expiry trend (items expiring per week)
 *  - Top 10 inventory items by value
 *  - Slow-moving items (low turnover)
 *  - Summary metrics (turnover ratio, shrinkage %, value at risk, gross margin %)
 */

// ─── Types ──────────────────────────────────────────────────

export type AgingBucket = 'Fresh (0-2d)' | 'Acceptable (3-5d)' | 'Aging (6-10d)' | 'Expired (>10d)';

export interface AgingDataPoint {
  bucket: AgingBucket;
  itemCount: number;
  value: number;           // ₹ total value
  percentage: number;      // % of total items
}

export interface WastageTrendPoint {
  date: string;            // 'Jan 20', 'Jan 21', etc.
  isoDate: string;         // '2026-01-20'
  wastageValue: number;    // ₹ lost
  wastageUnits: number;    // units lost
  category: string;        // primary category that day
}

export interface ExpiryTrendPoint {
  week: string;            // 'Week 1', 'Week 2', etc.
  weekStart: string;       // ISO date
  expiringItems: number;
  expiredItems: number;
  valueAtRisk: number;     // ₹
}

export interface TopInventoryItem {
  productName: string;
  category: string;
  currentStock: number;
  unitCost: number;
  totalValue: number;      // currentStock × unitCost
  percentOfTotal: number;  // % of total inventory value
}

export interface SlowMovingItem {
  productName: string;
  category: string;
  currentStock: number;
  avgDailyUsage: number;
  daysOfStock: number;     // currentStock / avgDailyUsage
  lastSoldDate: string;    // ISO date
  totalValue: number;
}

export interface HealthSummaryMetrics {
  inventoryTurnoverRatio: number;  // COGS / avg inventory value
  shrinkagePercent: number;        // lost value / total value × 100
  valueAtRisk: number;             // ₹ of items nearing expiry
  grossMarginPercent: number;      // (revenue - COGS) / revenue × 100
  totalInventoryValue: number;     // ₹
  totalItems: number;
  avgDaysOnHand: number;
}

export interface DateRange {
  start: string;  // ISO date
  end: string;    // ISO date
  label: string;  // 'Last 7 Days', 'Last 30 Days', etc.
}

// ─── Constants ──────────────────────────────────────────────

export const DATE_RANGE_OPTIONS: DateRange[] = [
  { start: daysAgo(7),  end: today(), label: 'Last 7 Days' },
  { start: daysAgo(14), end: today(), label: 'Last 14 Days' },
  { start: daysAgo(30), end: today(), label: 'Last 30 Days' },
  { start: daysAgo(60), end: today(), label: 'Last 60 Days' },
  { start: daysAgo(90), end: today(), label: 'Last 90 Days' },
];

export const CHART_COLORS = {
  blue:    '#2196f3',
  green:   '#4caf50',
  orange:  '#ff9800',
  red:     '#f44336',
  purple:  '#9c27b0',
  teal:    '#009688',
  amber:   '#ffc107',
  indigo:  '#3f51b5',
  pink:    '#e91e63',
  cyan:    '#00bcd4',
} as const;

export const AGING_COLORS: Record<AgingBucket, string> = {
  'Fresh (0-2d)':      CHART_COLORS.green,
  'Acceptable (3-5d)': CHART_COLORS.blue,
  'Aging (6-10d)':     CHART_COLORS.orange,
  'Expired (>10d)':    CHART_COLORS.red,
};

// ─── Date Helpers ───────────────────────────────────────────

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

function daysAgo(n: number): string {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d.toISOString().slice(0, 10);
}

function formatShortDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' });
}

// ─── Mock Data Generators ───────────────────────────────────

const CATEGORIES = [
  'Fresh Flowers', 'Greens & Foliage', 'Dried Flowers',
  'Supplies', 'Vases & Containers', 'Gift Items',
];

function generateAgingData(): AgingDataPoint[] {
  const raw: Omit<AgingDataPoint, 'percentage'>[] = [
    { bucket: 'Fresh (0-2d)',      itemCount: 142, value: 48500  },
    { bucket: 'Acceptable (3-5d)', itemCount: 87,  value: 31200  },
    { bucket: 'Aging (6-10d)',     itemCount: 34,  value: 12800  },
    { bucket: 'Expired (>10d)',    itemCount: 11,  value: 3200   },
  ];
  const total = raw.reduce((s, r) => s + r.itemCount, 0);
  return raw.map((r) => ({
    ...r,
    percentage: Math.round((r.itemCount / total) * 1000) / 10,
  }));
}

function generateWastageTrend(): WastageTrendPoint[] {
  const points: WastageTrendPoint[] = [];
  const base = new Date();
  base.setDate(base.getDate() - 29);

  for (let i = 0; i < 30; i++) {
    const d = new Date(base);
    d.setDate(d.getDate() + i);
    const iso = d.toISOString().slice(0, 10);
    const dayOfWeek = d.getDay();

    // Higher wastage on Mon (weekend leftovers) and lower on weekends
    let multiplier = 1;
    if (dayOfWeek === 1) multiplier = 1.6;
    if (dayOfWeek === 0 || dayOfWeek === 6) multiplier = 0.5;

    const wastageValue = Math.round((800 + Math.random() * 1200) * multiplier);
    const wastageUnits = Math.round(wastageValue / (40 + Math.random() * 20));
    const cat = CATEGORIES[Math.floor(Math.random() * 3)]; // mostly perishables

    points.push({
      date: formatShortDate(iso),
      isoDate: iso,
      wastageValue,
      wastageUnits,
      category: cat,
    });
  }
  return points;
}

function generateExpiryTrend(): ExpiryTrendPoint[] {
  const weeks: ExpiryTrendPoint[] = [];
  const base = new Date();

  for (let w = 0; w < 8; w++) {
    const weekStart = new Date(base);
    weekStart.setDate(weekStart.getDate() + w * 7);

    // More items expiring in near weeks, fewer in distant
    const expiringBase = Math.max(3, 25 - w * 3);
    const expiredBase = Math.max(0, 8 - w * 2);

    const expiringItems = expiringBase + Math.floor(Math.random() * 6);
    const expiredItems = w < 2 ? expiredBase + Math.floor(Math.random() * 3) : 0;
    const valueAtRisk = (expiringItems * 280 + expiredItems * 150) + Math.floor(Math.random() * 500);

    weeks.push({
      week: w === 0 ? 'This Week' : `Week ${w + 1}`,
      weekStart: weekStart.toISOString().slice(0, 10),
      expiringItems,
      expiredItems,
      valueAtRisk,
    });
  }
  return weeks;
}

function generateTopInventory(): TopInventoryItem[] {
  const items: Omit<TopInventoryItem, 'totalValue' | 'percentOfTotal'>[] = [
    { productName: 'Red Roses (Premium)',     category: 'Fresh Flowers',    currentStock: 480, unitCost: 2.80 },
    { productName: 'Orchids (Phalaenopsis)',  category: 'Fresh Flowers',    currentStock: 65,  unitCost: 8.50 },
    { productName: 'Preserved Rose Boxes',    category: 'Gift Items',       currentStock: 42,  unitCost: 12.00 },
    { productName: 'Glass Cylinder Vases',    category: 'Vases & Containers', currentStock: 120, unitCost: 4.50 },
    { productName: 'White Lilies',            category: 'Fresh Flowers',    currentStock: 180, unitCost: 3.50 },
    { productName: 'Peonies',                 category: 'Fresh Flowers',    currentStock: 95,  unitCost: 5.50 },
    { productName: "Baby's Breath",           category: 'Fresh Flowers',    currentStock: 650, unitCost: 0.60 },
    { productName: 'Ceramic Bud Vases',       category: 'Vases & Containers', currentStock: 88,  unitCost: 3.40 },
    { productName: 'Eucalyptus Bunches',      category: 'Greens & Foliage', currentStock: 210, unitCost: 2.10 },
    { productName: 'Spray Roses (Peach)',     category: 'Fresh Flowers',    currentStock: 320, unitCost: 2.20 },
  ];

  const withTotal = items.map((i) => ({
    ...i,
    totalValue: Math.round(i.currentStock * i.unitCost * 100) / 100,
    percentOfTotal: 0,
  }));

  // Sort by value descending
  withTotal.sort((a, b) => b.totalValue - a.totalValue);

  const grandTotal = withTotal.reduce((s, i) => s + i.totalValue, 0);
  return withTotal.map((i) => ({
    ...i,
    percentOfTotal: Math.round((i.totalValue / grandTotal) * 1000) / 10,
  }));
}

function generateSlowMovingItems(): SlowMovingItem[] {
  const base = new Date();
  const past = (d: number) => {
    const dt = new Date(base);
    dt.setDate(dt.getDate() - d);
    return dt.toISOString().slice(0, 10);
  };

  return [
    { productName: 'Dried Pampas Grass',     category: 'Dried Flowers',      currentStock: 45,  avgDailyUsage: 0.3,  daysOfStock: 150,  lastSoldDate: past(12), totalValue: 540   },
    { productName: 'Gold Spray Paint',        category: 'Supplies',           currentStock: 28,  avgDailyUsage: 0.4,  daysOfStock: 70,   lastSoldDate: past(8),  totalValue: 336   },
    { productName: 'Bamboo Basket (Large)',    category: 'Vases & Containers', currentStock: 18,  avgDailyUsage: 0.2,  daysOfStock: 90,   lastSoldDate: past(15), totalValue: 612   },
    { productName: 'Silk Orchid Stems',        category: 'Dried Flowers',      currentStock: 32,  avgDailyUsage: 0.5,  daysOfStock: 64,   lastSoldDate: past(6),  totalValue: 448   },
    { productName: 'Crystal Heart Vase',       category: 'Vases & Containers', currentStock: 8,   avgDailyUsage: 0.1,  daysOfStock: 80,   lastSoldDate: past(22), totalValue: 960   },
    { productName: 'Scented Candles (Vanilla)',category: 'Gift Items',         currentStock: 55,  avgDailyUsage: 0.8,  daysOfStock: 69,   lastSoldDate: past(4),  totalValue: 495   },
    { productName: 'Macrame Plant Hanger',     category: 'Vases & Containers', currentStock: 12,  avgDailyUsage: 0.15, daysOfStock: 80,   lastSoldDate: past(18), totalValue: 360   },
    { productName: 'Glitter Floral Tape',      category: 'Supplies',           currentStock: 40,  avgDailyUsage: 0.6,  daysOfStock: 67,   lastSoldDate: past(5),  totalValue: 240   },
  ].sort((a, b) => b.daysOfStock - a.daysOfStock);
}

function generateSummaryMetrics(): HealthSummaryMetrics {
  return {
    inventoryTurnoverRatio: 8.4,
    shrinkagePercent: 2.7,
    valueAtRisk: 18600,
    grossMarginPercent: 62.3,
    totalInventoryValue: 245800,
    totalItems: 274,
    avgDaysOnHand: 4.2,
  };
}

// ─── Exported Mock Data ─────────────────────────────────────

export const MOCK_AGING_DATA: AgingDataPoint[]           = generateAgingData();
export const MOCK_WASTAGE_TREND: WastageTrendPoint[]     = generateWastageTrend();
export const MOCK_EXPIRY_TREND: ExpiryTrendPoint[]       = generateExpiryTrend();
export const MOCK_TOP_INVENTORY: TopInventoryItem[]      = generateTopInventory();
export const MOCK_SLOW_MOVING: SlowMovingItem[]          = generateSlowMovingItems();
export const MOCK_SUMMARY_METRICS: HealthSummaryMetrics  = generateSummaryMetrics();

export const DEFAULT_DATE_RANGE: DateRange = DATE_RANGE_OPTIONS[2]; // Last 30 Days

// ─── Mock API ───────────────────────────────────────────────

export interface DashboardData {
  aging: AgingDataPoint[];
  wastageTrend: WastageTrendPoint[];
  expiryTrend: ExpiryTrendPoint[];
  topInventory: TopInventoryItem[];
  slowMoving: SlowMovingItem[];
  summary: HealthSummaryMetrics;
}

export const fetchDashboardData = (_range: DateRange): Promise<DashboardData> =>
  new Promise((resolve) =>
    setTimeout(
      () =>
        resolve({
          aging: MOCK_AGING_DATA,
          wastageTrend: MOCK_WASTAGE_TREND,
          expiryTrend: MOCK_EXPIRY_TREND,
          topInventory: MOCK_TOP_INVENTORY,
          slowMoving: MOCK_SLOW_MOVING,
          summary: MOCK_SUMMARY_METRICS,
        }),
      600,
    ),
  );
