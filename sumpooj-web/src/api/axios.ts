import axios from 'axios';
import type { InternalAxiosRequestConfig, AxiosError } from 'axios';

const api = axios.create({
  baseURL: 'https://localhost:7223/api', // your .NET API
});

// ─── Request: attach Bearer token ───────────────────────────
api.interceptors.request.use((config: InternalAxiosRequestConfig) => {
  const token = localStorage.getItem('auth_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// ─── Response: handle 401 / 403 globally ────────────────────
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    const status = error.response?.status;

    if (status === 401) {
      // Token expired or invalid — force re-login
      localStorage.removeItem('auth_token');
      // Only redirect if we're not already on the login page
      if (!window.location.pathname.startsWith('/auth/login')) {
        window.location.href = '/auth/login';
      }
    }

    if (status === 403) {
      // User is authenticated but lacks permission
      // Dispatch a custom event so UI layers can show a toast/snackbar
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
