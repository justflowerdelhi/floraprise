/**
 * Sales Mock Data
 * Comprehensive test data for Sales Analytics, Reports, and POS
 * Florist POS + ERP SaaS Platform
 */

const today = new Date();
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const isoDateTime = (d: Date) => d.toISOString();
const daysAgo = (n: number, hours = 12) => {
  const d = new Date(today);
  d.setDate(d.getDate() - n);
  d.setHours(hours, Math.floor(Math.random() * 60), 0, 0);
  return isoDateTime(d);
};

// ─── Sales Transaction Types ────────────────────────────────

export type PaymentMethod = 'CASH' | 'CARD' | 'UPI' | 'BANK_TRANSFER' | 'GIFT_CARD';
export type OrderSource = 'WALK_IN' | 'PHONE' | 'WEBSITE' | 'FTD' | 'BLOOMNATION';

export interface SalesTransaction {
  id: string;
  orderNumber: string;
  orderSource: OrderSource;
  customerId?: string;
  customerName: string;
  customerPhone?: string;
  items: SalesLineItem[];
  subtotal: number;
  taxAmount: number;
  discount: number;
  total: number;
  cost: number;
  profit: number;
  marginPercent: number;
  paymentMethod: PaymentMethod;
  paymentStatus: 'PAID' | 'PARTIAL' | 'UNPAID';
  cashierId: string;
  cashierName: string;
  locationId: string;
  createdAt: string;
}

export interface SalesLineItem {
  productId: string;
  productName: string;
  sku: string;
  category: string;
  quantity: number;
  unitPrice: number;
  discount: number;
  lineTotal: number;
  cost: number;
}

// ─── Helper Functions ───────────────────────────────────────

const createSaleItem = (
  productId: string,
  productName: string,
  sku: string,
  category: string,
  quantity: number,
  unitPrice: number,
  costPerUnit: number,
  discount = 0
): SalesLineItem => ({
  productId,
  productName,
  sku,
  category,
  quantity,
  unitPrice,
  discount,
  lineTotal: (unitPrice * quantity) - discount,
  cost: costPerUnit * quantity,
});

let txnSeq = 1000;
const createSale = (
  orderSource: OrderSource,
  customerName: string,
  items: SalesLineItem[],
  paymentMethod: PaymentMethod,
  cashierName: string,
  daysAgoNum: number,
  hours: number,
  discount = 0,
  customerPhone?: string,
): SalesTransaction => {
  const subtotal = items.reduce((sum, i) => sum + (i.unitPrice * i.quantity), 0);
  const itemDiscount = items.reduce((sum, i) => sum + i.discount, 0);
  const totalDiscount = discount + itemDiscount;
  const taxAmount = Math.round((subtotal - totalDiscount) * 0.05 * 100) / 100;
  const total = subtotal - totalDiscount + taxAmount;
  const cost = items.reduce((sum, i) => sum + i.cost, 0);
  const profit = total - cost;
  
  return {
    id: `sale_${++txnSeq}`,
    orderNumber: `ORD-2026-${String(txnSeq).padStart(4, '0')}`,
    orderSource,
    customerName,
    customerPhone,
    items,
    subtotal,
    taxAmount,
    discount: totalDiscount,
    total,
    cost,
    profit,
    marginPercent: Math.round((profit / total) * 100),
    paymentMethod,
    paymentStatus: 'PAID',
    cashierId: cashierName === 'Amit Kumar' ? 'user_001' : cashierName === 'Sneha Patel' ? 'user_002' : 'user_003',
    cashierName,
    locationId: 'loc_main',
    createdAt: daysAgo(daysAgoNum, hours),
  };
};

// ─── Mock Sales Transactions (Last 7 Days) ──────────────────

export const MOCK_SALES_TRANSACTIONS: SalesTransaction[] = [
  // Today's sales
  createSale('WALK_IN', 'Priya Sharma', [
    createSaleItem('p01', 'Red Roses (Premium)', 'RSP-001', 'Fresh Flowers', 5, 280, 120),
    createSaleItem('p08', "Baby's Breath", 'BBR-006', 'Fresh Flowers', 3, 60, 22),
  ], 'CARD', 'Amit Kumar', 0, 10, 0, '+91 98765 43210'),
  
  createSale('PHONE', 'Rahul Verma', [
    createSaleItem('p04', 'Classic Rose Bouquet', 'CRB-010', 'Bouquets', 1, 850, 380),
    createSaleItem('p13', 'Chocolate Box (Premium)', 'CBP-031', 'Add-Ons', 1, 650, 320),
  ], 'UPI', 'Sneha Patel', 0, 11, 50, '+91 87654 32109'),
  
  createSale('WALK_IN', 'Anita Desai', [
    createSaleItem('p02', 'White Lilies', 'WHL-002', 'Fresh Flowers', 3, 350, 160),
  ], 'CASH', 'Amit Kumar', 0, 12),
  
  createSale('WEBSITE', 'Vikram Singh', [
    createSaleItem('p05', 'Spring Garden Arrangement', 'SGA-011', 'Arrangements', 1, 1200, 520),
    createSaleItem('p09', 'Glass Cylinder Vase', 'GCV-020', 'Add-Ons', 1, 450, 180),
  ], 'CARD', 'Ravi Sharma', 0, 14, 0, '+91 65432 10987'),
  
  createSale('WALK_IN', 'Meera Kapoor', [
    createSaleItem('p06', 'Orchid Phalaenopsis', 'ORC-004', 'Plants', 1, 550, 280),
  ], 'UPI', 'Amit Kumar', 0, 15),
  
  createSale('FTD', 'David Johnson (FTD)', [
    createSaleItem('p15', 'Sympathy Spray', 'SYS-012', 'Arrangements', 1, 2200, 950),
    createSaleItem('p02', 'White Lilies', 'WHL-002', 'Fresh Flowers', 5, 350, 160),
  ], 'BANK_TRANSFER', 'Sneha Patel', 0, 16),
  
  // Yesterday's sales
  createSale('WALK_IN', 'Suresh Iyer', [
    createSaleItem('p01', 'Red Roses (Premium)', 'RSP-001', 'Fresh Flowers', 12, 280, 120),
    createSaleItem('p07', 'Eucalyptus Bunch', 'EUC-005', 'Greens & Foliage', 2, 210, 90),
  ], 'CASH', 'Amit Kumar', 1, 9, 100, '+91 99887 76655'),
  
  createSale('PHONE', 'Neha Gupta', [
    createSaleItem('p04', 'Classic Rose Bouquet', 'CRB-010', 'Bouquets', 2, 850, 380),
  ], 'CARD', 'Sneha Patel', 1, 10),
  
  createSale('BLOOMNATION', 'Jessica Brown (BN)', [
    createSaleItem('p05', 'Spring Garden Arrangement', 'SGA-011', 'Arrangements', 1, 1200, 520),
    createSaleItem('p12', 'Teddy Bear (Medium)', 'TBM-030', 'Add-Ons', 1, 480, 200),
  ], 'BANK_TRANSFER', 'Ravi Sharma', 1, 11),
  
  createSale('WALK_IN', 'Arun Mehta', [
    createSaleItem('p03', 'Sunflowers', 'SNF-003', 'Fresh Flowers', 10, 190, 80),
  ], 'UPI', 'Amit Kumar', 1, 13),
  
  createSale('WEBSITE', 'Kavita Reddy', [
    createSaleItem('p16', 'Preserved Rose Box', 'PRB-032', 'Gift Items', 1, 1200, 480),
  ], 'CARD', 'Sneha Patel', 1, 14),
  
  createSale('PHONE', 'Mohammed Ali', [
    createSaleItem('p02', 'White Lilies', 'WHL-002', 'Fresh Flowers', 4, 350, 160),
    createSaleItem('p08', "Baby's Breath", 'BBR-006', 'Fresh Flowers', 5, 60, 22),
  ], 'CASH', 'Ravi Sharma', 1, 15),
  
  createSale('WALK_IN', 'Pooja Desai', [
    createSaleItem('p14', 'Pink Carnations', 'PCN-007', 'Fresh Flowers', 20, 120, 48),
  ], 'GIFT_CARD', 'Amit Kumar', 1, 16),
  
  // 2 days ago
  createSale('WALK_IN', 'Rohit Sharma', [
    createSaleItem('p01', 'Red Roses (Premium)', 'RSP-001', 'Fresh Flowers', 24, 280, 120),
  ], 'CARD', 'Sneha Patel', 2, 9, 200),
  
  createSale('PHONE', 'Lakshmi Nair', [
    createSaleItem('p05', 'Spring Garden Arrangement', 'SGA-011', 'Arrangements', 2, 1200, 520),
    createSaleItem('p09', 'Glass Cylinder Vase', 'GCV-020', 'Add-Ons', 2, 450, 180),
  ], 'UPI', 'Amit Kumar', 2, 10),
  
  createSale('FTD', 'Laura Martinez (FTD)', [
    createSaleItem('p04', 'Classic Rose Bouquet', 'CRB-010', 'Bouquets', 1, 850, 380),
    createSaleItem('p13', 'Chocolate Box (Premium)', 'CBP-031', 'Add-Ons', 2, 650, 320),
  ], 'BANK_TRANSFER', 'Ravi Sharma', 2, 11),
  
  createSale('WALK_IN', 'Deepak Kumar', [
    createSaleItem('p06', 'Orchid Phalaenopsis', 'ORC-004', 'Plants', 2, 550, 280),
  ], 'CASH', 'Sneha Patel', 2, 13),
  
  createSale('WEBSITE', 'Sarah Johnson', [
    createSaleItem('p15', 'Sympathy Spray', 'SYS-012', 'Arrangements', 1, 2200, 950),
  ], 'CARD', 'Amit Kumar', 2, 14),
  
  // 3 days ago
  createSale('WALK_IN', 'Arjun Reddy', [
    createSaleItem('p01', 'Red Roses (Premium)', 'RSP-001', 'Fresh Flowers', 6, 280, 120),
    createSaleItem('p03', 'Sunflowers', 'SNF-003', 'Fresh Flowers', 4, 190, 80),
  ], 'UPI', 'Sneha Patel', 3, 10),
  
  createSale('PHONE', 'Sunita Menon', [
    createSaleItem('p04', 'Classic Rose Bouquet', 'CRB-010', 'Bouquets', 1, 850, 380),
  ], 'CARD', 'Ravi Sharma', 3, 11),
  
  createSale('BLOOMNATION', 'Karen Lee (BN)', [
    createSaleItem('p02', 'White Lilies', 'WHL-002', 'Fresh Flowers', 6, 350, 160),
  ], 'BANK_TRANSFER', 'Amit Kumar', 3, 12),
  
  createSale('WALK_IN', 'Vijay Patel', [
    createSaleItem('p07', 'Eucalyptus Bunch', 'EUC-005', 'Greens & Foliage', 5, 210, 90),
    createSaleItem('p08', "Baby's Breath", 'BBR-006', 'Fresh Flowers', 10, 60, 22),
  ], 'CASH', 'Sneha Patel', 3, 14),
  
  // 4 days ago (more sales)
  createSale('WALK_IN', 'Ramesh Gupta', [
    createSaleItem('p01', 'Red Roses (Premium)', 'RSP-001', 'Fresh Flowers', 10, 280, 120),
  ], 'CARD', 'Amit Kumar', 4, 9),
  
  createSale('PHONE', 'Geeta Sharma', [
    createSaleItem('p05', 'Spring Garden Arrangement', 'SGA-011', 'Arrangements', 1, 1200, 520),
  ], 'UPI', 'Ravi Sharma', 4, 11),
  
  createSale('WEBSITE', 'Amit Joshi', [
    createSaleItem('p06', 'Orchid Phalaenopsis', 'ORC-004', 'Plants', 1, 550, 280),
    createSaleItem('p12', 'Teddy Bear (Medium)', 'TBM-030', 'Add-Ons', 1, 480, 200),
  ], 'CARD', 'Sneha Patel', 4, 13),
  
  // 5 days ago
  createSale('WALK_IN', 'Kiran Rao', [
    createSaleItem('p04', 'Classic Rose Bouquet', 'CRB-010', 'Bouquets', 3, 850, 380),
  ], 'CASH', 'Amit Kumar', 5, 10, 150),
  
  createSale('FTD', 'Robert Williams (FTD)', [
    createSaleItem('p15', 'Sympathy Spray', 'SYS-012', 'Arrangements', 1, 2200, 950),
    createSaleItem('p02', 'White Lilies', 'WHL-002', 'Fresh Flowers', 3, 350, 160),
  ], 'BANK_TRANSFER', 'Sneha Patel', 5, 12),
  
  // 6 days ago
  createSale('WALK_IN', 'Prakash Verma', [
    createSaleItem('p01', 'Red Roses (Premium)', 'RSP-001', 'Fresh Flowers', 8, 280, 120),
    createSaleItem('p14', 'Pink Carnations', 'PCN-007', 'Fresh Flowers', 12, 120, 48),
  ], 'UPI', 'Ravi Sharma', 6, 11),
  
  createSale('PHONE', 'Shalini Das', [
    createSaleItem('p16', 'Preserved Rose Box', 'PRB-032', 'Gift Items', 2, 1200, 480),
  ], 'CARD', 'Amit Kumar', 6, 14),
];

// ─── Sales Summary by Day ───────────────────────────────────

export interface DailySalesSummary {
  date: string;
  totalSales: number;
  orderCount: number;
  avgOrderValue: number;
  totalCost: number;
  grossProfit: number;
  marginPercent: number;
  bySource: Record<OrderSource, number>;
  byPayment: Record<PaymentMethod, number>;
  topProducts: Array<{ productName: string; quantity: number; revenue: number }>;
}

export const calculateDailySummary = (sales: SalesTransaction[], date: string): DailySalesSummary => {
  const daySales = sales.filter(s => s.createdAt.startsWith(date));
  
  const totalSales = daySales.reduce((sum, s) => sum + s.total, 0);
  const totalCost = daySales.reduce((sum, s) => sum + s.cost, 0);
  const grossProfit = totalSales - totalCost;
  
  const bySource = daySales.reduce((acc, s) => {
    acc[s.orderSource] = (acc[s.orderSource] || 0) + s.total;
    return acc;
  }, {} as Record<OrderSource, number>);
  
  const byPayment = daySales.reduce((acc, s) => {
    acc[s.paymentMethod] = (acc[s.paymentMethod] || 0) + s.total;
    return acc;
  }, {} as Record<PaymentMethod, number>);
  
  // Aggregate products
  const productMap = new Map<string, { quantity: number; revenue: number }>();
  daySales.forEach(s => {
    s.items.forEach(item => {
      const existing = productMap.get(item.productName) || { quantity: 0, revenue: 0 };
      existing.quantity += item.quantity;
      existing.revenue += item.lineTotal;
      productMap.set(item.productName, existing);
    });
  });
  
  const topProducts = Array.from(productMap.entries())
    .map(([productName, data]) => ({ productName, ...data }))
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, 5);
  
  return {
    date,
    totalSales,
    orderCount: daySales.length,
    avgOrderValue: daySales.length > 0 ? Math.round(totalSales / daySales.length) : 0,
    totalCost,
    grossProfit,
    marginPercent: totalSales > 0 ? Math.round((grossProfit / totalSales) * 100) : 0,
    bySource,
    byPayment,
    topProducts,
  };
};

// ─── Generate Daily Summaries ───────────────────────────────

const getDates = (days: number): string[] => {
  const dates: string[] = [];
  for (let i = 0; i < days; i++) {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    dates.push(isoDate(d));
  }
  return dates;
};

export const MOCK_DAILY_SUMMARIES: DailySalesSummary[] = getDates(7).map(date => 
  calculateDailySummary(MOCK_SALES_TRANSACTIONS, date)
);

// ─── Hourly Sales (Today) ───────────────────────────────────

export interface HourlySales {
  hour: string;
  sales: number;
  orderCount: number;
}

export const MOCK_HOURLY_SALES: HourlySales[] = [
  { hour: '9 AM', sales: 2850, orderCount: 2 },
  { hour: '10 AM', sales: 4200, orderCount: 3 },
  { hour: '11 AM', sales: 3500, orderCount: 2 },
  { hour: '12 PM', sales: 5800, orderCount: 4 },
  { hour: '1 PM', sales: 3200, orderCount: 2 },
  { hour: '2 PM', sales: 4500, orderCount: 3 },
  { hour: '3 PM', sales: 2800, orderCount: 2 },
  { hour: '4 PM', sales: 6200, orderCount: 4 },
  { hour: '5 PM', sales: 2550, orderCount: 2 },
];

// ─── Cashier Performance ────────────────────────────────────

export interface CashierPerformance {
  cashierId: string;
  cashierName: string;
  totalSales: number;
  orderCount: number;
  avgOrderValue: number;
  itemsSold: number;
}

export const calculateCashierPerformance = (sales: SalesTransaction[]): CashierPerformance[] => {
  const cashierMap = new Map<string, { name: string; sales: number; orders: number; items: number }>();
  
  sales.forEach(s => {
    const existing = cashierMap.get(s.cashierId) || { name: s.cashierName, sales: 0, orders: 0, items: 0 };
    existing.sales += s.total;
    existing.orders += 1;
    existing.items += s.items.reduce((sum, i) => sum + i.quantity, 0);
    cashierMap.set(s.cashierId, existing);
  });
  
  return Array.from(cashierMap.entries())
    .map(([cashierId, data]) => ({
      cashierId,
      cashierName: data.name,
      totalSales: data.sales,
      orderCount: data.orders,
      avgOrderValue: Math.round(data.sales / data.orders),
      itemsSold: data.items,
    }))
    .sort((a, b) => b.totalSales - a.totalSales);
};

export const MOCK_CASHIER_PERFORMANCE = calculateCashierPerformance(MOCK_SALES_TRANSACTIONS);

// ─── Mock API Functions ─────────────────────────────────────

export const fetchSalesTransactions = (filters?: {
  startDate?: string;
  endDate?: string;
  orderSource?: OrderSource;
  paymentMethod?: PaymentMethod;
  cashierId?: string;
}): Promise<SalesTransaction[]> =>
  new Promise(resolve => setTimeout(() => {
    let results = [...MOCK_SALES_TRANSACTIONS];
    if (filters?.startDate) results = results.filter(s => s.createdAt >= filters.startDate!);
    if (filters?.endDate) results = results.filter(s => s.createdAt <= filters.endDate!);
    if (filters?.orderSource) results = results.filter(s => s.orderSource === filters.orderSource);
    if (filters?.paymentMethod) results = results.filter(s => s.paymentMethod === filters.paymentMethod);
    if (filters?.cashierId) results = results.filter(s => s.cashierId === filters.cashierId);
    resolve(results);
  }, 500));

export const fetchDailySummaries = (days: number = 7): Promise<DailySalesSummary[]> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_DAILY_SUMMARIES.slice(0, days)), 400));

export const fetchHourlySales = (): Promise<HourlySales[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_HOURLY_SALES]), 300));

export const fetchCashierPerformance = (): Promise<CashierPerformance[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_CASHIER_PERFORMANCE]), 300));

export const fetchTodaySalesTotal = (): Promise<number> =>
  new Promise(resolve => setTimeout(() => {
    const todayStr = isoDate(today);
    const total = MOCK_SALES_TRANSACTIONS
      .filter(s => s.createdAt.startsWith(todayStr))
      .reduce((sum, s) => sum + s.total, 0);
    resolve(total);
  }, 200));
