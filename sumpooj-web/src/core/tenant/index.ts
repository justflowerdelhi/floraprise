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
} from './TenantTypes';
export {
  PLAN_CONFIGS,
  MOCK_TENANT,
  getPlanConfig,
  isPlanHigherThan,
  isPlanAtLeast,
  getTrialDaysRemaining,
  isSubscriptionActive,
  getUsagePercentage,
  formatPlanPrice,
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
