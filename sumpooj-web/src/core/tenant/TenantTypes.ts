// =============================================================================
// TENANT TYPES - SaaS Subscription Architecture
// =============================================================================

// -----------------------------------------------------------------------------
// Plan & Subscription Types
// -----------------------------------------------------------------------------

export type TenantPlan = 'STARTER' | 'GROWTH' | 'PRO' | 'ENTERPRISE';

export type SubscriptionStatus = 'TRIAL' | 'ACTIVE' | 'PAST_DUE' | 'CANCELLED';

// -----------------------------------------------------------------------------
// Tenant Model
// -----------------------------------------------------------------------------

export interface Tenant {
  id: string;
  name: string;
  slug: string;
  plan: TenantPlan;
  subscriptionStatus: SubscriptionStatus;
  trialEndsAt?: string;
  subscriptionEndsAt?: string;
  isActive: boolean;
  createdAt: string;
  // Usage tracking
  usageStats?: TenantUsageStats;
}

export interface TenantUsageStats {
  ordersThisMonth: number;
  ordersLimit: number;
  staffCount: number;
  staffLimit: number;
  locationsCount: number;
  locationsLimit: number;
  storageUsedMB: number;
  storageLimitMB: number;
}

// -----------------------------------------------------------------------------
// Plan Configuration
// -----------------------------------------------------------------------------

export interface PlanConfig {
  id: TenantPlan;
  name: string;
  description: string;
  monthlyPrice: number;
  yearlyPrice: number;
  features: string[];
  limits: {
    orders: number; // per month, -1 = unlimited
    staff: number;
    locations: number;
    storageMB: number;
  };
  recommended?: boolean;
}

export const PLAN_CONFIGS: Record<TenantPlan, PlanConfig> = {
  STARTER: {
    id: 'STARTER',
    name: 'Starter',
    description: 'Perfect for small flower shops getting started',
    monthlyPrice: 29,
    yearlyPrice: 290,
    features: [
      'Point of Sale',
      'Basic Inventory Management',
      'Order Management',
      'Customer Database',
      'Basic Reports',
      'Email Support',
    ],
    limits: {
      orders: 500,
      staff: 3,
      locations: 1,
      storageMB: 1024,
    },
  },
  GROWTH: {
    id: 'GROWTH',
    name: 'Growth',
    description: 'For growing florists ready to expand',
    monthlyPrice: 79,
    yearlyPrice: 790,
    features: [
      'Everything in Starter',
      'Wedding & Event Module',
      'Profit Intelligence Dashboard',
      'Advanced Inventory Tracking',
      'Customer Insights',
      'Priority Support',
    ],
    limits: {
      orders: 2000,
      staff: 10,
      locations: 1,
      storageMB: 5120,
    },
    recommended: true,
  },
  PRO: {
    id: 'PRO',
    name: 'Pro',
    description: 'For established florists with multiple locations',
    monthlyPrice: 199,
    yearlyPrice: 1990,
    features: [
      'Everything in Growth',
      'Multi-Location Support',
      'External Integrations',
      'Staff Analytics & Performance',
      'Advanced Reporting',
      'Custom Branding',
      'Phone Support',
    ],
    limits: {
      orders: 10000,
      staff: 50,
      locations: 5,
      storageMB: 20480,
    },
  },
  ENTERPRISE: {
    id: 'ENTERPRISE',
    name: 'Enterprise',
    description: 'For large-scale florist operations',
    monthlyPrice: 499,
    yearlyPrice: 4990,
    features: [
      'Everything in Pro',
      'Unlimited Locations',
      'API Access',
      'Custom Integrations',
      'Dedicated Account Manager',
      'SLA Guarantee',
      '24/7 Priority Support',
      'Custom Training Sessions',
    ],
    limits: {
      orders: -1, // unlimited
      staff: -1,
      locations: -1,
      storageMB: 102400,
    },
  },
};

// -----------------------------------------------------------------------------
// Mock Tenant Data
// -----------------------------------------------------------------------------

export const MOCK_TENANT: Tenant = {
  id: 'tenant_001',
  name: 'Blooming Florals',
  slug: 'blooming-florals',
  plan: 'GROWTH',
  subscriptionStatus: 'TRIAL',
  trialEndsAt: '2026-03-04T23:59:59Z', // 14 days from now
  isActive: true,
  createdAt: '2026-02-18T10:00:00Z',
  country: 'IN',
  currency: 'INR',
  taxSystem: 'GST',
  dateFormat: 'DD/MM/YYYY',
  timeFormat: '12H',
  locale: 'en-IN',
  usageStats: {
    ordersThisMonth: 127,
    ordersLimit: 2000,
    staffCount: 5,
    staffLimit: 10,
    locationsCount: 1,
    locationsLimit: 1,
    storageUsedMB: 512,
    storageLimitMB: 5120,
  },
};

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------

export function getPlanConfig(plan: TenantPlan): PlanConfig {
  return PLAN_CONFIGS[plan];
}

export function isPlanHigherThan(currentPlan: TenantPlan, comparePlan: TenantPlan): boolean {
  const planOrder: TenantPlan[] = ['STARTER', 'GROWTH', 'PRO', 'ENTERPRISE'];
  return planOrder.indexOf(currentPlan) > planOrder.indexOf(comparePlan);
}

export function isPlanAtLeast(currentPlan: TenantPlan, requiredPlan: TenantPlan): boolean {
  const planOrder: TenantPlan[] = ['STARTER', 'GROWTH', 'PRO', 'ENTERPRISE'];
  return planOrder.indexOf(currentPlan) >= planOrder.indexOf(requiredPlan);
}

export function getTrialDaysRemaining(trialEndsAt: string | undefined): number {
  if (!trialEndsAt) return 0;
  const now = new Date();
  const trialEnd = new Date(trialEndsAt);
  const diffTime = trialEnd.getTime() - now.getTime();
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return Math.max(0, diffDays);
}

export function isSubscriptionActive(status: SubscriptionStatus): boolean {
  return status === 'ACTIVE' || status === 'TRIAL';
}

export function getUsagePercentage(used: number, limit: number): number {
  if (limit === -1) return 0; // unlimited
  return Math.min(100, Math.round((used / limit) * 100));
}

export function formatPlanPrice(plan: TenantPlan, yearly: boolean = false, currencySymbol: string = '$'): string {
  const config = PLAN_CONFIGS[plan];
  const price = yearly ? config.yearlyPrice : config.monthlyPrice;
  return `${currencySymbol}${price}`;
}

// -----------------------------------------------------------------------------
// Tenant Factory (backward-compatible)
// -----------------------------------------------------------------------------

/** Resolve a partial tenant config into full tenant with country defaults */
export function resolveTenantDefaults(partial: Partial<Tenant> & Pick<Tenant, 'id' | 'name' | 'slug' | 'plan' | 'subscriptionStatus' | 'isActive' | 'createdAt'>): Tenant {
  const country: TenantCountry = partial.country ?? 'US';
  const defaults = COUNTRY_DEFAULTS[country];
  return {
    ...partial,
    country,
    currency: partial.currency ?? defaults.currency,
    taxSystem: partial.taxSystem ?? defaults.taxSystem,
    dateFormat: partial.dateFormat ?? defaults.dateFormat,
    timeFormat: partial.timeFormat ?? defaults.timeFormat,
    locale: partial.locale ?? defaults.locale,
  } as Tenant;
}
