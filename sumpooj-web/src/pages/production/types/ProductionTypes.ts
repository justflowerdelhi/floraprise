/**
 * ProductionTypes.ts — Floral Production Engine Type Definitions
 *
 * Models:
 * - FloralRecipe (BOM)
 * - FinishedGoodsBatch
 * - ProductionRun
 * - ProductionMaintenanceLog
 * - WastageLog
 * - Custom Bouquet Builder types
 */

// ─── Floral Recipe (BOM) ────────────────────────────────────

export interface RecipeComponent {
  productId: string;
  productName: string;
  quantityRequired: number;
  unitCost: number; // current cost from inventory (for display)
}

export interface FloralRecipe {
  id: string;
  tenantId: string;
  name: string;
  category?: string;
  sellingPrice: number;
  laborCost?: number;
  components: RecipeComponent[];
  sampleImages?: string[];
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export type RecipeCategory =
  | 'Bouquet'
  | 'Arrangement'
  | 'Centerpiece'
  | 'Wreath'
  | 'Corsage'
  | 'Boutonniere'
  | 'Custom';

export const RECIPE_CATEGORIES: RecipeCategory[] = [
  'Bouquet',
  'Arrangement',
  'Centerpiece',
  'Wreath',
  'Corsage',
  'Boutonniere',
  'Custom',
];

// ─── Finished Goods Batch ───────────────────────────────────

export type FinishedBatchStatus = 'ACTIVE' | 'EXPIRED' | 'DISCARDED';

export interface FinishedGoodsBatch {
  id: string;
  recipeId: string;
  recipeName: string;
  batchCode: string;
  barcode: string;
  quantityProduced: number;
  quantityAvailable: number;
  expectedExpiry: string; // ISO datetime
  locationId: string;
  locationName: string;
  status: FinishedBatchStatus;
  producedAt: string;
  productId?: string; // linked Product entry type="FINISHED"
}

// ─── Production Run ─────────────────────────────────────────

export interface ProductionRunRequest {
  recipeId: string;
  quantity: number;
  expectedExpiry: string; // ISO datetime
  locationId: string;
}

export interface ProductionRunResult {
  batchId: string;
  batchCode: string;
  barcode: string;
  quantityProduced: number;
  componentsDeducted: { productId: string; quantityDeducted: number }[];
  totalCost: number;
}

// ─── On-Demand Assembly ─────────────────────────────────────

export interface OnDemandAssemblyRequest {
  recipeId: string;
  quantity: number;
  locationId: string;
}

// ─── Custom Bouquet ─────────────────────────────────────────

export interface CustomBouquetComponent {
  productId: string;
  productName: string;
  quantity: number;
  unitCost: number;
}

export interface CustomBouquetRequest {
  components: CustomBouquetComponent[];
  sellingPrice: number;
  laborCost?: number;
  image?: string;
}

// ─── Maintenance / Repair ───────────────────────────────────

export interface MaintenanceReplacement {
  productId: string;
  productName: string;
  quantityReplaced: number;
  reason: WastageReason;
}

export interface ProductionMaintenanceLog {
  id: string;
  finishedBatchId: string;
  batchCode: string;
  replacements: MaintenanceReplacement[];
  performedAt: string;
  performedBy?: string;
  notes?: string;
}

export interface MaintenanceRequest {
  finishedBatchId: string;
  replacements: MaintenanceReplacement[];
  notes?: string;
}

// ─── Wastage Log ────────────────────────────────────────────

export type WastageReason = 'SPOILED' | 'WILTED' | 'DAMAGED';

export const WASTAGE_REASONS: WastageReason[] = ['SPOILED', 'WILTED', 'DAMAGED'];

export interface WastageLog {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  reason: WastageReason;
  relatedFinishedBatchId?: string;
  relatedBatchCode?: string;
  createdAt: string;
  createdBy?: string;
}

// ─── Inventory Product (simplified for selection) ───────────

export interface InventoryProduct {
  id: string;
  name: string;
  productType: string;
  quantityAvailable: number;
  unitCost: number;
  locationId: string;
}

// ─── POS Finished Good Item ─────────────────────────────────

export interface POSFinishedGoodItem {
  productId: string;
  name: string;
  batchId: string;
  batchCode: string;
  barcode: string;
  sellingPrice: number;
  quantityAvailable: number;
  expectedExpiry: string;
  isExpired: boolean;
  recipeId: string;
}

// ─── Filter / Search Types ──────────────────────────────────

export interface RecipeFilterState {
  search: string;
  category: string;
  activeOnly: boolean;
}

export interface FinishedGoodsFilterState {
  search: string;
  status: FinishedBatchStatus | 'ALL';
  locationId: string;
}

export interface WastageFilterState {
  search: string;
  reason: WastageReason | 'ALL';
  dateFrom: string;
  dateTo: string;
}
