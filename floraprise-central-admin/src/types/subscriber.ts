export type SubscriberStatus = 
  | 'Active' 
  | 'Pending Onboarding' 
  | 'Needs Attention' 
  | 'Suspended' 
  | 'Expired' 
  | 'Trial';

export type OperationalMode = 'Flutter Solo' | 'Flutter Cloud Android' | 'Flutter Web';

export type CloudServiceKey = 
  | 'Subscription Validation' 
  | 'Delivery Tracking' 
  | 'Cloud Storage' 
  | 'Notifications' 
  | 'WhatsApp Integration'
  | 'Cloud Production & Recipes';

export interface SubscriberLocation {
  id: string;
  companyId: string;
  name: string;
  code: string;
  type: 'Store' | 'Warehouse' | 'Workshop' | 'Kiosk';
  address?: string;
  isActive: boolean;
  isDefault: boolean;
  createdAt: string;
}

export interface SubscriberDevice {
  id: string;
  companyId: string;
  deviceName: string;
  deviceModel: string;
  platform: 'Android' | 'Windows' | 'Web' | 'iOS';
  operationalMode: OperationalMode;
  appVersion: string;
  lastSeenAt: string;
  ipAddress: string;
  status: 'Online' | 'Offline' | 'Deactivated';
  licenseKey: string;
}

export interface SubscriberUser {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: 'CompanyAdmin' | 'Staff' | 'Driver';
  isActive: boolean;
  lastLogin?: string;
}

export interface ProvisioningCheckResult {
  key: string;
  title: string;
  passed: boolean;
  status: 'READY' | 'NEEDS ATTENTION' | 'NOT READY';
  problem?: string;
  explanation?: string;
  suggestedAction?: string;
  remediationAvailable?: boolean;
}

export interface SubscriberLicense {
  id: string; // GUID
  companyId: string;
  mobileUserId: string;
  licenseNumber: string;
  plan: string;
  status: 'Active' | 'Suspended' | 'Revoked' | 'Expired' | string;
  issuedAt: string;
  expiresAt?: string;
  remainingDays: number;
}

export interface SubscriberTimelineItem {
  timestamp: string;
  category: string;
  title: string;
  description: string;
}

export interface Subscriber {
  id: string; // CompanyId (UUID)
  mobileUserId?: string;
  businessName: string;
  ownerName: string;
  mobile: string;
  email: string;
  address: string;
  city: string;
  state: string;
  pinCode: string;
  gstin?: string;
  logoUrl?: string;
  
  status: SubscriberStatus;
  planId: string;
  planName: string;
  subscriptionStatus: 'Active' | 'Trial' | 'Grace' | 'Expired';
  subscriptionExpiresAt: string;
  subscriptionStartedAt: string;
  
  operationalModes: OperationalMode[];
  enabledCloudServices: CloudServiceKey[];
  
  maxDevices: number;
  maxStaff: number;
  activeDevicesCount: number;
  locationsCount: number;
  
  locations: SubscriberLocation[];
  licenses?: SubscriberLicense[];
  devices: SubscriberDevice[];
  users: SubscriberUser[];
  
  provisioningChecks: ProvisioningCheckResult[];
  overallProvisioningState: 'READY' | 'NEEDS ATTENTION' | 'NOT READY';
  
  activityTimeline?: SubscriberTimelineItem[];
  lastActivityAt: string;
  createdAt: string;
  notes?: string;
}
