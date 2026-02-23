import api from '../../api/axios';

// ── Dev mode flag ────────────────────────────────────────────────────────

const USE_MOCK_DATA = import.meta.env.DEV;

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

// ── Mock Data ────────────────────────────────────────────────────────────

const MOCK_ORDERS: PhoneOrderResponse[] = [
  {
    id: 'mock-001',
    companyId: 'company-1',
    customerId: 'cust-101',
    customerName: 'Sarah Johnson',
    orderNumber: 'SO-20260223-00000001',
    orderType: 'PhoneLocal',
    status: 'Confirmed',
    deliveryDate: '2026-02-24',
    deliveryCity: 'Downtown',
    timeSlot: '10:00 AM - 12:00 PM',
    occasion: 'Birthday',
    budget: 150,
    items: [
      { id: 'item-1', productId: 'prod-1', productName: 'Red Roses (12 stems)', quantity: 2, unitPrice: 35, totalPrice: 70 },
      { id: 'item-2', productId: 'prod-2', productName: 'Baby Breath', quantity: 1, unitPrice: 15, totalPrice: 15 },
    ],
    createdAtUtc: '2026-02-23T08:30:00Z',
  },
  {
    id: 'mock-002',
    companyId: 'company-1',
    customerId: 'cust-102',
    customerName: 'Michael Chen',
    orderNumber: 'SO-20260223-00000002',
    orderType: 'PhoneLocal',
    status: 'Confirmed',
    deliveryDate: '2026-02-24',
    deliveryCity: 'Midtown',
    timeSlot: '2:00 PM - 4:00 PM',
    occasion: 'Anniversary',
    budget: 200,
    items: [
      { id: 'item-3', productId: 'prod-3', productName: 'White Lilies', quantity: 3, unitPrice: 25, totalPrice: 75 },
    ],
    createdAtUtc: '2026-02-23T09:15:00Z',
  },
  {
    id: 'mock-003',
    companyId: 'company-1',
    customerId: 'cust-103',
    customerName: 'Emily Davis',
    orderNumber: 'SO-20260223-00000003',
    orderType: 'PhoneOutstation',
    status: 'Draft',
    deliveryDate: '2026-02-25',
    deliveryCity: 'Brooklyn',
    timeSlot: '9:00 AM - 11:00 AM',
    occasion: 'Get Well',
    budget: 100,
    items: [],
    createdAtUtc: '2026-02-23T10:00:00Z',
  },
];

const MOCK_FLOWERS: AvailableFlowerResponse[] = [
  { productId: 'flower-1', productName: 'Red Roses', availableUnits: 48, unitPrice: 3.50, consumptionUnit: 'stems' },
  { productId: 'flower-2', productName: 'White Lilies', availableUnits: 24, unitPrice: 5.00, consumptionUnit: 'stems' },
  { productId: 'flower-3', productName: 'Pink Tulips', availableUnits: 36, unitPrice: 2.75, consumptionUnit: 'stems' },
  { productId: 'flower-4', productName: 'Baby Breath', availableUnits: 100, unitPrice: 1.25, consumptionUnit: 'bunches' },
  { productId: 'flower-5', productName: 'Eucalyptus', availableUnits: 50, unitPrice: 2.00, consumptionUnit: 'stems' },
  { productId: 'flower-6', productName: 'Sunflowers', availableUnits: 18, unitPrice: 4.00, consumptionUnit: 'stems' },
];

// ── API functions ────────────────────────────────────────────────────────

export async function getPhoneOrders(params?: {
  status?: string;
  type?: string;
  filter?: 'today' | 'all';
  limit?: number;
}): Promise<PhoneOrderResponse[]> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300)); // simulate latency
    let filtered = [...MOCK_ORDERS];
    if (params?.status) filtered = filtered.filter((o) => o.status === params.status);
    if (params?.type) filtered = filtered.filter((o) => o.orderType === params.type);
    if (params?.filter === 'today') {
      const today = new Date().toISOString().slice(0, 10);
      filtered = filtered.filter((o) => o.deliveryDate === today);
    }
    if (params?.limit) filtered = filtered.slice(0, params.limit);
    return filtered;
  }
  const res = await api.get('/phone-orders', { params });
  return res.data;
}

export async function getPhoneOrder(
  orderId: string,
): Promise<PhoneOrderResponse> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 200));
    const order = MOCK_ORDERS.find((o) => o.id === orderId);
    if (!order) throw new Error('Order not found');
    return order;
  }
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
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300));
    const newOrder: PhoneOrderResponse = {
      id: `mock-${Date.now()}`,
      companyId: 'company-1',
      customerId: payload.customerId ?? 'guest',
      customerName: payload.customerName,
      orderNumber: `SO-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${String(Date.now()).slice(-8)}`,
      orderType: payload.orderType,
      status: 'Draft',
      deliveryDate: payload.deliveryDate,
      deliveryCity: payload.deliveryCity,
      timeSlot: payload.timeSlot,
      occasion: payload.occasion,
      budget: payload.budget,
      items: [],
      createdAtUtc: new Date().toISOString(),
    };
    MOCK_ORDERS.push(newOrder);
    return newOrder;
  }
  const res = await api.post('/phone-orders', payload);
  return res.data;
}

export async function addItemToPhoneOrder(
  orderId: string,
  item: {
    productId: string;
    quantity: number;
    unitPrice: number;
  },
): Promise<PhoneOrderResponse> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 200));
    const order = MOCK_ORDERS.find((o) => o.id === orderId);
    if (!order) throw new Error('Order not found');
    const flower = MOCK_FLOWERS.find((f) => f.productId === item.productId);
    order.items.push({
      id: `item-${Date.now()}`,
      productId: item.productId,
      productName: flower?.productName ?? 'Unknown',
      quantity: item.quantity,
      unitPrice: item.unitPrice,
      totalPrice: item.quantity * item.unitPrice,
    });
    return { ...order };
  }
  const res = await api.post(`/phone-orders/${orderId}/items`, item);
  return res.data;
}

export async function confirmPhoneLocalOrder(
  orderId: string,
): Promise<PhoneOrderResponse> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300));
    const order = MOCK_ORDERS.find((o) => o.id === orderId);
    if (!order) throw new Error('Order not found');
    order.status = 'Confirmed';
    return { ...order };
  }
  const res = await api.post(`/phone-orders/${orderId}/confirm-local`);
  return res.data;
}

export async function confirmPhoneOutstationOrder(payload: {
  salesOrderId: string;
  vendorId: string;
  vendorCost: number;
  deliveryCharge: number;
}): Promise<ConfirmOutstationResponse> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300));
    const order = MOCK_ORDERS.find((o) => o.id === payload.salesOrderId);
    if (!order) throw new Error('Order not found');
    order.status = 'SentToVendor';
    return { orderId: order.id, vendorExecutionId: `ve-${Date.now()}` };
  }
  const res = await api.post(
    `/phone-orders/${payload.salesOrderId}/confirm-outstation`,
    payload,
  );
  return res.data;
}

export async function cancelPhoneLocalOrder(
  orderId: string,
): Promise<PhoneOrderResponse> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300));
    const order = MOCK_ORDERS.find((o) => o.id === orderId);
    if (!order) throw new Error('Order not found');
    order.status = 'Cancelled';
    return { ...order };
  }
  const res = await api.post(`/phone-orders/${orderId}/cancel`);
  return res.data;
}

export async function startProductionForPhoneLocalOrder(
  orderId: string,
): Promise<PhoneOrderResponse> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300));
    const order = MOCK_ORDERS.find((o) => o.id === orderId);
    if (!order) throw new Error('Order not found');
    order.status = 'InProduction';
    return { ...order };
  }
  const res = await api.post(`/phone-orders/${orderId}/start-production`);
  return res.data;
}

export async function getAvailableFlowers(): Promise<AvailableFlowerResponse[]> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 200));
    return [...MOCK_FLOWERS];
  }
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
}): Promise<PaymentResponse> {
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 300));
    const payment: PaymentResponse = {
      id: `payment-${Date.now()}`,
      orderId: payload.orderId,
      amount: payload.amount,
      paymentMode: payload.paymentMode,
      createdAtUtc: new Date().toISOString(),
    };
    return payment;
  }
  const res = await api.post('/payments', payload);
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
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 400));
    const mockInvoice: InvoiceResponse = {
      invoiceNumber: `INV-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(100000 + Math.random() * 900000)}`,
      orderNumber: `SO-${Date.now()}`,
      customerName: 'Mock Customer',
      phone: '+1 555-1234',
      deliveryDate: new Date().toISOString().slice(0, 10),
      orderType: 'PhoneLocal',
      items: [
        { description: 'Red Roses Bouquet', quantity: 1, unitPrice: 1500, total: 1500 },
        { description: 'Card Message', quantity: 1, unitPrice: 50, total: 50 },
      ],
      subtotal: 1550,
      deliveryCharge: 100,
      discount: 0,
      total: 1650,
      paidAmount: 500,
      balance: 1150,
    };
    return mockInvoice;
  }
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
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 400));
    return {
      todayOrders: 12,
      pendingProduction: 5,
      pendingDelivery: 3,
      todayRevenue: 24500,
    };
  }
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
  if (USE_MOCK_DATA) {
    await new Promise((r) => setTimeout(r, 600));
    return { message: 'Delivery scheduled successfully' };
  }
  const res = await api.post(`/phone-orders/${orderId}/schedule-delivery`, request);
  return res.data;
}
