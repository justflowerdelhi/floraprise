/**
 * dashboard.api.ts — Dashboard API Service
 *
 * GET /Dashboard?role=...&locationId=...
 */
import api from './axios';

export const fetchDashboard = async (role?: string, locationId?: string) => {
  const res = await api.get('/Dashboard', { params: { role, locationId } });
  return res.data;
};
