import api from './axios';
import type {
  Customer,
  CustomerEventSummary,
  CustomerOrderSummary,
  LoyaltyTransaction,
  SmartReminder,
} from '../pages/crm/CRMTypes';

interface PagedResult<T> {
  items: T[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export interface CrmCustomer360Response {
  customer: Customer;
  orders: CustomerOrderSummary[];
  events: CustomerEventSummary[];
  loyaltyTransactions: LoyaltyTransaction[];
}

export async function getCrmCustomers(params?: { query?: string; page?: number; pageSize?: number }) {
  const response = await api.get<PagedResult<Customer>>('/crm/customers', {
    params: {
      query: params?.query,
      page: params?.page ?? 1,
      pageSize: params?.pageSize ?? 500,
    },
  });

  return response.data;
}

export async function getCrmCustomer360(customerId: string) {
  const response = await api.get<CrmCustomer360Response>(`/crm/customers/${customerId}`);
  return response.data;
}

export async function getCrmReminders() {
  const response = await api.get<SmartReminder[]>('/crm/reminders');
  return response.data;
}