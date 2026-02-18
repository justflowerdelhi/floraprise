/**
 * ProfitMockData.ts — Mock analytics data for Enterprise Profit Intelligence
 *
 * Generates realistic profit analytics for:
 * - Executive Summary
 * - Channel Profit Comparison
 * - Product Profitability
 * - Commission Analysis
 * - Inventory Impact
 * - Payment Analysis
 */
import type {
  ExecutiveSummary,
  ChannelProfitSummary,
  ProductProfitReport,
  PlatformCommissionReport,
  InventoryImpact,
  PaymentAnalysisSummary,
  DailyRevenueTrend,
  ChannelTrendPoint,
  ProfitDashboardData,
} from './ProfitTypes';

// ─── Helpers ────────────────────────────────────────────────

const today = new Date();
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const daysAgo = (n: number) => {
  const d = new Date(today);
  d.setDate(d.getDate() - n);
  return isoDate(d);
};

// ─── Executive Summary Mock ─────────────────────────────────

export const MOCK_EXECUTIVE_SUMMARY: ExecutiveSummary = {
  grossRevenue: 847500,
  externalCommissionPaid: 42375,  // ~5% of gross (external orders)
  refundsIssued: 12400,
  totalCOGS: 339000,             // ~40% of gross
  wastageValue: 18950,
  netProfit: 434775,
  profitMarginPercent: 51.3,
  paymentProcessingCost: 8475,   // ~1% of gross
  orderCount: 487,
  avgOrderValue: 1740,
  periodLabel: 'Last 30 Days',
  comparisonPeriod: {
    grossRevenue: 792000,
    netProfit: 396000,
    orderCount: 451,
  },
};

// ─── Channel Profit Mock ────────────────────────────────────

export const MOCK_CHANNEL_PROFIT: ChannelProfitSummary = [
  {
    channel: 'WALK_IN',
    grossRevenue: 285000,
    commission: 0,
    netRevenue: 285000,
    cogs: 114000,
    estimatedProfit: 171000,
    profitPercent: 60.0,
    orderCount: 195,
    avgOrderValue: 1462,
  },
  {
    channel: 'PHONE',
    grossRevenue: 198500,
    commission: 0,
    netRevenue: 198500,
    cogs: 79400,
    estimatedProfit: 119100,
    profitPercent: 60.0,
    orderCount: 112,
    avgOrderValue: 1772,
  },
  {
    channel: 'WEBSITE',
    grossRevenue: 156000,
    commission: 0,
    netRevenue: 156000,
    cogs: 62400,
    estimatedProfit: 93600,
    profitPercent: 60.0,
    orderCount: 98,
    avgOrderValue: 1592,
  },
  {
    channel: 'BLOOMNATION',
    grossRevenue: 124500,
    commission: 12450,   // 10%
    netRevenue: 112050,
    cogs: 49800,
    estimatedProfit: 62250,
    profitPercent: 50.0,
    orderCount: 52,
    avgOrderValue: 2394,
  },
  {
    channel: 'FTD',
    grossRevenue: 83500,
    commission: 22545,   // 27%
    netRevenue: 60955,
    cogs: 33400,
    estimatedProfit: 27555,
    profitPercent: 33.0,
    orderCount: 30,
    avgOrderValue: 2783,
  },
];

// ─── Product Profit Mock ────────────────────────────────────

export const MOCK_PRODUCT_PROFIT: ProductProfitReport = [
  {
    productId: 'p01',
    productName: 'Red Roses (Premium)',
    sku: 'RSP-001',
    category: 'Fresh Flowers',
    quantitySold: 420,
    grossRevenue: 117600,
    cogs: 50400,
    wastageImpact: 2800,
    channelBreakdown: { WALK_IN: 47000, PHONE: 28000, WEBSITE: 22400, BLOOMNATION: 14000, FTD: 6200 },
    netProfit: 64400,
    netProfitPercent: 54.8,
    effectiveMarginPercent: 52.4,
  },
  {
    productId: 'p04',
    productName: 'Classic Rose Bouquet',
    sku: 'CRB-010',
    category: 'Bouquets',
    quantitySold: 85,
    grossRevenue: 72250,
    cogs: 32300,
    wastageImpact: 1900,
    channelBreakdown: { WALK_IN: 25500, PHONE: 18700, WEBSITE: 12750, BLOOMNATION: 9350, FTD: 5950 },
    netProfit: 38050,
    netProfitPercent: 52.7,
    effectiveMarginPercent: 50.0,
  },
  {
    productId: 'p05',
    productName: 'Spring Garden Arrangement',
    sku: 'SGA-011',
    category: 'Arrangements',
    quantitySold: 48,
    grossRevenue: 57600,
    cogs: 24960,
    wastageImpact: 1560,
    channelBreakdown: { WALK_IN: 19200, PHONE: 14400, WEBSITE: 10800, BLOOMNATION: 8400, FTD: 4800 },
    netProfit: 31080,
    netProfitPercent: 53.9,
    effectiveMarginPercent: 51.2,
  },
  {
    productId: 'p02',
    productName: 'White Lilies',
    sku: 'WHL-002',
    category: 'Fresh Flowers',
    quantitySold: 145,
    grossRevenue: 50750,
    cogs: 23200,
    wastageImpact: 1600,
    channelBreakdown: { WALK_IN: 18000, PHONE: 13200, WEBSITE: 9500, BLOOMNATION: 6300, FTD: 3750 },
    netProfit: 25950,
    netProfitPercent: 51.1,
    effectiveMarginPercent: 48.0,
  },
  {
    productId: 'p06',
    productName: 'Orchid Phalaenopsis',
    sku: 'ORC-004',
    category: 'Plants',
    quantitySold: 65,
    grossRevenue: 35750,
    cogs: 18200,
    wastageImpact: 560,
    channelBreakdown: { WALK_IN: 14300, PHONE: 10450, WEBSITE: 6050, BLOOMNATION: 3300, FTD: 1650 },
    netProfit: 16990,
    netProfitPercent: 47.5,
    effectiveMarginPercent: 45.9,
  },
  {
    productId: 'p15',
    productName: 'Sympathy Spray',
    sku: 'SYS-012',
    category: 'Arrangements',
    quantitySold: 22,
    grossRevenue: 48400,
    cogs: 20900,
    wastageImpact: 950,
    channelBreakdown: { WALK_IN: 13200, PHONE: 15400, WEBSITE: 6600, BLOOMNATION: 8800, FTD: 4400 },
    netProfit: 26550,
    netProfitPercent: 54.9,
    effectiveMarginPercent: 52.9,
  },
  {
    productId: 'p13',
    productName: 'Chocolate Box (Premium)',
    sku: 'CBP-031',
    category: 'Add-Ons',
    quantitySold: 78,
    grossRevenue: 50700,
    cogs: 24960,
    wastageImpact: 640,
    channelBreakdown: { WALK_IN: 18200, PHONE: 14300, WEBSITE: 9750, BLOOMNATION: 5850, FTD: 2600 },
    netProfit: 25100,
    netProfitPercent: 49.5,
    effectiveMarginPercent: 48.2,
  },
  {
    productId: 'p03',
    productName: 'Sunflowers',
    sku: 'SNF-003',
    category: 'Fresh Flowers',
    quantitySold: 180,
    grossRevenue: 34200,
    cogs: 14400,
    wastageImpact: 1440,
    channelBreakdown: { WALK_IN: 13680, PHONE: 8550, WEBSITE: 6840, BLOOMNATION: 3420, FTD: 1710 },
    netProfit: 18360,
    netProfitPercent: 53.7,
    effectiveMarginPercent: 49.5,
  },
  {
    productId: 'p12',
    productName: 'Teddy Bear (Medium)',
    sku: 'TBM-030',
    category: 'Add-Ons',
    quantitySold: 45,
    grossRevenue: 21600,
    cogs: 9000,
    wastageImpact: 0,
    channelBreakdown: { WALK_IN: 8640, PHONE: 6480, WEBSITE: 4320, BLOOMNATION: 1440, FTD: 720 },
    netProfit: 12600,
    netProfitPercent: 58.3,
    effectiveMarginPercent: 58.3,
  },
  {
    productId: 'p09',
    productName: 'Glass Cylinder Vase',
    sku: 'GCV-020',
    category: 'Add-Ons',
    quantitySold: 62,
    grossRevenue: 27900,
    cogs: 11160,
    wastageImpact: 360,
    channelBreakdown: { WALK_IN: 11160, PHONE: 8370, WEBSITE: 5580, BLOOMNATION: 1953, FTD: 837 },
    netProfit: 16380,
    netProfitPercent: 58.7,
    effectiveMarginPercent: 57.4,
  },
];

// ─── Platform Commission Mock ───────────────────────────────

export const MOCK_PLATFORM_COMMISSION: PlatformCommissionReport = [
  {
    platform: 'BLOOMNATION',
    grossRevenue: 124500,
    commissionRate: 0.10,
    commissionAmount: 12450,
    platformFees: 0,
    netPayout: 112050,
    cogs: 49800,
    profit: 62250,
    profitPercent: 50.0,
    orderCount: 52,
  },
  {
    platform: 'FTD',
    grossRevenue: 83500,
    commissionRate: 0.27,
    commissionAmount: 22545,
    platformFees: 0,
    netPayout: 60955,
    cogs: 33400,
    profit: 27555,
    profitPercent: 33.0,
    orderCount: 30,
  },
];

// ─── Inventory Impact Mock ──────────────────────────────────

export const MOCK_INVENTORY_IMPACT: InventoryImpact = {
  totalSalesValue: 847500,
  totalCOGS: 339000,
  totalWastageValue: 18950,
  totalWastageUnits: 245,
  shrinkagePercent: 2.24,
  adjustedGrossProfit: 489550,
  adjustedProfitMargin: 57.8,
  wastageByCategory: [
    { category: 'Fresh Flowers', wastageValue: 9800, wastageUnits: 142, wastagePercent: 51.7 },
    { category: 'Arrangements', wastageValue: 4200, wastageUnits: 18, wastagePercent: 22.2 },
    { category: 'Bouquets', wastageValue: 2950, wastageUnits: 12, wastagePercent: 15.6 },
    { category: 'Greens & Foliage', wastageValue: 1400, wastageUnits: 58, wastagePercent: 7.4 },
    { category: 'Plants', wastageValue: 600, wastageUnits: 15, wastagePercent: 3.1 },
  ],
  monthlyWastageTrend: [
    { month: 'Nov 2025', wastageValue: 14200, salesValue: 720000, wastagePercent: 1.97 },
    { month: 'Dec 2025', wastageValue: 22400, salesValue: 980000, wastagePercent: 2.29 },
    { month: 'Jan 2026', wastageValue: 16800, salesValue: 810000, wastagePercent: 2.07 },
    { month: 'Feb 2026', wastageValue: 18950, salesValue: 847500, wastagePercent: 2.24 },
  ],
};

// ─── Payment Analysis Mock ──────────────────────────────────

export const MOCK_PAYMENT_ANALYSIS: PaymentAnalysisSummary = {
  totalTransactions: 512,
  totalRevenue: 847500,
  totalProcessingCost: 8475,
  netRevenueAfterProcessing: 839025,
  methodBreakdown: [
    {
      method: 'CASH',
      transactionCount: 168,
      totalAmount: 278500,
      percentOfTotal: 32.9,
      estimatedProcessingRate: 0,
      estimatedProcessingCost: 0,
      netRevenue: 278500,
    },
    {
      method: 'CARD',
      transactionCount: 245,
      totalAmount: 389000,
      percentOfTotal: 45.9,
      estimatedProcessingRate: 0.025,
      estimatedProcessingCost: 9725,
      netRevenue: 379275,
    },
    {
      method: 'GIFT_CARD',
      transactionCount: 42,
      totalAmount: 48000,
      percentOfTotal: 5.7,
      estimatedProcessingRate: 0.01,
      estimatedProcessingCost: 480,
      netRevenue: 47520,
    },
    {
      method: 'EXTERNAL_TERMINAL',
      transactionCount: 57,
      totalAmount: 132000,
      percentOfTotal: 15.6,
      estimatedProcessingRate: 0,
      estimatedProcessingCost: 0,
      netRevenue: 132000,
    },
  ],
  dailyTrend: [
    { date: daysAgo(6), cash: 38500, card: 52000, giftCard: 6500, externalTerminal: 18000 },
    { date: daysAgo(5), cash: 42000, card: 48500, giftCard: 7200, externalTerminal: 15500 },
    { date: daysAgo(4), cash: 36200, card: 58200, giftCard: 5800, externalTerminal: 21000 },
    { date: daysAgo(3), cash: 44500, card: 62400, giftCard: 8100, externalTerminal: 19500 },
    { date: daysAgo(2), cash: 39800, card: 55600, giftCard: 6900, externalTerminal: 17200 },
    { date: daysAgo(1), cash: 41200, card: 59800, giftCard: 7500, externalTerminal: 22800 },
    { date: daysAgo(0), cash: 36300, card: 52500, giftCard: 6000, externalTerminal: 18000 },
  ],
};

// ─── Revenue Trend Mock ─────────────────────────────────────

export const MOCK_REVENUE_TREND: DailyRevenueTrend[] = Array.from({ length: 30 }, (_, i) => {
  const dayOffset = 29 - i;
  const baseRevenue = 25000 + Math.random() * 10000;
  const cogs = baseRevenue * 0.4;
  return {
    date: daysAgo(dayOffset),
    grossRevenue: Math.round(baseRevenue),
    netRevenue: Math.round(baseRevenue * 0.95),
    orderCount: Math.round(12 + Math.random() * 8),
    cogs: Math.round(cogs),
    profit: Math.round(baseRevenue - cogs),
  };
});

// ─── Channel Trend Mock ─────────────────────────────────────

export const MOCK_CHANNEL_TREND: ChannelTrendPoint[] = Array.from({ length: 30 }, (_, i) => {
  const dayOffset = 29 - i;
  return {
    date: daysAgo(dayOffset),
    WALK_IN: Math.round(8000 + Math.random() * 4000),
    PHONE: Math.round(5500 + Math.random() * 3000),
    WEBSITE: Math.round(4000 + Math.random() * 2500),
    BLOOMNATION: Math.round(3500 + Math.random() * 2000),
    FTD: Math.round(2000 + Math.random() * 1500),
  };
});

// ─── Complete Dashboard Data ────────────────────────────────

export const MOCK_PROFIT_DASHBOARD_DATA: ProfitDashboardData = {
  summary: MOCK_EXECUTIVE_SUMMARY,
  channelProfit: MOCK_CHANNEL_PROFIT,
  productProfit: MOCK_PRODUCT_PROFIT,
  platformCommission: MOCK_PLATFORM_COMMISSION,
  inventoryImpact: MOCK_INVENTORY_IMPACT,
  paymentAnalysis: MOCK_PAYMENT_ANALYSIS,
  revenueTrend: MOCK_REVENUE_TREND,
  channelTrend: MOCK_CHANNEL_TREND,
};

// ─── API Simulation Functions ───────────────────────────────

/**
 * Simulates API call delay.
 */
export const simulateApiDelay = (ms = 500): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Simulates fetching profit dashboard data.
 * In production, this would call the backend API.
 */
export const fetchProfitDashboardData = async (
  _startDate: string,
  _endDate: string,
): Promise<ProfitDashboardData> => {
  await simulateApiDelay(800);
  return MOCK_PROFIT_DASHBOARD_DATA;
};
