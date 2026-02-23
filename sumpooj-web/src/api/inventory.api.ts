/**
 * inventory.api.ts — Inventory API Service
 *
 * Endpoints:
 *   GET  /inventory/batches
 *   POST /inventory/batches
 *   GET  /inventory/batches/:id
 *   GET  /inventory/batches/by-product/:productId
 *   GET  /inventory/expiry-alerts
 *   GET  /inventory/summary
 *   GET  /inventory/adjustments
 *   POST /inventory/adjustments
 *   GET  /inventory/adjustments/recent
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface BatchSearchParams {
  Query?: string;
  ProductId?: string;
  SupplierId?: string;
  LocationId?: string;
  IsActive?: boolean;
  IsPerishable?: boolean;
  ExpiringOnly?: boolean;
  ExpiringWithinDays?: number;
  Page?: number;
  PageSize?: number;
}

export interface CreateBatchRequest {
  productId: string;
  batchNumber: string;
  quantity: number;
  costPerUnit: number;
  sellingPricePerUnit?: number | null;
  receivedDate: string;
  expiryDate?: string | null;
  supplierId?: string | null;
  locationId?: string | null;
  storageLocation?: string | null;
}

export interface AdjustmentSearchParams {
  ProductId?: string;
  BatchId?: string;
  AdjustmentType?: string;
  FromDate?: string;
  ToDate?: string;
  Page?: number;
  PageSize?: number;
}

export interface CreateAdjustmentRequest {
  productId: string;
  batchId?: string | null;
  adjustmentType: string;
  quantity: number;
  costPerUnit: number;
  reason: string;
  adjustmentDate: string;
  notes?: string | null;
}

export interface ExpiryAlertParams {
  criticalDays?: number;
  warningDays?: number;
  upcomingDays?: number;
}

// ─── API Functions ──────────────────────────────────────────

export const searchBatches = async (params: BatchSearchParams = {}) => {
  const res = await api.get('/inventory/batches', { params });
  return res.data;
};

export const createBatch = async (data: CreateBatchRequest) => {
  const res = await api.post('/inventory/batches', data);
  return res.data;
};

export const getBatchById = async (id: string) => {
  const res = await api.get(`/inventory/batches/${id}`);
  return res.data;
};

export const getBatchesByProduct = async (productId: string) => {
  const res = await api.get(`/inventory/batches/by-product/${productId}`);
  return res.data;
};

export const getExpiryAlerts = async (params: ExpiryAlertParams = {}) => {
  const res = await api.get('/inventory/expiry-alerts', { params });
  return res.data;
};

export const getInventorySummary = async () => {
  const res = await api.get('/inventory/summary');
  return res.data;
};

export const searchAdjustments = async (params: AdjustmentSearchParams = {}) => {
  const res = await api.get('/inventory/adjustments', { params });
  return res.data;
};

export const createAdjustment = async (data: CreateAdjustmentRequest) => {
  const res = await api.post('/inventory/adjustments', data);
  return res.data;
};

export const getRecentAdjustments = async (count = 10) => {
  const res = await api.get('/inventory/adjustments/recent', { params: { count } });
  return res.data;
};

// ─── Batch Summary (aggregated inventory projections) ───────

export interface BatchSummaryItem {
  batchId: string;
  productId: string;
  productName: string;
  batchNumber: string;
  stemsInStock: number;
  totalUnits: number;
  usedUnits: number;
  damagedUnits: number;
  reservedUnits: number;
  availableUnits: number;
  consumedStems: number;
  remainingStems: number;
  partialUsedUnits: number;
}

export const getBatchSummary = async (): Promise<BatchSummaryItem[]> => {
  const res = await api.get('/inventory/batch-summary');
  return res.data;
};
