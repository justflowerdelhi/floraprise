/**
 * production.utils.ts — Utility functions for Floral Production Engine
 */

import type { FloralRecipe, RecipeComponent, FinishedGoodsBatch, WastageLog } from '../types/ProductionTypes';

// ─── Cost Calculations ──────────────────────────────────────

export const calculateComponentCost = (components: RecipeComponent[]): number =>
  components.reduce((sum, c) => sum + c.unitCost * c.quantityRequired, 0);

export const calculateTotalCost = (recipe: FloralRecipe): number =>
  calculateComponentCost(recipe.components) + (recipe.laborCost ?? 0);

export const calculateMargin = (recipe: FloralRecipe): number => {
  const cost = calculateTotalCost(recipe);
  if (recipe.sellingPrice === 0) return 0;
  return ((recipe.sellingPrice - cost) / recipe.sellingPrice) * 100;
};

export const calculateBatchTotalCost = (recipe: FloralRecipe, quantity: number): number =>
  calculateTotalCost(recipe) * quantity;

// ─── Batch Code Generation ──────────────────────────────────

export const generateBatchCode = (sequence: number): string => {
  const d = new Date();
  const dateStr = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
  return `FG-${dateStr}-${String(sequence).padStart(3, '0')}`;
};

export const generateBarcode = (sequence: number): string =>
  `890123456${String(sequence).padStart(4, '0')}`;

// ─── Expiry Helpers ─────────────────────────────────────────

export const isExpired = (expiryDate: string): boolean =>
  new Date(expiryDate) < new Date();

export const hoursUntilExpiry = (expiryDate: string): number => {
  const diff = new Date(expiryDate).getTime() - Date.now();
  return Math.round(diff / (1000 * 60 * 60));
};

export const expiryStatusColor = (expiryDate: string): 'success' | 'warning' | 'error' | 'default' => {
  const hours = hoursUntilExpiry(expiryDate);
  if (hours <= 0) return 'error';
  if (hours <= 12) return 'warning';
  if (hours <= 48) return 'default';
  return 'success';
};

export const expiryLabel = (expiryDate: string): string => {
  const hours = hoursUntilExpiry(expiryDate);
  if (hours <= 0) return 'Expired';
  if (hours < 24) return `${hours}h left`;
  const days = Math.floor(hours / 24);
  return `${days}d ${hours % 24}h left`;
};

// ─── Batch Status Helpers ───────────────────────────────────

export const getBatchDisplayStatus = (batch: FinishedGoodsBatch): { label: string; color: 'success' | 'warning' | 'error' | 'default' } => {
  if (batch.status === 'DISCARDED') return { label: 'Discarded', color: 'default' };
  if (batch.status === 'EXPIRED' || isExpired(batch.expectedExpiry)) return { label: 'Expired', color: 'error' };
  if (batch.quantityAvailable === 0) return { label: 'Sold Out', color: 'default' };
  const hours = hoursUntilExpiry(batch.expectedExpiry);
  if (hours <= 12) return { label: 'Expiring Soon', color: 'warning' };
  return { label: 'Active', color: 'success' };
};

export const isBatchSellable = (batch: FinishedGoodsBatch): boolean =>
  batch.status === 'ACTIVE' && batch.quantityAvailable > 0 && !isExpired(batch.expectedExpiry);

export const isBatchMaintainable = (batch: FinishedGoodsBatch): boolean =>
  batch.status === 'ACTIVE' && batch.quantityAvailable > 0;

// ─── Currency Formatter ─────────────────────────────────────

import { formatCurrency as _coreFormatCurrency } from '../../../core/i18n';

export const formatCurrency = (amount: number): string => _coreFormatCurrency(amount);

// ─── Date Formatter ─────────────────────────────────────────

export const formatDateTime = (iso: string): string => {
  const d = new Date(iso);
  return d.toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
};

export const formatDate = (iso: string): string => {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { dateStyle: 'medium' });
};

// ─── Wastage Aggregation ────────────────────────────────────

export interface WastageSummary {
  totalQuantity: number;
  byReason: Record<string, number>;
  byProduct: Record<string, number>;
}

export const aggregateWastage = (logs: WastageLog[]): WastageSummary => {
  const summary: WastageSummary = { totalQuantity: 0, byReason: {}, byProduct: {} };
  for (const log of logs) {
    summary.totalQuantity += log.quantity;
    summary.byReason[log.reason] = (summary.byReason[log.reason] ?? 0) + log.quantity;
    summary.byProduct[log.productName] = (summary.byProduct[log.productName] ?? 0) + log.quantity;
  }
  return summary;
};

// ─── Stock Sufficiency Check ────────────────────────────────

export interface StockCheck {
  productId: string;
  productName: string;
  required: number;
  available: number;
  sufficient: boolean;
}

export const checkStockSufficiency = (
  components: RecipeComponent[],
  quantity: number,
  inventory: { id: string; quantityAvailable: number }[],
): StockCheck[] => {
  return components.map((c) => {
    const inv = inventory.find((i) => i.id === c.productId);
    const available = inv?.quantityAvailable ?? 0;
    const required = c.quantityRequired * quantity;
    return {
      productId: c.productId,
      productName: c.productName,
      required,
      available,
      sufficient: available >= required,
    };
  });
};
