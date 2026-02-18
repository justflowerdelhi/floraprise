// =============================================================================
// CRM MODULE - Barrel Exports
// Florist ERP SaaS — Customer Retention & Intelligence
// =============================================================================

// Types (use export type for type-only re-exports)
export type {
  LoyaltyTier,
  LoyaltyTierConfig,
  CustomerTagType,
  CustomerTag,
  Customer,
  CustomerOrderSummary,
  CustomerEventSummary,
  CustomerActivityType,
  CustomerActivity,
  LoyaltyTransactionType,
  LoyaltyTransaction,
  ReminderType,
  ReminderPriority,
  SmartReminder,
  ReminderConfig,
  LoyaltyConfig,
  CustomerSearchFilters,
} from './CRMTypes';

// Value exports from CRMTypes
export {
  LOYALTY_TIERS,
  LOYALTY_TIER_CONFIGS,
  CUSTOMER_TAGS,
  REMINDER_CONFIGS,
  DEFAULT_LOYALTY_CONFIG,
  MOCK_CUSTOMERS,
  MOCK_CUSTOMER_ORDERS,
  MOCK_CUSTOMER_EVENTS,
  MOCK_REMINDERS,
  MOCK_LOYALTY_TRANSACTIONS,
  formatCurrency,
  daysSince,
  daysUntil,
  isWithinDays,
  getTierFromPoints,
  getPointsToNextTier,
  calculatePointsEarned,
} from './CRMTypes';

// Pages
export { default as Customer360View } from './Customer360View';
export { MetricCard, LoyaltyStatusCard } from './Customer360View';

export { default as SmartReminderDashboard } from './SmartReminderDashboard';
export { ReminderWidget } from './SmartReminderDashboard';

export { default as CustomerListPage } from './CustomerListPage';

export { default as LoyaltyProgramPage } from './LoyaltyProgramPage';

// Loyalty Components
export {
  LoyaltyTierBadge,
  PointsDisplay,
  TierProgressCard,
  PointsEarningPreview,
  PointsRedemptionDialog,
  LoyaltyTransactionItem,
  TierComparisonCard,
  PointsSummaryWidget,
} from './LoyaltyComponents';
