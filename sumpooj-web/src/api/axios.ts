import axios from 'axios';
import type { InternalAxiosRequestConfig, AxiosError, AxiosResponse } from 'axios';

const api = axios.create({
  baseURL: 'https://floritribe.com/floraedgeapi/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// ─── Request: attach Bearer token ───────────────────────────
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = localStorage.getItem('auth_token');
  console.log('📤 Request:', config.method?.toUpperCase(), config.url);
  console.log('🔑 Token present:', !!token, token ? `${token.substring(0, 20)}...` : 'null');

  if (token && token !== 'undefined' && token !== 'null') {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ─── Response: log and handle errors ────────────────────────
api.interceptors.response.use(
  (response: AxiosResponse) => {
    console.log('📥 Response:', response.status, response.config.url);
    console.log('📥 Response data:', response.data);
    return response;
  },
  (error: AxiosError) => {
    console.error('❌ Error:', error.response?.status, error.config?.url);
    console.error('❌ Error data:', error.response?.data);

    const status = error.response?.status;

    if (status === 401) {
      const requestUrl = error.config?.url ?? '';
      // Only force-logout when the auth-validation endpoint itself says
      // the token is invalid.  Other endpoints returning 401 (e.g. missing
      // company context for PlatformSuperAdmin) should NOT trigger logout.
      const isAuthEndpoint = requestUrl.includes('/auth/me');
      const token = localStorage.getItem('auth_token');
      if (token && isAuthEndpoint) {
        console.log('\ud83d\udd13 Token rejected by /auth/me - clearing and logging out');
        localStorage.removeItem('auth_token');
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
