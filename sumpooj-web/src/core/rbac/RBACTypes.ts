/**
 * RBACTypes.ts — Role-Based Access Control Type Definitions
 *
 * Defines:
 * - User roles (ADMIN, MANAGER, CASHIER, DESIGNER, DRIVER)
 * - Permissions per role
 * - Route access configuration
 * - Menu structure
 */

// ─── User Roles ─────────────────────────────────────────────

export type UserRole = 'ADMIN' | 'MANAGER' | 'CASHIER' | 'DESIGNER' | 'DRIVER' | 'STAFF' | 'PLATFORMSUPERADMIN';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  avatar?: string;
  // Multi-location support
  primaryLocationId?: string; // Default location for the user
  assignedLocationIds?: string[]; // All locations user can access
  // Platform admin flag
  isPlatformAdmin?: boolean;
}

// ─── Permission Types ───────────────────────────────────────

export type Permission =
  | 'pos:access'
  | 'pos:refund'
  | 'pos:day_close'
  | 'orders:view'
  | 'orders:create'
  | 'orders:edit'
  | 'orders:delete'
  | 'orders:external'
  | 'orders:status_update'
  | 'customers:view'
  | 'customers:create'
  | 'customers:edit'
  | 'crm:view'
  | 'crm:reminders'
  | 'crm:loyalty'
  | 'inventory:view'
  | 'inventory:adjust'
  | 'inventory:purchase'
  | 'products:view'
  | 'products:create'
  | 'products:edit'
  | 'reports:view'
  | 'reports:profit'
  | 'reports:inventory'
  | 'delivery:view'
  | 'delivery:update'
  | 'delivery:schedule'
  | 'events:view'
  | 'events:manage'
  | 'proposals:view'
  | 'proposals:create'
  | 'proposals:edit'
  | 'payments:schedule:view'
  | 'payments:schedule:manage'
  | 'staff:view'
  | 'staff:manage'
  | 'tasks:view'
  | 'tasks:manage'
  | 'production:view'
  | 'production:manage'
  | 'settings:view'
  | 'settings:edit'
  | 'settings:billing'
  | 'users:manage'
  | 'ai:view'
  | 'platform:admin';

// ─── Role Permission Mapping ────────────────────────────────

export const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
  PLATFORMSUPERADMIN: [
    // Platform admins have all permissions
    'platform:admin',
    'pos:access', 'pos:refund', 'pos:day_close',
    'orders:view', 'orders:create', 'orders:edit', 'orders:delete', 'orders:external', 'orders:status_update',
    'customers:view', 'customers:create', 'customers:edit',
    'crm:view', 'crm:reminders', 'crm:loyalty',
    'inventory:view', 'inventory:adjust', 'inventory:purchase',
    'products:view', 'products:create', 'products:edit',
    'reports:view', 'reports:profit', 'reports:inventory',
    'delivery:view', 'delivery:update', 'delivery:schedule',
    'events:view', 'events:manage',
    'proposals:view', 'proposals:create', 'proposals:edit',
    'payments:schedule:view', 'payments:schedule:manage',
    'staff:view', 'staff:manage',
    'tasks:view', 'tasks:manage',
    'production:view', 'production:manage',
    'settings:view', 'settings:edit', 'settings:billing', 'users:manage',
    'ai:view',
  ],

  ADMIN: [
    'pos:access', 'pos:refund', 'pos:day_close',
    'orders:view', 'orders:create', 'orders:edit', 'orders:delete', 'orders:external', 'orders:status_update',
    'customers:view', 'customers:create', 'customers:edit',
    'crm:view', 'crm:reminders', 'crm:loyalty',
    'inventory:view', 'inventory:adjust', 'inventory:purchase',
    'products:view', 'products:create', 'products:edit',
    'reports:view', 'reports:profit', 'reports:inventory',
    'delivery:view', 'delivery:update', 'delivery:schedule',
    'events:view', 'events:manage',
    'proposals:view', 'proposals:create', 'proposals:edit',
    'payments:schedule:view', 'payments:schedule:manage',
    'staff:view', 'staff:manage',
    'tasks:view', 'tasks:manage',
    'production:view', 'production:manage',
    'settings:view', 'settings:edit', 'settings:billing', 'users:manage',
    'ai:view',
  ],

  MANAGER: [
    'pos:access', 'pos:refund', 'pos:day_close',
    'orders:view', 'orders:create', 'orders:edit', 'orders:external', 'orders:status_update',
    'customers:view', 'customers:create', 'customers:edit',
    'crm:view', 'crm:reminders', 'crm:loyalty',
    'inventory:view', 'inventory:adjust', 'inventory:purchase',
    'products:view', 'products:create', 'products:edit',
    'reports:view', 'reports:profit', 'reports:inventory',
    'delivery:view', 'delivery:update', 'delivery:schedule',
    'events:view', 'events:manage',
    'proposals:view', 'proposals:create', 'proposals:edit',
    'payments:schedule:view', 'payments:schedule:manage',
    'staff:view', 'staff:manage',
    'tasks:view', 'tasks:manage',
    'production:view', 'production:manage',
    'settings:view', 'settings:edit', 'settings:billing', 'users:manage',
    'ai:view',
  ],

  CASHIER: [
    'pos:access', 'pos:refund',
    'orders:view',
    'customers:view',
    'products:view',
    'payments:schedule:view',
  ],

  DESIGNER: [
    'orders:view', 'orders:status_update',
    'products:view',
    'inventory:view',
    'events:view',
    'proposals:view',
    'payments:schedule:view',
    'tasks:view',
    'production:view', 'production:manage',
  ],

  DRIVER: [
    'orders:view',
    'delivery:view', 'delivery:update',
    'tasks:view',
  ],

  STAFF: [
    'pos:access',
    'orders:view',
    'customers:view',
    'products:view',
    'tasks:view',
  ],
};

// ─── Role Display Config ────────────────────────────────────

export const ROLE_CONFIG: Record<UserRole, { label: string; color: string; description: string }> = {
  PLATFORMSUPERADMIN: {
    label: 'Platform Admin',
    color: '#1B5E20',
    description: 'Platform-wide administration',
  },
  ADMIN: {
    label: 'Administrator',
    color: '#9c27b0',
    description: 'Full system access',
  },
  MANAGER: {
    label: 'Store Manager',
    color: '#2196f3',
    description: 'Manage inventory, reports, and staff',
  },
  CASHIER: {
    label: 'Cashier',
    color: '#4caf50',
    description: 'Process sales and basic orders',
  },
  DESIGNER: {
    label: 'Floral Designer',
    color: '#ff9800',
    description: 'Create arrangements and update order status',
  },
  DRIVER: {
    label: 'Delivery Driver',
    color: '#00bcd4',
    description: 'Manage deliveries and update status',
  },
  STAFF: {
    label: 'Staff',
    color: '#607d8b',
    description: 'General staff member',
  },
};

// ─── Menu Item Types ────────────────────────────────────────

export interface MenuItem {
  id: string;
  label: string;
  icon: string;
  path?: string;
  permissions: Permission[];
  children?: MenuItem[];
  badge?: string;
}

export interface MenuSection {
  id: string;
  title: string;
  items: MenuItem[];
}

// ─── Navigation Menu Configuration ──────────────────────────

export const MENU_SECTIONS: MenuSection[] = [
  {
    id: 'sales',
    title: 'Sales',
    items: [
      {
        id: 'pos',
        label: 'Walk-In Sales',
        icon: 'PointOfSale',
        path: '/pos',
        permissions: [],
      },
      {
        id: 'phone-order',
        label: 'Phone Order',
        icon: 'Phone',
        path: '/phone-orders',
        permissions: ['orders:create'],
      },
      {
        id: 'external-orders',
        label: 'Online Orders',
        icon: 'CloudDownload',
        path: '/external-orders',
        permissions: ['orders:external'],
      },
      {
        id: 'day-close',
        label: 'Day Close',
        icon: 'Lock',
        path: '/day-close',
        permissions: ['pos:day_close'],
      },
      {
        id: 'manual-sale-entry',
        label: 'Manual Sale Entry',
        icon: 'PointOfSale',
        path: '/pos/manual-sale',
        permissions: ['pos:access'],
      },
    ],
  },
  {
    id: 'orders',
    title: 'Orders',
    items: [
      {
        id: 'order-list',
        label: 'All Orders',
        icon: 'Receipt',
        path: '/order-list',
        permissions: ['orders:view'],
      },
      {
        id: 'deliveries',
        label: 'Deliveries',
        icon: 'LocalShipping',
        path: '/deliveries',
        permissions: ['delivery:view'],
      },
      {
        id: 'wire-vendors',
        label: 'Wire Vendors',
        icon: 'LocalFlorist',
        path: '/wire-vendors',
        permissions: ['orders:edit'],
      },
      {
        id: 'wire-settlements',
        label: 'Wire Settlements',
        icon: 'CreditCard',
        path: '/wire-settlements',
        permissions: ['orders:view'],
      },
      {
        id: 'delivery-routes',
        label: 'Delivery Routes',
        icon: 'AltRoute',
        path: '/delivery-routes',
        permissions: ['orders:view'],
      },
      {
        id: 'corporate-orders',
        label: 'Corporate Orders',
        icon: 'Receipt',
        path: '/corporate/orders',
        permissions: ['orders:create'],
      },
      {
        id: 'corporate-auto-orders',
        label: 'Auto Orders',
        icon: 'Assignment',
        path: '/corporate/orders/auto-created',
        permissions: ['orders:edit'],
      },
    ],
  },
  {
    id: 'events',
    title: 'Events & Weddings',
    items: [
      {
        id: 'events-list',
        label: 'All Events',
        icon: 'Celebration',
        path: '/events',
        permissions: ['events:view'],
      },
      {
        id: 'proposals-list',
        label: 'Proposals',
        icon: 'RequestQuote',
        path: '/proposals',
        permissions: ['proposals:view'],
      },
    ],
  },
  {
    id: 'reports',
    title: 'Reports',
    items: [
      {
        id: 'health-dashboard',
        label: 'Inventory Health Report',
        icon: 'Dashboard',
        path: '/health-dashboard',
        permissions: ['reports:view'],
      },
      {
        id: 'profit-intelligence',
        label: 'Profit Analysis',
        icon: 'TrendingUp',
        path: '/profit-intelligence',
        permissions: ['reports:profit'],
      },
      {
        id: 'valuation',
        label: 'Stock Value',
        icon: 'Assessment',
        path: '/valuation',
        permissions: ['reports:inventory'],
      },
      {
        id: 'stock-ledger',
        label: 'Stock History',
        icon: 'History',
        path: '/stock-ledger',
        permissions: ['reports:inventory'],
      },
      {
        id: 'reorder',
        label: 'Reorder Alerts',
        icon: 'NotificationsActive',
        path: '/reorder',
        permissions: ['inventory:view'],
      },
    ],
  },
  {
    id: 'staff',
    title: 'Staff',
    items: [
      {
        id: 'staff-list',
        label: 'All Staff',
        icon: 'People',
        path: '/staff',
        permissions: ['staff:view'],
      },
      {
        id: 'tasks',
        label: 'Tasks',
        icon: 'Assignment',
        path: '/tasks',
        permissions: ['tasks:view'],
      },
      {
        id: 'attendance',
        label: 'Attendance',
        icon: 'Schedule',
        path: '/staff/StaffAttendance',
        permissions: ['staff:view'],
      },
    ],
  },
  {
    id: 'catalog',
    title: 'Catalog',
    items: [
      {
        id: 'products',
        label: 'Products',
        icon: 'LocalFlorist',
        path: '/products',
        permissions: ['products:view'],
      },
      {
        id: 'new-product',
        label: 'New Product',
        icon: 'AddCircleOutline',
        path: '/products/new',
        permissions: ['products:create'],
      },
      {
        id: 'categories',
        label: 'Categories',
        icon: 'Category',
        path: '/categories',
        permissions: ['products:view'],
      },
    ],
  },
  {
    id: 'crm',
    title: 'CRM',
    items: [
      {
        id: 'crm-customers',
        label: 'Customers',
        icon: 'People',
        path: '/crm/customers',
        permissions: ['crm:view'],
      },
      {
        id: 'crm-customer-ledger',
        label: 'Customer Ledger',
        icon: 'MenuBook',
        path: '/crm/customer-ledger',
        permissions: ['crm:view'],
      },
      {
        id: 'crm-reminders',
        label: 'Reminders',
        icon: 'NotificationsActive',
        path: '/crm/reminders',
        permissions: ['crm:reminders'],
      },
      {
        id: 'crm-loyalty',
        label: 'Loyalty Program',
        icon: 'Loyalty',
        path: '/crm/loyalty',
        permissions: ['crm:loyalty'],
      },
      {
        id: 'crm-corporate-clients',
        label: 'Corporate Clients',
        icon: 'People',
        path: '/crm/corporate-clients',
        permissions: ['crm:view'],
      },
      {
        id: 'crm-corporate-dashboard',
        label: 'Corporate Dashboard',
        icon: 'Dashboard',
        path: '/corporate/dashboard',
        permissions: ['crm:view'],
      },
    ],
  },
  {
    id: 'production',
    title: 'Production',
    items: [
      {
        id: 'production-recipes',
        label: 'Recipes',
        icon: 'MenuBook',
        path: '/production/recipes',
        permissions: ['production:view'],
      },
      {
        id: 'production-produce',
        label: 'Produce',
        icon: 'Blender',
        path: '/production/produce',
        permissions: ['production:manage'],
      },
      {
        id: 'production-finished-goods',
        label: 'Finished Goods',
        icon: 'Inventory2',
        path: '/production/finished-goods',
        permissions: ['production:view'],
      },
      {
        id: 'production-custom-builder',
        label: 'Custom Builder',
        icon: 'AutoAwesome',
        path: '/production/custom-builder',
        permissions: ['production:manage'],
      },
      {
        id: 'production-wastage',
        label: 'Wastage Log',
        icon: 'DeleteSweep',
        path: '/production/wastage',
        permissions: ['production:view'],
      },
      {
        id: 'production-intelligence',
        label: 'Production Intelligence',
        icon: 'TrendingUp',
        path: '/production/intelligence',
        permissions: ['production:view'],
      },
    ],
  },
  {
    id: 'gift-cards',
    title: 'Gift Cards',
    items: [
      {
        id: 'gift-card-designer',
        label: 'Card Designer',
        icon: 'CardGiftcard',
        path: '/gift-cards/designer',
        permissions: ['orders:create'],
      },
    ],
  },
  {
    id: 'inventory',
    title: 'Inventory',
    items: [
      {
        id: 'inventory-batches',
        label: 'Stock Overview',
        icon: 'Inventory2',
        path: '/inventory',
        permissions: ['inventory:view'],
      },
      {
        id: 'suppliers',
        label: 'Suppliers',
        icon: 'LocalShipping',
        path: '/suppliers',
        permissions: ['inventory:view'],
      },
      {
        id: 'purchase-list',
        label: 'Purchase Orders',
        icon: 'AddShoppingCart',
        path: '/purchases',
        permissions: ['inventory:purchase'],
      },
      {
        id: 'purchases',
        label: 'New Purchase',
        icon: 'AddShoppingCart',
        path: '/purchases/new',
        permissions: ['inventory:purchase'],
      },
      {
        id: 'adjustments',
        label: 'Adjustments',
        icon: 'Tune',
        path: '/adjustments/new',
        permissions: ['inventory:adjust'],
      },
      {
        id: 'expiry-alerts',
        label: 'Expiry Alerts',
        icon: 'Warning',
        path: '/expiry-alerts',
        permissions: ['inventory:view'],
      },
      {
        id: 'inventory-ledger',
        label: 'Inventory Ledger',
        icon: 'Ledger',
        path: '/inventory/ledger',
        permissions: ['inventory:view'],
      },
      {
        id: 'daily-inventory-report',
        label: 'Daily Inventory Report',
        icon: 'CalendarToday',
        path: '/inventory/daily-report',
        permissions: ['inventory:view'],
      },
      {
        id: 'inventory-reconciliation',
        label: 'Reconciliation',
        icon: 'CompareArrows',
        path: '/inventory/reconciliation',
        permissions: ['inventory:view'],
      },
    ],
  },
  {
    id: 'settings',
    title: 'Settings',
    items: [
      {
        id: 'tenant-settings',
        label: 'Tenant Settings',
        icon: 'Settings',
        path: '/settings/tenant',
        permissions: ['settings:edit'],
      },
      {
        id: 'locations',
        label: 'Locations',
        icon: 'Store',
        path: '/settings/locations',
        permissions: ['settings:edit'],
      },
      {
        id: 'tax-rules',
        label: 'Tax Rules',
        icon: 'Receipt',
        path: '/settings/tax-rules',
        permissions: ['settings:edit'],
      },
      {
        id: 'delivery-zones',
        label: 'Delivery Zones',
        icon: 'LocalShipping',
        path: '/settings/delivery-zones',
        permissions: ['settings:edit'],
      },
      {
        id: 'discount-rules',
        label: 'Discount Rules',
        icon: 'Percent',
        path: '/settings/discount-rules',
        permissions: ['settings:edit'],
      },
      {
        id: 'payment-gateways',
        label: 'Payment Gateways',
        icon: 'CreditCard',
        path: '/settings/payment-gateways',
        permissions: ['settings:edit'],
      },
      {
        id: 'data-cleanup',
        label: 'Data Cleanup',
        icon: 'DeleteSweep',
        path: '/settings/data-cleanup',
        permissions: ['settings:edit'],
      },
      {
        id: 'subscription',
        label: 'Subscription',
        icon: 'CreditCard',
        path: '/subscription',
        permissions: ['settings:billing'],
      },
      {
        id: 'audit-logs',
        label: 'Audit Logs',
        icon: 'History',
        path: '/admin/audit-logs',
        permissions: ['settings:edit'],
      },
    ],
  },
  {
    id: 'accounting',
    title: 'Accounting',
    items: [
      { id: 'accounting-dashboard', label: 'Dashboard', icon: 'AccountBalance', path: '/accounting/dashboard', permissions: ['reports:view'] },
      { id: 'chart-of-accounts', label: 'Chart of Accounts', icon: 'ListAlt', path: '/accounting/chart-of-accounts', permissions: ['reports:view'] },
      { id: 'account-ledger', label: 'Account Ledger', icon: 'MenuBook', path: '/accounting/account-ledger', permissions: ['reports:view'] },
      { id: 'trial-balance', label: 'Trial Balance', icon: 'Balance', path: '/accounting/trial-balance', permissions: ['reports:view'] },
      { id: 'balance-sheet', label: 'Balance Sheet', icon: 'Assessment', path: '/accounting/balance-sheet', permissions: ['reports:view'] },
      { id: 'expenses', label: 'Expenses', icon: 'AttachMoney', path: '/accounting/expenses', permissions: ['reports:view'] },
      { id: 'journal', label: 'Journal', icon: 'ReceiptLong', path: '/accounting/journal', permissions: ['reports:view'] },
      { id: 'profit-loss', label: 'Profit & Loss', icon: 'TrendingUp', path: '/accounting/profit-loss', permissions: ['reports:view'] },
      { id: 'tax-summary', label: 'Tax Summary', icon: 'Percent', path: '/accounting/tax-summary', permissions: ['reports:view'] },
    ],
  },
  {
    id: 'ai',
    title: 'Floraprise AI',
    items: [
      {
        id: 'bouquet-scanner',
        label: 'Bouquet Scanner',
        icon: '🌸',
        path: '/ai/bouquet-scanner',
        permissions: ['ai:view'],
      },
    ],
  },
  {
    id: 'platform',
    title: 'Platform Admin',
    items: [
      {
        id: 'admin-dashboard',
        label: 'Admin Dashboard',
        icon: 'Dashboard',
        path: '/admin/dashboard',
        permissions: ['platform:admin'],
      },
      {
        id: 'admin-companies',
        label: 'Companies',
        icon: 'Store',
        path: '/admin/companies',
        permissions: ['platform:admin'],
      },
      {
        id: 'admin-analytics',
        label: 'Platform Analytics',
        icon: 'Assessment',
        path: '/admin/analytics',
        permissions: ['platform:admin'],
      },
      {
        id: 'admin-settings',
        label: 'Platform Settings',
        icon: 'Settings',
        path: '/admin/settings',
        permissions: ['platform:admin'],
      },
      {
        id: 'admin-demo-requests',
        label: 'Demo Requests',
        icon: 'RequestQuote',
        path: '/admin/demo-requests',
        permissions: ['platform:admin'],
      },
      {
        id: 'admin-audit-logs',
        label: 'Audit Logs',
        icon: 'History',
        path: '/admin/audit-logs',
        permissions: ['platform:admin'],
      },
    ],
  },
];

// ─── Route Access Configuration ─────────────────────────────

export interface RouteConfig {
  path: string;
  permissions: Permission[];
  redirectIfDenied?: string;
}

export const ROUTE_ACCESS: RouteConfig[] = [
  { path: '/pos', permissions: ['pos:access'] },
  { path: '/phone-orders', permissions: ['orders:create'] },
  { path: '/phone-orders/new', permissions: ['orders:create'] },
  { path: '/phone-orders/production', permissions: ['orders:create'] },
  { path: '/phone-orders/list', permissions: ['orders:view'] },
  { path: '/phone-orders/:orderId', permissions: ['orders:create'] },
  { path: '/external-orders', permissions: ['orders:external'] },
  { path: '/order-list', permissions: ['orders:view'] },
  { path: '/deliveries', permissions: ['delivery:view'] },
  { path: '/delivery-scheduler', permissions: ['delivery:view'] },
  { path: '/events', permissions: ['events:view'] },
  { path: '/proposals', permissions: ['proposals:view'] },
  { path: '/inventory', permissions: ['inventory:view'] },
  { path: '/purchases', permissions: ['inventory:purchase'] },
  { path: '/purchases/new', permissions: ['inventory:purchase'] },
  { path: '/adjustments/new', permissions: ['inventory:adjust'] },
  { path: '/expiry-alerts', permissions: ['inventory:view'] },
  { path: '/inventory/ledger', permissions: ['inventory:view'] },
  { path: '/inventory/reconciliation', permissions: ['inventory:view'] },
  { path: '/health-dashboard', permissions: ['reports:view'] },
  { path: '/profit-intelligence', permissions: ['reports:profit'] },
  { path: '/valuation', permissions: ['reports:inventory'] },
  { path: '/stock-ledger', permissions: ['reports:inventory'] },
  { path: '/reorder', permissions: ['inventory:view'] },
  { path: '/staff', permissions: ['staff:view'] },
  { path: '/tasks', permissions: ['tasks:view'] },
  { path: '/products/new', permissions: ['products:view'] },
  { path: '/categories', permissions: ['products:view'] },
  { path: '/customers', permissions: ['customers:view'] },
  { path: '/crm/customers', permissions: ['crm:view'] },
  { path: '/crm/customer-ledger', permissions: ['crm:view'] },
  { path: '/crm/reminders', permissions: ['crm:reminders'] },
  { path: '/crm/loyalty', permissions: ['crm:loyalty'] },
  { path: '/crm/corporate-clients', permissions: ['crm:view'] },
  { path: '/corporate/clients/:clientId', permissions: ['crm:view'] },
  { path: '/corporate/dashboard', permissions: ['crm:view'] },
  { path: '/corporate/orders', permissions: ['orders:create'] },
  { path: '/corporate/orders/auto-created', permissions: ['orders:edit'] },
  { path: '/corporate/invoices', permissions: ['reports:view'] },
  { path: '/subscription', permissions: ['settings:billing'] },
  { path: '/settings/tenant', permissions: ['settings:edit'] },
  { path: '/settings/data-cleanup', permissions: ['settings:edit'] },
  { path: '/settings/discount-rules', permissions: ['settings:edit'] },
  { path: '/day-close', permissions: ['pos:day_close'] },
];

// ─── Quick Actions Configuration ────────────────────────────

export interface QuickAction {
  id: string;
  label: string;
  icon: string;
  path: string;
  permissions: Permission[];
  color: string;
}

export const QUICK_ACTIONS: QuickAction[] = [
  {
    id: 'new-sale',
    label: 'New Sale',
    icon: 'PointOfSale',
    path: '/pos',
    permissions: ['pos:access'],
    color: '#4caf50',
  },
  {
    id: 'phone-order',
    label: 'Phone Order',
    icon: 'Phone',
    path: '/phone-orders',
    permissions: ['orders:create'],
    color: '#2196f3',
  },
  {
    id: 'new-purchase',
    label: 'Add Stock',
    icon: 'AddShoppingCart',
    path: '/purchases/new',
    permissions: ['inventory:purchase'],
    color: '#ff9800',
  },
];

// ─── Default Landing Pages by Role ──────────────────────────

export const DEFAULT_LANDING: Record<UserRole, string> = {
  PLATFORMSUPERADMIN: '/admin/dashboard',
  ADMIN: '/home',
  MANAGER: '/home',
  CASHIER: '/pos',
  DESIGNER: '/production/recipes',
  DRIVER: '/deliveries',
  STAFF: '/home',
};

// ─── Utility Type Guards ────────────────────────────────────

export const hasPermission = (userPermissions: Permission[], required: Permission[]): boolean => {
  if (required.length === 0) return true; // No permissions required — accessible to all
  return required.some((p) => userPermissions.includes(p));
};

export const hasAllPermissions = (userPermissions: Permission[], required: Permission[]): boolean => {
  return required.every((p) => userPermissions.includes(p));
};

export const getPermissionsForRole = (role: UserRole): Permission[] => {
  return ROLE_PERMISSIONS[role] ?? [];
};

export const canAccessRoute = (role: UserRole, path: string): boolean => {
  const userPerms = getPermissionsForRole(role);
  const routeConfig = ROUTE_ACCESS.find((r) => path.startsWith(r.path));
  if (!routeConfig) return true; // Allow access if route not configured
  return hasPermission(userPerms, routeConfig.permissions);
};
