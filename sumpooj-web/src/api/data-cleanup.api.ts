import api from './axios';

export interface CleanupRequest {
  orderNumbers?: string[];
}

export interface CleanupCandidate {
  orderId: string;
  orderNumber: string;
  orderDate: string;
  totalAmount: number;
  paymentEntries: number;
  revenueEntries: number;
  cogsEntries: number;
  inventoryReductionEntries: number;
}

export interface CleanupPreviewResponse {
  totalIncompleteOrders: number;
  selectedOrders: number;
  targetedOrderNumbers: string[];
  notFoundOrderNumbers: string[];
  candidates: CleanupCandidate[];
}

export interface CleanupDeleteResponse extends CleanupPreviewResponse {
  inventoryLedgersDeleted: number;
  journalEntriesDeleted: number;
  paymentTransactionsDeleted: number;
  paymentsDeleted: number;
  orderItemsDeleted: number;
  ordersDeleted: number;
}

export const previewIncompleteOrders = async (request: CleanupRequest = {}) => {
  const response = await api.post<CleanupPreviewResponse>('/admin/data-cleanup/incomplete-orders/preview', request);
  return response.data;
};

export const deleteIncompleteOrders = async (request: CleanupRequest = {}) => {
  const response = await api.post<CleanupDeleteResponse>('/admin/data-cleanup/incomplete-orders/delete', request);
  return response.data;
};
