import api from './axios';

// ── Request types ────────────────────────────────────────────────────────

export interface CreatePhoneOrderRequest {
  customerId: string;
  orderType: 'PhoneLocal' | 'PhoneOutstation';
}

export interface AddPhoneOrderItemRequest {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
}

export interface ConfirmPhoneOutstationPayload {
  salesOrderId: string;
  vendorId: string;
  vendorCost: number;
  deliveryCharge: number;
}

export interface AvailableFlower {
  productId: string;
  productName: string;
  availableUnits: number;
  pricePerUnit: number;
}

// ── API methods ──────────────────────────────────────────────────────────

export const getPhoneOrder = async (orderId: string) => {
  const res = await api.get(`/SalesOrders/${orderId}`);
  return res.data;
};

export const getAvailableFlowers = async (): Promise<AvailableFlower[]> => {
  const res = await api.get('/SalesOrders/available-flowers');
  return res.data;
};

export const createPhoneOrder = async (data: CreatePhoneOrderRequest) => {
  const res = await api.post('/SalesOrders', data);
  return res.data;
};

export const addItemToPhoneOrder = async (orderId: string, item: AddPhoneOrderItemRequest) => {
  const res = await api.post(`/SalesOrders/${orderId}/items`, item);
  return res.data;
};

export const confirmPhoneLocalOrder = async (orderId: string) => {
  const res = await api.post(`/SalesOrders/${orderId}/confirm-local`);
  return res.data;
};

export const confirmPhoneOutstationOrder = async (payload: ConfirmPhoneOutstationPayload) => {
  const res = await api.post(`/SalesOrders/${payload.salesOrderId}/confirm-outstation`, payload);
  return res.data;
};

export const cancelPhoneLocalOrder = async (orderId: string) => {
  const res = await api.post(`/SalesOrders/${orderId}/cancel-local`);
  return res.data;
};

export const startProductionForPhoneLocalOrder = async (orderId: string) => {
  const res = await api.post(`/SalesOrders/${orderId}/start-production`);
  return res.data;
};
