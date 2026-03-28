import axios from 'axios';
import type { InternalAxiosRequestConfig, AxiosError, AxiosResponse } from 'axios';

const useCredentials = import.meta.env.VITE_API_WITH_CREDENTIALS === 'true';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  // Token auth does not require browser credentials by default.
  // Set VITE_API_WITH_CREDENTIALS=true only when API relies on cookies.
  withCredentials: useCredentials,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// ─── Module-level token (primary source for interceptor) ────
let _authToken: string | null = (() => {
  try {
    const token = localStorage.getItem('auth_token');
    if (token && token !== 'undefined' && token !== 'null') return token;
    return null;
  } catch {
    return null;
  }
})();

let _refreshToken: string | null = (() => {
  try {
    const token = localStorage.getItem('refresh_token');
    if (token && token !== 'undefined' && token !== 'null') return token;
    return null;
  } catch {
    return null;
  }
})();

/** Call after login to store both tokens */
export function setAuthToken(token: string): void {
  _authToken = token;
  try { localStorage.setItem('auth_token', token); } catch { /* quota */ }
}

export function setRefreshToken(token: string): void {
  _refreshToken = token;
  try { localStorage.setItem('refresh_token', token); } catch { /* quota */ }
}

/** Call on logout to clear all tokens */
export function clearAuthToken(): void {
  _authToken = null;
  _refreshToken = null;
  try {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('refresh_token');
  } catch { /* ignore */ }
}

export function getRefreshToken(): string | null {
  return _refreshToken;
}

// ─── Request: attach Bearer token ───────────────────────────
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = _authToken;
  if (token && token !== 'undefined' && token !== 'null') {
    config.headers.set('Authorization', `Bearer ${token}`);
  }

  // Auto-attach locationId so location-aware modules stay scoped after login.
  if (!isAuthRequest(config.url) && !hasLocationIdParam(config.params)) {
    const locationId = resolveRequestLocationId();
    if (locationId) {
      if (config.params instanceof URLSearchParams) {
        config.params.set('locationId', locationId);
      } else {
        config.params = {
          ...(typeof config.params === 'object' && config.params ? config.params : {}),
          locationId,
        };
      }
    }
  }

  return config;
});

// ─── Response: silent refresh on 401 ────────────────────────

let isRefreshing = false;
let refreshSubscribers: Array<(token: string) => void> = [];

function onRefreshed(newToken: string) {
  refreshSubscribers.forEach((cb) => cb(newToken));
  refreshSubscribers = [];
}

function addRefreshSubscriber(cb: (token: string) => void) {
  refreshSubscribers.push(cb);
}

const LOCATION_STORAGE_KEY = 'app:currentLocationId';
const USER_STORAGE_KEY = 'app:user';
const ALL_LOCATIONS_ID = 'ALL';

function isAuthRequest(url?: string): boolean {
  if (!url) return false;
  return url.includes('/auth/');
}

function readPersistedLocationId(): string | null {
  try {
    const locationId = localStorage.getItem(LOCATION_STORAGE_KEY);
    if (!locationId || locationId === 'undefined' || locationId === 'null') {
      return null;
    }
    if (locationId === ALL_LOCATIONS_ID) {
      return null;
    }
    return locationId;
  } catch {
    return null;
  }
}

function readUserPrimaryLocationId(): string | null {
  try {
    const userRaw = localStorage.getItem(USER_STORAGE_KEY);
    if (!userRaw) return null;
    const user = JSON.parse(userRaw) as { primaryLocationId?: string | null };
    const locationId = user?.primaryLocationId;
    if (!locationId || locationId === ALL_LOCATIONS_ID) return null;
    return locationId;
  } catch {
    return null;
  }
}

function resolveRequestLocationId(): string | null {
  return readPersistedLocationId() ?? readUserPrimaryLocationId();
}

function hasLocationIdParam(params: unknown): boolean {
  if (!params) return false;

  if (params instanceof URLSearchParams) {
    return params.has('locationId');
  }

  if (typeof params === 'object') {
    return Object.prototype.hasOwnProperty.call(params, 'locationId');
  }

  return false;
}

api.interceptors.response.use(
  (response: AxiosResponse) => response,
  async (error: AxiosError) => {
    const status = error.response?.status;
    const originalRequest = error.config as InternalAxiosRequestConfig & { _retry?: boolean };

    // Only attempt refresh on 401 for non-auth endpoints
    if (status === 401 && originalRequest && !originalRequest._retry) {
      const requestUrl = originalRequest.url ?? '';

      // Don't retry auth endpoints (login, refresh, revoke) — prevents loops
      if (requestUrl.includes('/auth/login') ||
          requestUrl.includes('/auth/refresh') ||
          requestUrl.includes('/auth/revoke')) {
        return Promise.reject(error);
      }

      // If we have a refresh token, attempt silent refresh
      if (_refreshToken) {
        if (isRefreshing) {
          // Another refresh is in progress — queue this request
          return new Promise((resolve) => {
            addRefreshSubscriber((newToken: string) => {
              originalRequest.headers.set('Authorization', `Bearer ${newToken}`);
              resolve(api(originalRequest));
            });
          });
        }

        originalRequest._retry = true;
        isRefreshing = true;

        try {
          // Call refresh endpoint directly (bypass interceptor to avoid loops)
          const res = await axios.post(
            `${import.meta.env.VITE_API_BASE_URL}/auth/refresh`,
            { refreshToken: _refreshToken },
            { headers: { 'Content-Type': 'application/json' } }
          );

          const { access_token, refresh_token } = res.data;
          setAuthToken(access_token);
          setRefreshToken(refresh_token);

          isRefreshing = false;
          onRefreshed(access_token);

          // Retry the original request with the new token
          originalRequest.headers.set('Authorization', `Bearer ${access_token}`);
          return api(originalRequest);
        } catch {
          // Refresh failed — force logout
          isRefreshing = false;
          refreshSubscribers = [];
          clearAuthToken();
          window.dispatchEvent(new CustomEvent('auth:logout'));
          return Promise.reject(error);
        }
      }

      // No refresh token — check if it's /auth/me and force logout
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
