import api from '../../api/axios';

// ── Response types ───────────────────────────────────────────────────────

export interface PhoneOrderResponse {
  id: string;
  companyId: string;
  customerId: string;
  customerName?: string;
  orderNumber: string;
  orderType: 'PhoneLocal' | 'PhoneOutstation';
  status: string;
  deliveryDate: string;
  deliveryCity: string;
  timeSlot?: string;
  occasion?: string;
  budget?: number;
  items: PhoneOrderItemResponse[];
  createdAtUtc: string;
  updatedAtUtc?: string;
}

export interface PhoneOrderItemResponse {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

export interface ConfirmOutstationResponse {
  orderId: string;
  vendorExecutionId: string;
}

export interface AvailableFlowerResponse {
  productId: string;
  productName: string;
  availableUnits: number;
  unitPrice: number;
  consumptionUnit: string;
}

// ── API functions ────────────────────────────────────────────────────────

export async function getPhoneOrders(params?: {
  status?: string;
  type?: string;
  filter?: 'today' | 'all';
  limit?: number;
}): Promise<PhoneOrderResponse[]> {
  const res = await api.get('/phone-orders', { params });
  return res.data;
}

export async function getPhoneOrder(orderId: string): Promise<PhoneOrderResponse> {
  const res = await api.get(`/phone-orders/${orderId}`);
  return res.data;
}

export async function createPhoneOrder(payload: {
  customerName?: string;
  phoneNumber?: string;
  customerId?: string;
  orderType: 'PhoneLocal' | 'PhoneOutstation';
  deliveryDate: string;
  deliveryCity: string;
  timeSlot?: string;
  occasion?: string;
  budget?: number;
  specialInstructions?: string;
}): Promise<PhoneOrderResponse> {
  const res = await api.post('/phone-orders', payload);
  return res.data;
}

export async function addItemToPhoneOrder(
  orderId: string,
  item: { productId: string; quantity: number; unitPrice: number },
): Promise<PhoneOrderResponse> {
  const res = await api.post(`/phone-orders/${orderId}/items`, item);
  return res.data;
}

export async function confirmPhoneLocalOrder(orderId: string): Promise<PhoneOrderResponse> {
  const res = await api.post(`/phone-orders/${orderId}/confirm-local`);
  return res.data;
}

export async function confirmPhoneOutstationOrder(payload: {
  salesOrderId: string;
  vendorId: string;
  vendorCost: number;
  deliveryCharge: number;
}): Promise<ConfirmOutstationResponse> {
  const res = await api.post(`/phone-orders/${payload.salesOrderId}/confirm-outstation`, payload);
  return res.data;
}

export async function cancelPhoneLocalOrder(orderId: string): Promise<PhoneOrderResponse> {
  const res = await api.post(`/phone-orders/${orderId}/cancel`);
  return res.data;
}

export async function startProductionForPhoneLocalOrder(orderId: string): Promise<PhoneOrderResponse> {
  const res = await api.post(`/phone-orders/${orderId}/start-production`);
  return res.data;
}

export async function getAvailableFlowers(): Promise<AvailableFlowerResponse[]> {
  const res = await api.get('/inventory/available-flowers');
  return res.data;
}

export interface PaymentResponse {
  id: string;
  orderId: string;
  amount: number;
  paymentMode: 'Cash' | 'UPI' | 'Card' | 'BankTransfer';
  createdAtUtc: string;
}

export async function createPayment(payload: {
  orderId: string;
  amount: number;
  paymentMode: 'Cash' | 'UPI' | 'Card' | 'BankTransfer';
  locationId?: string;
}): Promise<PaymentResponse> {
  const guidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (!guidRegex.test(payload.orderId)) {
    throw new Error('Payment requires a valid saved order. Please create/confirm the order first.');
  }

  // Backend expects CreatePaymentRequest: { orderId: Guid, method: string, amount: decimal, locationId?: Guid }
  const requestBody: any = {
    orderId: payload.orderId,
    method: payload.paymentMode,
    amount: payload.amount,
  };

  if (payload.locationId && guidRegex.test(payload.locationId)) {
    requestBody.locationId = payload.locationId;
  }

  const res = await api.post('/payments', requestBody);
  return res.data;
}

// ── Invoice types & API ──────────────────────────────────────────────────────

export interface InvoiceItemResponse {
  description: string;
  quantity: number;
  unitPrice: number;
  total: number;
}

export interface InvoiceResponse {
  invoiceNumber: string;
  orderNumber: string;
  customerName: string;
  phone?: string;
  deliveryDate?: string;
  orderType: string;
  items: InvoiceItemResponse[];
  subtotal: number;
  deliveryCharge: number;
  discount: number;
  total: number;
  paidAmount: number;
  balance: number;
}

export async function getInvoice(orderId: string): Promise<InvoiceResponse> {
  const res = await api.get(`/phone-orders/${orderId}/invoice`);
  return res.data;
}

// ── Dashboard Summary ────────────────────────────────────────────────────

export interface DashboardSummaryResponse {
  todayOrders: number;
  pendingProduction: number;
  pendingDelivery: number;
  todayRevenue: number;
}

export async function getDashboardSummary(): Promise<DashboardSummaryResponse> {
  const res = await api.get('/phone-orders/dashboard-summary');
  return res.data;
}

// ── Schedule Delivery ────────────────────────────────────────────────────

export interface ScheduleDeliveryRequest {
  deliveryDate: string;
  timeSlot: string;
  address: string;
}

export async function scheduleDelivery(
  orderId: string,
  request: ScheduleDeliveryRequest
): Promise<{ message: string }> {
  const res = await api.post(`/phone-orders/${orderId}/schedule-delivery`, request);
  return res.data;
}
