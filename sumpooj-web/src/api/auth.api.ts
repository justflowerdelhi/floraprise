import api from './axios';

/** Login response from backend */
export interface LoginResponse {
  access_token: string;
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
