/**
 * customer.api.ts — Customer API Service
 *
 * Endpoints:
 *   GET  /customers/search
 *   GET  /customers/:id
 *   POST /customers
 *   PUT  /customers/:id/contact
 *   PUT  /customers/:id/card-message
 *   PUT  /customers/:id/deactivate
 *   PUT  /customers/:id/reactivate
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface CustomerSearchParams {
  Query?: string;
  Page?: number;
  PageSize?: number;
}

export interface CreateCustomerRequest {
  name: string;
  email?: string | null;
  phone?: string | null;
}

export interface UpdateCustomerContactRequest {
  email?: string | null;
  phone?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

export const searchCustomers = async (params: CustomerSearchParams = {}) => {
  const res = await api.get('/customers/search', { params });
  return res.data;
};

export const getCustomerById = async (id: string) => {
  const res = await api.get(`/customers/${id}`);
  return res.data;
};

export const createCustomer = async (data: CreateCustomerRequest) => {
  const res = await api.post('/customers', data);
  return res.data;
};

export const updateCustomerContact = async (id: string, data: UpdateCustomerContactRequest) => {
  const res = await api.put(`/customers/${id}/contact`, data);
  return res.data;
};

export const updateCardMessage = async (id: string, message: string | null) => {
  const res = await api.put(`/customers/${id}/card-message`, JSON.stringify(message), {
    headers: { 'Content-Type': 'application/json' },
  });
  return res.data;
};

export const deactivateCustomer = async (id: string) => {
  const res = await api.put(`/customers/${id}/deactivate`);
  return res.data;
};

export const reactivateCustomer = async (id: string) => {
  const res = await api.put(`/customers/${id}/reactivate`);
  return res.data;
};
