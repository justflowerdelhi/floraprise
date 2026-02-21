/**
 * Dashboard Mock Data
 * Test data for all role-based dashboards
 * Florist POS + ERP SaaS Platform
 */

import type {
  AdminDashboardData,
  ManagerDashboardData,
  DesignerDashboardData,
  CashierDashboardData,
  DriverDashboardData,
  DashboardResponse,
  SalesTrendPoint,
  OperationAlert,
  ProductionTask,
  DeliveryItem,
} from './dashboardApi';

const today = new Date();
const formatDay = (daysAgo: number) => {
  const d = new Date(today);
  d.setDate(d.getDate() - daysAgo);
  return d.toLocaleDateString('en-IN', { weekday: 'short' });
};

// ─── Sales Trend Data (Last 7 Days) ─────────────────────────

export const MOCK_SALES_TREND: SalesTrendPoint[] = [
  { day: formatDay(6), sales: 42500 },
  { day: formatDay(5), sales: 38200 },
  { day: formatDay(4), sales: 55800 },
  { day: formatDay(3), sales: 61200 },
  { day: formatDay(2), sales: 48500 },
  { day: formatDay(1), sales: 52300 },
  { day: 'Today', sales: 35600 },
];

// ─── Operation Alerts ───────────────────────────────────────

export const MOCK_ALERTS: OperationAlert[] = [
  {
    id: 'alert_001',
    type: 'expiry',
    message: '15 Red Rose batches expiring in 2 days',
    severity: 'critical',
    href: '/inventory?filter=expiring',
  },
  {
    id: 'alert_002',
    type: 'low_stock',
    message: 'White Lilies below reorder point (35 stems)',
    severity: 'warning',
    href: '/inventory?product=lily',
  },
  {
    id: 'alert_003',
    type: 'delivery',
    message: '3 deliveries scheduled for next 2 hours',
    severity: 'info',
    href: '/orders?tab=deliveries',
  },
  {
    id: 'alert_004',
    type: 'production',
    message: '2 wedding arrangements pending design',
    severity: 'warning',
    href: '/production',
  },
  {
    id: 'alert_005',
    type: 'expiry',
    message: 'Eucalyptus batch expires tomorrow',
    severity: 'warning',
    href: '/inventory?batch=euc-001',
  },
  {
    id: 'alert_006',
    type: 'low_stock',
    message: 'Floral foam running low (12 blocks)',
    severity: 'info',
    href: '/inventory?category=supplies',
  },
];

// ─── Production Tasks ───────────────────────────────────────

export const MOCK_PRODUCTION_TASKS: ProductionTask[] = [
  {
    id: 'task_001',
    title: 'Anniversary Rose Bouquet',
    type: 'bouquet',
    status: 'in_progress',
    dueTime: '11:00 AM',
    priority: 'high',
    notes: 'Customer requested extra baby breath',
  },
  {
    id: 'task_002',
    title: 'Spring Garden Arrangement',
    type: 'arrangement',
    status: 'pending',
    dueTime: '1:00 PM',
    priority: 'medium',
  },
  {
    id: 'task_003',
    title: 'Sharma Wedding Centerpieces (x8)',
    type: 'wedding',
    status: 'pending',
    dueTime: '4:00 PM',
    priority: 'high',
    notes: 'White & gold theme, delivery tomorrow 8 AM',
  },
  {
    id: 'task_004',
    title: 'Custom Orchid Arrangement',
    type: 'custom',
    status: 'pending',
    dueTime: '3:00 PM',
    priority: 'medium',
    notes: 'Mixed orchids in ceramic pot',
  },
  {
    id: 'task_005',
    title: 'Get Well Basket',
    type: 'arrangement',
    status: 'completed',
    dueTime: '10:00 AM',
    priority: 'low',
  },
  {
    id: 'task_006',
    title: 'Cooler Maintenance Check',
    type: 'maintenance',
    status: 'pending',
    priority: 'low',
    notes: 'Weekly temperature calibration',
  },
];

export const MOCK_WEDDING_TASKS: ProductionTask[] = [
  {
    id: 'wed_001',
    title: 'Sharma Wedding - Bridal Bouquet',
    type: 'wedding',
    status: 'in_progress',
    dueTime: '6:00 PM',
    priority: 'high',
    notes: 'White roses with trailing greenery',
  },
  {
    id: 'wed_002',
    title: 'Sharma Wedding - Bridesmaid Bouquets (x4)',
    type: 'wedding',
    status: 'pending',
    dueTime: '6:00 PM',
    priority: 'high',
    notes: 'Smaller version of bridal',
  },
  {
    id: 'wed_003',
    title: 'Sharma Wedding - Arch Decoration',
    type: 'wedding',
    status: 'pending',
    dueTime: 'Tomorrow 6 AM',
    priority: 'high',
  },
];

export const MOCK_CUSTOM_ORDERS: ProductionTask[] = [
  {
    id: 'cust_001',
    title: 'Corporate Logo Arrangement - TechCorp',
    type: 'custom',
    status: 'pending',
    dueTime: '2:00 PM',
    priority: 'high',
    notes: 'Use blue & white flowers only',
  },
  {
    id: 'cust_002',
    title: 'Birthday Cake Topper Flowers',
    type: 'custom',
    status: 'in_progress',
    dueTime: '12:00 PM',
    priority: 'medium',
  },
];

// ─── Delivery Items ─────────────────────────────────────────

export const MOCK_DELIVERIES: DeliveryItem[] = [
  {
    id: 'del_001',
    orderNumber: 'ORD-2026-0045',
    customerName: 'Priya Kapoor',
    phone: '+91 98765 43210',
    address: '45 MG Road, Koregaon Park, Pune 411001',
    timeSlot: '10:00 AM - 12:00 PM',
    status: 'pending',
    notes: 'Call before arrival',
    items: 'Classic Rose Bouquet, Chocolate Box',
  },
  {
    id: 'del_002',
    orderNumber: 'ORD-2026-0046',
    customerName: 'Jennifer Smith',
    phone: '+91 88776 65544',
    address: '12 Palm Drive, Baner Road, Pune 411045',
    timeSlot: '10:00 AM - 12:00 PM',
    status: 'pending',
    items: 'Spring Garden Arrangement',
  },
  {
    id: 'del_003',
    orderNumber: 'ORD-2026-0041',
    customerName: 'Rahul Mehta',
    phone: '+91 77665 54433',
    address: '88 Baner Road, Pune 411045',
    timeSlot: '12:00 PM - 2:00 PM',
    status: 'pending',
    notes: 'Gate code: 4521',
    items: 'Orchid Phalaenopsis, Glass Vase',
  },
  {
    id: 'del_004',
    orderNumber: 'ORD-2026-0038',
    customerName: 'Anita Sharma',
    phone: '+91 99001 12233',
    address: '33 Koregaon Park, Pune 411001',
    timeSlot: '9:00 AM - 10:00 AM',
    status: 'delivered',
    items: 'Birthday Arrangement',
  },
  {
    id: 'del_005',
    orderNumber: 'ORD-2026-0039',
    customerName: 'Vikram Singh',
    phone: '+91 65432 10987',
    address: '78 Shivaji Nagar, Pune 411005',
    timeSlot: '2:00 PM - 4:00 PM',
    status: 'pending',
    items: 'Sympathy Spray, Condolence Card',
  },
  {
    id: 'del_006',
    orderNumber: 'ORD-2026-0036',
    customerName: 'Meera Kapoor',
    phone: '+91 54321 09876',
    address: '15 FC Road, Pune 411004',
    timeSlot: '9:00 AM - 11:00 AM',
    status: 'failed',
    notes: 'Customer not available, rescheduled for tomorrow',
    items: 'Mixed Bouquet',
  },
];

// ─── Admin Dashboard Data ───────────────────────────────────

export const MOCK_ADMIN_DASHBOARD: AdminDashboardData = {
  todaySales: 35600,
  monthRevenue: 842500,
  grossProfitToday: 14240, // ~40% margin
  inventoryValue: 285000,
  wastageToday: 1200,
  networkOrdersPending: 5,
  expiringBouquets: 8,
  upcomingWeddings: 3,
  salesTrend: MOCK_SALES_TREND,
};

// ─── Manager Dashboard Data ─────────────────────────────────

export const MOCK_MANAGER_DASHBOARD: ManagerDashboardData = {
  ordersToFulfill: 12,
  deliveriesScheduled: 8,
  productionPending: 6,
  lowStockAlerts: 4,
  expiringBatches: 15,
  staffTasksPending: 9,
  topAlerts: MOCK_ALERTS,
};

// ─── Designer Dashboard Data ────────────────────────────────

export const MOCK_DESIGNER_DASHBOARD: DesignerDashboardData = {
  productionTasks: MOCK_PRODUCTION_TASKS.filter(t => !['wedding', 'custom'].includes(t.type)),
  weddingPrepTasks: MOCK_WEDDING_TASKS,
  maintenanceRequired: 1,
  expiringBouquets: 8,
  customOrders: MOCK_CUSTOM_ORDERS,
};

// ─── Cashier Dashboard Data ─────────────────────────────────

export const MOCK_CASHIER_DASHBOARD: CashierDashboardData = {
  pendingPickups: 3,
  unpaidOrders: 5,
  todaySalesCount: 18,
  todaySalesTotal: 35600,
};

// ─── Driver Dashboard Data ──────────────────────────────────

export const MOCK_DRIVER_DASHBOARD: DriverDashboardData = {
  deliveries: MOCK_DELIVERIES,
  completedCount: 1,
  pendingCount: 4,
  failedCount: 1,
};

// ─── Mock API Response by Role ──────────────────────────────

export const getMockDashboard = (role: string): DashboardResponse => {
  switch (role.toUpperCase()) {
    case 'ADMIN':
      return { role: 'ADMIN', data: MOCK_ADMIN_DASHBOARD };
    case 'MANAGER':
      return { role: 'MANAGER', data: MOCK_MANAGER_DASHBOARD };
    case 'DESIGNER':
      return { role: 'DESIGNER', data: MOCK_DESIGNER_DASHBOARD };
    case 'CASHIER':
      return { role: 'CASHIER', data: MOCK_CASHIER_DASHBOARD };
    case 'DRIVER':
      return { role: 'DRIVER', data: MOCK_DRIVER_DASHBOARD };
    default:
      return { role: 'ADMIN', data: MOCK_ADMIN_DASHBOARD };
  }
};

// ─── Extended Sales Data for Reports ────────────────────────

export interface DailySalesRecord {
  date: string;
  totalSales: number;
  orderCount: number;
  avgOrderValue: number;
  grossProfit: number;
  marginPercent: number;
  walkInSales: number;
  phoneSales: number;
  onlineSales: number;
  wireSales: number;
}

export const MOCK_DAILY_SALES: DailySalesRecord[] = [
  { date: '2026-02-21', totalSales: 35600, orderCount: 18, avgOrderValue: 1978, grossProfit: 14240, marginPercent: 40, walkInSales: 15200, phoneSales: 8500, onlineSales: 6400, wireSales: 5500 },
  { date: '2026-02-20', totalSales: 52300, orderCount: 24, avgOrderValue: 2179, grossProfit: 21440, marginPercent: 41, walkInSales: 22100, phoneSales: 12500, onlineSales: 9200, wireSales: 8500 },
  { date: '2026-02-19', totalSales: 48500, orderCount: 22, avgOrderValue: 2205, grossProfit: 19400, marginPercent: 40, walkInSales: 18500, phoneSales: 14200, onlineSales: 8800, wireSales: 7000 },
  { date: '2026-02-18', totalSales: 61200, orderCount: 28, avgOrderValue: 2186, grossProfit: 25704, marginPercent: 42, walkInSales: 25800, phoneSales: 15600, onlineSales: 12300, wireSales: 7500 },
  { date: '2026-02-17', totalSales: 55800, orderCount: 26, avgOrderValue: 2146, grossProfit: 22320, marginPercent: 40, walkInSales: 21200, phoneSales: 16500, onlineSales: 10600, wireSales: 7500 },
  { date: '2026-02-16', totalSales: 38200, orderCount: 19, avgOrderValue: 2011, grossProfit: 14708, marginPercent: 39, walkInSales: 15800, phoneSales: 9500, onlineSales: 7400, wireSales: 5500 },
  { date: '2026-02-15', totalSales: 42500, orderCount: 21, avgOrderValue: 2024, grossProfit: 16575, marginPercent: 39, walkInSales: 18200, phoneSales: 10800, onlineSales: 8000, wireSales: 5500 },
  { date: '2026-02-14', totalSales: 125000, orderCount: 65, avgOrderValue: 1923, grossProfit: 52500, marginPercent: 42, walkInSales: 55000, phoneSales: 35000, onlineSales: 22000, wireSales: 13000 }, // Valentine's Day
  { date: '2026-02-13', totalSales: 68500, orderCount: 32, avgOrderValue: 2141, grossProfit: 27400, marginPercent: 40, walkInSales: 28500, phoneSales: 18200, onlineSales: 13800, wireSales: 8000 },
  { date: '2026-02-12', totalSales: 45800, orderCount: 23, avgOrderValue: 1991, grossProfit: 18320, marginPercent: 40, walkInSales: 19200, phoneSales: 12500, onlineSales: 8600, wireSales: 5500 },
];

// ─── Monthly Summary ────────────────────────────────────────

export interface MonthlySalesSummary {
  month: string;
  totalSales: number;
  orderCount: number;
  avgOrderValue: number;
  grossProfit: number;
  topCategory: string;
  topProduct: string;
}

export const MOCK_MONTHLY_SUMMARY: MonthlySalesSummary[] = [
  { month: '2026-02', totalSales: 842500, orderCount: 412, avgOrderValue: 2045, grossProfit: 337000, topCategory: 'Bouquets', topProduct: 'Classic Rose Bouquet' },
  { month: '2026-01', totalSales: 725000, orderCount: 358, avgOrderValue: 2025, grossProfit: 283750, topCategory: 'Arrangements', topProduct: 'Spring Garden Arrangement' },
  { month: '2025-12', totalSales: 985000, orderCount: 485, avgOrderValue: 2031, grossProfit: 403850, topCategory: 'Bouquets', topProduct: 'Classic Rose Bouquet' },
  { month: '2025-11', totalSales: 682000, orderCount: 342, avgOrderValue: 1994, grossProfit: 266380, topCategory: 'Fresh Flowers', topProduct: 'Red Roses (Premium)' },
  { month: '2025-10', totalSales: 658000, orderCount: 335, avgOrderValue: 1964, grossProfit: 256620, topCategory: 'Fresh Flowers', topProduct: 'White Lilies' },
  { month: '2025-09', totalSales: 612000, orderCount: 312, avgOrderValue: 1962, grossProfit: 238680, topCategory: 'Arrangements', topProduct: 'Sympathy Spray' },
];

// ─── Category Sales Breakdown ───────────────────────────────

export interface CategorySales {
  category: string;
  todaySales: number;
  monthSales: number;
  orderCount: number;
  marginPercent: number;
}

export const MOCK_CATEGORY_SALES: CategorySales[] = [
  { category: 'Fresh Flowers', todaySales: 12500, monthSales: 285000, orderCount: 145, marginPercent: 58 },
  { category: 'Bouquets', todaySales: 8500, monthSales: 225000, orderCount: 85, marginPercent: 55 },
  { category: 'Arrangements', todaySales: 6200, monthSales: 168000, orderCount: 62, marginPercent: 52 },
  { category: 'Plants', todaySales: 3800, monthSales: 82000, orderCount: 45, marginPercent: 48 },
  { category: 'Add-Ons', todaySales: 2600, monthSales: 52000, orderCount: 48, marginPercent: 45 },
  { category: 'Gift Items', todaySales: 2000, monthSales: 30500, orderCount: 27, marginPercent: 42 },
];

// ─── Mock API Functions ─────────────────────────────────────

export const fetchMockDashboard = (role: string): Promise<DashboardResponse> =>
  new Promise(resolve => setTimeout(() => resolve(getMockDashboard(role)), 500));

export const fetchDailySales = (startDate?: string, endDate?: string): Promise<DailySalesRecord[]> =>
  new Promise(resolve => setTimeout(() => {
    let results = [...MOCK_DAILY_SALES];
    if (startDate) results = results.filter(r => r.date >= startDate);
    if (endDate) results = results.filter(r => r.date <= endDate);
    resolve(results);
  }, 400));

export const fetchMonthlySummary = (): Promise<MonthlySalesSummary[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_MONTHLY_SUMMARY]), 400));

export const fetchCategorySales = (): Promise<CategorySales[]> =>
  new Promise(resolve => setTimeout(() => resolve([...MOCK_CATEGORY_SALES]), 300));

export const fetchSalesTrend = (days: number = 7): Promise<SalesTrendPoint[]> =>
  new Promise(resolve => setTimeout(() => resolve(MOCK_SALES_TREND.slice(-days)), 300));
