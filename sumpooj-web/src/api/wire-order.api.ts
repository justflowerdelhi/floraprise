import api from './axios';
import type { PagedResult } from './types';

// ─── Types ──────────────────────────────────────────────────

export type WireServiceType = 'Ftd' | 'Teleflora' | 'BloomNation' | 'FloristOne' | 'Lovingly' | 'Other';
export type ExternalOrderStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'IN_PROGRESS' | 'FULFILLED' | 'CANCELLED';

export interface WireOrderItem {
  productName: string;
  quantity: number;
  unitPrice: number;
}

export interface WireOrder {
  id: string;
  externalOrderId: string;
  platform: string;
  wireService: WireServiceType;
  wireServiceName: string;
  wireOrderNumber: string;
  receivedDate: string;
  deliveryDate: string;
  timeSlot?: string;
  status: ExternalOrderStatus;
  
  // Sender
  senderName?: string;
  senderPhone?: string;
  senderEmail?: string;
  
  // Recipient
  recipientName: string;
  recipientPhone: string;
  deliveryAddress: string;
  deliveryCity?: string;
  deliveryZipCode?: string;
  deliveryInstructions?: string;
  
  cardMessage?: string;
  
  // Pricing
  grossAmount: number;
  commission: number;
  fees: number;
  netPayout: number;
  fulfillmentCost?: number;
  profit?: number;
  isExternallyPaid: boolean;
  
  // Product
  productDescription?: string;
  wireProductCode?: string;
  substitutionNotes?: string;
  items: WireOrderItem[];
  
  linkedOrderId?: string;
  assignedToUserId?: string;
  assignedToUserName?: string;
  
  internalNotes?: string;
  confirmationCode?: string;
  fulfilledAt?: string;
  rejectionReason?: string;
  
  receivedAt: string;
  createdAtUtc: string;
}

export interface CreateWireOrderRequest {
  wireService: WireServiceType;
  wireOrderNumber: string;
  receivedDate: string;
  deliveryDate: string;
  timeSlot?: string;
  
  senderName?: string;
  senderPhone?: string;
  senderEmail?: string;
  
  recipientName: string;
  recipientPhone: string;
  deliveryAddress: string;
  deliveryCity?: string;
  deliveryZipCode?: string;
  deliveryInstructions?: string;
  
  cardMessage?: string;
  
  grossAmount: number;
  commission: number;
  fees: number;
  
  productDescription?: string;
  wireProductCode?: string;
  
  items: WireOrderItem[];
}

export interface WireOrderSearchParams {
  wireService?: WireServiceType;
  status?: ExternalOrderStatus;
  fromDate?: string;
  toDate?: string;
  query?: string;
  page?: number;
  pageSize?: number;
}

export interface WireOrderSummary {
  totalOrders: number;
  pendingOrders: number;
  acceptedOrders: number;
  fulfilledOrders: number;
  rejectedOrders: number;
  totalGrossAmount: number;
  totalCommission: number;
  totalFees: number;
  totalNetPayout: number;
  totalFulfillmentCost: number;
  totalProfit: number;
  byPlatform: Record<string, number>;
  byStatus: Record<string, number>;
}

// ─── API Functions ──────────────────────────────────────────

/** GET /wire-orders/search - Search wire orders */
export const searchWireOrders = async (params: WireOrderSearchParams): Promise<PagedResult<WireOrder>> => {
  const res = await api.get('/wire-orders/search', { params });
  return res.data;
};

/** GET /wire-orders/:id - Get wire order by ID */
export const getWireOrderById = async (id: string): Promise<WireOrder> => {
  const res = await api.get(`/wire-orders/${id}`);
  return res.data;
};

/** GET /wire-orders/today - Get today's wire orders */
export const getTodaysWireOrders = async (): Promise<WireOrder[]> => {
  const res = await api.get('/wire-orders/today');
  return res.data;
};

/** GET /wire-orders/pending - Get pending wire orders */
export const getPendingWireOrders = async (): Promise<WireOrder[]> => {
  const res = await api.get('/wire-orders/pending');
  return res.data;
};

/** GET /wire-orders/summary - Get wire order summary */
export const getWireOrderSummary = async (fromDate?: string, toDate?: string): Promise<WireOrderSummary> => {
  const res = await api.get('/wire-orders/summary', { params: { fromDate, toDate } });
  return res.data;
};

/** POST /wire-orders - Create wire order */
export const createWireOrder = async (data: CreateWireOrderRequest): Promise<WireOrder> => {
  const res = await api.post('/wire-orders', data);
  return res.data;
};

/** POST /wire-orders/:id/accept - Accept wire order */
export const acceptWireOrder = async (id: string): Promise<WireOrder> => {
  const res = await api.post(`/wire-orders/${id}/accept`);
  return res.data;
};

/** POST /wire-orders/:id/start-processing - Start processing */
export const startProcessingWireOrder = async (id: string): Promise<WireOrder> => {
  const res = await api.post(`/wire-orders/${id}/start-processing`);
  return res.data;
};

/** POST /wire-orders/:id/assign - Assign to user */
export const assignWireOrder = async (id: string, userId: string): Promise<WireOrder> => {
  const res = await api.post(`/wire-orders/${id}/assign`, { userId });
  return res.data;
};

/** PATCH /wire-orders/:id/fulfillment-cost - Set fulfillment cost */
export const setWireOrderFulfillmentCost = async (id: string, cost: number): Promise<WireOrder> => {
  const res = await api.patch(`/wire-orders/${id}/fulfillment-cost`, { cost });
  return res.data;
};

/** PATCH /wire-orders/:id/substitution-notes - Set substitution notes */
export const setWireOrderSubstitutionNotes = async (id: string, notes: string): Promise<WireOrder> => {
  const res = await api.patch(`/wire-orders/${id}/substitution-notes`, { notes });
  return res.data;
};

/** POST /wire-orders/:id/link-order - Link to internal order */
export const linkWireOrderToOrder = async (id: string, orderId: string): Promise<WireOrder> => {
  const res = await api.post(`/wire-orders/${id}/link-order`, { orderId });
  return res.data;
};

/** POST /wire-orders/:id/fulfill - Mark as fulfilled */
export const fulfillWireOrder = async (id: string, confirmationCode?: string): Promise<WireOrder> => {
  const res = await api.post(`/wire-orders/${id}/fulfill`, { confirmationCode });
  return res.data;
};

/** POST /wire-orders/:id/reject - Reject wire order */
export const rejectWireOrder = async (id: string, reason: string): Promise<WireOrder> => {
  const res = await api.post(`/wire-orders/${id}/reject`, { reason });
  return res.data;
};

/** POST /wire-orders/:id/cancel - Cancel wire order */
export const cancelWireOrder = async (id: string, reason: string): Promise<WireOrder> => {
  const res = await api.post(`/wire-orders/${id}/cancel`, { reason });
  return res.data;
};
