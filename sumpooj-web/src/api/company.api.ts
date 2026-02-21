/**
 * company.api.ts — Companies (Platform) API Service
 *
 * Endpoints:
 *   GET   /platform/companies
 *   POST  /platform/companies
 *   PATCH /platform/companies/:companyId/activate
 *   PATCH /platform/companies/:companyId/deactivate
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface CreateCompanyRequest {
  name: string;
  region: string;
  email?: string | null;
  phone?: string | null;
  address?: string | null;
  shortDescription?: string | null;
  timeZone: string;
  currencyCode: string;
  taxIdentifier?: string | null;
}

// ─── API Functions ──────────────────────────────────────────

export const getCompanies = async () => {
  const res = await api.get('/platform/companies');
  return res.data;
};

export const createCompany = async (data: CreateCompanyRequest) => {
  const res = await api.post('/platform/companies', data);
  return res.data;
};

export const activateCompany = async (companyId: string) => {
  const res = await api.patch(`/platform/companies/${companyId}/activate`);
  return res.data;
};

export const deactivateCompany = async (companyId: string) => {
  const res = await api.patch(`/platform/companies/${companyId}/deactivate`);
  return res.data;
};
