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

// ─── Order Intent ───────────────────────────────────────────

export type OrderIntent = 'TAKE_NOW' | 'DELIVERY' | 'PICKUP_LATER';

export interface OrderIntentOption {
  value: OrderIntent;
  label: string;
  icon: string;
  shortcut?: string;
}

export const ORDER_INTENT_OPTIONS: OrderIntentOption[] = [
  { value: 'TAKE_NOW', label: 'Take Now', icon: 'Store', shortcut: 'F5' },
  { value: 'DELIVERY', label: 'Delivery', icon: 'LocalShipping', shortcut: 'F6' },
  { value: 'PICKUP_LATER', label: 'Pickup Later', icon: 'ShoppingBag', shortcut: 'F7' },
];

/** @deprecated Alias kept for backward-compat — use OrderIntent instead */
export type POSOrderType = OrderIntent;

// ─── Delivery Details ───────────────────────────────────────

export interface DeliveryDetails {
  address: string;
  zipCode: string;
  recipientName: string;
  recipientPhone: string;
  deliveryDate: string;      // ISO date
  deliveryTimeSlot?: string;
  deliveryFee: number;
  instructions?: string;
}

export const EMPTY_DELIVERY_DETAILS: DeliveryDetails = {
  address: '',
  zipCode: '',
  recipientName: '',
  recipientPhone: '',
  deliveryDate: '',
  deliveryTimeSlot: '',
  deliveryFee: 0,
  instructions: '',
};

/**
 * Auto-calculate delivery fee from ZIP code.
 * Simple zone-based logic: local = $0, nearby = $8, far = $15, unknown = $12.
 */
export const calcDeliveryFeeFromZip = (zip: string): number => {
  if (!zip || zip.length < 5) return 0;
  const prefix = parseInt(zip.substring(0, 3), 10);
  if (isNaN(prefix)) return 0;
  // Local zone
  if (prefix >= 100 && prefix <= 119) return 0;
  // Nearby zone
  if (prefix >= 120 && prefix <= 149) return 8;
  // Far zone
  if (prefix >= 150 && prefix <= 199) return 15;
  // Default
  return 12;
};

// ─── Pickup Details ─────────────────────────────────────────

export interface PickupDetails {
  pickupDate: string;        // ISO date
  pickupTimeSlot?: string;
  contactName: string;
  contactPhone: string;
}

export const EMPTY_PICKUP_DETAILS: PickupDetails = {
  pickupDate: '',
  pickupTimeSlot: '',
  contactName: '',
  contactPhone: '',
};

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
