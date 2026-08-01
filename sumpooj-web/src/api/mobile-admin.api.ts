import api from './axios';

export interface MobileAdminDashboardMetrics {
  activeUsers: number;
  trialUsers: number;
  activeSubscriptions: number;
  renewalsDue: number;
  revenue: number;
  onlineDevices: number;
  trialExpiringToday: number;
  renewalsDueToday: number;
  devicesOffline7Days: number;
  failedPayments: number;
  recentlySuspendedAccounts: number;
  newCustomersLast7Days: number;
}

export interface MobileAdminGlobalSearchResult {
  companyId: string;
  mobileUserId: string;
  businessName: string;
  currentPlan?: string | null;
  status: string;
  lastSeenAtUtc?: string | null;
  deviceCount: number;
}

export interface MobileAdminCustomerListItem {
  mobileUserId: string;
  companyId: string;
  customerName: string;
  businessName?: string | null;
  mobile: string;
  email?: string | null;
  userStatus: string;
  subscriptionStatus: string;
  planCode?: string | null;
  planName?: string | null;
  trialEndUtc?: string | null;
  subscriptionEndUtc?: string | null;
  remainingDays: number;
  totalDevices: number;
  onlineDevices: number;
}

export interface MobileAdminDevice {
  deviceId: string;
  platform: string;
  appVersion: string;
  status: string;
  lastHeartbeatAtUtc?: string | null;
  lastLoginAtUtc?: string | null;
  lastSyncAtUtc?: string | null;
  lastIpAddress?: string | null;
}

export interface MobileAdminPayment {
  transactionRef: string;
  amount: number;
  currency: string;
  paymentStatus: string;
  paymentType: string;
  createdAtUtc: string;
  paidAtUtc?: string | null;
}

export interface MobileAdminDeviceListItem {
  mobileDeviceId: string;
  companyId: string;
  mobileUserId: string;
  deviceName: string;
  deviceId: string;
  businessName?: string | null;
  platform: string;
  osVersion?: string | null;
  appVersion: string;
  online: boolean;
  lastSeenAtUtc?: string | null;
  registeredAtUtc: string;
  subscriptionType: string;
  deviceStatus: string;
}

export interface MobileAdminDevicePagedResult {
  items: MobileAdminDeviceListItem[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export interface MobileAdminDeviceQuery {
  companyId?: string;
  search?: string;
  connectionStatus?: 'online' | 'offline' | '';
  subscriptionType?: 'trial' | 'paid' | '';
  appVersion?: string;
  platform?: string;
  page?: number;
  pageSize?: number;
}

export interface MobileAdminLicenseListItem {
  mobileLicenseId: string;
  companyId: string;
  mobileUserId: string;
  licenseNumber: string;
  businessName?: string | null;
  plan?: string | null;
  status: string;
  issueDateUtc: string;
  expiryDateUtc?: string | null;
  remainingDays: number;
}

export interface MobileAdminLicensePagedResult {
  items: MobileAdminLicenseListItem[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export interface MobileAdminLicenseQuery {
  companyId?: string;
  search?: string;
  status?: string;
  planCode?: string;
  page?: number;
  pageSize?: number;
}

export interface MobileAdminSupportActivityItem {
  dateTimeUtc: string;
  supportUser: string;
  customer: string;
  action: string;
  previousValue?: string | null;
  newValue?: string | null;
  notes?: string | null;
}

export interface MobileAdminSupportActivityPagedResult {
  items: MobileAdminSupportActivityItem[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export interface MobileAdminSupportActivityQuery {
  companyId?: string;
  search?: string;
  action?: string;
  fromUtc?: string;
  toUtc?: string;
  page?: number;
  pageSize?: number;
}

export interface MobileAdminTimelineItem {
  timestampUtc: string;
  category: string;
  title: string;
  description: string;
}

export interface MobileAdminCustomerDetail {
  mobileUserId: string;
  companyId: string;
  customerName: string;
  businessName?: string | null;
  ownerName?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string | null;
  mobile: string;
  email?: string | null;
  userStatus: string;
  subscriptionStatus: string;
  planCode?: string | null;
  planName?: string | null;
  trialEndUtc?: string | null;
  subscriptionEndUtc?: string | null;
  autoRenew?: boolean | null;
  remainingDays: number;
  devices: MobileAdminDevice[];
  recentPayments: MobileAdminPayment[];
  activityTimeline: MobileAdminTimelineItem[];
}

export interface MobileAdminCustomerPagedResult {
  items: MobileAdminCustomerListItem[];
  totalCount: number;
  page: number;
  pageSize: number;
}

export interface MobileAdminCustomerQuery {
  companyId?: string;
  search?: string;
  userStatus?: string;
  subscriptionStatus?: string;
  planCode?: string;
  page?: number;
  pageSize?: number;
}

export interface MobileSubscriptionPlanDto {
  id: string;
  code: string;
  name: string;
  planType: string;
  monthlyPrice: number;
  annualPrice: number;
  lifetimePrice: number;
  trialDays: number;
  offlineDays: number;
  graceDays: number;
  maximumDevices: number;
  maximumStaff: number;
  isActive: boolean;
  includedModulesJson: string;
}

export const getMobileAdminDashboard = async (companyId?: string): Promise<MobileAdminDashboardMetrics> => {
  const res = await api.get('/platform/mobile-admin/dashboard', {
    params: { companyId },
  });
  return res.data;
};

export const getMobileAdminCustomers = async (
  params: MobileAdminCustomerQuery,
): Promise<MobileAdminCustomerPagedResult> => {
  const res = await api.get('/platform/mobile-admin/customers', { params });
  return res.data;
};

export const getMobileAdminCustomerDetails = async (
  companyId: string,
  mobileUserId: string,
): Promise<MobileAdminCustomerDetail> => {
  const res = await api.get(`/platform/mobile-admin/customers/${mobileUserId}`, {
    params: { companyId },
  });
  return res.data;
};

export const getMobileAdminPlans = async (): Promise<MobileSubscriptionPlanDto[]> => {
  const res = await api.get('/platform/mobile-admin/plans');
  return res.data;
};

export const upgradeMobileAdminCustomerPlan = async (
  mobileUserId: string,
  payload: { companyId: string; planId: string; billingCycle: string },
) => {
  const res = await api.post(`/platform/mobile-admin/customers/${mobileUserId}/upgrade-plan`, payload);
  return res.data;
};

export const renewMobileAdminCustomer = async (
  mobileUserId: string,
  payload: { companyId: string; billingCycle: string; autoRenew: boolean },
) => {
  const res = await api.post(`/platform/mobile-admin/customers/${mobileUserId}/renew`, payload);
  return res.data;
};

export const suspendMobileAdminCustomer = async (
  mobileUserId: string,
  payload: { companyId: string },
) => {
  const res = await api.post(`/platform/mobile-admin/customers/${mobileUserId}/suspend`, payload);
  return res.data;
};

export const resetMobileAdminCustomerDevice = async (
  mobileUserId: string,
  payload: { companyId: string; deviceId?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/customers/${mobileUserId}/reset-device`, payload);
  return res.data;
};

export const forceLogoutMobileAdminCustomer = async (
  mobileUserId: string,
  payload: { companyId: string; deviceId?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/customers/${mobileUserId}/force-logout`, payload);
  return res.data;
};

export const searchMobileAdminGlobal = async (
  q: string,
  companyId?: string,
  limit = 20,
): Promise<MobileAdminGlobalSearchResult[]> => {
  const res = await api.get('/platform/mobile-admin/search/global', {
    params: { q, companyId, limit },
  });
  return res.data;
};

export const getMobileAdminDevices = async (
  params: MobileAdminDeviceQuery,
): Promise<MobileAdminDevicePagedResult> => {
  const res = await api.get('/platform/mobile-admin/devices', { params });
  return res.data;
};

export const forceLogoutMobileAdminDevice = async (
  mobileDeviceId: string,
  payload: { companyId: string; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/devices/${mobileDeviceId}/force-logout`, payload);
  return res.data;
};

export const resetMobileAdminDevice = async (
  mobileDeviceId: string,
  payload: { companyId: string; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/devices/${mobileDeviceId}/reset`, payload);
  return res.data;
};

export const disableMobileAdminDevice = async (
  mobileDeviceId: string,
  payload: { companyId: string; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/devices/${mobileDeviceId}/disable`, payload);
  return res.data;
};

export const getMobileAdminLicenses = async (
  params: MobileAdminLicenseQuery,
): Promise<MobileAdminLicensePagedResult> => {
  const res = await api.get('/platform/mobile-admin/licenses', { params });
  return res.data;
};

export const activateMobileAdminLicense = async (
  mobileLicenseId: string,
  payload: { companyId: string; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/licenses/${mobileLicenseId}/activate`, payload);
  return res.data;
};

export const suspendMobileAdminLicense = async (
  mobileLicenseId: string,
  payload: { companyId: string; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/licenses/${mobileLicenseId}/suspend`, payload);
  return res.data;
};

export const resumeMobileAdminLicense = async (
  mobileLicenseId: string,
  payload: { companyId: string; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/licenses/${mobileLicenseId}/resume`, payload);
  return res.data;
};

export const extendMobileAdminLicense = async (
  mobileLicenseId: string,
  payload: { companyId: string; extendByDays: number; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/licenses/${mobileLicenseId}/extend`, payload);
  return res.data;
};

export const convertTrialMobileAdminLicense = async (
  mobileLicenseId: string,
  payload: { companyId: string; planId: string; billingCycle: string; notes?: string },
) => {
  const res = await api.post(`/platform/mobile-admin/licenses/${mobileLicenseId}/convert-trial`, payload);
  return res.data;
};

export const getMobileAdminSupportActivity = async (
  params: MobileAdminSupportActivityQuery,
): Promise<MobileAdminSupportActivityPagedResult> => {
  const res = await api.get('/platform/mobile-admin/support-activity', { params });
  return res.data;
};

export const exportMobileAdminSupportActivityUrl = (params: MobileAdminSupportActivityQuery): string => {
  const qs = new URLSearchParams();
  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && String(value).length > 0) {
      qs.append(key, String(value));
    }
  });
  return `/platform/mobile-admin/support-activity/export?${qs.toString()}`;
};