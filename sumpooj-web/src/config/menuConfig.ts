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
  items: MenuItem[];
}

export const MENU_CONFIG: MenuSection[] = [
  // Example structure
  {
    id: 'catalogue',
    label: 'Catalogue',
    items: [
      { id: 'categories', label: 'Categories', icon: 'Category', path: '/catalogue/categories' },
      { id: 'products', label: 'Products', icon: 'Inventory', path: '/catalogue/products' },
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
  // Add more sections/items as needed
];
