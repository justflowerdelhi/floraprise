import api from './axios';

// ─── Types ──────────────────────────────────────────────────

export interface DashboardPreferenceDto {
  visibleModules: string[];
  moduleOrder: string[];
  isDefault: boolean;
}

export interface SaveDashboardPreferenceRequest {
  visibleModules: string[];
  moduleOrder: string[];
}

// ─── API calls ──────────────────────────────────────────────

/** GET /api/dashboard-preference — returns user's saved prefs or defaults */
export const getDashboardPreference = async (): Promise<DashboardPreferenceDto> => {
  const { data } = await api.get<DashboardPreferenceDto>('/dashboard-preference');
  return data;
};

/** POST /api/dashboard-preference — save user's module visibility & order */
export const saveDashboardPreference = async (
  request: SaveDashboardPreferenceRequest,
): Promise<DashboardPreferenceDto> => {
  const { data } = await api.post<DashboardPreferenceDto>('/dashboard-preference', request);
  return data;
};
