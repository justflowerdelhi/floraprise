/**
 * POSContext.tsx — Global POS State Management
 * 
 * Single cart architecture with lifecycle management:
 * - idle: No items, ready for new transaction
 * - active: Items in cart, editing allowed
 * - payment: Payment in progress, cart locked
 * - completed: Transaction complete, auto-reset
 * 
 * Designed for single-cart retail POS with future multi-cart extensibility
 */
import React, {
  createContext,
  useContext,
  useReducer,
  useCallback,
  useEffect,
  type ReactNode,
} from 'react';
import { useBlocker } from 'react-router-dom';
import type { CartItem, CartSummary, Product, OrderSource, OrderDiscount, LineItemDiscount, BatchAllocation } from '../orders/OrderTypes';
import type {
  POSCustomer,
  POSOrderType,
  POSPaymentEntry,
  POSBillingInfo,
  OrderIntent,
  DeliveryDetails,
  PickupDetails,
} from './POSTypes';
import {
  EMPTY_DELIVERY_DETAILS,
  EMPTY_PICKUP_DETAILS,
} from './POSTypes';
import { calcLineItem, calcCartSummary, nextLineId } from '../cart/CartUtils';

// ─── Cart Lifecycle States ──────────────────────────────────

export type CartLifecycle = 'idle' | 'active' | 'payment' | 'completed';

// ─── POS Session State ──────────────────────────────────────

export interface POSSession {
  id: string;
  startedAt: string;
  locationId: string;
  locationName: string;
  operatorId?: string;
  operatorName?: string;
}

// ─── POS State ──────────────────────────────────────────────

export interface POSState {
  // Cart lifecycle
  lifecycle: CartLifecycle;
  
  // Cart data
  items: CartItem[];
  totals: CartSummary;
  orderSource: OrderSource;
  orderDiscount: OrderDiscount | null;
  
  // Transaction metadata
  transactionId: string | null;
  customer: POSCustomer | null;
  orderType: POSOrderType;

  // Order intent (TAKE_NOW / DELIVERY / PICKUP_LATER)
  orderIntent: OrderIntent;
  deliveryDetails: DeliveryDetails;
  pickupDetails: PickupDetails;
  
  // Payment state
  payments: POSPaymentEntry[];
  billingInfo: POSBillingInfo | null;
  
  // Session
  session: POSSession;
  
  // UI state
  isLocked: boolean; // Prevents all cart modifications
  lastActivity: string;
}

const EMPTY_TOTALS: CartSummary = {
  subtotal: 0,
  taxTotal: 0,
  discountTotal: 0,
  orderDiscountAmount: 0,
  grandTotal: 0,
  totalCost: 0,
  marginPercent: 0,
  marginWarning: false,
  itemCount: 0,
  lineCount: 0,
  taxBreakdown: [],
};

const createInitialState = (): POSState => ({
  lifecycle: 'idle',
  items: [],
  totals: EMPTY_TOTALS,
  orderSource: 'WALK_IN',
  orderDiscount: null,
  transactionId: null,
  customer: null,
  orderType: 'TAKE_NOW',
  orderIntent: 'TAKE_NOW',
  deliveryDetails: { ...EMPTY_DELIVERY_DETAILS },
  pickupDetails: { ...EMPTY_PICKUP_DETAILS },
  payments: [],
  billingInfo: null,
  session: {
    id: `session_${Date.now()}`,
    startedAt: new Date().toISOString(),
    locationId: 'loc_default',
    locationName: 'Main Store',
  },
  isLocked: false,
  lastActivity: new Date().toISOString(),
});

// ─── Actions ────────────────────────────────────────────────

type POSAction =
  // Cart actions
  | { type: 'ADD_PRODUCT'; product: Product; qty: number }
  | { type: 'REMOVE_ITEM'; lineId: string }
  | { type: 'UPDATE_QTY'; lineId: string; qty: number; product: Product }
  | { type: 'SET_LINE_DISCOUNT'; lineId: string; discount: LineItemDiscount | null; product: Product }
  | { type: 'OVERRIDE_BATCH'; lineId: string; allocations: BatchAllocation[]; product: Product }
  | { type: 'SET_ORDER_DISCOUNT'; discount: OrderDiscount }
  | { type: 'CLEAR_ORDER_DISCOUNT' }
  // Transaction actions
  | { type: 'SET_CUSTOMER'; customer: POSCustomer | null }
  | { type: 'SET_ORDER_TYPE'; orderType: POSOrderType }
  | { type: 'SET_ORDER_INTENT'; intent: OrderIntent }
  | { type: 'SET_DELIVERY_DETAILS'; details: DeliveryDetails }
  | { type: 'SET_PICKUP_DETAILS'; details: PickupDetails }
  // Lifecycle actions
  | { type: 'START_PAYMENT' }
  | { type: 'CANCEL_PAYMENT' }
  | { type: 'ADD_PAYMENT'; payment: POSPaymentEntry }
  | { type: 'REMOVE_PAYMENT'; paymentId: string }
  | { type: 'SET_BILLING_INFO'; billingInfo: POSBillingInfo }
  | { type: 'COMPLETE_TRANSACTION' }
  | { type: 'RESET_CART' }
  // Session actions
  | { type: 'SET_SESSION'; session: Partial<POSSession> };

function posReducer(state: POSState, action: POSAction): POSState {
  const now = new Date().toISOString();

  // Helper to recalculate totals
  const recalc = (items: CartItem[], orderDiscount: OrderDiscount | null = state.orderDiscount): Partial<POSState> => ({
    items,
    orderDiscount,
    totals: calcCartSummary(items, orderDiscount),
    lifecycle: items.length > 0 ? 'active' : 'idle',
    lastActivity: now,
  });

  // Block modifications when locked (payment in progress)
  const isCartAction = ['ADD_PRODUCT', 'REMOVE_ITEM', 'UPDATE_QTY', 'SET_LINE_DISCOUNT', 'OVERRIDE_BATCH'].includes(action.type);
  if (state.isLocked && isCartAction) {
    console.warn('Cart is locked during payment');
    return state;
  }

  switch (action.type) {
    // ─── Cart Actions ───────────────────────────────────────

    case 'ADD_PRODUCT': {
      const existing = state.items.find((i) => i.productId === action.product.id);
      if (existing) {
        const newQty = existing.quantity + action.qty;
        const updated = calcLineItem(action.product, newQty, existing.lineDiscount ?? existing.discountPercent);
        updated.id = existing.id;
        const items = state.items.map((i) => (i.id === existing.id ? updated : i));
        return { ...state, ...recalc(items) };
      }
      const item = calcLineItem(action.product, action.qty, 0);
      const newTransactionId = state.transactionId || `txn_${Date.now()}`;
      return {
        ...state,
        ...recalc([...state.items, item]),
        transactionId: newTransactionId,
      };
    }

    case 'REMOVE_ITEM': {
      const items = state.items.filter((i) => i.id !== action.lineId);
      return { ...state, ...recalc(items) };
    }

    case 'UPDATE_QTY': {
      if (action.qty <= 0) {
        const items = state.items.filter((i) => i.id !== action.lineId);
        return { ...state, ...recalc(items) };
      }
      const items = state.items.map((i) => {
        if (i.id !== action.lineId) return i;
        const updated = calcLineItem(action.product, action.qty, i.lineDiscount ?? i.discountPercent);
        updated.id = i.id;
        return updated;
      });
      return { ...state, ...recalc(items) };
    }

    case 'SET_LINE_DISCOUNT': {
      const items = state.items.map((i) => {
        if (i.id !== action.lineId) return i;
        const updated = calcLineItem(action.product, i.quantity, action.discount);
        updated.id = i.id;
        return updated;
      });
      return { ...state, ...recalc(items) };
    }

    case 'OVERRIDE_BATCH': {
      const items = state.items.map((i) => {
        if (i.id !== action.lineId) return i;
        const updated = calcLineItem(action.product, i.quantity, i.lineDiscount ?? i.discountPercent, action.allocations);
        updated.id = i.id;
        return updated;
      });
      return { ...state, ...recalc(items) };
    }

    case 'SET_ORDER_DISCOUNT':
      return { ...state, ...recalc(state.items, action.discount) };

    case 'CLEAR_ORDER_DISCOUNT':
      return { ...state, ...recalc(state.items, null) };

    // ─── Transaction Actions ────────────────────────────────

    case 'SET_CUSTOMER':
      return { ...state, customer: action.customer, lastActivity: now };

    case 'SET_ORDER_TYPE':
      return { ...state, orderType: action.orderType, lastActivity: now };

    case 'SET_ORDER_INTENT': {
      const intent = action.intent;
      return {
        ...state,
        orderIntent: intent,
        orderType: intent, // keep in sync
        // Reset irrelevant details when switching
        deliveryDetails: intent === 'DELIVERY' ? state.deliveryDetails : { ...EMPTY_DELIVERY_DETAILS },
        pickupDetails: intent === 'PICKUP_LATER' ? state.pickupDetails : { ...EMPTY_PICKUP_DETAILS },
        lastActivity: now,
      };
    }

    case 'SET_DELIVERY_DETAILS':
      return { ...state, deliveryDetails: action.details, lastActivity: now };

    case 'SET_PICKUP_DETAILS':
      return { ...state, pickupDetails: action.details, lastActivity: now };

    // ─── Lifecycle Actions ──────────────────────────────────

    case 'START_PAYMENT': {
      if (state.items.length === 0) {
        console.warn('Cannot start payment with empty cart');
        return state;
      }
      return {
        ...state,
        lifecycle: 'payment',
        isLocked: true,
        payments: [],
        billingInfo: state.customer ? {
          name: state.customer.name,
          email: state.customer.email || '',
          phone: state.customer.phone,
        } : null,
        lastActivity: now,
      };
    }

    case 'CANCEL_PAYMENT':
      return {
        ...state,
        lifecycle: 'active',
        isLocked: false,
        payments: [],
        lastActivity: now,
      };

    case 'ADD_PAYMENT':
      return {
        ...state,
        payments: [...state.payments, action.payment],
        lastActivity: now,
      };

    case 'REMOVE_PAYMENT':
      return {
        ...state,
        payments: state.payments.filter((p) => p.id !== action.paymentId),
        lastActivity: now,
      };

    case 'SET_BILLING_INFO':
      return { ...state, billingInfo: action.billingInfo, lastActivity: now };

    case 'COMPLETE_TRANSACTION':
      return {
        ...state,
        lifecycle: 'completed',
        lastActivity: now,
      };

    case 'RESET_CART':
      return {
        ...createInitialState(),
        session: state.session, // Preserve session
      };

    // ─── Session Actions ────────────────────────────────────

    case 'SET_SESSION':
      return {
        ...state,
        session: { ...state.session, ...action.session },
        lastActivity: now,
      };

    default:
      return state;
  }
}

// ─── Context Value ──────────────────────────────────────────

interface POSContextValue {
  state: POSState;
  
  // Cart actions
  addProduct: (product: Product, qty?: number) => void;
  removeItem: (lineId: string) => void;
  updateQty: (lineId: string, qty: number, product: Product) => void;
  setLineDiscount: (lineId: string, discount: LineItemDiscount | null, product: Product) => void;
  overrideBatch: (lineId: string, allocations: BatchAllocation[], product: Product) => void;
  setOrderDiscount: (discount: OrderDiscount) => void;
  clearOrderDiscount: () => void;
  
  // Transaction actions
  setCustomer: (customer: POSCustomer | null) => void;
  setOrderType: (orderType: POSOrderType) => void;
  setOrderIntent: (intent: OrderIntent) => void;
  setDeliveryDetails: (details: DeliveryDetails) => void;
  setPickupDetails: (details: PickupDetails) => void;
  
  // Lifecycle actions
  startPayment: () => void;
  cancelPayment: () => void;
  addPayment: (payment: POSPaymentEntry) => void;
  removePayment: (paymentId: string) => void;
  setBillingInfo: (billingInfo: POSBillingInfo) => void;
  completeTransaction: () => void;
  resetCart: () => void;
  
  // Computed values
  canCheckout: boolean;
  canEditCart: boolean;
  hasUnsavedCart: boolean;
  paidAmount: number;
  remainingAmount: number;
  isFullyPaid: boolean;
  intentErrors: string[];
}

const POSContext = createContext<POSContextValue | null>(null);

// ─── Provider ───────────────────────────────────────────────

interface POSProviderProps {
  children: ReactNode;
  locationId?: string;
  locationName?: string;
}

export const POSProvider: React.FC<POSProviderProps> = ({
  children,
  locationId = 'loc_default',
  locationName = 'Main Store',
}) => {
  const [state, dispatch] = useReducer(posReducer, undefined, () => {
    const initial = createInitialState();
    initial.session.locationId = locationId;
    initial.session.locationName = locationName;
    return initial;
  });

  // Auto-reset after completed state
  useEffect(() => {
    if (state.lifecycle === 'completed') {
      const timer = setTimeout(() => {
        dispatch({ type: 'RESET_CART' });
      }, 100); // Brief delay to allow UI feedback
      return () => clearTimeout(timer);
    }
  }, [state.lifecycle]);

  // ─── Actions ────────────────────────────────────────────

  const addProduct = useCallback((product: Product, qty = 1) => {
    dispatch({ type: 'ADD_PRODUCT', product, qty });
  }, []);

  const removeItem = useCallback((lineId: string) => {
    dispatch({ type: 'REMOVE_ITEM', lineId });
  }, []);

  const updateQty = useCallback((lineId: string, qty: number, product: Product) => {
    dispatch({ type: 'UPDATE_QTY', lineId, qty, product });
  }, []);

  const setLineDiscount = useCallback((lineId: string, discount: LineItemDiscount | null, product: Product) => {
    dispatch({ type: 'SET_LINE_DISCOUNT', lineId, discount, product });
  }, []);

  const overrideBatch = useCallback((lineId: string, allocations: BatchAllocation[], product: Product) => {
    dispatch({ type: 'OVERRIDE_BATCH', lineId, allocations, product });
  }, []);

  const setOrderDiscount = useCallback((discount: OrderDiscount) => {
    dispatch({ type: 'SET_ORDER_DISCOUNT', discount });
  }, []);

  const clearOrderDiscount = useCallback(() => {
    dispatch({ type: 'CLEAR_ORDER_DISCOUNT' });
  }, []);

  const setCustomer = useCallback((customer: POSCustomer | null) => {
    dispatch({ type: 'SET_CUSTOMER', customer });
  }, []);

  const setOrderType = useCallback((orderType: POSOrderType) => {
    dispatch({ type: 'SET_ORDER_TYPE', orderType });
  }, []);

  const setOrderIntent = useCallback((intent: OrderIntent) => {
    dispatch({ type: 'SET_ORDER_INTENT', intent });
  }, []);

  const setDeliveryDetails = useCallback((details: DeliveryDetails) => {
    dispatch({ type: 'SET_DELIVERY_DETAILS', details });
  }, []);

  const setPickupDetails = useCallback((details: PickupDetails) => {
    dispatch({ type: 'SET_PICKUP_DETAILS', details });
  }, []);

  const startPayment = useCallback(() => {
    dispatch({ type: 'START_PAYMENT' });
  }, []);

  const cancelPayment = useCallback(() => {
    dispatch({ type: 'CANCEL_PAYMENT' });
  }, []);

  const addPayment = useCallback((payment: POSPaymentEntry) => {
    dispatch({ type: 'ADD_PAYMENT', payment });
  }, []);

  const removePayment = useCallback((paymentId: string) => {
    dispatch({ type: 'REMOVE_PAYMENT', paymentId });
  }, []);

  const setBillingInfo = useCallback((billingInfo: POSBillingInfo) => {
    dispatch({ type: 'SET_BILLING_INFO', billingInfo });
  }, []);

  const completeTransaction = useCallback(() => {
    dispatch({ type: 'COMPLETE_TRANSACTION' });
  }, []);

  const resetCart = useCallback(() => {
    dispatch({ type: 'RESET_CART' });
  }, []);

  // ─── Computed Values ──────────────────────────────────────

  const canEditCart = !state.isLocked && state.lifecycle !== 'completed';
  const hasUnsavedCart = state.items.length > 0;
  const paidAmount = state.payments.reduce((sum, p) => sum + p.amount, 0);
  const remainingAmount = Math.max(0, Math.round((state.totals.grandTotal - paidAmount) * 100) / 100);
  const isFullyPaid = remainingAmount === 0 && state.payments.length > 0;

  // Intent-specific validation errors
  const intentErrors: string[] = [];

  // Phone number is required before payment
  const hasPhone = !!(state.customer?.phone?.trim());
  if (!hasPhone) intentErrors.push('Customer phone number is required');

  if (state.orderIntent === 'DELIVERY') {
    if (!state.deliveryDetails.zipCode.trim()) intentErrors.push('ZIP code is required');
    if (!state.deliveryDetails.address.trim()) intentErrors.push('Delivery address is required');
    if (!state.deliveryDetails.deliveryDate) intentErrors.push('Delivery date is required');
  }
  if (state.orderIntent === 'PICKUP_LATER') {
    if (!state.pickupDetails.pickupDate) intentErrors.push('Pickup date is required');
    if (!state.pickupDetails.pickupTimeSlot) intentErrors.push('Pickup time slot is required');
  }

  // canCheckout blocks on intent errors
  const canCheckout = state.items.length > 0 && state.lifecycle === 'active' && intentErrors.length === 0;

  const value: POSContextValue = {
    state,
    addProduct,
    removeItem,
    updateQty,
    setLineDiscount,
    overrideBatch,
    setOrderDiscount,
    clearOrderDiscount,
    setCustomer,
    setOrderType,
    setOrderIntent,
    setDeliveryDetails,
    setPickupDetails,
    startPayment,
    cancelPayment,
    addPayment,
    removePayment,
    setBillingInfo,
    completeTransaction,
    resetCart,
    canCheckout,
    canEditCart,
    hasUnsavedCart,
    paidAmount,
    remainingAmount,
    isFullyPaid,
    intentErrors,
  };

  return <POSContext.Provider value={value}>{children}</POSContext.Provider>;
};

// ─── Hook ───────────────────────────────────────────────────

export const usePOS = (): POSContextValue => {
  const ctx = useContext(POSContext);
  if (!ctx) throw new Error('usePOS must be used within POSProvider');
  return ctx;
};

// ─── Navigation Blocker Hook ────────────────────────────────

export const usePOSNavigationBlocker = () => {
  const { hasUnsavedCart, state } = usePOS();
  
  const blocker = useBlocker(
    ({ currentLocation, nextLocation }) =>
      hasUnsavedCart &&
      state.lifecycle !== 'completed' &&
      currentLocation.pathname !== nextLocation.pathname
  );

  return blocker;
};
