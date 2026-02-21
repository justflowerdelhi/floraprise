/**
 * tax.api.ts — Tax Rules API Service
 *
 * Endpoints:
 *   GET    /taxrules              — list / filter by country
 *   GET    /taxrules/:id          — single rule
 *   POST   /taxrules              — create
 *   PUT    /taxrules/:id          — update
 *   DELETE /taxrules/:id          — soft-deactivate
 *   POST   /taxrules/:id/activate — reactivate
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface TaxRuleDto {
  id: string;
  countryCode: string;
  name: string;
  rate: number;
  isInclusive: boolean;
  isActive: boolean;
  createdAtUtc: string;
  updatedAtUtc?: string | null;
}

export interface CreateTaxRuleRequest {
  countryCode: string;
  name: string;
  rate: number;
  isInclusive: boolean;
}

export interface UpdateTaxRuleRequest {
  countryCode: string;
  name: string;
  rate: number;
  isInclusive: boolean;
}

// ─── API Functions ──────────────────────────────────────────

export const getTaxRules = async (params?: { country?: string; activeOnly?: boolean }) => {
  const res = await api.get('/taxrules', { params });
  return res.data as TaxRuleDto[];
};

export const getTaxRuleById = async (id: string) => {
  const res = await api.get(`/taxrules/${id}`);
  return res.data as TaxRuleDto;
};

export const createTaxRule = async (data: CreateTaxRuleRequest) => {
  const res = await api.post('/taxrules', data);
  return res.data as TaxRuleDto;
};

export const updateTaxRule = async (id: string, data: UpdateTaxRuleRequest) => {
  const res = await api.put(`/taxrules/${id}`, data);
  return res.data;
};

export const deactivateTaxRule = async (id: string) => {
  const res = await api.delete(`/taxrules/${id}`);
  return res.data;
};

export const activateTaxRule = async (id: string) => {
  const res = await api.post(`/taxrules/${id}/activate`);
  return res.data;
};
