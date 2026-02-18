/**
 * ErrorPrevention.ts — UI-Level Business Rule Validations
 *
 * Implements safeguards to prevent common user errors:
 * - Negative inventory
 * - Unpaid order completion
 * - Low margin warnings
 * - Missing required data
 */

// ─── Validation Result Types ────────────────────────────────

export type ValidationSeverity = 'error' | 'warning' | 'info';

export interface ValidationResult {
  isValid: boolean;
  severity: ValidationSeverity;
  code: string;
  message: string;
  field?: string;
  suggestion?: string;
}

export interface ValidationContext {
  results: ValidationResult[];
  hasErrors: boolean;
  hasWarnings: boolean;
  canProceed: boolean;
}

// ─── Business Rule Thresholds ───────────────────────────────

export const BUSINESS_RULES = {
  // Profit & Margin
  MIN_PROFIT_MARGIN_PERCENT: 20,
  LOW_MARGIN_WARNING_PERCENT: 30,

  // Inventory
  MIN_STOCK_QUANTITY: 0,
  LOW_STOCK_WARNING_DAYS: 3,
  EXPIRY_WARNING_DAYS: 7,

  // Orders
  MAX_DISCOUNT_PERCENT: 50,
  MIN_ORDER_VALUE: 100,
  MAX_PHONE_ORDER_VALUE_WITHOUT_PAYMENT: 5000,

  // Payments
  MAX_CASH_TRANSACTION: 100000, // ₹1 Lakh limit
  MIN_PARTIAL_PAYMENT_PERCENT: 10,
};

// ─── Inventory Validations ──────────────────────────────────

export const validateInventoryQuantity = (
  currentQty: number,
  adjustmentQty: number,
  productName: string
): ValidationResult => {
  const finalQty = currentQty + adjustmentQty;

  if (finalQty < 0) {
    return {
      isValid: false,
      severity: 'error',
      code: 'NEGATIVE_INVENTORY',
      message: `Cannot remove ${Math.abs(adjustmentQty)} items. Only ${currentQty} in stock.`,
      field: 'quantity',
      suggestion: `Maximum you can remove is ${currentQty}.`,
    };
  }

  if (finalQty === 0) {
    return {
      isValid: true,
      severity: 'warning',
      code: 'ZERO_INVENTORY',
      message: `This will leave no "${productName}" in stock.`,
      field: 'quantity',
      suggestion: 'Consider ordering more stock soon.',
    };
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

export const validateExpiryDate = (
  expiryDate: string,
  productName: string
): ValidationResult => {
  const expiry = new Date(expiryDate);
  const today = new Date();
  const daysUntilExpiry = Math.ceil((expiry.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));

  if (daysUntilExpiry < 0) {
    return {
      isValid: false,
      severity: 'error',
      code: 'EXPIRED',
      message: `"${productName}" has already expired!`,
      field: 'expiry_date',
      suggestion: 'Remove expired items from stock.',
    };
  }

  if (daysUntilExpiry <= BUSINESS_RULES.EXPIRY_WARNING_DAYS) {
    return {
      isValid: true,
      severity: 'warning',
      code: 'EXPIRING_SOON',
      message: `"${productName}" expires in ${daysUntilExpiry} day(s).`,
      field: 'expiry_date',
      suggestion: 'Use or sell soon to avoid waste.',
    };
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

// ─── Order Validations ──────────────────────────────────────

export const validateOrderCompletion = (
  paymentStatus: string,
  amountPaid: number,
  totalAmount: number
): ValidationResult => {
  if (paymentStatus === 'PENDING' || amountPaid === 0) {
    return {
      isValid: false,
      severity: 'error',
      code: 'UNPAID_ORDER',
      message: 'Cannot complete order without payment.',
      suggestion: 'Collect payment first, then mark as complete.',
    };
  }

  if (amountPaid < totalAmount) {
    const remaining = totalAmount - amountPaid;
    return {
      isValid: false,
      severity: 'error',
      code: 'PARTIAL_PAYMENT',
      message: `₹${remaining.toLocaleString('en-IN')} still due.`,
      suggestion: 'Collect remaining amount or adjust the order.',
    };
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

export const validateDeliveryDate = (
  deliveryDate: string | null,
  orderType: string
): ValidationResult => {
  if (orderType === 'DELIVERY' && !deliveryDate) {
    return {
      isValid: false,
      severity: 'error',
      code: 'MISSING_DELIVERY_DATE',
      message: 'Delivery orders need a delivery date.',
      field: 'delivery_date',
      suggestion: 'Select when the customer wants delivery.',
    };
  }

  if (deliveryDate) {
    const delivery = new Date(deliveryDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    if (delivery < today) {
      return {
        isValid: false,
        severity: 'error',
        code: 'PAST_DELIVERY_DATE',
        message: 'Delivery date cannot be in the past.',
        field: 'delivery_date',
        suggestion: 'Choose today or a future date.',
      };
    }
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

export const validateExternalOrderEdit = (
  source: string,
  isLocked: boolean
): ValidationResult => {
  const externalSources = ['BLOOMNATION', 'FTD', 'TELEFLORA'];

  if (externalSources.includes(source) && isLocked) {
    return {
      isValid: false,
      severity: 'error',
      code: 'EXTERNAL_LOCKED',
      message: 'This order was placed through an external platform and cannot be changed.',
      suggestion: 'Contact the customer through the original platform to make changes.',
    };
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

// ─── Financial Validations ──────────────────────────────────

export const validateProfitMargin = (
  sellingPrice: number,
  costPrice: number,
  productName: string
): ValidationResult => {
  if (costPrice <= 0 || sellingPrice <= 0) {
    return { isValid: true, severity: 'info', code: 'OK', message: '' };
  }

  const margin = ((sellingPrice - costPrice) / sellingPrice) * 100;

  if (margin < BUSINESS_RULES.MIN_PROFIT_MARGIN_PERCENT) {
    return {
      isValid: false,
      severity: 'error',
      code: 'MARGIN_TOO_LOW',
      message: `Profit margin is only ${margin.toFixed(1)}% on "${productName}".`,
      suggestion: `Consider increasing price to at least ₹${Math.ceil(costPrice / (1 - BUSINESS_RULES.MIN_PROFIT_MARGIN_PERCENT / 100))}.`,
    };
  }

  if (margin < BUSINESS_RULES.LOW_MARGIN_WARNING_PERCENT) {
    return {
      isValid: true,
      severity: 'warning',
      code: 'LOW_MARGIN',
      message: `Low profit margin (${margin.toFixed(1)}%) on "${productName}".`,
      suggestion: 'This item has a thin margin. Verify pricing.',
    };
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

export const validateDiscount = (
  discountPercent: number,
  orderTotal: number
): ValidationResult => {
  if (discountPercent > BUSINESS_RULES.MAX_DISCOUNT_PERCENT) {
    return {
      isValid: false,
      severity: 'error',
      code: 'EXCESSIVE_DISCOUNT',
      message: `Cannot apply ${discountPercent}% discount.`,
      suggestion: `Maximum discount allowed is ${BUSINESS_RULES.MAX_DISCOUNT_PERCENT}%. Contact manager for higher.`,
    };
  }

  if (discountPercent > 25) {
    return {
      isValid: true,
      severity: 'warning',
      code: 'HIGH_DISCOUNT',
      message: `Applying ${discountPercent}% discount (₹${((discountPercent / 100) * orderTotal).toLocaleString('en-IN')} off).`,
      suggestion: 'Verify this discount is approved.',
    };
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

export const validateRefund = (
  refundAmount: number,
  originalAmount: number,
  daysSincePurchase: number
): ValidationResult => {
  if (refundAmount > originalAmount) {
    return {
      isValid: false,
      severity: 'error',
      code: 'REFUND_EXCEEDS_PAYMENT',
      message: 'Refund amount cannot exceed original payment.',
      suggestion: `Maximum refund is ₹${originalAmount.toLocaleString('en-IN')}.`,
    };
  }

  if (daysSincePurchase > 7) {
    return {
      isValid: true,
      severity: 'warning',
      code: 'LATE_REFUND',
      message: `This order is ${daysSincePurchase} days old.`,
      suggestion: 'Late refunds may need manager approval.',
    };
  }

  return { isValid: true, severity: 'info', code: 'OK', message: '' };
};

// ─── Batch Validation Runner ────────────────────────────────

export const runValidations = (
  validators: (() => ValidationResult)[]
): ValidationContext => {
  const results = validators.map((v) => v()).filter((r) => r.code !== 'OK');

  return {
    results,
    hasErrors: results.some((r) => r.severity === 'error'),
    hasWarnings: results.some((r) => r.severity === 'warning'),
    canProceed: !results.some((r) => r.severity === 'error'),
  };
};

// ─── Confirmation Requirements ──────────────────────────────

export interface ConfirmationRequirement {
  required: boolean;
  title: string;
  message: string;
  confirmLabel: string;
  cancelLabel: string;
  severity: 'warning' | 'danger';
}

export const getConfirmationRequirement = (
  action: string,
  context?: Record<string, unknown>
): ConfirmationRequirement | null => {
  switch (action) {
    case 'CANCEL_ORDER':
      return {
        required: true,
        title: 'Cancel This Order?',
        message: 'This will cancel the order. Customer will be notified.',
        confirmLabel: 'Yes, Cancel Order',
        cancelLabel: 'Keep Order',
        severity: 'warning',
      };

    case 'REFUND':
      return {
        required: true,
        title: 'Process Refund?',
        message: `This will return ₹${((context?.amount as number) ?? 0).toLocaleString('en-IN')} to the customer.`,
        confirmLabel: 'Yes, Refund',
        cancelLabel: 'Cancel',
        severity: 'danger',
      };

    case 'DELETE_PRODUCT':
      return {
        required: true,
        title: 'Delete Product?',
        message: 'This product will be removed. This cannot be undone.',
        confirmLabel: 'Yes, Delete',
        cancelLabel: 'Keep Product',
        severity: 'danger',
      };

    case 'VOID_TRANSACTION':
      return {
        required: true,
        title: 'Void This Sale?',
        message: 'This will void the entire transaction.',
        confirmLabel: 'Yes, Void Sale',
        cancelLabel: 'Cancel',
        severity: 'danger',
      };

    case 'CLEAR_CART':
      const itemCount = (context?.itemCount as number) ?? 0;
      if (itemCount < 3) return null; // No confirmation for small carts
      return {
        required: true,
        title: 'Clear All Items?',
        message: `Remove all ${itemCount} items from this order?`,
        confirmLabel: 'Yes, Clear All',
        cancelLabel: 'Keep Items',
        severity: 'warning',
      };

    case 'ADJUST_INVENTORY':
      return {
        required: true,
        title: 'Save Stock Adjustment?',
        message: 'This will update your inventory counts.',
        confirmLabel: 'Yes, Save Changes',
        cancelLabel: 'Cancel',
        severity: 'warning',
      };

    default:
      return null;
  }
};
