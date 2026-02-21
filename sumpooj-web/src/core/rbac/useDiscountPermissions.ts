/**
 * useDiscountPermissions.ts — Hook for discount permission checking and approval
 *
 * Combines static permission validation with interactive approval flow.
 * Automatically triggers approval modal when discount exceeds user's limit.
 */
import { useCallback, useMemo } from 'react';
import { useAuth } from '../../auth/AuthContext';
import {
  validateOrderDiscount,
  validateLineDiscount,
  validateFlatOrderDiscount,
  validateFlatLineDiscount,
  canApproveDiscounts,
  logDiscountApplication,
  DISCOUNT_PERMISSIONS,
  type DiscountValidationResult,
} from './DiscountPermissions';
import { useDiscountApproval, type DiscountApprovalRequest } from './DiscountApprovalModal';
import type { UserRole } from './RBACTypes';

// ─── Types ──────────────────────────────────────────────────

export interface ApplyDiscountOptions {
  /** Order or line item discount */
  discountType: 'ORDER' | 'LINE';
  /** Percentage or flat amount */
  discountMethod: 'PERCENT' | 'FLAT';
  /** The discount value (percentage or currency amount) */
  discountValue: number;
  /** The subtotal (for order) or gross line amount (for line item) */
  subtotalOrLineGross: number;
  /** Optional: Product name for line discounts */
  productName?: string;
  /** Optional: Line item ID for audit */
  lineItemId?: string;
  /** Optional: Order ID for audit */
  orderId?: string;
}

export interface ApplyDiscountResult {
  /** Whether discount was successfully applied (approved or within limits) */
  success: boolean;
  /** The validation result with limit info */
  validation: DiscountValidationResult;
  /** The calculated discount amount in currency */
  discountAmount: number;
  /** The effective percentage (for logging) */
  effectivePercent: number;
  /** Approval info if approval was required */
  approvedBy?: string;
  approverName?: string;
  approverRole?: UserRole;
  /** Error message if failed */
  error?: string;
}

export interface DiscountPermissionsInfo {
  /** Current user's role */
  role: UserRole;
  /** Max order discount percentage allowed (null = unlimited) */
  maxOrderPercent: number | null;
  /** Max line item discount percentage allowed (null = unlimited) */
  maxLinePercent: number | null;
  /** Whether discounts require manager approval */
  requiresApproval: boolean;
  /** Whether user can approve others' discounts */
  canApproveDiscounts: boolean;
}

// ─── Hook ───────────────────────────────────────────────────

export function useDiscountPermissions() {
  const { user } = useAuth();
  const { requestApproval } = useDiscountApproval();

  const userRole = (user?.role as UserRole) || 'CASHIER';
  const permissions = DISCOUNT_PERMISSIONS[userRole];

  // Memoized permissions info
  const permissionsInfo = useMemo<DiscountPermissionsInfo>(
    () => ({
      role: userRole,
      maxOrderPercent: permissions.maxOrderPercent,
      maxLinePercent: permissions.maxLinePercent,
      requiresApproval: permissions.requiresApproval,
      canApproveDiscounts: permissions.canApproveDiscounts,
    }),
    [userRole, permissions]
  );

  /**
   * Check if a discount is within the user's limits (without applying)
   */
  const checkDiscount = useCallback(
    (options: ApplyDiscountOptions): DiscountValidationResult => {
      const { discountType, discountMethod, discountValue, subtotalOrLineGross } = options;

      if (discountType === 'ORDER') {
        return discountMethod === 'PERCENT'
          ? validateOrderDiscount(userRole, discountValue, subtotalOrLineGross)
          : validateFlatOrderDiscount(userRole, discountValue, subtotalOrLineGross);
      } else {
        return discountMethod === 'PERCENT'
          ? validateLineDiscount(userRole, discountValue, subtotalOrLineGross)
          : validateFlatLineDiscount(userRole, discountValue, subtotalOrLineGross);
      }
    },
    [userRole]
  );

  /**
   * Calculate the discount amount and effective percentage
   */
  const calculateDiscountAmount = useCallback(
    (
      discountMethod: 'PERCENT' | 'FLAT',
      discountValue: number,
      subtotalOrLineGross: number
    ): { amount: number; effectivePercent: number } => {
      if (discountMethod === 'PERCENT') {
        const amount = subtotalOrLineGross * (discountValue / 100);
        return { amount, effectivePercent: discountValue };
      } else {
        const amount = Math.min(discountValue, subtotalOrLineGross);
        const effectivePercent = subtotalOrLineGross > 0 ? (amount / subtotalOrLineGross) * 100 : 0;
        return { amount, effectivePercent };
      }
    },
    []
  );

  /**
   * Apply a discount with automatic approval flow if needed
   * Returns a promise that resolves when discount is applied or rejected
   */
  const applyDiscount = useCallback(
    async (options: ApplyDiscountOptions): Promise<ApplyDiscountResult> => {
      const { discountType, discountMethod, discountValue, subtotalOrLineGross, productName, lineItemId, orderId } =
        options;

      // Validate discount
      const validation = checkDiscount(options);
      const { amount: discountAmount, effectivePercent } = calculateDiscountAmount(
        discountMethod,
        discountValue,
        subtotalOrLineGross
      );

      // If within limits, apply directly
      if (validation.allowed) {
        // Log the discount
        logDiscountApplication({
          userId: user?.id || 'unknown',
          userName: user?.name || 'Unknown User',
          userRole,
          discountType,
          discountMethod,
          discountValue,
          effectivePercent,
          orderId,
          lineItemId,
          productName,
          subtotalBefore: subtotalOrLineGross,
          discountAmount,
          approvalRequired: false,
        });

        return {
          success: true,
          validation,
          discountAmount,
          effectivePercent,
        };
      }

      // If requires approval, show modal
      if (validation.requiresApproval) {
        const approvalRequest: DiscountApprovalRequest = {
          discountType,
          discountMethod,
          discountValue,
          effectivePercent,
          subtotalOrLineGross,
          discountAmount,
          validation,
          productName,
          lineItemId,
          orderId,
          requestingUserId: user?.id || 'unknown',
          requestingUserName: user?.name || 'Unknown User',
          requestingUserRole: userRole,
        };

        const result = await requestApproval(approvalRequest);

        if (result.approved) {
          return {
            success: true,
            validation,
            discountAmount,
            effectivePercent,
            approvedBy: result.approvedBy,
            approverName: result.approverName,
            approverRole: result.approverRole,
          };
        } else {
          return {
            success: false,
            validation,
            discountAmount,
            effectivePercent,
            error: 'Discount approval was denied',
          };
        }
      }

      // Not allowed and no approval path
      return {
        success: false,
        validation,
        discountAmount,
        effectivePercent,
        error: 'Discount exceeds your permission level',
      };
    },
    [checkDiscount, calculateDiscountAmount, requestApproval, user, userRole]
  );

  /**
   * Quick check if user can approve discounts
   */
  const userCanApprove = useMemo(() => canApproveDiscounts(userRole), [userRole]);

  return {
    /** Current user's permission info */
    permissions: permissionsInfo,
    /** Check if a discount is within limits (without applying) */
    checkDiscount,
    /** Apply discount with automatic approval flow */
    applyDiscount,
    /** Calculate discount amount and effective percentage */
    calculateDiscountAmount,
    /** Whether current user can approve others' discounts */
    canApprove: userCanApprove,
  };
}

export type { DiscountValidationResult };
