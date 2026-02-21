/**
 * dashboard.api.ts — Dashboard API Service
 *
 * GET /Dashboard?role=...&locationId=...
 * Uses mock data when USE_MOCK_DATA is true (no backend)
 */
import { fetchMockDashboard } from '../pages/dashboard/api/DashboardMockData';
import api from './axios';

const USE_MOCK_DATA = true; // Set to false when backend is available

export const fetchDashboard = async (role?: string, locationId?: string) => {
  if (USE_MOCK_DATA) {
    return fetchMockDashboard(role ?? 'ADMIN');
  }
  const res = await api.get('/Dashboard', { params: { role, locationId } });
  return res.data;
};
