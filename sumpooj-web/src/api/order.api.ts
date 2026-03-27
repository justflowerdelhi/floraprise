/**
 * order.api.ts — Orders API Service
 *
 * Endpoints:
 *   GET   /Orders/search
 *   GET   /Orders/today
 *   GET   /Orders/by-date/:date
 *   GET   /Orders/by-customer/:customerId
 *   GET   /Orders/:id
 *   GET   /Orders/by-number/:orderNumber
 *   POST  /Orders
 *   PATCH /Orders/:id/status
 *   PATCH /Orders/:id/fulfillment-status
 *   POST  /Orders/:id/assign-designer
 *   POST  /Orders/:id/assign-driver
 *   POST  /Orders/:id/cancel
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface OrderSearchParams {
  Query?: string;
  CustomerId?: string;
  Status?: string;
  PaymentStatus?: string;
  FulfillmentStatus?: string;
  OrderSource?: string;
  FromDate?: string;
  ToDate?: string;
  DeliveryDate?: string;
  Page?: number;
  PageSize?: number;
}

export interface OrderItemRequest {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  specialInstructions?: string | null;
}

export interface CreateOrderRequest {
  customerId: string | null;
  locationId?: string | null;
  deliveryDate: string | null;
  deliveryAddress?: string | null;
  recipientName?: string | null;
  recipientPhone?: string | null;
  cardMessage?: string | null;
  deliveryPriority: string;
  timeSlot?: string | null;
  orderSource: string;
  orderIntent?: string;        // 'TAKE_NOW' | 'DELIVERY' | 'PICKUP_LATER'
  pickupDate?: string | null;
  pickupTimeSlot?: string | null;
  deliveryFee: number;
  discountAmount: number;
  internalNotes?: string | null;
  items: OrderItemRequest[];
  payments?: OrderPaymentRequest[];
}

export interface OrderPaymentRequest {
  method: string;
  amount: number;
}

export interface UpdateStatusRequest {
  status: string;
}

export interface AssignStaffRequest {
  staffId: string;
}

export interface CancelOrderRequest {
  reason?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

export const searchOrders = async (params: OrderSearchParams = {}) => {
  const res = await api.get('/Orders/search', { params });
  return res.data;
};

export const getTodayOrders = async (locationId?: string) => {
  const res = await api.get('/Orders/today', { params: { locationId } });
  return res.data;
};

export const getOrdersByDate = async (date: string) => {
  const res = await api.get(`/Orders/by-date/${date}`);
  return res.data;
};

export const getOrdersByCustomer = async (customerId: string) => {
  const res = await api.get(`/Orders/by-customer/${customerId}`);
  return res.data;
};

export const getOrderById = async (id: string) => {
  const res = await api.get(`/Orders/${id}`);
  return res.data;
};

export const getOrderByNumber = async (orderNumber: string) => {
  const res = await api.get(`/Orders/by-number/${orderNumber}`);
  return res.data;
};

export const createOrder = async (data: CreateOrderRequest) => {
  console.log("🚀 FINAL API PAYLOAD:", data);  // 🔥 THIS WILL ALWAYS RUN

  const res = await api.post('/Orders', data);

  console.log("✅ API RESPONSE:", res.data);

  return res.data;
};

export const updateOrderStatus = async (id: string, data: UpdateStatusRequest) => {
  const res = await api.patch(`/Orders/${id}/status`, data);
  return res.data;
};

export const updateFulfillmentStatus = async (id: string, data: UpdateStatusRequest) => {
  const res = await api.patch(`/Orders/${id}/fulfillment-status`, data);
  return res.data;
};

export const assignDesigner = async (id: string, data: AssignStaffRequest) => {
  const res = await api.post(`/Orders/${id}/assign-designer`, data);
  return res.data;
};

export const assignDriver = async (id: string, data: AssignStaffRequest) => {
  const res = await api.post(`/Orders/${id}/assign-driver`, data);
  return res.data;
};

export const cancelOrder = async (id: string, data?: CancelOrderRequest) => {
  const res = await api.post(`/Orders/${id}/cancel`, data);
  return res.data;
};

// ─── Finished Goods (Production items for Walk-In POS) ──────
import { apiClient } from '../core/api/apiClient';

export const fetchSellableFinishedGoods = async () => {
  const res = await apiClient.get('/production/finished-goods/sellable');
  const data = res.data;
  if (Array.isArray(data)) return data;
  // Handle paginated shape: { items: [...] } or { $values: [...] }
  if (data && Array.isArray(data.items)) return data.items;
  if (data && Array.isArray(data.$values)) return data.$values;
  return [];
};
