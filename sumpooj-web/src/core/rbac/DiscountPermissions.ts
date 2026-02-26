/**
 * DiscountPermissions.ts — Role-Based Discount Permission Control
 *
 * Defines discount limits per role and provides validation utilities.
 * Integrates with RBAC system for role-aware discount enforcement.
 */
import type { UserRole } from '../rbac/RBACTypes';

// ─── Discount Permission Types ──────────────────────────────

export interface DiscountPermission {
  /** Maximum allowed percentage for order-level discount. null = unlimited */
  maxOrderPercent: number | null;
  /** Maximum allowed percentage for line-item discount. null = unlimited */
  maxLinePercent: number | null;
  /** Whether discounts exceeding limits require manager approval */
  requiresApproval: boolean;
  /** Can approve other users' discount requests */
  canApproveDiscounts: boolean;
}

export const DISCOUNT_PERMISSIONS: Record<UserRole, DiscountPermission> = {
  PLATFORMSUPERADMIN: {
    maxOrderPercent: null,
    maxLinePercent: null,
    requiresApproval: false,
    canApproveDiscounts: true,
  },
  ADMIN: {
    maxOrderPercent: null,
    maxLinePercent: null,
    requiresApproval: false,
    canApproveDiscounts: true,
  },
  MANAGER: {
    maxOrderPercent: 30,
    maxLinePercent: 20,
    requiresApproval: false,
    canApproveDiscounts: true,
  },
  CASHIER: {
    maxOrderPercent: 10,
    maxLinePercent: 5,
    requiresApproval: true,
    canApproveDiscounts: false,
  },
  DESIGNER: {
    maxOrderPercent: 5,
    maxLinePercent: 5,
    requiresApproval: true,
    canApproveDiscounts: false,
  },
  DRIVER: {
    maxOrderPercent: 0,
    maxLinePercent: 0,
    requiresApproval: true,
    canApproveDiscounts: false,
  },
  STAFF: {
    maxOrderPercent: 10,
    maxLinePercent: 5,
    requiresApproval: true,
    canApproveDiscounts: false,
  },
};

// ─── Validation Types ───────────────────────────────────────

export interface DiscountValidationResult {
  allowed: boolean;
  requiresApproval: boolean;
  maxAllowed: number | null;
  requestedPercent: number;
  exceedsLimit: boolean;
  message?: string;
}

// ─── Validation Functions ───────────────────────────────────

/**
 * Check if a discount percentage is allowed for the given role.
 */
export function validateOrderDiscount(
  role: UserRole,
  discountPercent: number,
  subtotal: number
): DiscountValidationResult {
  const permissions = DISCOUNT_PERMISSIONS[role];
  const maxAllowed = permissions.maxOrderPercent;

  // Unlimited discount
  if (maxAllowed === null) {
    return {
      allowed: true,
      requiresApproval: false,
      maxAllowed: null,
      requestedPercent: discountPercent,
      exceedsLimit: false,
    };
  }

  const exceedsLimit = discountPercent > maxAllowed;

  if (exceedsLimit && !permissions.requiresApproval) {
    return {
      allowed: false,
      requiresApproval: false,
      maxAllowed,
      requestedPercent: discountPercent,
      exceedsLimit: true,
      message: `Maximum order discount is ${maxAllowed}% for your role.`,
    };
  }

  if (exceedsLimit && permissions.requiresApproval) {
    return {
      allowed: false,
      requiresApproval: true,
      maxAllowed,
      requestedPercent: discountPercent,
      exceedsLimit: true,
      message: `Discount of ${discountPercent}% exceeds your limit of ${maxAllowed}%. Manager approval required.`,
    };
  }

  return {
    allowed: true,
    requiresApproval: false,
    maxAllowed,
    requestedPercent: discountPercent,
    exceedsLimit: false,
  };
}

/**
 * Validate a flat discount amount by converting to percentage.
 */
export function validateFlatOrderDiscount(
  role: UserRole,
  discountAmount: number,
  subtotal: number
): DiscountValidationResult {
  if (subtotal <= 0) {
    return {
      allowed: false,
      requiresApproval: false,
      maxAllowed: 0,
      requestedPercent: 0,
      exceedsLimit: true,
      message: 'Cannot apply discount to zero subtotal.',
    };
  }

  const effectivePercent = Math.round((discountAmount / subtotal) * 100 * 10) / 10;
  return validateOrderDiscount(role, effectivePercent, subtotal);
}

/**
 * Check if a line-item discount percentage is allowed.
 */
export function validateLineDiscount(
  role: UserRole,
  discountPercent: number,
  lineGross: number
): DiscountValidationResult {
  const permissions = DISCOUNT_PERMISSIONS[role];
  const maxAllowed = permissions.maxLinePercent;

  // Unlimited discount
  if (maxAllowed === null) {
    return {
      allowed: true,
      requiresApproval: false,
      maxAllowed: null,
      requestedPercent: discountPercent,
      exceedsLimit: false,
    };
  }

  const exceedsLimit = discountPercent > maxAllowed;

  if (exceedsLimit && !permissions.requiresApproval) {
    return {
      allowed: false,
      requiresApproval: false,
      maxAllowed,
      requestedPercent: discountPercent,
      exceedsLimit: true,
      message: `Maximum line discount is ${maxAllowed}% for your role.`,
    };
  }

  if (exceedsLimit && permissions.requiresApproval) {
    return {
      allowed: false,
      requiresApproval: true,
      maxAllowed,
      requestedPercent: discountPercent,
      exceedsLimit: true,
      message: `Discount of ${discountPercent}% exceeds your limit of ${maxAllowed}%. Manager approval required.`,
    };
  }

  return {
    allowed: true,
    requiresApproval: false,
    maxAllowed,
    requestedPercent: discountPercent,
    exceedsLimit: false,
  };
}

/**
 * Validate a flat line discount amount by converting to percentage.
 */
export function validateFlatLineDiscount(
  role: UserRole,
  discountAmount: number,
  lineGross: number
): DiscountValidationResult {
  if (lineGross <= 0) {
    return {
      allowed: false,
      requiresApproval: false,
      maxAllowed: 0,
      requestedPercent: 0,
      exceedsLimit: true,
      message: 'Cannot apply discount to zero line total.',
    };
  }

  const effectivePercent = Math.round((discountAmount / lineGross) * 100 * 10) / 10;
  return validateLineDiscount(role, effectivePercent, lineGross);
}

/**
 * Check if user can approve discount requests.
 */
export function canApproveDiscounts(role: UserRole): boolean {
  return DISCOUNT_PERMISSIONS[role].canApproveDiscounts;
}

/**
 * Get the maximum discount allowed for a role (for display purposes).
 */
export function getDiscountLimits(role: UserRole): { orderMax: number | null; lineMax: number | null } {
  const permissions = DISCOUNT_PERMISSIONS[role];
  return {
    orderMax: permissions.maxOrderPercent,
    lineMax: permissions.maxLinePercent,
  };
}

// ─── Audit Log Types for Discounts ──────────────────────────

export interface DiscountAuditLog {
  id: string;
  timestamp: string;
  userId: string;
  userName: string;
  userRole: UserRole;
  discountType: 'ORDER' | 'LINE';
  discountMethod: 'PERCENT' | 'FLAT';
  discountValue: number;
  effectivePercent: number;
  orderId?: string;
  lineItemId?: string;
  productName?: string;
  subtotalBefore: number;
  discountAmount: number;
  approvalRequired: boolean;
  approvedBy?: string;
  approverName?: string;
  approverRole?: UserRole;
  reason?: string;
}

// In-memory audit log for demo (would be API in production)
export const DISCOUNT_AUDIT_LOGS: DiscountAuditLog[] = [];

export function logDiscountApplication(log: Omit<DiscountAuditLog, 'id' | 'timestamp'>): DiscountAuditLog {
  const entry: DiscountAuditLog = {
    ...log,
    id: `disc_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    timestamp: new Date().toISOString(),
  };
  DISCOUNT_AUDIT_LOGS.unshift(entry);
  console.log('[Discount Audit]', entry);
  return entry;
}
