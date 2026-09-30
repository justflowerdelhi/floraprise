/**
 * Central Admin API Client
 * Configurable HTTP client with automatic Bearer token injection and graceful error handling.
 */

export interface ApiResponse<T> {
  data: T | null;
  status: number;
  isSuccess: boolean;
  error?: string;
}

class ApiClient {
  private baseUrl: string;

  constructor() {
    // Default to local ASP.NET backend or environment variable
    this.baseUrl = (import.meta as any).env?.VITE_API_BASE_URL || 'http://localhost:5148';
  }

  getBaseUrl(): string {
    return this.baseUrl;
  }

  setBaseUrl(url: string): void {
    this.baseUrl = url.replace(/\/$/, '');
  }

  getToken(): string | null {
    return localStorage.getItem('floraprise_access_token');
  }

  setToken(token: string | null): void {
    if (token) {
      localStorage.setItem('floraprise_access_token', token);
    } else {
      localStorage.removeItem('floraprise_access_token');
    }
  }

  private getHeaders(): HeadersInit {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    const token = this.getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    return headers;
  }

  async checkConnectivity(): Promise<{ isOnline: boolean; latencyMs: number }> {
    const start = performance.now();
    try {
      const response = await fetch(`${this.baseUrl}/api/ping`, {
        method: 'GET',
        headers: this.getHeaders(),
        signal: AbortSignal.timeout(3000),
      });
      const latencyMs = Math.round(performance.now() - start);
      return { isOnline: response.ok, latencyMs };
    } catch {
      return { isOnline: false, latencyMs: 0 };
    }
  }

  async get<T>(path: string, params?: Record<string, any>): Promise<ApiResponse<T>> {
    let url = `${this.baseUrl}${path.startsWith('/') ? path : `/${path}`}`;
    if (params) {
      const searchParams = new URLSearchParams();
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined && value !== null && value !== '') {
          searchParams.append(key, String(value));
        }
      });
      const queryString = searchParams.toString();
      if (queryString) {
        url += (url.includes('?') ? '&' : '?') + queryString;
      }
    }

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: this.getHeaders(),
        signal: AbortSignal.timeout(8000),
      });

      if (!response.ok) {
        const errorText = await response.text().catch(() => '');
        return {
          data: null,
          status: response.status,
          isSuccess: false,
          error: errorText || `HTTP ${response.status} ${response.statusText}`,
        };
      }

      const data = await response.json().catch(() => null);
      return {
        data: data as T,
        status: response.status,
        isSuccess: true,
      };
    } catch (err: any) {
      return {
        data: null,
        status: 0,
        isSuccess: false,
        error: err?.message || 'Network connection failed',
      };
    }
  }

  async post<T>(path: string, body?: any): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${path.startsWith('/') ? path : `/${path}`}`;

    try {
      const response = await fetch(url, {
        method: 'POST',
        headers: this.getHeaders(),
        body: body ? JSON.stringify(body) : undefined,
        signal: AbortSignal.timeout(10000),
      });

      if (!response.ok) {
        const errorText = await response.text().catch(() => '');
        return {
          data: null,
          status: response.status,
          isSuccess: false,
          error: errorText || `HTTP ${response.status} ${response.statusText}`,
        };
      }

      const data = await response.json().catch(() => null);
      return {
        data: data as T,
        status: response.status,
        isSuccess: true,
      };
    } catch (err: any) {
      return {
        data: null,
        status: 0,
        isSuccess: false,
        error: err?.message || 'Network connection failed',
      };
    }
  }

  async patch<T>(path: string, body?: any): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${path.startsWith('/') ? path : `/${path}`}`;

    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: this.getHeaders(),
        body: body ? JSON.stringify(body) : undefined,
        signal: AbortSignal.timeout(10000),
      });

      if (!response.ok) {
        const errorText = await response.text().catch(() => '');
        return {
          data: null,
          status: response.status,
          isSuccess: false,
          error: errorText || `HTTP ${response.status} ${response.statusText}`,
        };
      }

      const data = await response.json().catch(() => null);
      return {
        data: data as T,
        status: response.status,
        isSuccess: true,
      };
    } catch (err: any) {
      return {
        data: null,
        status: 0,
        isSuccess: false,
        error: err?.message || 'Network connection failed',
      };
    }
  }
}

export const apiClient = new ApiClient();
