/**
 * production.api.ts — API Service Layer for Floral Production Engine
 *
 * API-ready architecture: currently uses mock data,
 * swap to real endpoints by changing the implementations below.
 */

import _api from '../../../api/axios'; // TODO: rename to `api` when switching to real endpoints
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
import {
  fetchRecipes,
  fetchFinishedBatches,
  fetchMaintenanceLogs,
  fetchWastageLogs,
  fetchInventoryProducts,
  MOCK_RECIPES,
  MOCK_FINISHED_BATCHES,
} from '../data/ProductionMockData';

// ─── Recipes ────────────────────────────────────────────────

export const getRecipes = async (): Promise<FloralRecipe[]> => {
  // TODO: return (await api.get('/production/recipes')).data;
  return fetchRecipes();
};

export const getRecipeById = async (id: string): Promise<FloralRecipe | undefined> => {
  // TODO: return (await api.get(`/production/recipes/${id}`)).data;
  const recipes = await fetchRecipes();
  return recipes.find((r) => r.id === id);
};

export const createRecipe = async (recipe: Omit<FloralRecipe, 'id' | 'createdAt' | 'updatedAt'>): Promise<FloralRecipe> => {
  // TODO: return (await api.post('/production/recipes', recipe)).data;
  const newRecipe: FloralRecipe = {
    ...recipe,
    id: `recipe-${Date.now()}`,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
  MOCK_RECIPES.push(newRecipe);
  return newRecipe;
};

export const updateRecipe = async (id: string, recipe: Partial<FloralRecipe>): Promise<FloralRecipe> => {
  // TODO: return (await api.put(`/production/recipes/${id}`, recipe)).data;
  const idx = MOCK_RECIPES.findIndex((r) => r.id === id);
  if (idx === -1) throw new Error('Recipe not found');
  MOCK_RECIPES[idx] = { ...MOCK_RECIPES[idx], ...recipe, updatedAt: new Date().toISOString() };
  return MOCK_RECIPES[idx];
};

export const deleteRecipe = async (id: string): Promise<void> => {
  // TODO: await api.delete(`/production/recipes/${id}`);
  const idx = MOCK_RECIPES.findIndex((r) => r.id === id);
  if (idx !== -1) MOCK_RECIPES.splice(idx, 1);
};

// ─── Finished Goods ─────────────────────────────────────────

export const getFinishedBatches = async (): Promise<FinishedGoodsBatch[]> => {
  // TODO: return (await api.get('/production/finished-goods')).data;
  return fetchFinishedBatches();
};

export const getFinishedBatchById = async (id: string): Promise<FinishedGoodsBatch | undefined> => {
  // TODO: return (await api.get(`/production/finished-goods/${id}`)).data;
  const batches = await fetchFinishedBatches();
  return batches.find((b) => b.id === id);
};

// ─── Production Runs ────────────────────────────────────────

export const createProductionRun = async (request: ProductionRunRequest): Promise<ProductionRunResult> => {
  // TODO: return (await api.post('/production/runs', request)).data;
  // Mock: simulate backend transactional logic
  const recipe = MOCK_RECIPES.find((r) => r.id === request.recipeId);
  if (!recipe) throw new Error('Recipe not found');

  const batchCode = `FG-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${String(MOCK_FINISHED_BATCHES.length + 1).padStart(3, '0')}`;
  const barcode = `890123456${String(MOCK_FINISHED_BATCHES.length + 1).padStart(4, '0')}`;

  const componentsDeducted = recipe.components.map((c) => ({
    productId: c.productId,
    quantityDeducted: c.quantityRequired * request.quantity,
  }));

  const totalCost = recipe.components.reduce((sum, c) => sum + c.unitCost * c.quantityRequired * request.quantity, 0)
    + (recipe.laborCost ?? 0) * request.quantity;

  const batch: FinishedGoodsBatch = {
    id: `fb-${Date.now()}`,
    recipeId: recipe.id,
    recipeName: recipe.name,
    batchCode,
    barcode,
    quantityProduced: request.quantity,
    quantityAvailable: request.quantity,
    expectedExpiry: request.expectedExpiry,
    locationId: request.locationId,
    locationName: 'Location', // resolved by backend
    status: 'ACTIVE',
    producedAt: new Date().toISOString(),
  };

  MOCK_FINISHED_BATCHES.push(batch);

  return {
    batchId: batch.id,
    batchCode,
    barcode,
    quantityProduced: request.quantity,
    componentsDeducted,
    totalCost,
  };
};

// ─── On-Demand Assembly ─────────────────────────────────────

export const createOnDemandAssembly = async (request: OnDemandAssemblyRequest): Promise<{ success: boolean; componentsDeducted: { productId: string; quantityDeducted: number }[] }> => {
  // TODO: return (await api.post('/production/on-demand', request)).data;
  const recipe = MOCK_RECIPES.find((r) => r.id === request.recipeId);
  if (!recipe) throw new Error('Recipe not found');

  const componentsDeducted = recipe.components.map((c) => ({
    productId: c.productId,
    quantityDeducted: c.quantityRequired * request.quantity,
  }));

  return { success: true, componentsDeducted };
};

// ─── Custom Bouquet ─────────────────────────────────────────

export const createCustomBouquetAndSell = async (_request: CustomBouquetRequest): Promise<{ success: boolean }> => {
  // TODO: return (await api.post('/production/custom/sell', _request)).data;
  return { success: true };
};

export const saveCustomBouquetAsRecipe = async (request: CustomBouquetRequest & { name: string; category?: string }): Promise<FloralRecipe> => {
  // TODO: return (await api.post('/production/custom/save-recipe', request)).data;
  return createRecipe({
    tenantId: 'tenant-001',
    name: request.name,
    category: request.category,
    sellingPrice: request.sellingPrice,
    laborCost: request.laborCost,
    components: request.components.map((c) => ({
      productId: c.productId,
      productName: c.productName,
      quantityRequired: c.quantity,
      unitCost: c.unitCost,
    })),
    sampleImages: request.image ? [request.image] : [],
    isActive: true,
  });
};

// ─── Maintenance ────────────────────────────────────────────

export const performMaintenance = async (request: MaintenanceRequest): Promise<ProductionMaintenanceLog> => {
  // TODO: return (await api.post('/production/maintenance', request)).data;
  const log: ProductionMaintenanceLog = {
    id: `maint-${Date.now()}`,
    finishedBatchId: request.finishedBatchId,
    batchCode: MOCK_FINISHED_BATCHES.find((b) => b.id === request.finishedBatchId)?.batchCode ?? '',
    replacements: request.replacements,
    performedAt: new Date().toISOString(),
    notes: request.notes,
  };
  return log;
};

export const getMaintenanceLogs = async (): Promise<ProductionMaintenanceLog[]> => {
  // TODO: return (await api.get('/production/maintenance')).data;
  return fetchMaintenanceLogs();
};

// ─── Wastage ────────────────────────────────────────────────

export const getWastageLogs = async (): Promise<WastageLog[]> => {
  // TODO: return (await api.get('/production/wastage')).data;
  return fetchWastageLogs();
};

export const createWastageEntry = async (entry: Omit<WastageLog, 'id' | 'createdAt'>): Promise<WastageLog> => {
  // TODO: return (await api.post('/production/wastage', entry)).data;
  return { ...entry, id: `waste-${Date.now()}`, createdAt: new Date().toISOString() };
};

// ─── Inventory Products (for component selection) ───────────

export const getInventoryProducts = async (locationId?: string): Promise<InventoryProduct[]> => {
  // TODO: return (await api.get('/inventory/products', { params: { locationId } })).data;
  return fetchInventoryProducts(locationId);
};

// ─── Image Upload ───────────────────────────────────────────

export const uploadImage = async (file: File): Promise<string> => {
  // TODO: uncomment real upload when API is ready
  // const formData = new FormData();
  // formData.append('file', file);
  // const response = await _api.post('/upload/image', formData, {
  //   headers: { 'Content-Type': 'multipart/form-data' },
  // });
  // return response.data.url;

  // Mock: simulate upload delay and return an object URL as placeholder
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(URL.createObjectURL(file));
    }, 800);
  });
};
