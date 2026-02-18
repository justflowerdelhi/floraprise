// =============================================================================
// TENANT MODULE - Barrel Exports
// =============================================================================

// Types
export type {
  TenantPlan,
  SubscriptionStatus,
  Tenant,
  TenantUsageStats,
  PlanConfig,
  TenantCountry,
  TaxSystemType,
  TimeFormat,
  CountryDefaults,
} from './TenantTypes';
export {
  PLAN_CONFIGS,
  MOCK_TENANT,
  COUNTRY_DEFAULTS,
  getPlanConfig,
  isPlanHigherThan,
  isPlanAtLeast,
  getTrialDaysRemaining,
  isSubscriptionActive,
  getUsagePercentage,
  formatPlanPrice,
  resolveTenantDefaults,
} from './TenantTypes';

export type { FeatureFlag, FeatureMetadata } from './FeatureFlags';
export {
  FEATURE_METADATA,
  hasFeature,
  getAvailableFeatures,
  getUnavailableFeatures,
  getRequiredPlanForFeature,
  getUpgradePathForFeature,
} from './FeatureFlags';

// Context & Hooks
export { TenantProvider, useTenant, FeatureGate, withFeatureGate } from './TenantContext';

// Components
export {
  UpgradePromptModal,
  FeatureLockedOverlay,
  TrialBanner,
  PastDueBanner,
} from './UpgradePrompt';
