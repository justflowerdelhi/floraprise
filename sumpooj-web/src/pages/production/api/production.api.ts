/**
 * production.api.ts — API Service Layer for Floral Production Engine
 *
 * Connected to backend /api/production endpoints.
 */

import api from '../../../api/axios';
import type {
  FloralRecipe,
  FinishedGoodsBatch,
  ProductionRunRequest,
  ProductionRunResult,
  OnDemandAssemblyRequest,
  CustomBouquetRequest,
  MaintenanceRequest,
  ProductionMaintenanceLog,
  WastageLog,
  InventoryProduct,
} from '../types/ProductionTypes';

// ─── Recipes ────────────────────────────────────────────────

export const getRecipes = async (): Promise<FloralRecipe[]> => {
  return (await api.get('/production/recipes')).data;
};

export const getRecipeById = async (id: string): Promise<FloralRecipe | undefined> => {
  return (await api.get(`/production/recipes/${id}`)).data;
};

export const createRecipe = async (recipe: Omit<FloralRecipe, 'id' | 'createdAt' | 'updatedAt'>): Promise<FloralRecipe> => {
  return (await api.post('/production/recipes', recipe)).data;
};

export const updateRecipe = async (id: string, recipe: Partial<FloralRecipe>): Promise<FloralRecipe> => {
  return (await api.put(`/production/recipes/${id}`, recipe)).data;
};

export const deleteRecipe = async (id: string): Promise<void> => {
  await api.delete(`/production/recipes/${id}`);
};

// ─── Finished Goods ─────────────────────────────────────────

export const getFinishedBatches = async (): Promise<FinishedGoodsBatch[]> => {
  return (await api.get('/production/finished-goods')).data;
};

export const getFinishedBatchById = async (id: string): Promise<FinishedGoodsBatch | undefined> => {
  return (await api.get(`/production/finished-goods/${id}`)).data;
};

// ─── Production Runs ────────────────────────────────────────

export const createProductionRun = async (request: ProductionRunRequest): Promise<ProductionRunResult> => {
  return (await api.post('/production/runs', request)).data;
};

// ─── On-Demand Assembly ─────────────────────────────────────

export const createOnDemandAssembly = async (request: OnDemandAssemblyRequest): Promise<{ success: boolean; componentsDeducted: { productId: string; quantityDeducted: number }[] }> => {
  return (await api.post('/production/on-demand', request)).data;
};

// ─── Custom Bouquet ─────────────────────────────────────────

export const createCustomBouquetAndSell = async (request: CustomBouquetRequest): Promise<{ success: boolean }> => {
  return (await api.post('/production/custom/sell', request)).data;
};

export const saveCustomBouquetAsRecipe = async (request: CustomBouquetRequest & { name: string; category?: string }): Promise<FloralRecipe> => {
  return (await api.post('/production/custom/save-recipe', request)).data;
};

// ─── Maintenance ────────────────────────────────────────────

export const performMaintenance = async (request: MaintenanceRequest): Promise<ProductionMaintenanceLog> => {
  return (await api.post('/production/maintenance', request)).data;
};

export const getMaintenanceLogs = async (): Promise<ProductionMaintenanceLog[]> => {
  return (await api.get('/production/maintenance')).data;
};

// ─── Wastage ────────────────────────────────────────────────

export const getWastageLogs = async (): Promise<WastageLog[]> => {
  return (await api.get('/production/wastage')).data;
};

export const createWastageEntry = async (entry: Omit<WastageLog, 'id' | 'createdAt'>): Promise<WastageLog> => {
  return (await api.post('/production/wastage', entry)).data;
};

// ─── Inventory Products (for component selection) ───────────

export const getInventoryProducts = async (locationId?: string): Promise<InventoryProduct[]> => {
  return (await api.get('/production/inventory-products', { params: { locationId } })).data;
};

// ─── Image Upload ───────────────────────────────────────────

export const uploadImage = async (file: File): Promise<string> => {
  // Client-side preview — real upload can be added when backend supports it
  return URL.createObjectURL(file);
};
