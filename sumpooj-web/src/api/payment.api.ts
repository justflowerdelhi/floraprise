/**
 * payment.api.ts — Payments API Service
 *
 * Endpoints:
 *   GET   /Payments/:id
 *   GET   /Payments/by-order/:orderId
 *   POST  /Payments
 *   PATCH /Payments/:id/approve
 *   PATCH /Payments/:id/card-details
 *   PATCH /Payments/:id/terminal-response
 *   PATCH /Payments/:id/decline
 *   PATCH /Payments/:id/void
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface CreatePaymentRequest {
  orderId: string;
  method: string;
  amount: number;
  locationId?: string | null;
}

export interface ApprovePaymentRequest {
  transactionId?: string | null;
  authorizationCode?: string | null;
}

export interface CardDetailsRequest {
  cardBrand: string;
  last4: string;
}

export interface TerminalResponseDto {
  terminalId: string;
  responseCode: string;
  message: string;
  receiptData?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

export const getPaymentById = async (id: string) => {
  const res = await api.get(`/Payments/${id}`);
  return res.data;
};

export const getPaymentsByOrder = async (orderId: string) => {
  const res = await api.get(`/Payments/by-order/${orderId}`);
  return res.data;
};

export const createPayment = async (data: CreatePaymentRequest) => {
  const res = await api.post('/Payments', data);
  return res.data;
};

export const approvePayment = async (id: string, data?: ApprovePaymentRequest) => {
  const res = await api.patch(`/Payments/${id}/approve`, data);
  return res.data;
};

export const updateCardDetails = async (id: string, data: CardDetailsRequest) => {
  const res = await api.patch(`/Payments/${id}/card-details`, data);
  return res.data;
};

export const sendTerminalResponse = async (id: string, data: TerminalResponseDto) => {
  const res = await api.patch(`/Payments/${id}/terminal-response`, data);
  return res.data;
};

export const declinePayment = async (id: string) => {
  const res = await api.patch(`/Payments/${id}/decline`);
  return res.data;
};

export const voidPayment = async (id: string) => {
  const res = await api.patch(`/Payments/${id}/void`);
  return res.data;
};
