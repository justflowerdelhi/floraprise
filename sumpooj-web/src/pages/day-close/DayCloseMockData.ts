/**
 * Day Close Mock Data
 * Test data for Day Close / End-of-Day Reconciliation module
 * Florist POS + ERP SaaS Platform
 */

import type { DayCloseStatus } from '../../core/audit/AuditTypes';

const today = new Date();
const isoDate = (d: Date) => d.toISOString().slice(0, 10);
const daysAgo = (n: number) => {
  const d = new Date(today);
  d.setDate(d.getDate() - n);
  return isoDate(d);
};

// ─── Payment Method Breakdown ───────────────────────────────

export interface PaymentMethodBreakdown {
  method: string;
  icon: string;
  expected: number;
  actual: number;
  difference: number;
  count: number;
}

// ─── Day Close Summary Record ───────────────────────────────

export interface DayCloseSummary {
  id: string;
  locationId: string;
  businessDate: string;
  status: DayCloseStatus;
  
  // Sales Summary
  totalSales: number;
  grossRevenue: number;
  netRevenue: number;
  taxCollected: number;
  discountsGiven: number;
  refundsProcessed: number;
  
  // Order Counts
  totalOrders: number;
  walkInOrders: number;
  phoneOrders: number;
  onlineOrders: number;
  wireInOrders: number;
  wireOutOrders: number;
  
  // Payments
  paymentBreakdown: PaymentMethodBreakdown[];
  expectedCash: number;
  actualCash: number;
  cashVariance: number;
  
  // Staff Performance
  staffSales: StaffSaleSummary[];
  
  // Notes & Audit
  notes?: string;
  closedBy?: string;
  closedAt?: string;
  reopenedBy?: string;
  reopenedAt?: string;
  reopenReason?: string;
}

export interface StaffSaleSummary {
  staffId: string;
  staffName: string;
  orderCount: number;
  totalSales: number;
  avgOrderValue: number;
}

// ─── Mock Day Close Records ─────────────────────────────────

export const MOCK_DAY_CLOSE_RECORDS: DayCloseSummary[] = [
  // Today - Still Open
  {
    id: 'dc_001',
    locationId: 'loc_main',
    businessDate: daysAgo(0),
    status: 'OPEN',
    totalSales: 28450,
    grossRevenue: 30000,
    netRevenue: 28450,
    taxCollected: 1422.50,
    discountsGiven: 1550,
    refundsProcessed: 0,
    totalOrders: 18,
    walkInOrders: 12,
    phoneOrders: 4,
    onlineOrders: 2,
    wireInOrders: 0,
    wireOutOrders: 0,
    paymentBreakdown: [
      { method: 'Cash', icon: 'Cash', expected: 8500, actual: 0, difference: 0, count: 6 },
      { method: 'Card', icon: 'CreditCard', expected: 12350, actual: 12350, difference: 0, count: 8 },
      { method: 'UPI', icon: 'Smartphone', expected: 5200, actual: 5200, difference: 0, count: 3 },
      { method: 'Bank Transfer', icon: 'AccountBalance', expected: 2400, actual: 2400, difference: 0, count: 1 },
    ],
    expectedCash: 8500,
    actualCash: 0,
    cashVariance: 0,
    staffSales: [
      { staffId: 'staff_001', staffName: 'Priya Sharma', orderCount: 7, totalSales: 12500, avgOrderValue: 1785 },
      { staffId: 'staff_002', staffName: 'Anita Patel', orderCount: 6, totalSales: 9800, avgOrderValue: 1633 },
      { staffId: 'staff_003', staffName: 'Ravi Kumar', orderCount: 5, totalSales: 6150, avgOrderValue: 1230 },
    ],
  },
  // Yesterday - Closed
  {
    id: 'dc_002',
    locationId: 'loc_main',
    businessDate: daysAgo(1),
    status: 'CLOSED',
    totalSales: 42680,
    grossRevenue: 45000,
    netRevenue: 42680,
    taxCollected: 2134,
    discountsGiven: 2320,
    refundsProcessed: 850,
    totalOrders: 28,
    walkInOrders: 18,
    phoneOrders: 6,
    onlineOrders: 3,
    wireInOrders: 1,
    wireOutOrders: 0,
    paymentBreakdown: [
      { method: 'Cash', icon: 'Cash', expected: 14200, actual: 14150, difference: -50, count: 12 },
      { method: 'Card', icon: 'CreditCard', expected: 18500, actual: 18500, difference: 0, count: 10 },
      { method: 'UPI', icon: 'Smartphone', expected: 7480, actual: 7480, difference: 0, count: 4 },
      { method: 'Bank Transfer', icon: 'AccountBalance', expected: 2500, actual: 2500, difference: 0, count: 2 },
    ],
    expectedCash: 14200,
    actualCash: 14150,
    cashVariance: -50,
    staffSales: [
      { staffId: 'staff_001', staffName: 'Priya Sharma', orderCount: 10, totalSales: 18200, avgOrderValue: 1820 },
      { staffId: 'staff_002', staffName: 'Anita Patel', orderCount: 9, totalSales: 14300, avgOrderValue: 1588 },
      { staffId: 'staff_003', staffName: 'Ravi Kumar', orderCount: 6, totalSales: 7500, avgOrderValue: 1250 },
      { staffId: 'staff_004', staffName: 'Neha Gupta', orderCount: 3, totalSales: 2680, avgOrderValue: 893 },
    ],
    notes: 'Minor cash shortage - ₹50 (count error during rush hour)',
    closedBy: 'Priya Sharma',
    closedAt: `${daysAgo(1)}T21:15:00Z`,
  },
  // 2 Days Ago - Closed (Valentine's Week - High Sales)
  {
    id: 'dc_003',
    locationId: 'loc_main',
    businessDate: daysAgo(2),
    status: 'CLOSED',
    totalSales: 68500,
    grossRevenue: 72000,
    netRevenue: 68500,
    taxCollected: 3425,
    discountsGiven: 3500,
    refundsProcessed: 1200,
    totalOrders: 45,
    walkInOrders: 30,
    phoneOrders: 10,
    onlineOrders: 4,
    wireInOrders: 1,
    wireOutOrders: 0,
    paymentBreakdown: [
      { method: 'Cash', icon: 'Cash', expected: 22500, actual: 22500, difference: 0, count: 20 },
      { method: 'Card', icon: 'CreditCard', expected: 28000, actual: 28000, difference: 0, count: 15 },
      { method: 'UPI', icon: 'Smartphone', expected: 14000, actual: 14000, difference: 0, count: 8 },
      { method: 'Bank Transfer', icon: 'AccountBalance', expected: 4000, actual: 4000, difference: 0, count: 2 },
    ],
    expectedCash: 22500,
    actualCash: 22500,
    cashVariance: 0,
    staffSales: [
      { staffId: 'staff_001', staffName: 'Priya Sharma', orderCount: 15, totalSales: 28000, avgOrderValue: 1867 },
      { staffId: 'staff_002', staffName: 'Anita Patel', orderCount: 12, totalSales: 20500, avgOrderValue: 1708 },
      { staffId: 'staff_003', staffName: 'Ravi Kumar', orderCount: 10, totalSales: 12000, avgOrderValue: 1200 },
      { staffId: 'staff_004', staffName: 'Neha Gupta', orderCount: 8, totalSales: 8000, avgOrderValue: 1000 },
    ],
    notes: 'Valentine\'s week - Record sales day!',
    closedBy: 'Anita Patel',
    closedAt: `${daysAgo(2)}T22:30:00Z`,
  },
  // 3 Days Ago - Reopened then Closed
  {
    id: 'dc_004',
    locationId: 'loc_main',
    businessDate: daysAgo(3),
    status: 'CLOSED',
    totalSales: 35200,
    grossRevenue: 37000,
    netRevenue: 35200,
    taxCollected: 1760,
    discountsGiven: 1800,
    refundsProcessed: 0,
    totalOrders: 24,
    walkInOrders: 16,
    phoneOrders: 5,
    onlineOrders: 2,
    wireInOrders: 0,
    wireOutOrders: 1,
    paymentBreakdown: [
      { method: 'Cash', icon: 'Cash', expected: 12000, actual: 12150, difference: 150, count: 10 },
      { method: 'Card', icon: 'CreditCard', expected: 15200, actual: 15200, difference: 0, count: 9 },
      { method: 'UPI', icon: 'Smartphone', expected: 6000, actual: 6000, difference: 0, count: 4 },
      { method: 'Bank Transfer', icon: 'AccountBalance', expected: 2000, actual: 2000, difference: 0, count: 1 },
    ],
    expectedCash: 12000,
    actualCash: 12150,
    cashVariance: 150,
    staffSales: [
      { staffId: 'staff_001', staffName: 'Priya Sharma', orderCount: 9, totalSales: 15000, avgOrderValue: 1667 },
      { staffId: 'staff_002', staffName: 'Anita Patel', orderCount: 8, totalSales: 12200, avgOrderValue: 1525 },
      { staffId: 'staff_003', staffName: 'Ravi Kumar', orderCount: 7, totalSales: 8000, avgOrderValue: 1143 },
    ],
    notes: 'Cash overage of ₹150 found - customer tip uncounted',
    closedBy: 'Priya Sharma',
    closedAt: `${daysAgo(3)}T21:45:00Z`,
    reopenedBy: 'Manager',
    reopenedAt: `${daysAgo(2)}T09:00:00Z`,
    reopenReason: 'Missed wire order entry - added and reclosed',
  },
  // 4 Days Ago - Closed
  {
    id: 'dc_005',
    locationId: 'loc_main',
    businessDate: daysAgo(4),
    status: 'CLOSED',
    totalSales: 29800,
    grossRevenue: 31500,
    netRevenue: 29800,
    taxCollected: 1490,
    discountsGiven: 1700,
    refundsProcessed: 500,
    totalOrders: 20,
    walkInOrders: 14,
    phoneOrders: 4,
    onlineOrders: 2,
    wireInOrders: 0,
    wireOutOrders: 0,
    paymentBreakdown: [
      { method: 'Cash', icon: 'Cash', expected: 10500, actual: 10500, difference: 0, count: 9 },
      { method: 'Card', icon: 'CreditCard', expected: 12800, actual: 12800, difference: 0, count: 7 },
      { method: 'UPI', icon: 'Smartphone', expected: 4500, actual: 4500, difference: 0, count: 3 },
      { method: 'Bank Transfer', icon: 'AccountBalance', expected: 2000, actual: 2000, difference: 0, count: 1 },
    ],
    expectedCash: 10500,
    actualCash: 10500,
    cashVariance: 0,
    staffSales: [
      { staffId: 'staff_001', staffName: 'Priya Sharma', orderCount: 8, totalSales: 13500, avgOrderValue: 1688 },
      { staffId: 'staff_002', staffName: 'Anita Patel', orderCount: 7, totalSales: 10300, avgOrderValue: 1471 },
      { staffId: 'staff_003', staffName: 'Ravi Kumar', orderCount: 5, totalSales: 6000, avgOrderValue: 1200 },
    ],
    closedBy: 'Ravi Kumar',
    closedAt: `${daysAgo(4)}T21:00:00Z`,
  },
  // 5 Days Ago - Closed
  {
    id: 'dc_006',
    locationId: 'loc_main',
    businessDate: daysAgo(5),
    status: 'CLOSED',
    totalSales: 31500,
    grossRevenue: 33000,
    netRevenue: 31500,
    taxCollected: 1575,
    discountsGiven: 1500,
    refundsProcessed: 0,
    totalOrders: 22,
    walkInOrders: 15,
    phoneOrders: 5,
    onlineOrders: 2,
    wireInOrders: 0,
    wireOutOrders: 0,
    paymentBreakdown: [
      { method: 'Cash', icon: 'Cash', expected: 11200, actual: 11200, difference: 0, count: 10 },
      { method: 'Card', icon: 'CreditCard', expected: 13000, actual: 13000, difference: 0, count: 8 },
      { method: 'UPI', icon: 'Smartphone', expected: 5300, actual: 5300, difference: 0, count: 3 },
      { method: 'Bank Transfer', icon: 'AccountBalance', expected: 2000, actual: 2000, difference: 0, count: 1 },
    ],
    expectedCash: 11200,
    actualCash: 11200,
    cashVariance: 0,
    staffSales: [
      { staffId: 'staff_001', staffName: 'Priya Sharma', orderCount: 9, totalSales: 14200, avgOrderValue: 1578 },
      { staffId: 'staff_002', staffName: 'Anita Patel', orderCount: 8, totalSales: 11000, avgOrderValue: 1375 },
      { staffId: 'staff_003', staffName: 'Ravi Kumar', orderCount: 5, totalSales: 6300, avgOrderValue: 1260 },
    ],
    closedBy: 'Anita Patel',
    closedAt: `${daysAgo(5)}T21:30:00Z`,
  },
  // 6 Days Ago - Closed
  {
    id: 'dc_007',
    locationId: 'loc_main',
    businessDate: daysAgo(6),
    status: 'CLOSED',
    totalSales: 26800,
    grossRevenue: 28500,
    netRevenue: 26800,
    taxCollected: 1340,
    discountsGiven: 1700,
    refundsProcessed: 350,
    totalOrders: 18,
    walkInOrders: 12,
    phoneOrders: 4,
    onlineOrders: 2,
    wireInOrders: 0,
    wireOutOrders: 0,
    paymentBreakdown: [
      { method: 'Cash', icon: 'Cash', expected: 9500, actual: 9500, difference: 0, count: 8 },
      { method: 'Card', icon: 'CreditCard', expected: 11300, actual: 11300, difference: 0, count: 6 },
      { method: 'UPI', icon: 'Smartphone', expected: 4000, actual: 4000, difference: 0, count: 3 },
      { method: 'Bank Transfer', icon: 'AccountBalance', expected: 2000, actual: 2000, difference: 0, count: 1 },
    ],
    expectedCash: 9500,
    actualCash: 9500,
    cashVariance: 0,
    staffSales: [
      { staffId: 'staff_001', staffName: 'Priya Sharma', orderCount: 7, totalSales: 11500, avgOrderValue: 1643 },
      { staffId: 'staff_002', staffName: 'Anita Patel', orderCount: 6, totalSales: 9300, avgOrderValue: 1550 },
      { staffId: 'staff_003', staffName: 'Ravi Kumar', orderCount: 5, totalSales: 6000, avgOrderValue: 1200 },
    ],
    closedBy: 'Priya Sharma',
    closedAt: `${daysAgo(6)}T21:15:00Z`,
  },
];

// ─── Day Close Summary Stats ────────────────────────────────

export interface DayCloseOverview {
  currentDayStatus: DayCloseStatus;
  currentDaySales: number;
  weekTotalSales: number;
  weekTotalOrders: number;
  weekAvgDailySales: number;
  weekCashVarianceTotal: number;
  monthToDateSales: number;
}

export const calculateDayCloseOverview = (records: DayCloseSummary[]): DayCloseOverview => {
  const todayRecord = records.find(r => r.businessDate === daysAgo(0));
  const weekRecords = records.filter(r => {
    const recordDate = new Date(r.businessDate);
    const weekAgo = new Date(today);
    weekAgo.setDate(weekAgo.getDate() - 7);
    return recordDate >= weekAgo;
  });

  return {
    currentDayStatus: todayRecord?.status || 'OPEN',
    currentDaySales: todayRecord?.totalSales || 0,
    weekTotalSales: weekRecords.reduce((sum, r) => sum + r.totalSales, 0),
    weekTotalOrders: weekRecords.reduce((sum, r) => sum + r.totalOrders, 0),
    weekAvgDailySales: weekRecords.length > 0 ? weekRecords.reduce((sum, r) => sum + r.totalSales, 0) / weekRecords.length : 0,
    weekCashVarianceTotal: weekRecords.reduce((sum, r) => sum + r.cashVariance, 0),
    monthToDateSales: records.reduce((sum, r) => sum + r.totalSales, 0),
  };
};

export const MOCK_DAY_CLOSE_OVERVIEW = calculateDayCloseOverview(MOCK_DAY_CLOSE_RECORDS);

// ─── Mock API Functions ─────────────────────────────────────

export const fetchDayCloseSummary = (date?: string): Promise<DayCloseSummary | null> =>
  new Promise(resolve => setTimeout(() => {
    const targetDate = date || daysAgo(0);
    const record = MOCK_DAY_CLOSE_RECORDS.find(r => r.businessDate === targetDate);
    resolve(record || null);
  }, 400));

export const fetchDayCloseHistory = (days: number = 7): Promise<DayCloseSummary[]> =>
  new Promise(resolve => setTimeout(() => {
    const cutoffDate = new Date(today);
    cutoffDate.setDate(cutoffDate.getDate() - days);
    const records = MOCK_DAY_CLOSE_RECORDS.filter(r => new Date(r.businessDate) >= cutoffDate);
    resolve(records);
  }, 500));

export const fetchDayCloseOverview = (): Promise<DayCloseOverview> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_DAY_CLOSE_OVERVIEW), 300));

export const isDayClosedMock = (date?: string): Promise<boolean> =>
  new Promise(resolve => setTimeout(() => {
    const targetDate = date || daysAgo(0);
    const record = MOCK_DAY_CLOSE_RECORDS.find(r => r.businessDate === targetDate);
    resolve(record?.status === 'CLOSED');
  }, 200));
