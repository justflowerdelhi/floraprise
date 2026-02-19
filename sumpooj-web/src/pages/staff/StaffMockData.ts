/**
 * StaffMockData.ts — Mock Data for Staff & Performance Module
 *
 * Features:
 * - Staff member records
 * - Performance metrics by staff
 * - Commission calculations
 * - Helper functions for data retrieval
 */
import type {
  Staff,
  SalesMetrics,
  EventMetrics,
  ProductionMetrics,
  DeliveryMetrics,
  StaffRole,
} from './StaffTypes';
import { calculateCommission } from './StaffTypes';

// ─── Mock Staff Members ─────────────────────────────────────

export const MOCK_STAFF: Staff[] = [
  {
    id: 'staff-001',
    name: 'Raj Kumar',
    role: 'ADMIN',
    locationId: 'loc-001',
    phone: '+91 98765 43210',
    email: 'raj@florist.com',
    commissionType: 'PROFIT',
    commissionRate: 2,
    isActive: true,
    hireDate: '2020-01-15',
    createdAt: '2020-01-15T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-002',
    name: 'Priya Sharma',
    role: 'MANAGER',
    locationId: 'loc-001',
    locationIds: ['loc-001', 'loc-002'],
    phone: '+91 87654 32109',
    email: 'priya@florist.com',
    commissionType: 'PROFIT',
    commissionRate: 3,
    isActive: true,
    hireDate: '2021-03-10',
    createdAt: '2021-03-10T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-003',
    name: 'Amit Singh',
    role: 'CASHIER',
    locationId: 'loc-001',
    phone: '+91 76543 21098',
    email: 'amit@florist.com',
    commissionType: 'REVENUE',
    commissionRate: 1,
    hourlyRate: 150,
    isActive: true,
    hireDate: '2022-06-15',
    createdAt: '2022-06-15T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-004',
    name: 'Meera Patel',
    role: 'DESIGNER',
    locationId: 'loc-001',
    phone: '+91 65432 10987',
    email: 'meera@florist.com',
    commissionType: 'PROFIT',
    commissionRate: 5,
    hourlyRate: 200,
    isActive: true,
    hireDate: '2021-09-01',
    createdAt: '2021-09-01T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-005',
    name: 'Ananya Sharma',
    role: 'DESIGNER',
    locationId: 'loc-002',
    phone: '+91 54321 09876',
    email: 'ananya@florist.com',
    commissionType: 'PROFIT',
    commissionRate: 5,
    hourlyRate: 180,
    isActive: true,
    hireDate: '2023-02-20',
    createdAt: '2023-02-20T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-006',
    name: 'Priya Gupta',
    role: 'DESIGNER',
    locationId: 'loc-003',
    phone: '+91 43210 98765',
    email: 'priyag@florist.com',
    commissionType: 'PROFIT',
    commissionRate: 4,
    hourlyRate: 160,
    isActive: true,
    hireDate: '2024-01-10',
    createdAt: '2024-01-10T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-007',
    name: 'Kavita Reddy',
    role: 'DESIGNER',
    locationId: 'loc-001',
    phone: '+91 32109 87654',
    email: 'kavita@florist.com',
    commissionType: 'PROFIT',
    commissionRate: 4,
    hourlyRate: 160,
    isActive: false,
    hireDate: '2023-06-15',
    createdAt: '2023-06-15T10:00:00Z',
    updatedAt: '2025-12-01T10:00:00Z',
  },
  {
    id: 'staff-008',
    name: 'Vikram Rao',
    role: 'DRIVER',
    locationId: 'loc-001',
    phone: '+91 21098 76543',
    email: 'vikram@florist.com',
    hourlyRate: 100,
    isActive: true,
    hireDate: '2022-08-01',
    createdAt: '2022-08-01T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-009',
    name: 'Rajan Kumar',
    role: 'DRIVER',
    locationId: 'loc-002',
    phone: '+91 10987 65432',
    email: 'rajan@florist.com',
    hourlyRate: 100,
    isActive: true,
    hireDate: '2024-03-01',
    createdAt: '2024-03-01T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
  {
    id: 'staff-010',
    name: 'Neha Verma',
    role: 'CASHIER',
    locationId: 'loc-004',
    phone: '+91 09876 54321',
    email: 'neha@florist.com',
    commissionType: 'REVENUE',
    commissionRate: 0.5,
    hourlyRate: 140,
    isActive: true,
    hireDate: '2025-01-15',
    createdAt: '2025-01-15T10:00:00Z',
    updatedAt: '2026-01-01T10:00:00Z',
  },
];

// ─── Mock Sales Performance Data (This Month) ───────────────

const MOCK_SALES_DATA: Record<string, SalesMetrics> = {
  'staff-001': {
    totalOrders: 45,
    totalRevenue: 287500,
    totalCost: 115000,
    grossProfit: 172500,
    marginPercent: 60,
    averageOrderValue: 6389,
    totalDiscountsGiven: 14375,
    walkInSales: 115000,
    phoneSales: 86250,
    onlineSales: 86250,
  },
  'staff-002': {
    totalOrders: 68,
    totalRevenue: 425000,
    totalCost: 161500,
    grossProfit: 263500,
    marginPercent: 62,
    averageOrderValue: 6250,
    totalDiscountsGiven: 21250,
    walkInSales: 170000,
    phoneSales: 127500,
    onlineSales: 127500,
  },
  'staff-003': {
    totalOrders: 156,
    totalRevenue: 468000,
    totalCost: 187200,
    grossProfit: 280800,
    marginPercent: 60,
    averageOrderValue: 3000,
    totalDiscountsGiven: 23400,
    walkInSales: 374400,
    phoneSales: 93600,
    onlineSales: 0,
  },
  'staff-004': {
    totalOrders: 12,
    totalRevenue: 85000,
    totalCost: 34000,
    grossProfit: 51000,
    marginPercent: 60,
    averageOrderValue: 7083,
    totalDiscountsGiven: 4250,
    walkInSales: 0,
    phoneSales: 85000,
    onlineSales: 0,
  },
  'staff-005': {
    totalOrders: 8,
    totalRevenue: 62000,
    totalCost: 24800,
    grossProfit: 37200,
    marginPercent: 60,
    averageOrderValue: 7750,
    totalDiscountsGiven: 3100,
    walkInSales: 0,
    phoneSales: 62000,
    onlineSales: 0,
  },
  'staff-010': {
    totalOrders: 98,
    totalRevenue: 245000,
    totalCost: 98000,
    grossProfit: 147000,
    marginPercent: 60,
    averageOrderValue: 2500,
    totalDiscountsGiven: 12250,
    walkInSales: 196000,
    phoneSales: 49000,
    onlineSales: 0,
  },
};

// ─── Mock Event Performance Data ────────────────────────────

const MOCK_EVENT_DATA: Record<string, EventMetrics> = {
  'staff-001': {
    eventsAssigned: 0,
    eventsCompleted: 0,
    proposalsCreated: 5,
    proposalsApproved: 4,
    eventRevenue: 850000,
    eventProfit: 340000,
  },
  'staff-002': {
    eventsAssigned: 0,
    eventsCompleted: 0,
    proposalsCreated: 8,
    proposalsApproved: 6,
    eventRevenue: 520000,
    eventProfit: 208000,
  },
  'staff-004': {
    eventsAssigned: 8,
    eventsCompleted: 5,
    proposalsCreated: 12,
    proposalsApproved: 9,
    eventRevenue: 680000,
    eventProfit: 272000,
  },
  'staff-005': {
    eventsAssigned: 6,
    eventsCompleted: 4,
    proposalsCreated: 8,
    proposalsApproved: 5,
    eventRevenue: 420000,
    eventProfit: 168000,
  },
  'staff-006': {
    eventsAssigned: 4,
    eventsCompleted: 3,
    proposalsCreated: 5,
    proposalsApproved: 3,
    eventRevenue: 180000,
    eventProfit: 72000,
  },
  'staff-007': {
    eventsAssigned: 2,
    eventsCompleted: 2,
    proposalsCreated: 3,
    proposalsApproved: 2,
    eventRevenue: 95000,
    eventProfit: 38000,
  },
};

// ─── Mock Production Performance Data ───────────────────────

const MOCK_PRODUCTION_DATA: Record<string, ProductionMetrics> = {
  'staff-004': {
    itemsAssigned: 85,
    itemsCompleted: 72,
    itemsInProgress: 8,
    productionCompletionRate: 84.7,
    averageCompletionTime: 2.5,
  },
  'staff-005': {
    itemsAssigned: 62,
    itemsCompleted: 55,
    itemsInProgress: 5,
    productionCompletionRate: 88.7,
    averageCompletionTime: 2.2,
  },
  'staff-006': {
    itemsAssigned: 48,
    itemsCompleted: 40,
    itemsInProgress: 6,
    productionCompletionRate: 83.3,
    averageCompletionTime: 2.8,
  },
  'staff-007': {
    itemsAssigned: 15,
    itemsCompleted: 15,
    itemsInProgress: 0,
    productionCompletionRate: 100,
    averageCompletionTime: 2.4,
  },
};

// ─── Mock Delivery Performance Data ─────────────────────────

const MOCK_DELIVERY_DATA: Record<string, DeliveryMetrics> = {
  'staff-008': {
    deliveriesAssigned: 145,
    deliveriesCompleted: 142,
    deliveriesOnTime: 136,
    onTimeRate: 95.8,
    totalDistance: 1850,
  },
  'staff-009': {
    deliveriesAssigned: 98,
    deliveriesCompleted: 95,
    deliveriesOnTime: 88,
    onTimeRate: 92.6,
    totalDistance: 1240,
  },
};

// ─── Helper Functions ───────────────────────────────────────

/**
 * Get all staff members
 */
export const getAllStaff = (): Staff[] => MOCK_STAFF;

/**
 * Get active staff only
 */
export const getActiveStaff = (): Staff[] => MOCK_STAFF.filter((s) => s.isActive);

/**
 * Get staff by ID
 */
export const getStaffById = (id: string): Staff | null =>
  MOCK_STAFF.find((s) => s.id === id) || null;

/**
 * Get staff by role
 */
export const getStaffByRole = (role: StaffRole): Staff[] =>
  MOCK_STAFF.filter((s) => s.role === role);

/**
 * Get full performance data for a staff member
 */
export const getStaffPerformance = (
  staffId: string,
  periodStart: string,
  periodEnd: string
): StaffPerformance | null => {
  const staff = getStaffById(staffId);
  if (!staff) return null;

  const sales = MOCK_SALES_DATA[staffId] || {
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
  };

  const events = MOCK_EVENT_DATA[staffId] || {
    eventsAssigned: 0,
    eventsCompleted: 0,
    proposalsCreated: 0,
    proposalsApproved: 0,
    eventRevenue: 0,
    eventProfit: 0,
  };

  const production = MOCK_PRODUCTION_DATA[staffId] || {
    itemsAssigned: 0,
    itemsCompleted: 0,
    itemsInProgress: 0,
    productionCompletionRate: 0,
  };

  const deliveries = MOCK_DELIVERY_DATA[staffId] || {
    deliveriesAssigned: 0,
    deliveriesCompleted: 0,
    deliveriesOnTime: 0,
    onTimeRate: 0,
  };

  // Calculate commission
  const commissionBase =
    staff.commissionType === 'REVENUE'
      ? sales.totalRevenue + events.eventRevenue
      : sales.grossProfit + events.eventProfit;

  const commissionEarned = calculateCommission(
    staff.commissionType,
    staff.commissionRate,
    sales.totalRevenue + events.eventRevenue,
    sales.grossProfit + events.eventProfit
  );

  return {
    staffId,
    staffName: staff.name,
    staffRole: staff.role,
    periodStart,
    periodEnd,
    sales,
    events,
    production,
    deliveries,
    commission: {
      commissionBase,
      commissionRate: staff.commissionRate || 0,
      commissionEarned,
      periodStart,
      periodEnd,
    },
  };
};

/**
 * Get top performers by metric
 */
export const getTopPerformers = (
  metric: 'revenue' | 'orders' | 'events' | 'deliveries',
  limit: number = 5
): Array<{ staff: Staff; value: number }> => {
  const results: Array<{ staff: Staff; value: number }> = [];

  MOCK_STAFF.forEach((staff) => {
    let value = 0;
    switch (metric) {
      case 'revenue':
        value = (MOCK_SALES_DATA[staff.id]?.totalRevenue || 0) +
                (MOCK_EVENT_DATA[staff.id]?.eventRevenue || 0);
        break;
      case 'orders':
        value = MOCK_SALES_DATA[staff.id]?.totalOrders || 0;
        break;
      case 'events':
        value = MOCK_EVENT_DATA[staff.id]?.eventsCompleted || 0;
        break;
      case 'deliveries':
        value = MOCK_DELIVERY_DATA[staff.id]?.deliveriesCompleted || 0;
        break;
    }
    if (value > 0) {
      results.push({ staff, value });
    }
  });

  return results.sort((a, b) => b.value - a.value).slice(0, limit);
};

/**
 * Get team summary metrics
 */
export const getTeamSummary = (): {
  totalStaff: number;
  activeStaff: number;
  totalRevenue: number;
  totalOrders: number;
  totalCommission: number;
  byRole: Record<StaffRole, number>;
} => {
  const activeStaff = getActiveStaff();
  let totalRevenue = 0;
  let totalOrders = 0;
  let totalCommission = 0;
  const byRole: Record<StaffRole, number> = {
    ADMIN: 0,
    MANAGER: 0,
    CASHIER: 0,
    DESIGNER: 0,
    DRIVER: 0,
  };

  MOCK_STAFF.forEach((staff) => {
    if (staff.isActive) {
      byRole[staff.role]++;
      const sales = MOCK_SALES_DATA[staff.id];
      const events = MOCK_EVENT_DATA[staff.id];
      if (sales) {
        totalRevenue += sales.totalRevenue;
        totalOrders += sales.totalOrders;
      }
      if (events) {
        totalRevenue += events.eventRevenue;
      }
      // Calculate commission
      totalCommission += calculateCommission(
        staff.commissionType,
        staff.commissionRate,
        (sales?.totalRevenue || 0) + (events?.eventRevenue || 0),
        (sales?.grossProfit || 0) + (events?.eventProfit || 0)
      );
    }
  });

  return {
    totalStaff: MOCK_STAFF.length,
    activeStaff: activeStaff.length,
    totalRevenue,
    totalOrders,
    totalCommission,
    byRole,
  };
};

/**
 * Search staff by name or email
 */
export const searchStaff = (query: string): Staff[] => {
  const lowerQuery = query.toLowerCase();
  return MOCK_STAFF.filter(
    (s) =>
      s.name.toLowerCase().includes(lowerQuery) ||
      s.email?.toLowerCase().includes(lowerQuery) ||
      s.phone?.includes(query)
  );
};

// ─── Staff Order History Check ──────────────────────────────

/** IDs of staff members who have historical orders (mock) */
const STAFF_WITH_ORDERS = new Set([
  'staff-001', 'staff-002', 'staff-003', 'staff-004',
  'staff-005', 'staff-007', 'staff-008', 'staff-010',
]);

/**
 * Check if a staff member has historical orders.
 * If true, the staff member cannot be permanently deleted (use deactivation).
 */
export const staffHasOrders = (staffId: string): boolean =>
  STAFF_WITH_ORDERS.has(staffId);
