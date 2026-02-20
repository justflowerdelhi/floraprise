/**
 * dashboardApi.ts — Dashboard Data Types & Mock API
 *
 * Single API call per role. Location-aware. No hardcoded tenant logic.
 */

// ─── Shared Types ───────────────────────────────────────────

export interface DashboardCard {
  label: string;
  value: string | number;
  change?: number;          // % change vs yesterday/last period
  href?: string;            // navigate on click
  color?: string;           // accent color
  icon?: string;
}

export interface SalesTrendPoint {
  day: string;
  sales: number;
}

// ─── Admin Dashboard ────────────────────────────────────────

export interface AdminDashboardData {
  todaySales: number;
  monthRevenue: number;
  grossProfitToday: number;
  inventoryValue: number;
  wastageToday: number;
  networkOrdersPending: number;
  expiringBouquets: number;
  upcomingWeddings: number;
  salesTrend: SalesTrendPoint[];
}

// ─── Manager Dashboard ──────────────────────────────────────

export interface ManagerDashboardData {
  ordersToFulfill: number;
  deliveriesScheduled: number;
  productionPending: number;
  lowStockAlerts: number;
  expiringBatches: number;
  staffTasksPending: number;
  topAlerts: OperationAlert[];
}

export interface OperationAlert {
  id: string;
  type: 'low_stock' | 'expiry' | 'delivery' | 'production';
  message: string;
  severity: 'info' | 'warning' | 'critical';
  href?: string;
}

// ─── Designer Dashboard ─────────────────────────────────────

export interface DesignerDashboardData {
  productionTasks: ProductionTask[];
  weddingPrepTasks: ProductionTask[];
  maintenanceRequired: number;
  expiringBouquets: number;
  customOrders: ProductionTask[];
}

export interface ProductionTask {
  id: string;
  title: string;
  type: 'bouquet' | 'arrangement' | 'wedding' | 'custom' | 'maintenance';
  status: 'pending' | 'in_progress' | 'completed';
  dueTime?: string;
  priority: 'low' | 'medium' | 'high';
  notes?: string;
}

// ─── Cashier Dashboard ──────────────────────────────────────

export interface CashierDashboardData {
  pendingPickups: number;
  unpaidOrders: number;
  todaySalesCount: number;
  todaySalesTotal: number;
}

// ─── Driver Dashboard ───────────────────────────────────────

export interface DriverDashboardData {
  deliveries: DeliveryItem[];
  completedCount: number;
  pendingCount: number;
  failedCount: number;
}

export interface DeliveryItem {
  id: string;
  orderNumber: string;
  customerName: string;
  phone: string;
  address: string;
  timeSlot: string;
  status: 'pending' | 'delivered' | 'failed';
  notes?: string;
  items: string;
}

// ─── Union type for any dashboard response ──────────────────

export type DashboardResponse =
  | { role: 'ADMIN'; data: AdminDashboardData }
  | { role: 'MANAGER'; data: ManagerDashboardData }
  | { role: 'DESIGNER'; data: DesignerDashboardData }
  | { role: 'CASHIER'; data: CashierDashboardData }
  | { role: 'DRIVER'; data: DriverDashboardData };

// ─── Mock Data ──────────────────────────────────────────────

const MOCK_ADMIN: AdminDashboardData = {
  todaySales: 47_250,
  monthRevenue: 8_34_500,
  grossProfitToday: 18_900,
  inventoryValue: 3_42_000,
  wastageToday: 1_250,
  networkOrdersPending: 7,
  expiringBouquets: 4,
  upcomingWeddings: 2,
  salesTrend: [
    { day: 'Mon', sales: 42_000 },
    { day: 'Tue', sales: 38_500 },
    { day: 'Wed', sales: 51_200 },
    { day: 'Thu', sales: 45_800 },
    { day: 'Fri', sales: 62_100 },
    { day: 'Sat', sales: 58_700 },
    { day: 'Sun', sales: 47_250 },
  ],
};

const MOCK_MANAGER: ManagerDashboardData = {
  ordersToFulfill: 14,
  deliveriesScheduled: 9,
  productionPending: 6,
  lowStockAlerts: 3,
  expiringBatches: 2,
  staffTasksPending: 5,
  topAlerts: [
    { id: 'a1', type: 'low_stock', message: 'Red Roses — only 12 stems left', severity: 'critical', href: '/inventory' },
    { id: 'a2', type: 'expiry', message: '2 bouquets expire today', severity: 'warning', href: '/expiry-alerts' },
    { id: 'a3', type: 'delivery', message: '3 deliveries in next hour', severity: 'info', href: '/delivery-scheduler' },
    { id: 'a4', type: 'production', message: 'Wedding centerpieces not started', severity: 'warning', href: '/production/produce' },
  ],
};

const MOCK_DESIGNER: DesignerDashboardData = {
  productionTasks: [
    { id: 't1', title: 'Rose Bouquet x3', type: 'bouquet', status: 'pending', dueTime: '11:00 AM', priority: 'high' },
    { id: 't2', title: 'White Lily Arrangement', type: 'arrangement', status: 'in_progress', dueTime: '12:30 PM', priority: 'medium' },
    { id: 't3', title: 'Mixed Flower Basket', type: 'bouquet', status: 'pending', dueTime: '2:00 PM', priority: 'low' },
    { id: 't4', title: 'Sunflower Bundle x2', type: 'bouquet', status: 'pending', dueTime: '3:30 PM', priority: 'medium' },
  ],
  weddingPrepTasks: [
    { id: 'w1', title: 'Sharma Wedding — Table Centerpieces x20', type: 'wedding', status: 'pending', dueTime: 'Feb 22', priority: 'high' },
    { id: 'w2', title: 'Sharma Wedding — Bridal Bouquet', type: 'wedding', status: 'pending', dueTime: 'Feb 22', priority: 'high' },
  ],
  maintenanceRequired: 3,
  expiringBouquets: 4,
  customOrders: [
    { id: 'c1', title: 'Custom Anniversary Arrangement — Mehta', type: 'custom', status: 'pending', dueTime: '5:00 PM', priority: 'high', notes: 'Pink & white theme, no lilies' },
  ],
};

const MOCK_CASHIER: CashierDashboardData = {
  pendingPickups: 5,
  unpaidOrders: 3,
  todaySalesCount: 18,
  todaySalesTotal: 47_250,
};

const MOCK_DRIVER: DriverDashboardData = {
  deliveries: [
    { id: 'd1', orderNumber: 'ORD-1042', customerName: 'Priya Mehta', phone: '+91 98765 43210', address: '12 Hill Road, Bandra West', timeSlot: '10:00 – 11:00 AM', status: 'pending', items: 'Rose Bouquet, Greeting Card' },
    { id: 'd2', orderNumber: 'ORD-1045', customerName: 'Arjun Shah', phone: '+91 87654 32109', address: '45 Linking Road, Santacruz', timeSlot: '11:30 AM – 12:30 PM', status: 'pending', items: 'White Lily Arrangement' },
    { id: 'd3', orderNumber: 'ORD-1038', customerName: 'Neha Verma', phone: '+91 76543 21098', address: '78 Turner Road, Bandra East', timeSlot: '1:00 – 2:00 PM', status: 'delivered', items: 'Sunflower Bundle x2' },
    { id: 'd4', orderNumber: 'ORD-1050', customerName: 'Raj Kapoor', phone: '+91 65432 10987', address: '23 Waterfield Rd, Bandra', timeSlot: '3:00 – 4:00 PM', status: 'pending', items: 'Mixed Flower Basket, Chocolates' },
    { id: 'd5', orderNumber: 'ORD-1051', customerName: 'Simran Kaur', phone: '+91 54321 09876', address: '90 S.V. Road, Andheri', timeSlot: '4:30 – 5:30 PM', status: 'failed', notes: 'Customer not available', items: 'Anniversary Arrangement' },
  ],
  completedCount: 1,
  pendingCount: 3,
  failedCount: 1,
};

// ─── Fetch Function (single call per role) ──────────────────

export async function fetchDashboard(
  role: string,
  _locationId?: string,
): Promise<DashboardResponse> {
  // Simulate network delay
  await new Promise((r) => setTimeout(r, 600));

  switch (role) {
    case 'ADMIN':
      return { role: 'ADMIN', data: MOCK_ADMIN };
    case 'MANAGER':
      return { role: 'MANAGER', data: MOCK_MANAGER };
    case 'DESIGNER':
      return { role: 'DESIGNER', data: MOCK_DESIGNER };
    case 'CASHIER':
      return { role: 'CASHIER', data: MOCK_CASHIER };
    case 'DRIVER':
      return { role: 'DRIVER', data: MOCK_DRIVER };
    default:
      throw new Error(`Unknown role: ${role}`);
  }
}
