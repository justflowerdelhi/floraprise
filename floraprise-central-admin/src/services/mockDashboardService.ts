import { realDashboardService, DashboardMetrics, MobileAdminDashboardDto } from './api/realDashboardService';

export type { DashboardMetrics, MobileAdminDashboardDto };
export const mockDashboardService = realDashboardService;
export { realDashboardService };
