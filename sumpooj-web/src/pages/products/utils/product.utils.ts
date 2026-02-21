/**
 * Product Utilities
 * Helper functions for the product form
 */

import type { ProductType } from '../types/product.types';
import { PRODUCT_TYPES } from '../types/product.types';

// ============================================
// SKU GENERATOR
// ============================================

/**
 * Legacy prefix map kept for backward-compat helpers.
 * New SKU generation uses the dynamic category name.
 */
const productTypePrefixes: Record<ProductType, string> = {
  fresh_flower: 'FLW',
  dried_flower: 'DRY',
  plant: 'PLT',
  arrangement: 'ARR',
  bouquet: 'BQT',
  gift_item: 'GFT',
  container: 'CNT',
  ribbon: 'RBN',
  supply: 'SUP',
  service: 'SVC',
};

/**
 * Derive a 3-char prefix from an arbitrary category name.
 * Takes the first 3 consonants (uppercase). Falls back to first 3 chars.
 */
const derivePrefixFromName = (name: string): string => {
  const clean = name.toUpperCase().replace(/[^A-Z]/g, '');
  const consonants = clean.replace(/[AEIOU]/g, '');
  return (consonants.slice(0, 3) || clean.slice(0, 3)).padEnd(3, 'X');
};

/**
 * Generate a unique SKU.
 *
 * Overloaded:
 *   generateSku(categoryName: string, productName: string)
 *   generateSku(productType: ProductType, productName: string)  // legacy
 */
export const generateSku = (
  categoryOrType: string,
  productName: string,
): string => {
  // Check if the first arg is a known ProductType value
  const legacyPrefix = productTypePrefixes[categoryOrType as ProductType];
  const prefix = legacyPrefix ?? derivePrefixFromName(categoryOrType);
  
  // Extract first 3 consonants from product name (or first 3 chars if not enough)
  const cleanName = productName
    .toUpperCase()
    .replace(/[^A-Z]/g, '');
  
  const consonants = cleanName.replace(/[AEIOU]/g, '');
  const nameCode = (consonants.slice(0, 3) || cleanName.slice(0, 3)).padEnd(3, 'X');
  
  // Generate random 3-digit number
  const randomNum = Math.floor(100 + Math.random() * 900);
  
  return `${prefix}-${nameCode}-${randomNum}`;
};

/**
 * Generate a sequential SKU (for when incrementing)
 */
export const generateSequentialSku = (
  categoryOrType: string,
  lastNumber: number = 0
): string => {
  const legacyPrefix = productTypePrefixes[categoryOrType as ProductType];
  const prefix = legacyPrefix ?? derivePrefixFromName(categoryOrType);
  const nextNumber = String(lastNumber + 1).padStart(5, '0');
  return `${prefix}-${nextNumber}`;
};

// ============================================
// FORMATTING UTILITIES
// ============================================

import { formatCurrency as _coreFormatCurrency } from '../../../core/i18n';

/**
 * Format currency using tenant settings
 */
export const formatCurrency = (value: number): string => _coreFormatCurrency(value);

/**
 * Format percentage
 */
export const formatPercent = (value: number): string => {
  return `${value >= 0 ? '+' : ''}${value.toFixed(1)}%`;
};

/**
 * Parse currency input string to number
 */
export const parseCurrencyInput = (value: string): number => {
  const cleaned = value.replace(/[^0-9.-]/g, '');
  const parsed = parseFloat(cleaned);
  return isNaN(parsed) ? 0 : parsed;
};

// ============================================
// MARGIN CALCULATORS
// ============================================

/**
 * Calculate gross margin percentage
 */
export const calculateMargin = (
  retailPrice: number,
  costPrice: number
): number => {
  if (retailPrice <= 0) return 0;
  return ((retailPrice - costPrice) / retailPrice) * 100;
};

/**
 * Calculate markup percentage
 */
export const calculateMarkup = (
  retailPrice: number,
  costPrice: number
): number => {
  if (costPrice <= 0) return 0;
  return ((retailPrice - costPrice) / costPrice) * 100;
};

/**
 * Calculate profit amount
 */
export const calculateProfit = (
  retailPrice: number,
  costPrice: number
): number => {
  return retailPrice - costPrice;
};

// ============================================
// DATE UTILITIES
// ============================================

/**
 * Calculate expiry date from shelf life
 */
export const calculateExpiryDate = (shelfLifeDays: number): Date => {
  const date = new Date();
  date.setDate(date.getDate() + shelfLifeDays);
  return date;
};

/**
 * Format date for display
 */
export const formatDate = (date: Date): string => {
  return date.toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

/**
 * Get days until expiry
 */
export const getDaysUntilExpiry = (expiryDate: Date): number => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const expiry = new Date(expiryDate);
  expiry.setHours(0, 0, 0, 0);
  const diffTime = expiry.getTime() - today.getTime();
  return Math.ceil(diffTime / (1000 * 60 * 60 * 24));
};

// ============================================
// VALIDATION HELPERS
// ============================================

/**
 * Check if product type requires perishable info
 */
export const isPerishableType = (productType: ProductType): boolean => {
  return productType === 'fresh_flower';
};

/**
 * Check if shelf life is considered low (warning threshold)
 */
export const isLowShelfLife = (days: number): boolean => {
  return days < 5;
};

/**
 * Get product type label from value
 */
export const getProductTypeLabel = (value: ProductType): string => {
  const type = PRODUCT_TYPES.find((t) => t.value === value);
  return type?.label || value;
};

// ============================================
// COLOR UTILITIES
// ============================================

/**
 * Common flower colors for suggestions
 */
export const COMMON_FLOWER_COLORS = [
  'Red',
  'Pink',
  'White',
  'Yellow',
  'Orange',
  'Purple',
  'Lavender',
  'Peach',
  'Coral',
  'Burgundy',
  'Cream',
  'Bi-color',
  'Mixed',
];

/**
 * Common flower varieties
 */
export const COMMON_VARIETIES = {
  fresh_flower: [
    'Freedom',
    'Mondial',
    'Vendela',
    'Explorer',
    'High Magic',
    'Avalanche',
    'Tiffany',
    'Cherry Brandy',
  ],
  plant: [
    'Pothos',
    'Snake Plant',
    'Fiddle Leaf Fig',
    'Peace Lily',
    'Orchid',
    'Succulent',
  ],
};

// ============================================
// DEBOUNCE UTILITY
// ============================================

/**
 * Debounce function for input handlers
 */
export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;
  
  return (...args: Parameters<T>) => {
    if (timeoutId) {
      clearTimeout(timeoutId);
    }
    timeoutId = setTimeout(() => {
      func(...args);
    }, wait);
  };
};

// ============================================
// LOCAL STORAGE HELPERS
// ============================================

const DRAFT_STORAGE_KEY = 'product_form_draft';

/**
 * Save form draft to local storage
 */
export const saveDraftToStorage = <T>(data: T): void => {
  try {
    localStorage.setItem(DRAFT_STORAGE_KEY, JSON.stringify(data));
  } catch (error) {
    console.warn('Failed to save draft to local storage:', error);
  }
};

/**
 * Load form draft from local storage
 */
export const loadDraftFromStorage = <T>(): T | null => {
  try {
    const data = localStorage.getItem(DRAFT_STORAGE_KEY);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    console.warn('Failed to load draft from local storage:', error);
    return null;
  }
};

/**
 * Clear form draft from local storage
 */
export const clearDraftFromStorage = (): void => {
  try {
    localStorage.removeItem(DRAFT_STORAGE_KEY);
  } catch (error) {
    console.warn('Failed to clear draft from local storage:', error);
  }
};
