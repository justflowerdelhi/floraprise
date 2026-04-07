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

export const getInventoryProducts = async () => {
  const res = await api.get('/inventory/products');
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

// ─── Inventory Health Dashboard ─────────────────────────────

export interface HealthDashboardParams {
  fromDate?: string;
  toDate?: string;
  locationId?: string;
}

export const getInventoryHealthDashboard = async (params: HealthDashboardParams = {}) => {
  const res = await api.get('/inventory/health-dashboard', { params });
  return res.data;
};

// ─── Inventory Valuation ────────────────────────────────────

export interface ValuationParams {
  asOfDate?: string;
  locationId?: string;
  category?: string;
}

export const getInventoryValuation = async (params: ValuationParams = {}) => {
  const res = await api.get('/inventory/valuation', { params });
  return res.data;
};

// ─── Stock Movements / Ledger ───────────────────────────────

export interface StockMovementParams {
  productId?: string;
  locationId?: string;
  referenceType?: string;
  fromDate?: string;
  toDate?: string;
  page?: number;
  pageSize?: number;
}

export const getStockMovements = async (params: StockMovementParams = {}) => {
  const res = await api.get('/inventory/movements', { params });
  return res.data;
};

// ─── Inventory Ledger ───────────────────────────────────────

export const getInventoryLedger = async (productId: string) => {
  const res = await api.get(`/inventory/ledger/${productId}`);
  return res.data;
};

// ─── Daily Inventory Report ──────────────────────────────────

export interface DailyInventoryReportRow {
  productId: string;
  productName: string;
  openingStock: number;
  purchased: number;
  sold: number;
  adjustments: number;
  closingStock: number;
}

export const getDailyInventoryReport = async (date: string): Promise<DailyInventoryReportRow[]> => {
  const res = await api.get('/inventory/daily-report', { params: { date } });
  return res.data;
};

// ─── Inventory Reconciliation ───────────────────────────────

export interface InventoryReconciliationRow {
  productId: string;
  productName: string;
  trackInventory: boolean;
  trackBatch: boolean;
  productStockQuantity: number;
  batchStockQuantity: number;
  difference: number;
  batchCount: number;
}

export const getInventoryReconciliation = async (
  mismatchesOnly = true,
): Promise<InventoryReconciliationRow[]> => {
  const res = await api.get('/inventory/reconciliation', { params: { mismatchesOnly } });
  return res.data;
};

export interface ReconciliationApplyRequest {
  productId: string;
  expectedDifference?: number;
  reason: string;
  notes?: string;
}

export interface ReconciliationApplyResult {
  productId: string;
  productName: string;
  beforeDifference: number;
  appliedQuantity: number;
  afterDifference: number;
  appliedAdjustmentType: string;
}

export const applyInventoryReconciliationFix = async (
  payload: ReconciliationApplyRequest,
): Promise<ReconciliationApplyResult> => {
  const res = await api.post('/inventory/reconciliation/apply', payload);
  return res.data;
};

// ─── Quick Receive ───────────────────────────────────────────

export interface QuickReceiveItemRequest {
  productId: string;
  quantity: number;
  costPerUnit: number;
  sellingPricePerUnit?: number | null;
  unit?: string | null;
  expiryDate?: string | null;
  shelfLifeDays?: number | null;
  storageLocation?: string | null;
  mergeWithSameDayBatch?: boolean;
}

export interface QuickReceiveRequest {
  supplierId?: string | null;
  locationId: string;
  items: QuickReceiveItemRequest[];
}

export interface QuickReceiveResult {
  purchaseOrderId?: string | null;
  purchaseOrderNumber?: string | null;
  batchIds: string[];
  itemsReceived: number;
}

export const quickReceive = async (data: QuickReceiveRequest): Promise<QuickReceiveResult> => {
  const res = await api.post('/inventory/quick-receive', data);
  return res.data;
};

// ─── Direct Stock Add ────────────────────────────────────────

export interface DirectAddRequest {
  productId: string;
  quantity: number;
  costPerUnit: number;
  locationId: string;
  expiryDate?: string | null;
  storageLocation?: string | null;
  mergeWithSameDayBatch?: boolean;
}

export interface DirectAddResult {
  batchId: string;
  batchNumber: string;
}

export const directAddStock = async (data: DirectAddRequest): Promise<DirectAddResult> => {
  const res = await api.post('/inventory/direct-add', data);
  return res.data;
};
