// src/config/menuConfig.ts
// Centralized menu configuration for sidebar/left menu

export interface MenuItem {
  id: string;
  label: string;
  icon?: string;
  path?: string;
  children?: MenuItem[];
  permissions?: string[];
}

export interface MenuSection {
  id: string;
  label: string;
  permissions?: string[];
  items: MenuItem[];
}

export const MENU_CONFIG: MenuSection[] = [
  // Example structure
  {
    id: 'sales',
    label: 'Sales',
    items: [
      { id: 'walk-in-sales', label: 'Walk-In Sales', icon: 'Storefront', path: '/sales/walk-in' },
      { id: 'phone-order', label: 'Phone Order', icon: 'Phone', path: '/sales/phone-order' },
      { id: 'online-orders', label: 'Online Orders', icon: 'ShoppingCart', path: '/sales/online-orders' },
      { id: 'day-close', label: 'Day Close', icon: 'Event', path: '/sales/day-close' },
    ],
  },
  {
    id: 'catalogue',
    label: 'Catalogue',
    items: [
      { id: 'categories', label: 'Categories', icon: 'Category', path: '/catalogue/categories' },
      { id: 'products', label: 'Products', icon: 'Inventory', path: '/catalogue/products' },
    ],
  },
  {
    id: 'pos',
    label: 'POS',
    items: [
      { id: 'manual-sale', label: 'Manual Sale', icon: 'PointOfSale', path: '/pos/manual-sale' }
    ],
  },
  {
    id: 'orders',
    label: 'Orders',
    items: [
      { id: 'all-orders', label: 'All Orders', icon: 'Receipt', path: '/orders' },
      { id: 'phone-orders', label: 'Phone Orders', icon: 'Phone', path: '/phone-orders' },
    ],
  },
  {
    id: 'reports',
    label: 'Reports',
    items: [
      { id: 'health-dashboard', label: 'Dashboard', icon: 'Dashboard', path: '/health-dashboard' },
      { id: 'profit-intelligence', label: 'Profit Analysis', icon: 'TrendingUp', path: '/profit-intelligence' },
      { id: 'valuation', label: 'Stock Value', icon: 'Assessment', path: '/valuation' },
      { id: 'stock-ledger', label: 'Stock History', icon: 'History', path: '/stock-ledger' },
      { id: 'reorder', label: 'Reorder Alerts', icon: 'NotificationsActive', path: '/reorder' },
    ],
  },
  {
    id: 'accounting',
    label: 'Accounting',
    permissions: ['Admin', 'Accountant'],
    items: [
      { id: 'accounting-dashboard', label: 'Dashboard', icon: 'AccountBalance', path: '/accounting/dashboard' },
      { id: 'chart-of-accounts', label: 'Chart of Accounts', icon: 'ListAlt', path: '/accounting/chart-of-accounts' },
      { id: 'account-ledger', label: 'Account Ledger', icon: 'MenuBook', path: '/accounting/account-ledger' },
      { id: 'trial-balance', label: 'Trial Balance', icon: 'Balance', path: '/accounting/trial-balance' },
      { id: 'balance-sheet', label: 'Balance Sheet', icon: 'Assessment', path: '/accounting/balance-sheet' },
      { id: 'expenses', label: 'Expenses', icon: 'AttachMoney', path: '/accounting/expenses' },
      { id: 'journal', label: 'Journal', icon: 'ReceiptLong', path: '/accounting/journal' },
      { id: 'profit-loss', label: 'Profit & Loss', icon: 'TrendingUp', path: '/accounting/profit-loss' },
      { id: 'tax-summary', label: 'Tax Summary', icon: 'Percent', path: '/accounting/tax-summary' },
    ],
  },
  {
    id: 'staff',
    label: 'Staff',
    items: [
      { id: 'staff-list', label: 'All Staff', icon: 'People', path: '/staff' },
      { id: 'tasks', label: 'Tasks', icon: 'Assignment', path: '/tasks' },
        { id: 'attendance', label: 'Attendance', icon: 'Schedule', path: '/staff/StaffAttendance' },
    ],
  },
  {
    id: 'ai',
    label: 'Floraprise Smart AI',
    items: [
      {
        id: 'bouquet-scanner',
        label: 'Bouquet Scanner',
        icon: 'Science',
        path: '/ai/bouquet-scanner',
        color: 'green', // Changed from yellow to green
        permissions: [], // Visible to all users
      },
    ],
  },
  // Add more sections/items as needed
];
