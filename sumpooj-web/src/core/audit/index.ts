// =============================================================================
// AUDIT MODULE - Barrel Exports
// =============================================================================

// Types
export type {
  AuditEntityType,
  AuditAction,
  AuditLog,
  SensitiveActionType,
  SensitiveActionConfig,
  LockReason,
  LockStatus,
  DayCloseStatus,
  DayCloseSummary,
} from './AuditTypes';
export {
  SENSITIVE_ACTION_CONFIGS,
  LOCK_MESSAGES,
  MOCK_AUDIT_LOGS,
  MOCK_DAY_SUMMARY,
  getActionColor,
  getActionIcon,
  getEntityIcon,
  formatAuditTimestamp,
  checkOrderLock,
  checkProposalLock,
  checkEventDeleteLock,
} from './AuditTypes';

// Activity Feed Components
export { ActivityFeed, ActivityCard, ActivitySummary } from './ActivityFeed';

// Sensitive Action Modal
export {
  SensitiveActionProvider,
  useSensitiveAction,
  SensitiveActionButton,
  createSensitiveActionHandler,
} from './SensitiveActionModal';

// Financial Lock Components
export {
  LockStatusBanner,
  LockStatusChip,
  LockedFieldWrapper,
  EditLockGuard,
  DeleteLockGuard,
  FinancialRulesSummary,
  ORDER_FINANCIAL_RULES,
  PROPOSAL_FINANCIAL_RULES,
  EVENT_FINANCIAL_RULES,
} from './FinancialLock';
