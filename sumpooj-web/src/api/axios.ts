import axios from 'axios';
import type { InternalAxiosRequestConfig, AxiosError, AxiosResponse } from 'axios';

const api = axios.create({
  baseURL: import.meta.env.PROD
    ? 'https://floritribe.com/floraedgeapi/api'
    : '/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// ─── Module-level token (primary source for interceptor) ────
// Keeps token in JS memory so the interceptor always has it
// immediately after login — eliminates localStorage timing issues.
let _authToken: string | null = localStorage.getItem('auth_token');

/** Call after login to make the token available to every request */
export function setAuthToken(token: string): void {
  _authToken = token;
  console.log(`🔐 [setAuthToken] Token stored in memory: ${token.substring(0, 30)}...`);
  try { 
    localStorage.setItem('auth_token', token);
    console.log(`💾 [setAuthToken] Token also saved to localStorage`);
  } catch { 
    console.warn(`⚠️ [setAuthToken] Could not save to localStorage (quota or private mode)`);
  }
}

/** Call on logout to clear the token everywhere */
export function clearAuthToken(): void {
  _authToken = null;
  console.log(`🔓 [clearAuthToken] Token cleared from memory and localStorage`);
  try { localStorage.removeItem('auth_token'); } catch { /* ignore */ }
}

// ─── Request: attach Bearer token ───────────────────────────
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = _authToken;
  console.log(`🔐 [Interceptor] Token present: ${!!token} | URL: ${config.url}`);
  if (token && token !== 'undefined' && token !== 'null') {
    config.headers.set('Authorization', `Bearer ${token}`);
    console.log(`✅ [Interceptor] Authorization header set: Bearer ${token.substring(0, 20)}...`);
  } else {
    console.warn(`❌ [Interceptor] NO TOKEN - cannot attach Authorization header`);
  }
  return config;
});

// ─── Response: log and handle errors ────────────────────────
api.interceptors.response.use(
  (response: AxiosResponse) => response,
  (error: AxiosError) => {
    const status = error.response?.status;

    if (status === 401) {
      const requestUrl = error.config?.url ?? '';
      // Only force-logout when the auth-validation endpoint itself says
      // the token is invalid.  Other endpoints returning 401 (e.g. missing
      // company context for PlatformSuperAdmin) should NOT trigger logout.
      const isAuthEndpoint = requestUrl.includes('/auth/me');
      if (_authToken && isAuthEndpoint) {
        clearAuthToken();
        window.dispatchEvent(new CustomEvent('auth:logout'));
      }
    }

    if (status === 403) {
      window.dispatchEvent(
        new CustomEvent('auth:forbidden', {
          detail: { url: error.config?.url, message: 'Access denied — insufficient permissions' },
        }),
      );
    }

    return Promise.reject(error);
  },
);

export default api;
