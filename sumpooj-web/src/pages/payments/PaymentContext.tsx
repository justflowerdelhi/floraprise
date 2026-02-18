/**
 * PaymentContext.tsx — Manages payment records per-order
 *
 * Separated from Order state. Provides:
 * - addPayment (creates PENDING)
 * - processPayment (simulates terminal / cash / gift card)
 * - voidPayment / createRefund
 * - getOrderPayments / getOrderPaymentStatus
 */
import React, { createContext, useContext, useReducer, useCallback, type ReactNode } from 'react';
import type { Payment, PaymentMethod } from './PaymentTypes';
import {
  createPayment,
  simulateTerminalResponse,
  approveCashPayment,
  approveGiftCardPayment,
  voidPayment as voidPay,
  createRefund as mkRefund,
  deriveOrderPaymentStatus,
  getApprovedTotal,
  getRemainingBalance,
  type OrderPaymentStatus,
} from './PaymentUtils';

// ─── State ──────────────────────────────────────────────────

interface PaymentState {
  /** All payment records keyed by payment ID */
  payments: Record<string, Payment>;
}

const initialState: PaymentState = {
  payments: {},
};

// ─── Actions ────────────────────────────────────────────────

type PaymentAction =
  | { type: 'UPSERT_PAYMENT'; payment: Payment }
  | { type: 'REMOVE_PAYMENT'; paymentId: string }
  | { type: 'CLEAR_ORDER_PAYMENTS'; orderId: string };

function paymentReducer(state: PaymentState, action: PaymentAction): PaymentState {
  switch (action.type) {
    case 'UPSERT_PAYMENT':
      return {
        ...state,
        payments: { ...state.payments, [action.payment.id]: action.payment },
      };

    case 'REMOVE_PAYMENT': {
      const { [action.paymentId]: _removed, ...rest } = state.payments;
      return { ...state, payments: rest };
    }

    case 'CLEAR_ORDER_PAYMENTS': {
      const filtered: Record<string, Payment> = {};
      for (const [k, v] of Object.entries(state.payments)) {
        if (v.orderId !== action.orderId) filtered[k] = v;
      }
      return { ...state, payments: filtered };
    }

    default:
      return state;
  }
}

// ─── Process result ─────────────────────────────────────────

export interface ProcessPaymentResult {
  success: boolean;
  payment: Payment;
  message: string;
}

// ─── Context value ──────────────────────────────────────────

interface PaymentContextValue {
  state: PaymentState;

  /** Create & process a payment in one step. Returns result. */
  processNewPayment: (orderId: string, method: PaymentMethod, amount: number) => ProcessPaymentResult;

  /** Void an existing payment */
  voidPayment: (paymentId: string) => void;

  /** Create a refund record */
  createRefund: (orderId: string, method: PaymentMethod, amount: number, originalTxnId?: string) => Payment;

  /** Clear all payments for an order */
  clearOrderPayments: (orderId: string) => void;

  /** Get all payments for a specific order */
  getOrderPayments: (orderId: string) => Payment[];

  /** Derive order payment status from its payments */
  getOrderPaymentStatus: (orderId: string, grandTotal: number) => OrderPaymentStatus;

  /** Get total approved amount for an order */
  getOrderApprovedTotal: (orderId: string) => number;

  /** Get remaining balance */
  getOrderRemainingBalance: (orderId: string, grandTotal: number) => number;
}

const PaymentContext = createContext<PaymentContextValue | null>(null);

// ─── Provider ───────────────────────────────────────────────

export const PaymentProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(paymentReducer, initialState);

  const getOrderPayments = useCallback(
    (orderId: string): Payment[] =>
      Object.values(state.payments).filter((p) => p.orderId === orderId),
    [state.payments],
  );

  const processNewPayment = useCallback(
    (orderId: string, method: PaymentMethod, amount: number): ProcessPaymentResult => {
      const pending = createPayment(orderId, method, amount);

      let processed: Payment;
      let success: boolean;
      let message: string;

      switch (method) {
        case 'CASH': {
          processed = approveCashPayment(pending);
          success = true;
          message = 'Cash payment recorded';
          break;
        }
        case 'GIFT_CARD': {
          processed = approveGiftCardPayment(pending);
          success = true;
          message = 'Gift card payment approved';
          break;
        }
        case 'CARD':
        case 'EXTERNAL_TERMINAL': {
          const result = simulateTerminalResponse(pending);
          processed = result.payment;
          success = result.approved;
          message = success
            ? `Card approved — ${processed.cardBrand} ending ${processed.last4}`
            : `Card declined — ${processed.terminalResponse?.message ?? 'Unknown error'}`;
          break;
        }
        default: {
          processed = pending;
          success = false;
          message = 'Unknown payment method';
        }
      }

      dispatch({ type: 'UPSERT_PAYMENT', payment: processed });
      return { success, payment: processed, message };
    },
    [],
  );

  const handleVoid = useCallback(
    (paymentId: string) => {
      const existing = state.payments[paymentId];
      if (!existing) return;
      dispatch({ type: 'UPSERT_PAYMENT', payment: voidPay(existing) });
    },
    [state.payments],
  );

  const handleRefund = useCallback(
    (orderId: string, method: PaymentMethod, amount: number, originalTxnId?: string): Payment => {
      const refund = mkRefund(orderId, method, amount, originalTxnId);
      dispatch({ type: 'UPSERT_PAYMENT', payment: refund });
      return refund;
    },
    [],
  );

  const clearOrderPayments = useCallback(
    (orderId: string) => dispatch({ type: 'CLEAR_ORDER_PAYMENTS', orderId }),
    [],
  );

  const getStatus = useCallback(
    (orderId: string, grandTotal: number): OrderPaymentStatus => {
      const payments = Object.values(state.payments).filter((p) => p.orderId === orderId);
      return deriveOrderPaymentStatus(payments, grandTotal);
    },
    [state.payments],
  );

  const getApproved = useCallback(
    (orderId: string): number => {
      const payments = Object.values(state.payments).filter((p) => p.orderId === orderId);
      return getApprovedTotal(payments);
    },
    [state.payments],
  );

  const getRemaining = useCallback(
    (orderId: string, grandTotal: number): number => {
      const payments = Object.values(state.payments).filter((p) => p.orderId === orderId);
      return getRemainingBalance(payments, grandTotal);
    },
    [state.payments],
  );

  return (
    <PaymentContext.Provider
      value={{
        state,
        processNewPayment,
        voidPayment: handleVoid,
        createRefund: handleRefund,
        clearOrderPayments,
        getOrderPayments,
        getOrderPaymentStatus: getStatus,
        getOrderApprovedTotal: getApproved,
        getOrderRemainingBalance: getRemaining,
      }}
    >
      {children}
    </PaymentContext.Provider>
  );
};

export const usePayments = (): PaymentContextValue => {
  const ctx = useContext(PaymentContext);
  if (!ctx) throw new Error('usePayments must be used within PaymentProvider');
  return ctx;
};
