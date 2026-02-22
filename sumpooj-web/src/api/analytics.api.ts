import api from './axios';

// ─── Types (matching frontend ProfitTypes.ts) ───────────────

export type DateRangePreset = 'TODAY' | 'YESTERDAY' | 'LAST_7_DAYS' | 'LAST_30_DAYS' | 'THIS_MONTH' | 'LAST_MONTH' | 'CUSTOM';
export type OrderSource = 'WALK_IN' | 'PHONE' | 'WEBSITE' | 'BLOOMNATION' | 'FTD';
export type PaymentMethod = 'CASH' | 'CARD' | 'GIFT_CARD' | 'EXTERNAL_TERMINAL' | 'UPI' | 'BANK_TRANSFER';

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

export interface DailyRevenueTrend {
  date: string;
  grossRevenue: number;
  netRevenue: number;
  orderCount: number;
  cogs: number;
  profit: number;
}

export interface ProfitDashboardData {
  summary: ExecutiveSummary;
  channelProfit: ChannelProfit[];
  productProfit: ProductProfit[];
  platformCommission: PlatformCommission[];
  inventoryImpact?: InventoryImpact;
  paymentAnalysis?: PaymentAnalysisSummary;
}

export interface ProfitDashboardRequest {
  fromDate?: string;
  toDate?: string;
  locationId?: string;
  dateRangePreset?: DateRangePreset;
}

// ─── API Functions ──────────────────────────────────────────

/** GET /analytics/profit-dashboard - Get full profit dashboard */
export const getProfitDashboard = async (params: ProfitDashboardRequest): Promise<ProfitDashboardData> => {
  const res = await api.get('/analytics/profit-dashboard', { params });
  return res.data;
};

/** GET /analytics/profit-summary - Get profit summary */
export const getProfitSummary = async (fromDate?: string, toDate?: string) => {
  const res = await api.get('/analytics/profit-summary', { params: { fromDate, toDate } });
  return res.data;
};

/** GET /analytics/profit-by-category - Get category-wise profit breakdown */
export const getProfitByCategory = async (fromDate?: string, toDate?: string): Promise<ChannelProfit[]> => {
  const res = await api.get('/analytics/profit-by-category', { params: { fromDate, toDate } });
  return res.data;
};

/** GET /analytics/top-products - Get top performing products by profit */
export const getTopProducts = async (fromDate?: string, toDate?: string, limit = 10): Promise<ProductProfit[]> => {
  const res = await api.get('/analytics/top-products', { params: { fromDate, toDate, limit } });
  return res.data;
};

/** GET /analytics/low-margin-products - Get low margin products */
export const getLowMarginProducts = async (fromDate?: string, toDate?: string, limit = 10): Promise<ProductProfit[]> => {
  const res = await api.get('/analytics/low-margin-products', { params: { fromDate, toDate, limit } });
  return res.data;
};

/** GET /analytics/profit-by-source - Get profit by order source */
export const getProfitBySource = async (fromDate?: string, toDate?: string): Promise<ChannelProfit[]> => {
  const res = await api.get('/analytics/profit-by-source', { params: { fromDate, toDate } });
  return res.data;
};

/** GET /analytics/daily-profit - Get daily profit trend */
export const getDailyProfit = async (fromDate?: string, toDate?: string): Promise<DailyRevenueTrend[]> => {
  const res = await api.get('/analytics/daily-profit', { params: { fromDate, toDate } });
  return res.data;
};

/** GET /analytics/wire-order-profit - Get wire order profit analysis */
export const getWireOrderProfit = async (fromDate?: string, toDate?: string) => {
  const res = await api.get('/analytics/wire-order-profit', { params: { fromDate, toDate } });
  return res.data;
};

/** GET /analytics/event-profit - Get event profit summary */
export const getEventProfit = async (fromDate?: string, toDate?: string) => {
  const res = await api.get('/analytics/event-profit', { params: { fromDate, toDate } });
  return res.data;
};
/** GET /analytics/profit-by-channel - Get profit breakdown by sales channel */
export const getProfitByChannel = async (fromDate?: string, toDate?: string): Promise<ChannelProfit[]> => {
  const res = await api.get('/analytics/profit-by-channel', { params: { fromDate, toDate } });
  return res.data;
};

/** GET /analytics/product-profit - Get profit breakdown by products */
export const getProductProfit = async (fromDate?: string, toDate?: string): Promise<ProductProfit[]> => {
  const res = await api.get('/analytics/product-profit', { params: { fromDate, toDate } });
  return res.data;
};

/** GET /analytics/platform-commission - Get platform commission analysis */
export const getPlatformCommission = async (fromDate?: string, toDate?: string): Promise<PlatformCommission[]> => {
  const res = await api.get('/analytics/platform-commission', { params: { fromDate, toDate } });
  return res.data;
};