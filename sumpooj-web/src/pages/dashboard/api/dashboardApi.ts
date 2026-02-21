/**
 * dashboardApi.ts — Dashboard Data Types & Real API
 *
 * Single API call per role. Location-aware. No hardcoded tenant logic.
 */
import { fetchDashboard as fetchDashboardApi } from '../../../api/dashboard.api';

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

// ─── Fetch Function (single call per role) ──────────────────

export async function fetchDashboard(
  role: string,
  locationId?: string,
): Promise<DashboardResponse> {
  return await fetchDashboardApi(role, locationId);
}
