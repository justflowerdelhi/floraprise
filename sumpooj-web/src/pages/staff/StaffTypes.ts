/**
 * StaffTypes.ts — Staff & Performance Intelligence Type Definitions
 *
 * Features:
 * - Staff model with roles and commission settings
 * - Performance metrics tracking
 * - Commission calculation utilities
 * - Date range filtering support
 */
import type { UserRole } from '../../core/rbac/RBACTypes';

// ─── Staff Role (mirrors RBAC UserRole) ─────────────────────

export type StaffRole = UserRole;

export const STAFF_ROLES: StaffRole[] = ['ADMIN', 'MANAGER', 'CASHIER', 'DESIGNER', 'DRIVER', 'STAFF'];

// ─── Commission Types ───────────────────────────────────────

export type CommissionType = 'REVENUE' | 'PROFIT';

export const COMMISSION_TYPES: CommissionType[] = ['REVENUE', 'PROFIT'];

// ─── Staff Interface ────────────────────────────────────────

export interface Staff {
  id: string;
  name: string;
  role: StaffRole;
  locationId?: string; // Assigned location
  locationIds?: string[]; // Multiple locations (for managers)
  phone?: string;
  email?: string;
  commissionType?: CommissionType;
  commissionRate?: number; // Percentage (e.g., 5 = 5%)
  hourlyRate?: number;
  avatar?: string;
  hireDate?: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;

  // ── Identity / Login info ────────────────────────────────
  identityUserId?: string | null;
  loginIdentifier?: string | null;
  loginRole?: string | null;
}

// ─── Staff Form Data ────────────────────────────────────────

export interface StaffFormData {
  name: string;
  role: StaffRole;
  phone: string;
  email: string;
  commissionType: CommissionType | '';
  commissionRate: string;
  hourlyRate: string;
  isActive: boolean;
  // Optional login access
  enableLogin: boolean;
  loginIdentifier: string;
  loginRole: string;
  password: string;
  confirmPassword: string;
}

// ─── Performance Metrics ────────────────────────────────────

export interface SalesMetrics {
  totalOrders: number;
  totalRevenue: number;
  totalCost: number;
  grossProfit: number;
  marginPercent: number;
  averageOrderValue: number;
  totalDiscountsGiven: number;
  walkInSales: number;
  phoneSales: number;
  onlineSales: number;
}

export interface EventMetrics {
  eventsAssigned: number;
  eventsCompleted: number;
  proposalsCreated: number;
  proposalsApproved: number;
  eventRevenue: number;
  eventProfit: number;
}

export interface ProductionMetrics {
  itemsAssigned: number;
  itemsCompleted: number;
  itemsInProgress: number;
  productionCompletionRate: number;
  averageCompletionTime?: number; // hours
}

export interface DeliveryMetrics {
  deliveriesAssigned: number;
  deliveriesCompleted: number;
  deliveriesOnTime: number;
  onTimeRate: number;
  totalDistance?: number; // km
}

export interface CommissionMetrics {
  commissionBase: number; // revenue or profit based on type
  commissionRate: number;
  commissionEarned: number;
  periodStart?: string;
  periodEnd?: string;
}

// ─── Full Staff Performance ─────────────────────────────────

export interface StaffPerformance {
  staffId: string;
  staffName: string;
  staffRole: StaffRole;
  periodStart: string;
  periodEnd: string;
  sales: SalesMetrics;
  events: EventMetrics;
  production: ProductionMetrics;
  deliveries: DeliveryMetrics;
  commission: CommissionMetrics;
}

// ─── Date Range Filter ──────────────────────────────────────

export type DateRangePreset = 'TODAY' | 'WEEK' | 'MONTH' | 'QUARTER' | 'YEAR' | 'CUSTOM';

export interface DateRange {
  preset: DateRangePreset;
  startDate: string;
  endDate: string;
}

export const DATE_RANGE_PRESETS: { value: DateRangePreset; label: string }[] = [
  { value: 'TODAY', label: 'Today' },
  { value: 'WEEK', label: 'This Week' },
  { value: 'MONTH', label: 'This Month' },
  { value: 'QUARTER', label: 'This Quarter' },
  { value: 'YEAR', label: 'This Year' },
  { value: 'CUSTOM', label: 'Custom Range' },
];

// ─── Role Configuration ─────────────────────────────────────

export interface StaffRoleConfig {
  label: string;
  color: string;
  bgColor: string;
  icon: string;
  description: string;
  tracksSales: boolean;
  tracksProduction: boolean;
  tracksDeliveries: boolean;
  tracksEvents: boolean;
}

export const STAFF_ROLE_CONFIG: Record<StaffRole, StaffRoleConfig> = {
  ADMIN: {
    label: 'Administrator',
    color: '#9c27b0',
    bgColor: 'rgba(156, 39, 176, 0.12)',
    icon: '👑',
    description: 'Full system access',
    tracksSales: true,
    tracksProduction: false,
    tracksDeliveries: false,
    tracksEvents: true,
  },
  MANAGER: {
    label: 'Store Manager',
    color: '#2196f3',
    bgColor: 'rgba(33, 150, 243, 0.12)',
    icon: '📊',
    description: 'Manage operations and staff',
    tracksSales: true,
    tracksProduction: false,
    tracksDeliveries: false,
    tracksEvents: true,
  },
  CASHIER: {
    label: 'Cashier',
    color: '#4caf50',
    bgColor: 'rgba(76, 175, 80, 0.12)',
    icon: '💳',
    description: 'Process sales and payments',
    tracksSales: true,
    tracksProduction: false,
    tracksDeliveries: false,
    tracksEvents: false,
  },
  DESIGNER: {
    label: 'Floral Designer',
    color: '#ff9800',
    bgColor: 'rgba(255, 152, 0, 0.12)',
    icon: '🌸',
    description: 'Create arrangements and handle events',
    tracksSales: false,
    tracksProduction: true,
    tracksDeliveries: false,
    tracksEvents: true,
  },
  DRIVER: {
    label: 'Delivery Driver',
    color: '#00bcd4',
    bgColor: 'rgba(0, 188, 212, 0.12)',
    icon: '🚚',
    description: 'Handle deliveries',
    tracksSales: false,
    tracksProduction: false,
    tracksDeliveries: true,
    tracksEvents: false,
  },
  STAFF: {
    label: 'Staff',
    color: '#607d8b',
    bgColor: 'rgba(96, 125, 138, 0.12)',
    icon: '👤',
    description: 'General staff member',
    tracksSales: true,
    tracksProduction: false,
    tracksDeliveries: false,
    tracksEvents: false,
  },
};

/**
 * Normalize a role string from the backend (PascalCase) to the frontend (UPPERCASE).
 * Falls back to 'STAFF' for unrecognized roles.
 */
export const normalizeRole = (role: string): StaffRole => {
  const upper = role?.toUpperCase() as StaffRole;
  return upper in STAFF_ROLE_CONFIG ? upper : 'STAFF';
};

// ─── Commission Type Config ─────────────────────────────────

export const COMMISSION_TYPE_CONFIG: Record<CommissionType, { label: string; description: string }> = {
  REVENUE: {
    label: 'Revenue-Based',
    description: 'Commission calculated on total revenue',
  },
  PROFIT: {
    label: 'Profit-Based',
    description: 'Commission calculated on gross profit',
  },
};

// ─── Utility Functions ──────────────────────────────────────

/**
 * Calculate commission based on type and rate
 */
export const calculateCommission = (
  commissionType: CommissionType | undefined,
  commissionRate: number | undefined,
  revenue: number,
  grossProfit: number
): number => {
  if (!commissionType || !commissionRate) return 0;

  const base = commissionType === 'REVENUE' ? revenue : grossProfit;
  return Math.round(base * (commissionRate / 100) * 100) / 100;
};

/**
 * Calculate margin percentage
 */
export const calculateMargin = (revenue: number, cost: number): number => {
  if (revenue === 0) return 0;
  return Math.round(((revenue - cost) / revenue) * 100 * 100) / 100;
};

/**
 * Calculate average order value
 */
export const calculateAOV = (revenue: number, orderCount: number): number => {
  if (orderCount === 0) return 0;
  return Math.round((revenue / orderCount) * 100) / 100;
};

/**
 * Get date range from preset
 */
export const getDateRangeFromPreset = (preset: DateRangePreset): { start: string; end: string } => {
  const today = new Date();
  const end = today.toISOString().split('T')[0];
  let start: Date;

  switch (preset) {
    case 'TODAY':
      return { start: end, end };
    case 'WEEK':
      start = new Date(today);
      start.setDate(today.getDate() - today.getDay());
      return { start: start.toISOString().split('T')[0], end };
    case 'MONTH':
      start = new Date(today.getFullYear(), today.getMonth(), 1);
      return { start: start.toISOString().split('T')[0], end };
    case 'QUARTER':
      const quarter = Math.floor(today.getMonth() / 3);
      start = new Date(today.getFullYear(), quarter * 3, 1);
      return { start: start.toISOString().split('T')[0], end };
    case 'YEAR':
      start = new Date(today.getFullYear(), 0, 1);
      return { start: start.toISOString().split('T')[0], end };
    default:
      return { start: end, end };
  }
};

/**
 * Get initial form data from staff
 */
export const getInitialFormData = (staff?: Staff): StaffFormData => ({
  name: staff?.name || '',
  role: staff?.role || 'CASHIER',
  phone: staff?.phone || '',
  email: staff?.email || '',
  commissionType: staff?.commissionType || '',
  commissionRate: staff?.commissionRate?.toString() || '',
  hourlyRate: staff?.hourlyRate?.toString() || '',
  isActive: staff?.isActive ?? true,
  enableLogin: false,
  loginIdentifier: '',
  loginRole: '',
  password: '',
  confirmPassword: '',
});

/** Roles available for identity login assignment */
export const LOGIN_ROLES = ['Admin', 'Manager', 'Cashier', 'Designer', 'Driver', 'Staff'] as const;

/**
 * Create empty sales metrics
 */
export const createEmptySalesMetrics = (): SalesMetrics => ({
  totalOrders: 0,
  totalRevenue: 0,
  totalCost: 0,
  grossProfit: 0,
  marginPercent: 0,
  averageOrderValue: 0,
  totalDiscountsGiven: 0,
  walkInSales: 0,
  phoneSales: 0,
  onlineSales: 0,
});

/**
 * Create empty event metrics
 */
export const createEmptyEventMetrics = (): EventMetrics => ({
  eventsAssigned: 0,
  eventsCompleted: 0,
  proposalsCreated: 0,
  proposalsApproved: 0,
  eventRevenue: 0,
  eventProfit: 0,
});

/**
 * Create empty production metrics
 */
export const createEmptyProductionMetrics = (): ProductionMetrics => ({
  itemsAssigned: 0,
  itemsCompleted: 0,
  itemsInProgress: 0,
  productionCompletionRate: 0,
});

/**
 * Create empty delivery metrics
 */
export const createEmptyDeliveryMetrics = (): DeliveryMetrics => ({
  deliveriesAssigned: 0,
  deliveriesCompleted: 0,
  deliveriesOnTime: 0,
  onTimeRate: 0,
});

/**
 * Create empty commission metrics
 */
export const createEmptyCommissionMetrics = (): CommissionMetrics => ({
  commissionBase: 0,
  commissionRate: 0,
  commissionEarned: 0,
});
