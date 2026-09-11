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
  TenantSettings,
} from './TenantTypes';
export {
  PLAN_CONFIGS,
  MOCK_TENANT,
  COUNTRY_DEFAULTS,
  CURRENCY_SYMBOL_MAP,
  countryCurrencyMap,
  getPlanConfig,
  isPlanHigherThan,
  isPlanAtLeast,
  getTrialDaysRemaining,
  isSubscriptionActive,
  getUsagePercentage,
  formatPlanPrice,
  resolveTenantDefaults,
  deriveTenantSettings,
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

// Operational View (Retail View vs ERP Professional)
export type { OperationalView } from './TenantTypes';
export {
  OPERATIONAL_VIEWS,
  OPERATIONAL_VIEW_LABELS,
  OPERATIONAL_VIEW_STORAGE_KEY,
  isProfessionalViewEligible,
  resolveOperationalView,
} from './TenantTypes';
export type { OperationalViewContextValue } from './OperationalViewContext';
export {
  OperationalViewProvider,
  useOperationalView,
  getStoredOperationalView,
  setStoredOperationalView,
} from './OperationalViewContext';
export { OperationalViewSwitcher } from './OperationalViewSwitcher';

