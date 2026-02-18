// =============================================================================
// FEATURE FLAGS - SaaS Plan-Based Feature Gating
// =============================================================================

import type { TenantPlan } from './TenantTypes';

// -----------------------------------------------------------------------------
// Feature Flag Definitions
// -----------------------------------------------------------------------------

export type FeatureFlag =
  | 'POS'
  | 'BASIC_INVENTORY'
  | 'ORDER_MANAGEMENT'
  | 'CUSTOMER_DATABASE'
  | 'BASIC_REPORTS'
  | 'WEDDING_MODULE'
  | 'PROFIT_INTELLIGENCE'
  | 'ADVANCED_INVENTORY'
  | 'MULTI_LOCATION'
  | 'EXTERNAL_INTEGRATION'
  | 'STAFF_ANALYTICS'
  | 'CUSTOM_BRANDING'
  | 'API_ACCESS'
  | 'ADVANCED_REPORTS';

// -----------------------------------------------------------------------------
// Feature Metadata
// -----------------------------------------------------------------------------

export interface FeatureMetadata {
  id: FeatureFlag;
  name: string;
  description: string;
  icon?: string;
  requiredPlan: TenantPlan;
  category: 'core' | 'growth' | 'pro' | 'enterprise';
}

export const FEATURE_METADATA: Record<FeatureFlag, FeatureMetadata> = {
  POS: {
    id: 'POS',
    name: 'Point of Sale',
    description: 'Process sales, manage payments, and handle walk-in customers',
    requiredPlan: 'STARTER',
    category: 'core',
  },
  BASIC_INVENTORY: {
    id: 'BASIC_INVENTORY',
    name: 'Basic Inventory',
    description: 'Track stock levels, manage products, and monitor inventory',
    requiredPlan: 'STARTER',
    category: 'core',
  },
  ORDER_MANAGEMENT: {
    id: 'ORDER_MANAGEMENT',
    name: 'Order Management',
    description: 'Create, track, and manage customer orders',
    requiredPlan: 'STARTER',
    category: 'core',
  },
  CUSTOMER_DATABASE: {
    id: 'CUSTOMER_DATABASE',
    name: 'Customer Database',
    description: 'Store and manage customer information and history',
    requiredPlan: 'STARTER',
    category: 'core',
  },
  BASIC_REPORTS: {
    id: 'BASIC_REPORTS',
    name: 'Basic Reports',
    description: 'View sales summaries and basic business metrics',
    requiredPlan: 'STARTER',
    category: 'core',
  },
  WEDDING_MODULE: {
    id: 'WEDDING_MODULE',
    name: 'Wedding & Events',
    description: 'Manage wedding consultations, proposals, and event timelines',
    requiredPlan: 'GROWTH',
    category: 'growth',
  },
  PROFIT_INTELLIGENCE: {
    id: 'PROFIT_INTELLIGENCE',
    name: 'Profit Intelligence',
    description: 'Advanced profit analytics, margin tracking, and insights',
    requiredPlan: 'GROWTH',
    category: 'growth',
  },
  ADVANCED_INVENTORY: {
    id: 'ADVANCED_INVENTORY',
    name: 'Advanced Inventory',
    description: 'Batch tracking, expiry alerts, and inventory valuation',
    requiredPlan: 'GROWTH',
    category: 'growth',
  },
  MULTI_LOCATION: {
    id: 'MULTI_LOCATION',
    name: 'Multi-Location',
    description: 'Manage multiple store locations from a single dashboard',
    requiredPlan: 'PRO',
    category: 'pro',
  },
  EXTERNAL_INTEGRATION: {
    id: 'EXTERNAL_INTEGRATION',
    name: 'External Integrations',
    description: 'Connect with third-party services and platforms',
    requiredPlan: 'PRO',
    category: 'pro',
  },
  STAFF_ANALYTICS: {
    id: 'STAFF_ANALYTICS',
    name: 'Staff Analytics',
    description: 'Track staff performance, productivity, and metrics',
    requiredPlan: 'PRO',
    category: 'pro',
  },
  CUSTOM_BRANDING: {
    id: 'CUSTOM_BRANDING',
    name: 'Custom Branding',
    description: 'Customize invoices, receipts, and customer-facing materials',
    requiredPlan: 'PRO',
    category: 'pro',
  },
  ADVANCED_REPORTS: {
    id: 'ADVANCED_REPORTS',
    name: 'Advanced Reports',
    description: 'Detailed analytics, custom reports, and data exports',
    requiredPlan: 'PRO',
    category: 'pro',
  },
  API_ACCESS: {
    id: 'API_ACCESS',
    name: 'API Access',
    description: 'Full API access for custom integrations and automation',
    requiredPlan: 'ENTERPRISE',
    category: 'enterprise',
  },
};

// -----------------------------------------------------------------------------
// Plan Feature Matrix
// -----------------------------------------------------------------------------

export const PLAN_FEATURES: Record<TenantPlan, FeatureFlag[]> = {
  STARTER: [
    'POS',
    'BASIC_INVENTORY',
    'ORDER_MANAGEMENT',
    'CUSTOMER_DATABASE',
    'BASIC_REPORTS',
  ],
  GROWTH: [
    'POS',
    'BASIC_INVENTORY',
    'ORDER_MANAGEMENT',
    'CUSTOMER_DATABASE',
    'BASIC_REPORTS',
    'WEDDING_MODULE',
    'PROFIT_INTELLIGENCE',
    'ADVANCED_INVENTORY',
  ],
  PRO: [
    'POS',
    'BASIC_INVENTORY',
    'ORDER_MANAGEMENT',
    'CUSTOMER_DATABASE',
    'BASIC_REPORTS',
    'WEDDING_MODULE',
    'PROFIT_INTELLIGENCE',
    'ADVANCED_INVENTORY',
    'MULTI_LOCATION',
    'EXTERNAL_INTEGRATION',
    'STAFF_ANALYTICS',
    'CUSTOM_BRANDING',
    'ADVANCED_REPORTS',
  ],
  ENTERPRISE: [
    'POS',
    'BASIC_INVENTORY',
    'ORDER_MANAGEMENT',
    'CUSTOMER_DATABASE',
    'BASIC_REPORTS',
    'WEDDING_MODULE',
    'PROFIT_INTELLIGENCE',
    'ADVANCED_INVENTORY',
    'MULTI_LOCATION',
    'EXTERNAL_INTEGRATION',
    'STAFF_ANALYTICS',
    'CUSTOM_BRANDING',
    'ADVANCED_REPORTS',
    'API_ACCESS',
  ],
};

// -----------------------------------------------------------------------------
// Feature Access Helpers
// -----------------------------------------------------------------------------

export function hasFeature(plan: TenantPlan, feature: FeatureFlag): boolean {
  return PLAN_FEATURES[plan].includes(feature);
}

export function getAvailableFeatures(plan: TenantPlan): FeatureFlag[] {
  return PLAN_FEATURES[plan];
}

export function getUnavailableFeatures(plan: TenantPlan): FeatureFlag[] {
  const allFeatures = Object.keys(FEATURE_METADATA) as FeatureFlag[];
  return allFeatures.filter((f) => !PLAN_FEATURES[plan].includes(f));
}

export function getRequiredPlanForFeature(feature: FeatureFlag): TenantPlan {
  return FEATURE_METADATA[feature].requiredPlan;
}

export function getUpgradePathForFeature(
  currentPlan: TenantPlan,
  feature: FeatureFlag
): TenantPlan | null {
  const requiredPlan = FEATURE_METADATA[feature].requiredPlan;
  const planOrder: TenantPlan[] = ['STARTER', 'GROWTH', 'PRO', 'ENTERPRISE'];
  
  if (planOrder.indexOf(currentPlan) >= planOrder.indexOf(requiredPlan)) {
    return null; // Already has access
  }
  
  return requiredPlan;
}

export function getFeaturesByCategory(category: FeatureMetadata['category']): FeatureMetadata[] {
  return Object.values(FEATURE_METADATA).filter((f) => f.category === category);
}

// -----------------------------------------------------------------------------
// Route-to-Feature Mapping
// -----------------------------------------------------------------------------

export const ROUTE_FEATURE_MAP: Record<string, FeatureFlag> = {
  // Core routes (STARTER)
  '/pos': 'POS',
  '/orders': 'ORDER_MANAGEMENT',
  '/customers': 'CUSTOMER_DATABASE',
  '/inventory': 'BASIC_INVENTORY',
  
  // Growth routes
  '/events': 'WEDDING_MODULE',
  '/proposals': 'WEDDING_MODULE',
  '/profit-dashboard': 'PROFIT_INTELLIGENCE',
  '/expiry-alerts': 'ADVANCED_INVENTORY',
  '/adjustments': 'ADVANCED_INVENTORY',
  '/valuation': 'ADVANCED_INVENTORY',
  
  // Pro routes
  '/staff': 'STAFF_ANALYTICS',
  '/staff/performance': 'STAFF_ANALYTICS',
  '/integrations': 'EXTERNAL_INTEGRATION',
};

export function getRequiredFeatureForRoute(route: string): FeatureFlag | null {
  // Check exact match first
  if (ROUTE_FEATURE_MAP[route]) {
    return ROUTE_FEATURE_MAP[route];
  }
  
  // Check prefix matches
  for (const [routePattern, feature] of Object.entries(ROUTE_FEATURE_MAP)) {
    if (route.startsWith(routePattern)) {
      return feature;
    }
  }
  
  return null;
}
