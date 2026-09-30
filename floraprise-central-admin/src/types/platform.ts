export interface AdminUser {
  id: string;
  name: string;
  email: string;
  role: 'SuperAdmin' | 'SupportOperator' | 'BillingAdmin' | 'Auditor';
  avatar?: string;
  status: 'Active' | 'Suspended';
  lastLoginAt: string;
  twoFactorEnabled: boolean;
}

export interface PlatformSettings {
  platformName: string;
  environment: 'Production' | 'Staging';
  supportContactEmail: string;
  supportPhone: string;
  annualPlanPriceInr: number;
  trialDurationDays: number;
  gracePeriodDays: number;
  maintenanceMode: boolean;
  allowPublicSelfRegistration: boolean;
  requireDefaultLocationCheck: boolean;
  automaticSoloMigrationVerify: boolean;
  webhookUrl: string;
}
