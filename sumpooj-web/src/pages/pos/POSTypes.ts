/**
 * POSTypes.ts — Type definitions for the FloraEdge POS system
 */

import type { Product, CartItem, CartSummary, OrderPaymentEntry } from '../orders/OrderTypes';
import type { Customer as CRMCustomer } from '../crm/CRMTypes';

// ─── Category Types ─────────────────────────────────────────

export interface POSCategory {
  id: string;
  name: string;
  icon: string;
  color?: string;
}

export const POS_CATEGORIES: POSCategory[] = [
  { id: 'all', name: 'All', icon: 'GridView' },
  { id: 'fresh-flowers', name: 'Fresh Flowers', icon: 'LocalFlorist' },
  { id: 'arrangements', name: 'Arrangements', icon: 'Spa' },
  { id: 'bouquets', name: 'Bouquets', icon: 'Yard' },
  { id: 'plants', name: 'Plants', icon: 'Park' },
  { id: 'greens', name: 'Greens', icon: 'Grass' },
  { id: 'supplies', name: 'Supplies', icon: 'Inventory2' },
  { id: 'add-ons', name: 'Add-Ons', icon: 'Redeem' },
  { id: 'gifts', name: 'Gifts', icon: 'CardGiftcard' },
];

// ─── Order Type Options ─────────────────────────────────────

export type POSOrderType = 'local' | 'delivery' | 'pickup';

export interface POSOrderTypeOption {
  value: POSOrderType;
  label: string;
  icon: string;
}

export const POS_ORDER_TYPES: POSOrderTypeOption[] = [
  { value: 'local', label: 'Local', icon: 'Store' },
  { value: 'delivery', label: 'Delivery', icon: 'LocalShipping' },
  { value: 'pickup', label: 'Pickup', icon: 'ShoppingBag' },
];

// ─── Stock Status ───────────────────────────────────────────

export type StockStatus = 'in-stock' | 'low-stock' | 'out-of-stock';

export const getStockStatus = (stock: number): StockStatus => {
  if (stock <= 0) return 'out-of-stock';
  if (stock <= 5) return 'low-stock';
  return 'in-stock';
};

export const STOCK_STATUS_CONFIG: Record<StockStatus, { label: string; color: string; bgColor: string }> = {
  'in-stock': { label: 'In Stock', color: '#15803d', bgColor: '#dcfce7' },
  'low-stock': { label: 'Low Stock', color: '#b45309', bgColor: '#fef3c7' },
  'out-of-stock': { label: 'Out of Stock', color: '#dc2626', bgColor: '#fee2e2' },
};

// ─── Payment Types ──────────────────────────────────────────

export type POSPaymentMethod = 'CASH' | 'CARD' | 'UPI' | 'STORE_CREDIT' | 'GIFT_CARD';

export interface POSPaymentEntry {
  id: string;
  method: POSPaymentMethod;
  amount: number;
  reference?: string;
}

export interface POSBillingInfo {
  name: string;
  email: string;
  phone?: string;
}

// ─── Cart Line Item Add-On ──────────────────────────────────

export interface CartAddOn {
  id: string;
  name: string;
  price: number;
}

// ─── Keyboard Shortcuts ─────────────────────────────────────

export const POS_SHORTCUTS = {
  SEARCH: 'F2',
  CHECKOUT: 'F9',
  HOLD: 'F4',
  CLEAR: 'F8',
  CUSTOMER: 'F3',
} as const;

// ─── Re-exports for convenience ─────────────────────────────

export type { Product, CartItem, CartSummary, OrderPaymentEntry };
export type POSCustomer = CRMCustomer;
