/**
 * AuthContext.tsx — Single Source of Auth Truth
 *
 * All identity (userId, tenantId, role, locationIds) comes from
 * GET /auth/me after login. Nothing is decoded client-side.
 */
import { createContext, useContext, useState, useCallback, useEffect, useMemo } from 'react';
import type { ReactNode } from 'react';
import type { User, UserRole } from '../core/rbac/RBACTypes';
import type { Tenant } from '../core/tenant/TenantTypes';
import { fetchMe } from '../api/auth.api';

// ─── Dev Bypass ─────────────────────────────────────────────
const DEV_BYPASS_AUTH = import.meta.env.VITE_DEV_BYPASS_AUTH === 'true';

const MOCK_USER: User = {
  id: 'dev-user-1',
  name: 'Dev Admin',
  email: 'admin@floraedge.dev',
  role: 'ADMIN',
  primaryLocationId: 'loc-1',
  assignedLocationIds: ['loc-1'],
};

const MOCK_TENANT: Tenant = {
  id: 'dev-tenant-1',
  name: 'Dev Flower Shop',
  slug: 'dev-shop',
  plan: 'PRO',
  subscriptionStatus: 'ACTIVE',
  country: 'US',
  currency: 'USD',
  taxSystem: 'SALES_TAX',
  dateFormat: 'MM/DD/YYYY',
  timeFormat: '12H',
  locale: 'en-US',
  isActive: true,
  createdAt: '2025-01-01T00:00:00Z',
};

// Default tenant for Platform Admins (no company)
const PLATFORM_ADMIN_TENANT: Tenant = {
  id: 'platform',
  name: 'Platform Admin',
  slug: 'platform',
  plan: 'ENTERPRISE',
  subscriptionStatus: 'ACTIVE',
  country: 'IN',
  currency: 'INR',
  taxSystem: 'GST',
  dateFormat: 'DD/MM/YYYY',
  timeFormat: '12H',
  locale: 'en-IN',
  isActive: true,
  createdAt: '2025-01-01T00:00:00Z',
};

// ─── Types ──────────────────────────────────────────────────

/** Shape returned by GET /auth/me */
export interface AuthMeResponse {
  user: User;
  tenant: Tenant;
}

export type AuthStatus = 'loading' | 'authenticated' | 'unauthenticated';

interface AuthContextValue {
  /** Current auth status — drives boot guard */
  status: AuthStatus;

  /** Authenticated user (null until /auth/me succeeds) */
  user: User | null;

  /** Tenant resolved by backend (null until /auth/me succeeds) */
  tenant: Tenant | null;

  /** Convenience booleans */
  isAuthenticated: boolean;
  isLoading: boolean;

  /** Store token + user/tenant from login response */
  login: (token: string, user?: User, tenant?: Tenant | null) => Promise<void>;

  /** Clear token + reset state */
  logout: () => void;
}

// ─── Context ────────────────────────────────────────────────

const AuthContext = createContext<AuthContextValue | null>(null);

// ─── Provider ───────────────────────────────────────────────

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [status, setStatus] = useState<AuthStatus>('loading');
  const [user, setUser] = useState<User | null>(null);
  const [tenant, setTenant] = useState<Tenant | null>(null);

  /**
   * Call GET /auth/me to resolve identity from the current token.
   * Returns true if the session is valid.
   */
  const resolveIdentity = useCallback(async (): Promise<boolean> => {
    if (DEV_BYPASS_AUTH) {
      setUser(MOCK_USER);
      setTenant(MOCK_TENANT);
      setStatus('authenticated');
      return true;
    }
    try {
      const data: AuthMeResponse = await fetchMe();
      setUser(data.user);
      // Use PLATFORM_ADMIN_TENANT for platform admins (no company)
      setTenant(data.tenant ?? PLATFORM_ADMIN_TENANT);
      setStatus('authenticated');
      return true;
    } catch {
      // Token invalid / expired / missing
      localStorage.removeItem('auth_token');
      setUser(null);
      setTenant(null);
      setStatus('unauthenticated');
      return false;
    }
  }, []);

  /**
   * On mount: if a token exists try to resolve identity.
   * If no token, go straight to unauthenticated.
   */
  useEffect(() => {
    if (DEV_BYPASS_AUTH) {
      resolveIdentity();
      return;
    }
    const token = localStorage.getItem('auth_token');
    if (token) {
      resolveIdentity();
    } else {
      setStatus('unauthenticated');
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  /**
   * Listen for auth:logout events from the axios 401 interceptor.
   * This provides a graceful logout via React state instead of a hard page reload.
   */
  useEffect(() => {
    const handleForceLogout = () => {
      console.log('🔓 Force logout triggered by 401 interceptor');
      setUser(null);
      setTenant(null);
      setStatus('unauthenticated');
    };
    window.addEventListener('auth:logout', handleForceLogout);
    return () => window.removeEventListener('auth:logout', handleForceLogout);
  }, []);

  /** Store token then call /auth/me */
  const login = useCallback(
    async (token: string, userData?: User, tenantData?: Tenant | null) => {
      if (!DEV_BYPASS_AUTH) {
        // Validate token before storing
        if (!token || token === 'undefined' || token === 'null') {
          console.error('\u274c Invalid token received:', token);
          setStatus('unauthenticated');
          return;
        }
        localStorage.setItem('auth_token', token);
      }

      // If user/tenant provided from login response, use directly (no extra API call)
      if (userData) {
        setUser(userData);
        // Use PLATFORM_ADMIN_TENANT for platform admins (no company)
        setTenant(tenantData ?? PLATFORM_ADMIN_TENANT);
        setStatus('authenticated');
        return;
      }

      // Fallback: resolve from /auth/me
      setStatus('loading');
      await resolveIdentity();
    },
    [resolveIdentity],
  );

  /** Clear everything */
  const logout = useCallback(() => {
    localStorage.removeItem('auth_token');
    setUser(null);
    setTenant(null);
    setStatus('unauthenticated');
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      status,
      user,
      tenant,
      isAuthenticated: status === 'authenticated',
      isLoading: status === 'loading',
      login,
      logout,
    }),
    [status, user, tenant, login, logout],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// ─── Hook ───────────────────────────────────────────────────

export const useAuth = (): AuthContextValue => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
};
