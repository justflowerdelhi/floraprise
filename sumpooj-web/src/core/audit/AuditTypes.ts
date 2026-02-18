// =============================================================================
// AUDIT LOG TYPES - Enterprise Audit & Control Layer
// =============================================================================

// -----------------------------------------------------------------------------
// Core Audit Types
// -----------------------------------------------------------------------------

export type AuditEntityType =
  | 'ORDER'
  | 'EVENT'
  | 'PRODUCT'
  | 'PAYMENT'
  | 'INVENTORY'
  | 'PROPOSAL'
  | 'CUSTOMER'
  | 'STAFF'
  | 'SETTINGS';

export type AuditAction =
  | 'CREATE'
  | 'UPDATE'
  | 'DELETE'
  | 'STATUS_CHANGE'
  | 'APPROVE'
  | 'REJECT'
  | 'REFUND'
  | 'VOID'
  | 'LOCK'
  | 'UNLOCK';

export interface AuditLog {
  id: string;
  tenantId: string;
  locationId?: string;
  entityType: AuditEntityType;
  entityId: string;
  action: AuditAction;
  changedBy: string;
  changedByName: string;
  changeSummary: string;
  previousValue?: Record<string, unknown>;
  newValue?: Record<string, unknown>;
  metadata?: Record<string, unknown>;
  createdAt: string;
}

// -----------------------------------------------------------------------------
// Sensitive Actions Configuration
// -----------------------------------------------------------------------------

export type SensitiveActionType =
  | 'REFUND'
  | 'INVENTORY_ADJUSTMENT'
  | 'PROPOSAL_OVERRIDE'
  | 'EVENT_DELETION'
  | 'PLAN_DOWNGRADE'
  | 'ORDER_VOID'
  | 'PAYMENT_VOID'
  | 'DAY_CLOSE'
  | 'UNLOCK_CLOSED_DAY'
  | 'DELETE_CUSTOMER';

export interface SensitiveActionConfig {
  type: SensitiveActionType;
  title: string;
  description: string;
  confirmText: string;
  cancelText: string;
  requireReason: boolean;
  requirePassword?: boolean;
  warningLevel: 'info' | 'warning' | 'danger';
  icon: string;
}

export const SENSITIVE_ACTION_CONFIGS: Record<SensitiveActionType, SensitiveActionConfig> = {
  REFUND: {
    type: 'REFUND',
    title: 'Process Refund',
    description: 'This will refund the payment to the customer. This action cannot be undone.',
    confirmText: 'Process Refund',
    cancelText: 'Cancel',
    requireReason: true,
    warningLevel: 'warning',
    icon: 'MoneyOff',
  },
  INVENTORY_ADJUSTMENT: {
    type: 'INVENTORY_ADJUSTMENT',
    title: 'Inventory Adjustment',
    description: 'This will permanently adjust inventory levels. Ensure you have the correct reason documented.',
    confirmText: 'Confirm Adjustment',
    cancelText: 'Cancel',
    requireReason: true,
    warningLevel: 'warning',
    icon: 'Inventory',
  },
  PROPOSAL_OVERRIDE: {
    type: 'PROPOSAL_OVERRIDE',
    title: 'Override Approved Proposal',
    description: 'This proposal has already been approved. Changes will create a new version requiring re-approval.',
    confirmText: 'Create New Version',
    cancelText: 'Cancel',
    requireReason: true,
    warningLevel: 'warning',
    icon: 'Edit',
  },
  EVENT_DELETION: {
    type: 'EVENT_DELETION',
    title: 'Delete Event',
    description: 'This will permanently delete the event and all associated data. This action cannot be undone.',
    confirmText: 'Delete Event',
    cancelText: 'Keep Event',
    requireReason: true,
    warningLevel: 'danger',
    icon: 'DeleteForever',
  },
  PLAN_DOWNGRADE: {
    type: 'PLAN_DOWNGRADE',
    title: 'Downgrade Plan',
    description: 'Downgrading will remove access to features not included in the new plan. Data will be preserved but may become inaccessible.',
    confirmText: 'Confirm Downgrade',
    cancelText: 'Keep Current Plan',
    requireReason: false,
    warningLevel: 'warning',
    icon: 'ArrowDownward',
  },
  ORDER_VOID: {
    type: 'ORDER_VOID',
    title: 'Void Order',
    description: 'This will void the entire order. Any payments must be refunded separately.',
    confirmText: 'Void Order',
    cancelText: 'Cancel',
    requireReason: true,
    warningLevel: 'danger',
    icon: 'Block',
  },
  PAYMENT_VOID: {
    type: 'PAYMENT_VOID',
    title: 'Void Payment',
    description: 'This will void the payment record. This is different from a refund.',
    confirmText: 'Void Payment',
    cancelText: 'Cancel',
    requireReason: true,
    warningLevel: 'danger',
    icon: 'CreditCardOff',
  },
  DAY_CLOSE: {
    type: 'DAY_CLOSE',
    title: 'Close Business Day',
    description: 'Closing the day will lock all transactions. No further changes can be made to this day\'s records.',
    confirmText: 'Close Day',
    cancelText: 'Keep Day Open',
    requireReason: false,
    warningLevel: 'warning',
    icon: 'Lock',
  },
  UNLOCK_CLOSED_DAY: {
    type: 'UNLOCK_CLOSED_DAY',
    title: 'Unlock Closed Day',
    description: 'This will unlock a previously closed day. This action requires manager approval and will be logged.',
    confirmText: 'Unlock Day',
    cancelText: 'Cancel',
    requireReason: true,
    requirePassword: true,
    warningLevel: 'danger',
    icon: 'LockOpen',
  },
  DELETE_CUSTOMER: {
    type: 'DELETE_CUSTOMER',
    title: 'Delete Customer',
    description: 'This will permanently delete the customer and their history. This action cannot be undone.',
    confirmText: 'Delete Customer',
    cancelText: 'Cancel',
    requireReason: true,
    warningLevel: 'danger',
    icon: 'PersonRemove',
  },
};

// -----------------------------------------------------------------------------
// Financial Lock Types
// -----------------------------------------------------------------------------

export type LockReason =
  | 'FULLY_PAID'
  | 'PROPOSAL_APPROVED'
  | 'EVENT_HAS_PAYMENTS'
  | 'DAY_CLOSED'
  | 'INVOICE_SENT'
  | 'ORDER_COMPLETED';

export interface LockStatus {
  isLocked: boolean;
  reason?: LockReason;
  message?: string;
  canOverride: boolean;
  overridePermission?: string;
}

export const LOCK_MESSAGES: Record<LockReason, string> = {
  FULLY_PAID: 'This order is fully paid and cannot be edited.',
  PROPOSAL_APPROVED: 'This proposal has been approved. Create a new version to make changes.',
  EVENT_HAS_PAYMENTS: 'This event has payment history and cannot be deleted.',
  DAY_CLOSED: 'This day has been closed. Records cannot be modified.',
  INVOICE_SENT: 'An invoice has been sent. Changes may affect customer records.',
  ORDER_COMPLETED: 'This order has been completed and is now read-only.',
};

// -----------------------------------------------------------------------------
// Day Close Types
// -----------------------------------------------------------------------------

export type DayCloseStatus = 'OPEN' | 'PENDING_REVIEW' | 'CLOSED' | 'REOPENED';

export interface DayCloseSummary {
  date: string;
  locationId: string;
  status: DayCloseStatus;
  // Sales Summary
  totalSales: number;
  totalOrders: number;
  walkInSales: number;
  walkInOrders: number;
  phoneOrders: number;
  phoneOrdersAmount: number;
  onlineOrders: number;
  onlineOrdersAmount: number;
  // Payment Breakdown
  cashSales: number;
  cardSales: number;
  upiSales: number;
  otherPayments: number;
  // Cash Reconciliation
  expectedCash: number;
  countedCash?: number;
  cashVariance?: number;
  // Refunds
  totalRefunds: number;
  refundCount: number;
  // Close Details
  closedBy?: string;
  closedAt?: string;
  notes?: string;
}

// -----------------------------------------------------------------------------
// Mock Audit Data
// -----------------------------------------------------------------------------

export const MOCK_AUDIT_LOGS: AuditLog[] = [
  {
    id: 'audit_001',
    tenantId: 'tenant_001',
    locationId: 'loc_001',
    entityType: 'ORDER',
    entityId: 'ORD-2026-0001',
    action: 'CREATE',
    changedBy: 'user_001',
    changedByName: 'Priya Sharma',
    changeSummary: 'Created new walk-in order for ₹2,450',
    createdAt: '2026-02-18T09:15:00Z',
  },
  {
    id: 'audit_002',
    tenantId: 'tenant_001',
    locationId: 'loc_001',
    entityType: 'ORDER',
    entityId: 'ORD-2026-0001',
    action: 'STATUS_CHANGE',
    changedBy: 'user_002',
    changedByName: 'Raj Kumar',
    changeSummary: 'Changed status from "Pending" to "Ready for Pickup"',
    previousValue: { status: 'PENDING' },
    newValue: { status: 'READY' },
    createdAt: '2026-02-18T10:30:00Z',
  },
  {
    id: 'audit_003',
    tenantId: 'tenant_001',
    locationId: 'loc_001',
    entityType: 'PAYMENT',
    entityId: 'PAY-2026-0001',
    action: 'CREATE',
    changedBy: 'user_001',
    changedByName: 'Priya Sharma',
    changeSummary: 'Processed card payment of ₹2,450',
    createdAt: '2026-02-18T09:16:00Z',
  },
  {
    id: 'audit_004',
    tenantId: 'tenant_001',
    locationId: 'loc_001',
    entityType: 'INVENTORY',
    entityId: 'INV-BATCH-001',
    action: 'UPDATE',
    changedBy: 'user_003',
    changedByName: 'Admin User',
    changeSummary: 'Adjusted Red Roses quantity: 50 → 45 (Reason: Damaged stock)',
    previousValue: { quantity: 50 },
    newValue: { quantity: 45 },
    metadata: { reason: 'Damaged stock', adjustmentType: 'DAMAGE' },
    createdAt: '2026-02-18T08:00:00Z',
  },
  {
    id: 'audit_005',
    tenantId: 'tenant_001',
    entityType: 'PROPOSAL',
    entityId: 'PROP-2026-0001',
    action: 'APPROVE',
    changedBy: 'user_003',
    changedByName: 'Admin User',
    changeSummary: 'Approved wedding proposal for Sharma-Patel Wedding (₹85,000)',
    createdAt: '2026-02-17T14:00:00Z',
  },
  {
    id: 'audit_006',
    tenantId: 'tenant_001',
    entityType: 'EVENT',
    entityId: 'EVT-2026-0001',
    action: 'UPDATE',
    changedBy: 'user_002',
    changedByName: 'Raj Kumar',
    changeSummary: 'Updated venue address for Sharma-Patel Wedding',
    createdAt: '2026-02-16T11:30:00Z',
  },
];

export const MOCK_DAY_SUMMARY: DayCloseSummary = {
  date: '2026-02-18',
  locationId: 'loc_001',
  status: 'OPEN',
  totalSales: 45750,
  totalOrders: 23,
  walkInSales: 28500,
  walkInOrders: 15,
  phoneOrders: 5,
  phoneOrdersAmount: 12250,
  onlineOrders: 3,
  onlineOrdersAmount: 5000,
  cashSales: 15500,
  cardSales: 22750,
  upiSales: 7500,
  otherPayments: 0,
  expectedCash: 15500,
  totalRefunds: 1200,
  refundCount: 1,
};

// -----------------------------------------------------------------------------
// Helper Functions
// -----------------------------------------------------------------------------

export function getActionColor(action: AuditAction): string {
  const colors: Record<AuditAction, string> = {
    CREATE: '#4caf50',
    UPDATE: '#2196f3',
    DELETE: '#f44336',
    STATUS_CHANGE: '#ff9800',
    APPROVE: '#4caf50',
    REJECT: '#f44336',
    REFUND: '#ff9800',
    VOID: '#f44336',
    LOCK: '#9c27b0',
    UNLOCK: '#00bcd4',
  };
  return colors[action] || '#9e9e9e';
}

export function getActionIcon(action: AuditAction): string {
  const icons: Record<AuditAction, string> = {
    CREATE: 'Add',
    UPDATE: 'Edit',
    DELETE: 'Delete',
    STATUS_CHANGE: 'SwapHoriz',
    APPROVE: 'CheckCircle',
    REJECT: 'Cancel',
    REFUND: 'Undo',
    VOID: 'Block',
    LOCK: 'Lock',
    UNLOCK: 'LockOpen',
  };
  return icons[action] || 'Info';
}

export function getEntityIcon(entityType: AuditEntityType): string {
  const icons: Record<AuditEntityType, string> = {
    ORDER: 'Receipt',
    EVENT: 'Event',
    PRODUCT: 'LocalFlorist',
    PAYMENT: 'Payment',
    INVENTORY: 'Inventory2',
    PROPOSAL: 'Description',
    CUSTOMER: 'Person',
    STAFF: 'Badge',
    SETTINGS: 'Settings',
  };
  return icons[entityType] || 'Info';
}

export function formatAuditTimestamp(timestamp: string): string {
  const date = new Date(timestamp);
  const now = new Date();
  const diffMs = now.getTime() - date.getTime();
  const diffMins = Math.floor(diffMs / 60000);
  const diffHours = Math.floor(diffMs / 3600000);
  const diffDays = Math.floor(diffMs / 86400000);
  
  if (diffMins < 1) return 'Just now';
  if (diffMins < 60) return `${diffMins}m ago`;
  if (diffHours < 24) return `${diffHours}h ago`;
  if (diffDays < 7) return `${diffDays}d ago`;
  
  return date.toLocaleDateString('en-IN', {
    day: 'numeric',
    month: 'short',
    year: date.getFullYear() !== now.getFullYear() ? 'numeric' : undefined,
  });
}

export function checkOrderLock(order: {
  paymentStatus?: string;
  status?: string;
}): LockStatus {
  if (order.paymentStatus === 'PAID') {
    return {
      isLocked: true,
      reason: 'FULLY_PAID',
      message: LOCK_MESSAGES.FULLY_PAID,
      canOverride: false,
    };
  }
  
  if (order.status === 'COMPLETED' || order.status === 'DELIVERED') {
    return {
      isLocked: true,
      reason: 'ORDER_COMPLETED',
      message: LOCK_MESSAGES.ORDER_COMPLETED,
      canOverride: true,
      overridePermission: 'orders:override_lock',
    };
  }
  
  return { isLocked: false, canOverride: false };
}

export function checkProposalLock(proposal: {
  status?: string;
}): LockStatus {
  if (proposal.status === 'APPROVED' || proposal.status === 'ACCEPTED') {
    return {
      isLocked: true,
      reason: 'PROPOSAL_APPROVED',
      message: LOCK_MESSAGES.PROPOSAL_APPROVED,
      canOverride: true,
      overridePermission: 'proposals:override',
    };
  }
  
  return { isLocked: false, canOverride: false };
}

export function checkEventDeleteLock(event: {
  paymentHistory?: unknown[];
  totalPaid?: number;
}): LockStatus {
  if ((event.paymentHistory && event.paymentHistory.length > 0) || (event.totalPaid && event.totalPaid > 0)) {
    return {
      isLocked: true,
      reason: 'EVENT_HAS_PAYMENTS',
      message: LOCK_MESSAGES.EVENT_HAS_PAYMENTS,
      canOverride: false,
    };
  }
  
  return { isLocked: false, canOverride: false };
}
