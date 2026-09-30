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

export async function getCrmCustomers(params?: { query?: string; purchasedCategories?: string[]; page?: number; pageSize?: number }) {
  const qParams: any = {
      query: params?.query,
      page: params?.page ?? 1,
      pageSize: params?.pageSize ?? 500,
  };
  if (params?.purchasedCategories && params.purchasedCategories.length > 0) {
      qParams.PurchasedCategories = params.purchasedCategories;
  }

  const response = await api.get<PagedResult<Customer>>('/crm/customers', {
    params: qParams,
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