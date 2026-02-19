/**
 * PaymentTypes.ts — Strict payment model, terminal-ready
 *
 * Separated from Order model. One Order can have multiple Payments.
 * Order is PAID only when sum of APPROVED payments >= grandTotal.
 */

// ─── Payment Method ─────────────────────────────────────────

export type PaymentMethod =
  | 'CASH'
  | 'CARD'
  | 'GIFT_CARD'
  | 'EXTERNAL_TERMINAL';

// ─── Payment Status ─────────────────────────────────────────

export type PaymentStatus =
  | 'PENDING'
  | 'APPROVED'
  | 'DECLINED'
  | 'VOIDED'
  | 'REFUNDED';

// ─── Terminal Response (credit-card terminal integration) ───

export interface TerminalResponse {
  terminalId: string;
  responseCode: string;
  message: string;
  timestamp: string;
  receiptData?: string;
}

// ─── Payment Record ─────────────────────────────────────────

export interface Payment {
  id: string;
  orderId: string;
  locationId?: string; // Multi-location support
  method: PaymentMethod;
  amount: number;
  status: PaymentStatus;
  transactionId?: string;
  authorizationCode?: string;
  cardBrand?: string;
  last4?: string;
  terminalResponse?: TerminalResponse;
  createdAt: string;
}

// ─── Config / Display Maps ──────────────────────────────────

export interface PaymentMethodConfig {
  label: string;
  icon: string;       // MUI icon name hint for UI
  color: string;      // hex color for chips
}

export const PAYMENT_METHOD_CONFIG: Record<PaymentMethod, PaymentMethodConfig> = {
  CASH:              { label: 'Cash',              icon: 'AttachMoney',   color: '#4caf50' },
  CARD:              { label: 'Credit/Debit Card', icon: 'CreditCard',    color: '#2196f3' },
  GIFT_CARD:         { label: 'Gift Card',         icon: 'CardGiftcard',  color: '#9c27b0' },
  EXTERNAL_TERMINAL: { label: 'External Terminal', icon: 'PointOfSale',   color: '#ff9800' },
};

export interface PaymentStatusConfig {
  label: string;
  color: string;
}

export const PAYMENT_STATUS_CONFIG: Record<PaymentStatus, PaymentStatusConfig> = {
  PENDING:  { label: 'Pending',  color: '#ed6c02' },
  APPROVED: { label: 'Approved', color: '#2e7d32' },
  DECLINED: { label: 'Declined', color: '#d32f2f' },
  VOIDED:   { label: 'Voided',   color: '#9e9e9e' },
  REFUNDED: { label: 'Refunded', color: '#0288d1' },
};

// ─── API Payload examples (documentation) ───────────────────

/**
 * Create Payment request:
 * POST /api/orders/{orderId}/payments
 * {
 *   method: "CARD",
 *   amount: 1500
 * }
 *
 * Terminal callback (webhook / polling):
 * PATCH /api/payments/{paymentId}
 * {
 *   status: "APPROVED",
 *   transactionId: "TXN-123456",
 *   authorizationCode: "AUTH-789",
 *   cardBrand: "Visa",
 *   last4: "4242",
 *   terminalResponse: { terminalId: "T-001", responseCode: "00", message: "Approved", timestamp: "..." }
 * }
 *
 * Void:
 * PATCH /api/payments/{paymentId}
 * { status: "VOIDED" }
 *
 * Refund:
 * POST /api/orders/{orderId}/payments
 * { method: "CARD", amount: -500, status: "REFUNDED", transactionId: "REF-123" }
 */
