/**
 * production.api.ts — API Service Layer for Floral Production Engine
 *
 * Connected to backend /api/production endpoints.
 */

import { apiClient } from "../../../core/api/apiClient";
import { safeArray } from "../../../utils/safeArray";
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
} from "../types/ProductionTypes";

type InventoryProductLike = Partial<InventoryProduct> & {
  id?: string;
  productId?: string;
  name?: string;
  productName?: string;
  productType?: string;
  quantityAvailable?: number;
  availableUnits?: number;
  unitCost?: number;
  unitPrice?: number;
  locationId?: string;
};

const extractArrayPayload = (payload: unknown): unknown[] => {
  if (Array.isArray(payload)) return payload;
  if (!payload || typeof payload !== "object") return [];

  const candidate = payload as {
    items?: unknown;
    Items?: unknown;
    data?: unknown;
    results?: unknown;
  };

  if (Array.isArray(candidate.items)) return candidate.items;
  if (Array.isArray(candidate.Items)) return candidate.Items;
  if (Array.isArray(candidate.data)) return candidate.data;
  if (Array.isArray(candidate.results)) return candidate.results;
  return [];
};

const normalizeInventoryProduct = (p: InventoryProductLike): InventoryProduct => ({
  id: String(p.id ?? p.productId ?? ""),
  name: String(p.name ?? p.productName ?? ""),
  productType: String(p.productType ?? "Unknown"),
  quantityAvailable: Number(p.quantityAvailable ?? p.availableUnits ?? 0),
  unitCost: Number(p.unitCost ?? p.unitPrice ?? 0),
  locationId: String(p.locationId ?? ""),
});

// ─── Recipes ────────────────────────────────────────────────

export const getRecipes = async (): Promise<FloralRecipe[]> => {
  const res = await apiClient.get("/production/recipes");
  return safeArray(res.data);
};

export const getRecipeById = async (
  id: string
): Promise<FloralRecipe | undefined> => {
  return (await apiClient.get(`/production/recipes/${id}`)).data;
};

export const createRecipe = async (
  recipe: Omit<FloralRecipe, "id" | "createdAt" | "updatedAt">
): Promise<FloralRecipe> => {
  return (await apiClient.post("/production/recipes", recipe)).data;
};

export const updateRecipe = async (
  id: string,
  recipe: Partial<FloralRecipe>
): Promise<FloralRecipe> => {
  return (await apiClient.put(`/production/recipes/${id}`, recipe)).data;
};

export const deleteRecipe = async (id: string): Promise<void> => {
  await apiClient.delete(`/production/recipes/${id}`);
};

// ─── Finished Goods ─────────────────────────────────────────

export const getFinishedBatches = async (): Promise<FinishedGoodsBatch[]> => {
  const res = await apiClient.get("/production/finished-batches");
  return safeArray(res.data);
};

export const getFinishedBatchById = async (
  id: string
): Promise<FinishedGoodsBatch | undefined> => {
  return (await apiClient.get(`/production/finished-goods/${id}`)).data;
};

// ─── Production Runs ────────────────────────────────────────

export const createProductionRun = async (
  request: ProductionRunRequest
): Promise<ProductionRunResult> => {
  return (await apiClient.post("/production/runs", request)).data;
};

// ─── On-Demand Assembly ─────────────────────────────────────

export const createOnDemandAssembly = async (
  request: OnDemandAssemblyRequest
): Promise<{
  success: boolean;
  componentsDeducted: { productId: string; quantityDeducted: number }[];
}> => {
  return (await apiClient.post("/production/on-demand", request)).data;
};

// ─── Custom Bouquet ─────────────────────────────────────────

export const createCustomBouquetAndSell = async (
  request: CustomBouquetRequest
): Promise<{ success: boolean }> => {
  return (await apiClient.post("/production/custom/sell", request)).data;
};

export const saveCustomBouquetAsRecipe = async (
  request: CustomBouquetRequest & { name: string; category?: string }
): Promise<FloralRecipe> => {
  return (await apiClient.post("/production/custom/save-recipe", request)).data;
};

// ─── Maintenance ────────────────────────────────────────────

export const performMaintenance = async (
  request: MaintenanceRequest
): Promise<ProductionMaintenanceLog> => {
  return (await apiClient.post("/production/maintenance", request)).data;
};

export const getMaintenanceLogs =
  async (): Promise<ProductionMaintenanceLog[]> => {
    const res = await apiClient.get("/production/maintenance");
    return safeArray(res.data);
  };

// ─── Wastage ────────────────────────────────────────────────

export const getWastageLogs = async (): Promise<WastageLog[]> => {
  const res = await apiClient.get("/production/wastage");
  return safeArray(res.data);
};

export const createWastageEntry = async (
  entry: Omit<WastageLog, "id" | "createdAt">
): Promise<WastageLog> => {
  return (await apiClient.post("/production/wastage", entry)).data;
};

// ─── Inventory Products (for component selection) ───────────

export const getInventoryProducts = async (locationId?: string) => {
  const params = locationId ? { locationId } : undefined;

  try {
    const res = await apiClient.get('/inventory/products', { params });
    const normalized = extractArrayPayload(res.data)
      .map((p) => normalizeInventoryProduct(p as InventoryProductLike))
      .filter((p) => p.id && p.name);

    if (normalized.length > 0) return normalized;
  } catch {
    // Fall back to production-scoped endpoint below.
  }

  // Production fallback requires a locationId in backend contract.
  if (!locationId) {
    return [];
  }

  const fallbackRes = await apiClient.get('/production/inventory-products', { params });
  return safeArray<InventoryProductLike>(extractArrayPayload(fallbackRes.data))
    .map((p) => normalizeInventoryProduct(p))
    .filter((p) => p.id && p.name);
};

// ─── Image Upload ───────────────────────────────────────────

export const uploadImage = async (file: File): Promise<string> => {
  // Client-side preview — real upload can be added when backend supports it
  return URL.createObjectURL(file);
};