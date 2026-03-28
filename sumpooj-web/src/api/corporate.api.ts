import api from './axios';

export interface CorporateClient {
  id: string;
  customerId: string;
  name: string;
  billingEmail: string;
  phone?: string;
  creditLimit?: number;
  paymentTerms?: string;
  billingCycle: string;
  defaultProductId?: string;
  defaultMessage?: string;
  isActive: boolean;
  outstandingAmount: number;
  activeEmployees: number;
  createdAtUtc: string;
}

export interface CorporateEmployee {
  id: string;
  clientId: string;
  name: string;
  dateOfBirth: string;
  address?: string;
  isActive: boolean;
}

export interface PendingCorporateApprovalOrder {
  orderId: string;
  orderNumber: string;
  clientId: string;
  clientName: string;
  employeeId?: string;
  employeeName?: string;
  orderDateUtc: string;
  deliveryDateUtc: string;
  deliveryAddress?: string;
  totalAmount: number;
  needsApproval: boolean;
  automationDateUtc?: string;
}

export interface CorporateInvoiceLine {
  orderId: string;
  orderNumber: string;
  orderDateUtc: string;
  amount: number;
}

export interface CorporateInvoice {
  id: string;
  clientId: string;
  startDateUtc: string;
  endDateUtc: string;
  totalAmount: number;
  status: number | string;
  paidAtUtc?: string;
  lines: CorporateInvoiceLine[];
  createdAtUtc: string;
}

export type CorporateInvoiceStatus = 'Draft' | 'Issued' | 'PartiallyPaid' | 'Paid' | 'Overdue';

export interface RecordCorporateInvoicePaymentRequest {
  paidAtUtc: string;
  paymentMethod?: string;
}

export interface CreateCorporateClientRequest {
  name: string;
  billingEmail: string;
  phone?: string;
  creditLimit?: number;
  paymentTerms?: string;
  billingCycle?: string;
  defaultProductId?: string;
  defaultMessage?: string;
}

export interface CreateCorporateEmployeeRequest {
  name: string;
  dateOfBirth: string;
  address?: string;
}

export interface CreateCorporateOrderItemRequest {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
}

export interface CreateCorporateOrderRequest {
  clientId: string;
  orderType: 'DELIVERY' | 'PICKUP';
  deliveryDate: string;
  timeSlot?: string;
  deliveryAddress?: string;
  deliveryPincode?: string;
  recipientName?: string;
  recipientPhone?: string;
  message?: string;
  locationId?: string;
  items: CreateCorporateOrderItemRequest[];
}

export interface CreateCorporateOrderResponse {
  orderId: string;
  orderNumber: string;
  corporateClientId: string;
  creditLimitExceeded: boolean;
}

export interface GenerateCorporateInvoiceRequest {
  clientId: string;
  startDate: string;
  endDate: string;
}

export interface ApproveAutoCreatedOrderRequest {
  approvedTimeSlot?: string;
}

export interface CorporateBirthdayAutomationResult {
  runDateUtc: string;
  createdOrders: number;
  skippedMissingDefaultProduct: number;
  skippedNoAddress: number;
  skippedDuplicate: number;
}

export const searchCorporateClients = async (params?: { query?: string; isActive?: boolean; page?: number; pageSize?: number }) => {
  const res = await api.get('/corporate/clients', { params });
  return res.data as { items: CorporateClient[]; totalCount: number; page: number; pageSize: number };
};

export const createCorporateClient = async (data: CreateCorporateClientRequest) => {
  const res = await api.post('/corporate/clients', data);
  return res.data as CorporateClient;
};

export const getCorporateEmployees = async (clientId: string, activeOnly = false) => {
  const res = await api.get(`/corporate/clients/${clientId}/employees`, { params: { activeOnly } });
  return res.data as CorporateEmployee[];
};

export const addCorporateEmployee = async (clientId: string, data: CreateCorporateEmployeeRequest) => {
  const res = await api.post(`/corporate/clients/${clientId}/employees`, data);
  return res.data as CorporateEmployee;
};

export const createCorporateOrder = async (data: CreateCorporateOrderRequest) => {
  const res = await api.post('/corporate/orders', data);
  return res.data as CreateCorporateOrderResponse;
};

export const getPendingCorporateAutoOrders = async () => {
  const res = await api.get('/corporate/orders/auto-created');
  return res.data as PendingCorporateApprovalOrder[];
};

export const approveCorporateAutoOrder = async (orderId: string, _data?: ApproveAutoCreatedOrderRequest) => {
  await api.post(`/corporate/orders/${orderId}/approve`);
};

export const cancelCorporateAutoOrder = async (orderId: string, reason?: string) => {
  await api.post(`/corporate/orders/${orderId}/cancel`, { reason });
};

export const generateCorporateInvoice = async (data: GenerateCorporateInvoiceRequest) => {
  const res = await api.post('/corporate/invoices/generate', data);
  return res.data as CorporateInvoice;
};

export const getCorporateClientInvoices = async (clientId: string) => {
  const res = await api.get(`/corporate/clients/${clientId}/invoices`);
  return res.data as CorporateInvoice[];
};

export const recordCorporateInvoicePayment = async (invoiceId: string, request: RecordCorporateInvoicePaymentRequest) => {
  await api.post(`/corporate/invoices/${invoiceId}/payment`, {
    paidAtUtc: request.paidAtUtc,
    paymentMethod: request.paymentMethod ?? 'BANK',
  });
};

export const runCorporateBirthdayAutomation = async (runDateUtc?: string) => {
  const params = runDateUtc ? { runDateUtc } : undefined;
  const res = await api.post('/corporate/automation/birthdays/run', null, { params });
  return res.data as CorporateBirthdayAutomationResult;
};

// Compatibility wrappers for page modules
export const getPendingAutoCreatedOrders = getPendingCorporateAutoOrders;
export const approveAutoCreatedOrder = approveCorporateAutoOrder;
export const cancelAutoCreatedOrder = cancelCorporateAutoOrder;

export const listCorporateInvoices = async (params?: { clientId?: string; status?: CorporateInvoiceStatus | '' }) => {
  if (params?.clientId) {
    const invoices = await getCorporateClientInvoices(params.clientId);
    if (!params.status) {
      return invoices;
    }
    return invoices.filter((inv) => String(inv.status) === params.status);
  }

  const clients = await searchCorporateClients({ page: 1, pageSize: 500 });
  const all = await Promise.all((clients.items ?? []).map((c) => getCorporateClientInvoices(c.id)));
  const flattened = all.flat();
  if (!params?.status) {
    return flattened;
  }
  return flattened.filter((inv) => String(inv.status) === params.status);
};

export const payCorporateInvoice = async (
  invoiceId: string,
  data: { amount: number; paymentDate: string; paymentMode?: string; referenceNumber?: string; notes?: string }
) => {
  await recordCorporateInvoicePayment(invoiceId, {
    paidAtUtc: data.paymentDate,
    paymentMethod: data.paymentMode ?? 'BANK',
  });
};
