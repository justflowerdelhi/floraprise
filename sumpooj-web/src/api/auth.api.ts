import api from './axios';
import type { UserRole } from '../core/rbac/RBACTypes';

/**
 * Normalize backend role strings to frontend UserRole type.
 * Backend roles: ADMIN, COMPANYADMIN, MANAGER, CASHIER, DESIGNER, DRIVER, etc.
 * Frontend roles: ADMIN, MANAGER, CASHIER, DESIGNER, DRIVER
 */
export function normalizeRole(backendRole: string): UserRole {
  const normalized = backendRole.toUpperCase();
  
  // Map common backend roles to frontend roles
  const roleMap: Record<string, UserRole> = {
    'ADMIN': 'ADMIN',
    'COMPANYADMIN': 'ADMIN',  // Backend's company admin → frontend admin
    'MANAGER': 'MANAGER',
    'STOREMANAGER': 'MANAGER',
    'CASHIER': 'CASHIER',
    'DESIGNER': 'DESIGNER',
    'FLORALDESIGNER': 'DESIGNER',
    'DRIVER': 'DRIVER',
    'DELIVERYDRIVER': 'DRIVER',
  };

  return roleMap[normalized] || 'CASHIER';  // Default to CASHIER for unknown roles
}

/** Login response from backend */
export interface LoginResponse {
  access_token: string;
  refresh_token: string;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
    primaryLocationId: string | null;
    assignedLocationIds: string[];
  };
  tenant: {
    id: string;
    name: string;
    slug: string;
    plan: string;
    subscriptionStatus: string;
    country: string;
    currency: string;
    taxSystem: string;
    dateFormat: string;
    timeFormat: string;
    locale: string;
    isActive: boolean;
    createdAt: string;
  } | null;
}

/** POST /auth/login — returns { access_token, user, tenant } */
export const login = async (email: string, password: string): Promise<LoginResponse> => {
  console.log('🔐 Login request:', { email });

  const res = await api.post<LoginResponse>('/auth/login', { email, password });

  console.log('🔐 Login response:', res.data);
  return res.data;
};

/** GET /auth/me — returns current user + tenant (for session refresh) */
export const fetchMe = async () => {
  const res = await api.get('/auth/me');
  return res.data;
};

/** POST /auth/refresh — exchange refresh token for new access + refresh tokens */
export const refreshTokens = async (refreshToken: string): Promise<LoginResponse> => {
  const res = await api.post<LoginResponse>('/auth/refresh', { refreshToken });
  return res.data;
};

/** POST /auth/revoke — revoke a refresh token (on logout) */
export const revokeToken = async (refreshToken: string): Promise<void> => {
  await api.post('/auth/revoke', { refreshToken });
};
