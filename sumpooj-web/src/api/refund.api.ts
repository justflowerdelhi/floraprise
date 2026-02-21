/**
 * refund.api.ts — Refunds API Service
 *
 * Endpoints:
 *   GET  /Refunds/:id
 *   GET  /Refunds/by-order/:orderId
 *   POST /Refunds
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface RefundItemRequest {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  restock: boolean;
}

export interface CreateRefundRequest {
  orderId: string;
  method: string;
  reason: string;
  items: RefundItemRequest[];
}

// ─── API Functions ──────────────────────────────────────────

export const getRefundById = async (id: string) => {
  const res = await api.get(`/Refunds/${id}`);
  return res.data;
};

export const getRefundsByOrder = async (orderId: string) => {
  const res = await api.get(`/Refunds/by-order/${orderId}`);
  return res.data;
};

export const createRefund = async (data: CreateRefundRequest) => {
  const res = await api.post('/Refunds', data);
  return res.data;
};
