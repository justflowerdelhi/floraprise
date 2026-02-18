/**
 * Purchase Entry Form — Utility Functions
 */

import type { PurchaseItem, OrderSummary } from '../types/purchase.types';

/**
 * Calculate row total
 */
export const calcRowTotal = (quantity: number, costPerUnit: number): number => {
  return Math.round(quantity * costPerUnit * 100) / 100;
};

/**
 * Calculate margin for a single item
 */
export const calcMargin = (
  costPerUnit: number,
  sellingPrice: number
): { marginAmount: number; marginPercent: number } => {
  if (sellingPrice <= 0) return { marginAmount: 0, marginPercent: 0 };
  const marginAmount = Math.round((sellingPrice - costPerUnit) * 100) / 100;
  const marginPercent =
    Math.round((marginAmount / sellingPrice) * 100 * 10) / 10;
  return { marginAmount, marginPercent };
};

/**
 * Get margin status color
 */
export const getMarginColor = (marginPercent: number): string => {
  if (marginPercent >= 50) return '#2e7d32'; // green
  if (marginPercent >= 30) return '#388e3c';
  if (marginPercent >= 15) return '#f57c00'; // orange
  if (marginPercent > 0) return '#e65100'; // dark orange
  return '#c62828'; // red / negative
};

/**
 * Get margin severity for MUI
 */
export const getMarginSeverity = (
  marginPercent: number
): 'success' | 'warning' | 'error' | 'info' => {
  if (marginPercent >= 30) return 'success';
  if (marginPercent >= 15) return 'warning';
  return 'error';
};

/**
 * Calculate expiry date from purchase date + shelf life
 */
export const calcExpiryDate = (
  purchaseDate: string,
  shelfLifeDays: number
): string => {
  if (!purchaseDate || shelfLifeDays <= 0) return '';
  const d = new Date(purchaseDate);
  d.setDate(d.getDate() + shelfLifeDays);
  return d.toISOString().split('T')[0];
};

/**
 * Get days until expiry
 */
export const getDaysUntilExpiry = (expiryDate: string): number => {
  if (!expiryDate) return Infinity;
  const now = new Date();
  now.setHours(0, 0, 0, 0);
  const exp = new Date(expiryDate);
  return Math.ceil((exp.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
};

/**
 * Get expiry status color & label
 */
export const getExpiryStatus = (
  expiryDate: string
): { color: string; label: string; severity: 'success' | 'warning' | 'error' } => {
  const days = getDaysUntilExpiry(expiryDate);
  if (days <= 0) return { color: '#c62828', label: 'EXPIRED', severity: 'error' };
  if (days <= 3) return { color: '#e65100', label: `${days}d left`, severity: 'error' };
  if (days <= 7) return { color: '#f57c00', label: `${days}d left`, severity: 'warning' };
  return { color: '#2e7d32', label: `${days}d left`, severity: 'success' };
};

/**
 * Calculate full order summary
 */
export const calcOrderSummary = (
  items: PurchaseItem[],
  taxRate: number,
  shippingCost: number
): OrderSummary => {
  const validItems = items.filter((i) => i.productId && i.quantity > 0 && i.costPerUnit > 0);

  const subtotal = validItems.reduce((sum, i) => sum + i.total, 0);
  const taxAmount = Math.round(subtotal * (taxRate / 100) * 100) / 100;
  const grandTotal = Math.round((subtotal + taxAmount + shippingCost) * 100) / 100;

  const marginsWithSelling = validItems.filter((i) => i.sellingPrice > 0);
  const averageMargin =
    marginsWithSelling.length > 0
      ? Math.round(
          (marginsWithSelling.reduce((sum, i) => sum + i.marginPercent, 0) /
            marginsWithSelling.length) *
            10
        ) / 10
      : 0;

  const lowMarginItems = validItems.filter(
    (i) => i.sellingPrice > 0 && i.marginPercent < 15
  ).length;

  const perishableItems = validItems.filter((i) => i.isPerishable).length;

  const expiryDates = validItems
    .filter((i) => i.isPerishable && i.expiryDate)
    .map((i) => i.expiryDate)
    .sort();

  return {
    itemCount: validItems.length,
    subtotal: Math.round(subtotal * 100) / 100,
    taxRate,
    taxAmount,
    shippingCost,
    grandTotal,
    averageMargin,
    lowMarginItems,
    perishableItems,
    earliestExpiry: expiryDates[0] || null,
  };
};

/**
 * Generate batch number
 */
export const generateBatchNumber = (sku: string): string => {
  const date = new Date().toISOString().split('T')[0].replace(/-/g, '');
  const rand = Math.random().toString(36).substring(2, 6).toUpperCase();
  return `${sku}-${date}-${rand}`;
};

/**
 * Format currency
 */
export const fmt = (n: number): string =>
  new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
  }).format(n);

/**
 * Draft persistence
 */
export const saveDraftToStorage = (data: unknown) => {
  try {
    localStorage.setItem('purchase_draft', JSON.stringify(data));
  } catch { /* ignore quota errors */ }
};

export const loadDraftFromStorage = (): unknown | null => {
  try {
    const raw = localStorage.getItem('purchase_draft');
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
};

export const clearDraftFromStorage = () => {
  localStorage.removeItem('purchase_draft');
};
