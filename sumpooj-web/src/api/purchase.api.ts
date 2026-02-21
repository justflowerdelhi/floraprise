/**
 * purchase.api.ts — Purchases API Service
 *
 * Endpoints:
 *   GET  /purchases/search
 *   GET  /purchases/:id
 *   POST /purchases
 *   POST /purchases/:id/submit
 *   POST /purchases/:id/approve
 *   POST /purchases/:id/receive
 *   POST /purchases/:id/cancel
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface PurchaseSearchParams {
  Query?: string;
  SupplierId?: string;
  Status?: string;
  FromDate?: string;
  ToDate?: string;
  Page?: number;
  PageSize?: number;
}

export interface PurchaseOrderItemRequest {
  productId: string;
  productName: string;
  sku?: string | null;
  unit?: string | null;
  quantity: number;
  costPerUnit: number;
  isPerishable: boolean;
  shelfLifeDays: number;
  batchNumber?: string | null;
  expiryDate?: string | null;
  storageLocation?: string | null;
  sellingPrice?: number | null;
}

export interface CreatePurchaseOrderRequest {
  supplierId: string;
  invoiceNumber?: string | null;
  purchaseDate: string;
  expectedDeliveryDate: string;
  paymentTerms?: string | null;
  location?: string | null;
  shippingCost: number;
  taxRate: number;
  notes?: string | null;
  items: PurchaseOrderItemRequest[];
}

export interface ReceiveItemRequest {
  productId: string;
  receivedQuantity: number;
  batchNumber?: string | null;
  expiryDate?: string | null;
  storageLocation?: string | null;
}

export interface ReceivePurchaseOrderRequest {
  actualDeliveryDate: string;
  items: ReceiveItemRequest[];
}

// ─── API Functions ──────────────────────────────────────────

export const searchPurchases = async (params: PurchaseSearchParams = {}) => {
  const res = await api.get('/purchases/search', { params });
  return res.data;
};

export const getPurchaseById = async (id: string) => {
  const res = await api.get(`/purchases/${id}`);
  return res.data;
};

export const createPurchaseOrder = async (data: CreatePurchaseOrderRequest) => {
  const res = await api.post('/purchases', data);
  return res.data;
};

export const submitPurchaseOrder = async (id: string) => {
  const res = await api.post(`/purchases/${id}/submit`);
  return res.data;
};

export const approvePurchaseOrder = async (id: string) => {
  const res = await api.post(`/purchases/${id}/approve`);
  return res.data;
};

export const receivePurchaseOrder = async (id: string, data: ReceivePurchaseOrderRequest) => {
  const res = await api.post(`/purchases/${id}/receive`, data);
  return res.data;
};

export const cancelPurchaseOrder = async (id: string) => {
  const res = await api.post(`/purchases/${id}/cancel`);
  return res.data;
};
