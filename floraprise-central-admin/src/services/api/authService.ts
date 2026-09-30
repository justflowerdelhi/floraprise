/**
 * Central Admin Authentication Service
 * Communicates with Sumpooj.API auth endpoints:
 * - POST /api/auth/login
 * - POST /api/auth/refresh
 * - POST /api/auth/revoke
 * - GET  /api/auth/me
 */

import { apiClient } from './apiClient';
import { AdminUser } from '../../types/platform';

export interface LoginResponseDto {
  access_token: string;
  refresh_token: string;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
  };
  tenant?: {
    id: string;
    name: string;
    plan: string;
    subscriptionStatus: string;
  };
}

class AuthService {
  async loginWithCredentials(email: string, password: string): Promise<{ success: boolean; user?: AdminUser; error?: string }> {
    const res = await apiClient.post<LoginResponseDto>('/api/auth/login', {
      email: email.trim(),
      password: password.trim(),
    });

    if (res.isSuccess && res.data) {
      apiClient.setToken(res.data.access_token);
      localStorage.setItem('floraprise_refresh_token', res.data.refresh_token);

      const rawRole = res.data.user.role?.toUpperCase() || 'SUPERADMIN';
      let role: AdminUser['role'] = 'SuperAdmin';
      if (rawRole.includes('SUPPORT')) role = 'SupportOperator';
      else if (rawRole.includes('BILLING')) role = 'BillingAdmin';
      else if (rawRole.includes('READ') || rawRole.includes('AUDIT')) role = 'Auditor';

      const user: AdminUser = {
        id: res.data.user.id,
        name: res.data.user.name || email.split('@')[0],
        email: res.data.user.email || email,
        role: role,
        status: 'Active',
        lastLoginAt: 'Just now',
        twoFactorEnabled: true,
      };

      return { success: true, user };
    }

    return {
      success: false,
      error: res.error || 'Authentication failed. Please check credentials or API server connectivity.',
    };
  }

  async getCurrentUser(): Promise<AdminUser | null> {
    const token = apiClient.getToken();
    if (!token) return null;

    const res = await apiClient.get<any>('/api/auth/me');
    if (res.isSuccess && res.data?.user) {
      const u = res.data.user;
      const rawRole = u.role?.toUpperCase() || 'SUPERADMIN';
      let role: AdminUser['role'] = 'SuperAdmin';
      if (rawRole.includes('SUPPORT')) role = 'SupportOperator';
      else if (rawRole.includes('BILLING')) role = 'BillingAdmin';
      else if (rawRole.includes('READ') || rawRole.includes('AUDIT')) role = 'Auditor';

      return {
        id: u.id,
        name: u.name || u.email.split('@')[0],
        email: u.email,
        role: role,
        status: 'Active',
        lastLoginAt: 'Current session',
        twoFactorEnabled: true,
      };
    }

    return null;
  }

  async logout(): Promise<void> {
    const refreshToken = localStorage.getItem('floraprise_refresh_token');
    if (refreshToken) {
      await apiClient.post('/api/auth/revoke', { refreshToken }).catch(() => {});
    }
    apiClient.setToken(null);
    localStorage.removeItem('floraprise_refresh_token');
    localStorage.removeItem('floraprise_admin_user');
  }
}

export const authService = new AuthService();
