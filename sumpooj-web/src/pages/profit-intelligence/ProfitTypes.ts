/**
 * ProfitTypes.ts — Enterprise Profit Intelligence System Types
 *
 * Strict TypeScript types for profit analytics, channel comparison,
 * product profitability, commission tracking, and payment analysis.
 */
import type { OrderSource } from '../orders/OrderTypes';
import type { PaymentMethod } from '../payments/PaymentTypes';

// ─── Date Range Filter ──────────────────────────────────────

export type DateRangePreset = 'TODAY' | 'YESTERDAY' | 'LAST_7_DAYS' | 'LAST_30_DAYS' | 'THIS_MONTH' | 'LAST_MONTH' | 'CUSTOM';

export interface DateRange {
  startDate: string; // ISO date
  endDate: string;   // ISO date
  preset: DateRangePreset;
}

// ─── Executive Summary ──────────────────────────────────────

export interface ExecutiveSummary {
  grossRevenue: number;
  externalCommissionPaid: number;
  refundsIssued: number;
  totalCOGS: number;
  wastageValue: number;
  netProfit: number;
  profitMarginPercent: number;
  paymentProcessingCost: number;
  orderCount: number;
  avgOrderValue: number;
  periodLabel: string;
  comparisonPeriod?: {
    grossRevenue: number;
    netProfit: number;
    orderCount: number;
  };
}

// ─── Channel Profit Analysis ────────────────────────────────

export interface ChannelProfit {
  channel: OrderSource;
  grossRevenue: number;
  commission: number;
  netRevenue: number;
  cogs: number;
  estimatedProfit: number;
  profitPercent: number;
  orderCount: number;
  avgOrderValue: number;
}

export type ChannelProfitSummary = ChannelProfit[];

// ─── Product Profit Analysis ────────────────────────────────

export interface ProductProfit {
  productId: string;
  productName: string;
  sku: string;
  category: string;
  quantitySold: number;
  grossRevenue: number;
  cogs: number;
  wastageImpact: number;
  channelBreakdown: Record<OrderSource, number>;
  netProfit: number;
  netProfitPercent: number;
  effectiveMarginPercent: number;
}

export type ProductProfitReport = ProductProfit[];

// ─── Commission & Platform Analysis ─────────────────────────

export interface PlatformCommission {
  platform: 'BLOOMNATION' | 'FTD';
  grossRevenue: number;
  commissionRate: number;
  commissionAmount: number;
  platformFees: number;
  netPayout: number;
  cogs: number;
  profit: number;
  profitPercent: number;
  orderCount: number;
}

export type PlatformCommissionReport = PlatformCommission[];

// ─── Inventory Impact Analysis ──────────────────────────────

export interface InventoryImpact {
  totalSalesValue: number;
  totalCOGS: number;
  totalWastageValue: number;
  totalWastageUnits: number;
  shrinkagePercent: number;
  adjustedGrossProfit: number;
  adjustedProfitMargin: number;
  wastageByCategory: Array<{
    category: string;
    wastageValue: number;
    wastageUnits: number;
    wastagePercent: number;
  }>;
  monthlyWastageTrend: Array<{
    month: string;
    wastageValue: number;
    salesValue: number;
    wastagePercent: number;
  }>;
}

// ─── Payment Analysis ───────────────────────────────────────

export interface PaymentMethodAnalysis {
  method: PaymentMethod;
  transactionCount: number;
  totalAmount: number;
  percentOfTotal: number;
  estimatedProcessingRate: number;
  estimatedProcessingCost: number;
  netRevenue: number;
}

export interface PaymentAnalysisSummary {
  totalTransactions: number;
  totalRevenue: number;
  totalProcessingCost: number;
  netRevenueAfterProcessing: number;
  methodBreakdown: PaymentMethodAnalysis[];
  dailyTrend: Array<{
    date: string;
    cash: number;
    card: number;
    giftCard: number;
    externalTerminal: number;
  }>;
}

// ─── Trend Data ─────────────────────────────────────────────

export interface DailyRevenueTrend {
  date: string;
  grossRevenue: number;
  netRevenue: number;
  orderCount: number;
  cogs: number;
  profit: number;
}

export interface ChannelTrendPoint {
  date: string;
  WALK_IN: number;
  PHONE: number;
  WEBSITE: number;
  BLOOMNATION: number;
  FTD: number;
}

// ─── Config for display ─────────────────────────────────────

export const DATE_RANGE_CONFIG: Record<DateRangePreset, { label: string; days: number }> = {
  TODAY: { label: 'Today', days: 1 },
  YESTERDAY: { label: 'Yesterday', days: 1 },
  LAST_7_DAYS: { label: 'Last 7 Days', days: 7 },
  LAST_30_DAYS: { label: 'Last 30 Days', days: 30 },
  THIS_MONTH: { label: 'This Month', days: 0 },
  LAST_MONTH: { label: 'Last Month', days: 0 },
  CUSTOM: { label: 'Custom Range', days: 0 },
};

export const CHANNEL_CONFIG: Record<OrderSource, { label: string; color: string }> = {
  WALK_IN: { label: 'Walk-In', color: '#4caf50' },
  PHONE: { label: 'Phone', color: '#2196f3' },
  WEBSITE: { label: 'Website', color: '#9c27b0' },
  BLOOMNATION: { label: 'BloomNation', color: '#e91e63' },
  FTD: { label: 'FTD', color: '#ff9800' },
};

export const PAYMENT_METHOD_PROCESSING_RATES: Record<PaymentMethod, number> = {
  CASH: 0,
  CARD: 0.025,           // 2.5%
  GIFT_CARD: 0.01,       // 1%
  EXTERNAL_TERMINAL: 0,  // Already processed externally
};

// ─── API Response Shapes ────────────────────────────────────

export interface ProfitDashboardData {
  summary: ExecutiveSummary;
  channelProfit: ChannelProfitSummary;
  productProfit: ProductProfitReport;
  platformCommission: PlatformCommissionReport;
  inventoryImpact: InventoryImpact;
  paymentAnalysis: PaymentAnalysisSummary;
  revenueTrend: DailyRevenueTrend[];
  channelTrend: ChannelTrendPoint[];
}

/** API request shape */
export interface ProfitDashboardRequest {
  startDate: string;
  endDate: string;
  channels?: OrderSource[];
  products?: string[];
}
