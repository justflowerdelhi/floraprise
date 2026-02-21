/**
 * supplier.api.ts — Suppliers API Service
 *
 * Endpoints:
 *   GET  /suppliers/search
 *   GET  /suppliers
 *   POST /suppliers
 *   GET  /suppliers/:id
 *   PUT  /suppliers/:id
 *   PUT  /suppliers/:id/deactivate
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface SupplierSearchParams {
  Query?: string;
  IsActive?: boolean;
  Page?: number;
  PageSize?: number;
}

export interface CreateSupplierRequest {
  name: string;
  contactPerson?: string | null;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  paymentTermsDays: number;
  taxIdentifier?: string | null;
}

export interface UpdateSupplierRequest {
  name?: string | null;
  contactPerson?: string | null;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  paymentTermsDays?: number | null;
  taxIdentifier?: string | null;
  rating?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

export const searchSuppliers = async (params: SupplierSearchParams = {}) => {
  const res = await api.get('/suppliers/search', { params });
  return res.data;
};

export const getAllSuppliers = async () => {
  const res = await api.get('/suppliers');
  return res.data;
};

export const createSupplier = async (data: CreateSupplierRequest) => {
  const res = await api.post('/suppliers', data);
  return res.data;
};

export const getSupplierById = async (id: string) => {
  const res = await api.get(`/suppliers/${id}`);
  return res.data;
};

export const updateSupplier = async (id: string, data: UpdateSupplierRequest) => {
  const res = await api.put(`/suppliers/${id}`, data);
  return res.data;
};

export const deactivateSupplier = async (id: string) => {
  const res = await api.put(`/suppliers/${id}/deactivate`);
  return res.data;
};
