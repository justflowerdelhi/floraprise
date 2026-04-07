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
import { fetchMe, revokeToken } from '../api/auth.api';
import { setAuthToken, setRefreshToken, clearAuthToken, getRefreshToken } from '../api/axios';
import { normalizeRole } from '../api/auth.api';

// ─── Dev Bypass ─────────────────────────────────────────────
const DEV_BYPASS_AUTH = import.meta.env.VITE_DEV_BYPASS_AUTH === 'true';

const MOCK_USER: User = {
  id: 'dev-user-1',
  name: 'Dev Admin',
  email: 'admin@floraprise.dev',
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
  login: (token: string, user?: User, tenant?: Tenant | null, refreshToken?: string) => Promise<void>;

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
      const resolvedUser = { ...data.user, role: normalizeRole(data.user.role) };
      const resolvedTenant = data.tenant ?? PLATFORM_ADMIN_TENANT;
      setUser(resolvedUser);
      setTenant(resolvedTenant);
      setStatus('authenticated');
      // Persist for next refresh
      try {
        localStorage.setItem('app:user', JSON.stringify(resolvedUser));
        localStorage.setItem('app:tenant', JSON.stringify(resolvedTenant));
      } catch { /* quota */ }
      return true;
    } catch {
      // /auth/me is the source of truth for token validity.
      // If it fails, clear local state and require re-auth.
      clearAuthToken();
      setUser(null);
      setTenant(null);
      setStatus('unauthenticated');
      return false;
    }
  }, []);

  /**
   * On mount: hydrate from localStorage and validate session
   */
  useEffect(() => {
    let isMounted = true;

    const initAuth = async () => {
      if (DEV_BYPASS_AUTH) {
        if (isMounted) {
          setUser(MOCK_USER);
          setTenant(MOCK_TENANT);
          setStatus('authenticated');
        }
        return;
      }

      try {
        // 1. Try to restore user + tenant from localStorage
        const storedUserJson = localStorage.getItem('app:user');
        const storedTenantJson = localStorage.getItem('app:tenant');
        if (storedUserJson) {
          try {
            const storedUser = JSON.parse(storedUserJson);
            if (isMounted) setUser(storedUser);
          } catch {
            // Invalid JSON, ignore
          }
        }
        if (storedTenantJson) {
          try {
            const storedTenant = JSON.parse(storedTenantJson);
            if (isMounted) setTenant(storedTenant);
          } catch {
            // Invalid JSON, ignore
          }
        }

        // 2. Try to restore token from localStorage
        const token = localStorage.getItem('auth_token');
        if (token && token !== 'undefined' && token !== 'null') {
          // Ensure axios interceptor has the token
          setAuthToken(token);

          // 3. Validate token with backend
          const isValid = await resolveIdentity();
          if (isMounted && !isValid) {
            setUser(null);
          }
        } else {
          // No token, go straight to login
          if (isMounted) {
            setUser(null);
            setStatus('unauthenticated');
          }
        }
      } catch (err) {
        console.error('Auth initialization error:', err);
        if (isMounted) {
          setUser(null);
          setStatus('unauthenticated');
        }
      }
    };

    initAuth();
    return () => {
      isMounted = false;
    };
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
    async (token: string, userData?: User, tenantData?: Tenant | null, refreshTokenValue?: string) => {
      if (!DEV_BYPASS_AUTH) {
        // Validate token before storing
        if (!token || token === 'undefined' || token === 'null') {
          console.error('\u274c Invalid token received:', token);
          setStatus('unauthenticated');
          return;
        }
        setAuthToken(token);
        if (refreshTokenValue) {
          setRefreshToken(refreshTokenValue);
        }
      }

      // If user/tenant provided from login response, use directly (no extra API call)
      if (userData) {
        setUser(userData);
        // Use PLATFORM_ADMIN_TENANT for platform admins (no company)
        const resolvedTenant = tenantData ?? PLATFORM_ADMIN_TENANT;
        setTenant(resolvedTenant);
        // Store user + tenant for session persistence across page refreshes
        try {
          localStorage.setItem('app:user', JSON.stringify(userData));
          localStorage.setItem('app:tenant', JSON.stringify(resolvedTenant));
        } catch {}
        setStatus('authenticated');
        return;
      }

      // Fallback: resolve from /auth/me
      setStatus('loading');
      await resolveIdentity();
    },
    [resolveIdentity],
  );

  /** Clear everything and revoke refresh token */
  const logout = useCallback(() => {
    const rt = getRefreshToken();
    if (rt) {
      revokeToken(rt).catch(() => { /* best-effort */ });
    }
    clearAuthToken();
    setUser(null);
    setTenant(null);
    setStatus('unauthenticated');
    try {
      localStorage.removeItem('app:user');
      localStorage.removeItem('app:tenant');
    } catch {}
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
