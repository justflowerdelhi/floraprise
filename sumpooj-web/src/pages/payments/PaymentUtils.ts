/**
 * PaymentUtils.ts — Payment lifecycle helpers
 *
 * - Create pending payments
 * - Simulate terminal response
 * - Calculate order payment status from payment records
 * - Void / refund helpers
 */
import type { Payment, PaymentMethod } from './PaymentTypes';

let _paySeq = 0;

/** Generate a unique payment ID */
export const nextPaymentId = (): string => `pay_${String(++_paySeq).padStart(5, '0')}`;

/** Generate a mock transaction ID */
const mockTxnId = (): string => `TXN-${Date.now()}-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;

// ─── Create a new PENDING payment ───────────────────────────

export const createPayment = (
  orderId: string,
  method: PaymentMethod,
  amount: number,
): Payment => ({
  id: nextPaymentId(),
  orderId,
  method,
  amount,
  status: 'PENDING',
  createdAt: new Date().toISOString(),
});

// ─── Simulate terminal approval/decline ─────────────────────

export interface TerminalSimResult {
  approved: boolean;
  payment: Payment;
}

/**
 * Simulates a card terminal interaction.
 * 90% approval rate for demo purposes.
 */
export const simulateTerminalResponse = (payment: Payment): TerminalSimResult => {
  const approved = Math.random() < 0.9;
  const updated: Payment = {
    ...payment,
    status: approved ? 'APPROVED' : 'DECLINED',
    transactionId: approved ? mockTxnId() : undefined,
    authorizationCode: approved ? `AUTH-${Math.floor(Math.random() * 900000 + 100000)}` : undefined,
    cardBrand: approved ? (['Visa', 'Mastercard', 'RuPay', 'Amex'] as const)[Math.floor(Math.random() * 4)] : undefined,
    last4: approved ? String(Math.floor(Math.random() * 9000 + 1000)) : undefined,
    terminalResponse: {
      terminalId: 'T-001',
      responseCode: approved ? '00' : '51',
      message: approved ? 'Transaction Approved' : 'Insufficient Funds',
      timestamp: new Date().toISOString(),
    },
  };
  return { approved, payment: updated };
};

// ─── Cash payment — auto-approve ────────────────────────────

export const approveCashPayment = (payment: Payment): Payment => ({
  ...payment,
  status: 'APPROVED',
  transactionId: `CASH-${Date.now()}`,
});

// ─── Gift card payment — auto-approve ───────────────────────

export const approveGiftCardPayment = (payment: Payment): Payment => ({
  ...payment,
  status: 'APPROVED',
  transactionId: `GC-${Date.now()}`,
});

// ─── Void a payment ─────────────────────────────────────────

export const voidPayment = (payment: Payment): Payment => ({
  ...payment,
  status: 'VOIDED',
});

// ─── Refund — create a negative REFUNDED record ─────────────

export const createRefund = (
  orderId: string,
  method: PaymentMethod,
  amount: number,
  originalTxnId?: string,
): Payment => ({
  id: nextPaymentId(),
  orderId,
  method,
  amount: -Math.abs(amount),
  status: 'REFUNDED',
  transactionId: `REF-${Date.now()}`,
  authorizationCode: originalTxnId,
  createdAt: new Date().toISOString(),
});

// ─── Order-level payment status derivation ──────────────────

export type OrderPaymentStatus = 'UNPAID' | 'PARTIAL' | 'PAID';

/**
 * Derive the order-level payment status from its payment records.
 * Sum of APPROVED amounts (negative for refunds) vs grandTotal.
 */
export const deriveOrderPaymentStatus = (
  payments: Payment[],
  grandTotal: number,
): OrderPaymentStatus => {
  const approvedTotal = payments
    .filter((p) => p.status === 'APPROVED' || p.status === 'REFUNDED')
    .reduce((sum, p) => sum + p.amount, 0);

  if (approvedTotal <= 0) return 'UNPAID';
  if (approvedTotal >= grandTotal) return 'PAID';
  return 'PARTIAL';
};

/**
 * Get the total approved amount for an order.
 */
export const getApprovedTotal = (payments: Payment[]): number =>
  payments
    .filter((p) => p.status === 'APPROVED')
    .reduce((sum, p) => sum + p.amount, 0);

/**
 * Get remaining balance to pay.
 */
export const getRemainingBalance = (payments: Payment[], grandTotal: number): number => {
  const paid = getApprovedTotal(payments);
  return Math.max(0, grandTotal - paid);
};

// ─── Formatters ─────────────────────────────────────────────

const INR = new Intl.NumberFormat('en-IN', {
  style: 'currency', currency: 'INR',
  minimumFractionDigits: 0, maximumFractionDigits: 2,
});

export const fmtPaymentAmount = (v: number): string => INR.format(v);
