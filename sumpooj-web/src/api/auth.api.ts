import api from './axios';

/** POST /auth/login — returns { access_token } */
export const login = async (email: string, password: string) => {
  const res = await api.post('/auth/login', { email, password });
  return res.data;
};

/** GET /auth/me — returns current user + tenant identity (backend-authoritative) */
export const fetchMe = async () => {
  const res = await api.get('/auth/me');
  return res.data;
};
