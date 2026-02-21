/**
 * OrderContext.tsx — Manages the global order list
 *
 * Provides:
 * - addOrder / updateOrder / removeOrder
 * - getOrder / getAllOrders
 * - updateFulfillmentStatus / updatePaymentStatus
 */
import React, { createContext, useContext, useReducer, useCallback, useEffect, type ReactNode } from 'react';
import type { Order, FulfillmentStatus, OrderPaymentStatus, InventoryActionStatus, InventoryReservation } from './OrderTypes';
import { searchOrders } from '../../api/order.api';

// ─── State ──────────────────────────────────────────────────

interface OrderState {
  orders: Record<string, Order>;
}

const initialState: OrderState = {
  orders: {},
};

// ─── Actions ────────────────────────────────────────────────

type OrderAction =
  | { type: 'LOAD_ORDERS'; orders: Order[] }
  | { type: 'ADD_ORDER'; order: Order }
  | { type: 'UPDATE_ORDER'; order: Order }
  | { type: 'REMOVE_ORDER'; orderId: string }
  | { type: 'SET_FULFILLMENT'; orderId: string; status: FulfillmentStatus }
  | { type: 'SET_PAYMENT_STATUS'; orderId: string; status: OrderPaymentStatus }
  | { type: 'SET_INVENTORY_STATUS'; orderId: string; inventoryStatus: InventoryActionStatus; reservations?: InventoryReservation[] };

function orderReducer(state: OrderState, action: OrderAction): OrderState {
  switch (action.type) {
    case 'LOAD_ORDERS':
      return {
        ...state,
        orders: Object.fromEntries(action.orders.map((o) => [o.id, o])),
      };

    case 'ADD_ORDER':
      return {
        ...state,
        orders: { ...state.orders, [action.order.id]: action.order },
      };

    case 'UPDATE_ORDER':
      return {
        ...state,
        orders: { ...state.orders, [action.order.id]: { ...action.order, updatedAt: new Date().toISOString() } },
      };

    case 'REMOVE_ORDER': {
      const { [action.orderId]: _removed, ...rest } = state.orders;
      return { ...state, orders: rest };
    }

    case 'SET_FULFILLMENT': {
      const existing = state.orders[action.orderId];
      if (!existing) return state;
      return {
        ...state,
        orders: {
          ...state.orders,
          [action.orderId]: { ...existing, fulfillmentStatus: action.status, updatedAt: new Date().toISOString() },
        },
      };
    }

    case 'SET_PAYMENT_STATUS': {
      const existing = state.orders[action.orderId];
      if (!existing) return state;
      return {
        ...state,
        orders: {
          ...state.orders,
          [action.orderId]: { ...existing, paymentStatus: action.status, updatedAt: new Date().toISOString() },
        },
      };
    }

    case 'SET_INVENTORY_STATUS': {
      const existing = state.orders[action.orderId];
      if (!existing) return state;
      return {
        ...state,
        orders: {
          ...state.orders,
          [action.orderId]: {
            ...existing,
            inventoryStatus: action.inventoryStatus,
            ...(action.reservations && { reservations: action.reservations }),
            updatedAt: new Date().toISOString(),
          },
        },
      };
    }

    default:
      return state;
  }
}

// ─── Context ────────────────────────────────────────────────

interface OrderContextValue {
  state: OrderState;
  loading: boolean;
  addOrder: (order: Order) => void;
  updateOrder: (order: Order) => void;
  removeOrder: (orderId: string) => void;
  setFulfillment: (orderId: string, status: FulfillmentStatus) => void;
  setPaymentStatus: (orderId: string, status: OrderPaymentStatus) => void;
  setInventoryStatus: (orderId: string, inventoryStatus: InventoryActionStatus, reservations?: InventoryReservation[]) => void;
  getOrder: (orderId: string) => Order | undefined;
  getAllOrders: () => Order[];
}

const OrderContext = createContext<OrderContextValue | null>(null);

export const OrderProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(orderReducer, initialState);
  const [loading, setLoading] = React.useState(true);

  // Load orders from API on mount
  useEffect(() => {
    let cancelled = false;
    const load = async () => {
      try {
        const result = await searchOrders({ PageSize: 200 });
        if (!cancelled) {
          const orders = result?.items ?? (Array.isArray(result) ? result : []);
          dispatch({ type: 'LOAD_ORDERS', orders });
        }
      } catch (err) {
        console.error('Failed to load orders:', err);
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    load();
    return () => { cancelled = true; };
  }, []);

  const addOrder        = useCallback((order: Order) => dispatch({ type: 'ADD_ORDER', order }), []);
  const updateOrder     = useCallback((order: Order) => dispatch({ type: 'UPDATE_ORDER', order }), []);
  const removeOrder     = useCallback((orderId: string) => dispatch({ type: 'REMOVE_ORDER', orderId }), []);
  const setFulfillment  = useCallback((orderId: string, status: FulfillmentStatus) => dispatch({ type: 'SET_FULFILLMENT', orderId, status }), []);
  const setPaymentStatus = useCallback((orderId: string, status: OrderPaymentStatus) => dispatch({ type: 'SET_PAYMENT_STATUS', orderId, status }), []);
  const setInventoryStatus = useCallback(
    (orderId: string, inventoryStatus: InventoryActionStatus, reservations?: InventoryReservation[]) =>
      dispatch({ type: 'SET_INVENTORY_STATUS', orderId, inventoryStatus, reservations }),
    [],
  );

  const getOrder = useCallback(
    (orderId: string): Order | undefined => state.orders[orderId],
    [state.orders],
  );

  const getAllOrders = useCallback(
    (): Order[] => Object.values(state.orders).sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
    [state.orders],
  );

  return (
    <OrderContext.Provider
      value={{
        state, loading, addOrder, updateOrder, removeOrder,
        setFulfillment, setPaymentStatus, setInventoryStatus, getOrder, getAllOrders,
      }}
    >
      {children}
    </OrderContext.Provider>
  );
};

export const useOrders = (): OrderContextValue => {
  const ctx = useContext(OrderContext);
  if (!ctx) throw new Error('useOrders must be used within OrderProvider');
  return ctx;
};
