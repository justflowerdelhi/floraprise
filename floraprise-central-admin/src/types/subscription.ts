import { CloudServiceKey, OperationalMode } from './subscriber';

export type PlanBillingCycle = 'Trial' | 'Monthly' | 'Quarterly' | 'Half-Yearly' | 'Annual';

export interface SubscriptionPlan {
  id: string;
  name: string;
  code: string;
  planType?: 'Basic' | 'Pro' | 'Enterprise' | 'Lifetime' | string;
  billingCycle: PlanBillingCycle;
  priceInr: number;
  monthlyPrice?: number;
  annualPrice?: number;
  lifetimePrice?: number;
  trialDays?: number;
  offlineDays?: number;
  graceDays?: number;
  maximumDevices?: number;
  maximumStaff?: number;
  maxDevices: number;
  maxStaff: number;
  maxLocations: number;
  durationDays: number;
  supportedModes: OperationalMode[];
  includedServices: CloudServiceKey[];
  includedModulesJson?: string;
  description: string;
  isPopular?: boolean;
  isActive: boolean;
}

export interface SubscriptionRecord {
  id: string;
  subscriberId: string;
  businessName: string;
  planName: string;
  planCode: string;
  status: 'Active' | 'Trial' | 'Grace' | 'Expired';
  amountInr: number;
  startDate: string;
  expiryDate: string;
  gracePeriodEndsAt?: string;
  autoRenew: boolean;
  paymentMethod?: string;
  lastPaymentReference?: string;
}
