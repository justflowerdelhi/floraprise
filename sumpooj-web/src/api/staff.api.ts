/**
 * staff.api.ts — Staff API Service
 *
 * Endpoints:
 *   GET    /Staff
 *   POST   /Staff
 *   GET    /Staff/search
 *   GET    /Staff/:id
 *   PUT    /Staff/:id
 *   DELETE /Staff/:id
 *   GET    /Staff/by-role/:role
 */
import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface StaffSearchParams {
  Query?: string;
  Role?: string;
  IsActive?: boolean;
  Page?: number;
  PageSize?: number;
}

export interface CreateStaffRequest {
  name: string;
  role: string;
  email?: string | null;
  phone?: string | null;
  commissionType?: string | null;
  commissionRate?: number | null;
  hourlyRate?: number | null;
  primaryLocationId?: string | null;
  isActive: boolean;
  // Optional login access
  enableLogin?: boolean;
  loginIdentifier?: string | null;
  loginRole?: string | null;
  password?: string | null;
}

export interface CreateStaffResult {
  id: string;
}

export interface UpdateStaffRequest {
  name?: string | null;
  role?: string | null;
  email?: string | null;
  phone?: string | null;
  commissionType?: string | null;
  commissionRate?: number | null;
  hourlyRate?: number | null;
  primaryLocationId?: string | null;
  isActive?: boolean | null;
}

// ─── API Functions ──────────────────────────────────────────

export const getAllStaff = async () => {
  const res = await api.get('/Staff');
  return res.data;
};

export const createStaff = async (data: CreateStaffRequest): Promise<CreateStaffResult> => {
  const res = await api.post('/Staff', data);
  return res.data;
};

export const searchStaff = async (params: StaffSearchParams = {}) => {
  const res = await api.get('/Staff/search', { params });
  return res.data;
};

export const getStaffById = async (id: string) => {
  const res = await api.get(`/Staff/${id}`);
  return res.data;
};

export const updateStaff = async (id: string, data: UpdateStaffRequest) => {
  const res = await api.put(`/Staff/${id}`, data);
  return res.data;
};

export const deleteStaff = async (id: string) => {
  const res = await api.delete(`/Staff/${id}`);
  return res.data;
};

export const getStaffByRole = async (role: string) => {
  const res = await api.get(`/Staff/by-role/${role}`);
  return res.data;
};

// ─── Login Management (Edit mode) ───────────────────────────

export interface EnableLoginRequest {
  loginIdentifier: string;
  loginRole: string;
  password: string;
}

export interface ResetPasswordRequest {
  password: string;
}

export const enableStaffLogin = async (staffId: string, data: EnableLoginRequest): Promise<void> => {
  await api.post(`/Staff/${staffId}/enable-login`, data);
};

export const resetStaffPassword = async (staffId: string, data: ResetPasswordRequest): Promise<void> => {
  await api.post(`/Staff/${staffId}/reset-password`, data);
};

export const disableStaffLogin = async (staffId: string): Promise<void> => {
  await api.post(`/Staff/${staffId}/disable-login`);
};

export const getStaffPerformance = async (
  staffId: string,
  from?: string,
  to?: string,
) => {
  const res = await api.get(`/Staff/${staffId}/performance`, {
    params: { from, to },
  });
  return res.data;
};

export const checkStaffHasOrders = async (staffId: string): Promise<{ hasOrders: boolean; orderCount: number }> => {
  const res = await api.get(`/Staff/${staffId}/has-orders`);
  return res.data;
};
