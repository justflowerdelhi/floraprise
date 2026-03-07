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
  refreshOrders: () => Promise<void>;
}

const OrderContext = createContext<OrderContextValue | null>(null);

// ─── API → Frontend Mapping ────────────────────────────────

const SOURCE_MAP: Record<string, Order['orderSource']> = {
  WalkIn: 'WALK_IN', Phone: 'PHONE', Website: 'WEBSITE',
  BloomNation: 'BLOOMNATION', Ftd: 'FTD', Other: 'WALK_IN',
  WALK_IN: 'WALK_IN', PHONE: 'PHONE', WEBSITE: 'WEBSITE',
  BLOOMNATION: 'BLOOMNATION', FTD: 'FTD',
};

const FULFILLMENT_MAP: Record<string, FulfillmentStatus> = {
  Draft: 'DRAFT', Confirmed: 'CONFIRMED', InDesign: 'IN_DESIGN',
  Ready: 'READY', OutForDelivery: 'OUT_FOR_DELIVERY',
  Completed: 'COMPLETED', Cancelled: 'CANCELLED',
  DRAFT: 'DRAFT', CONFIRMED: 'CONFIRMED', IN_DESIGN: 'IN_DESIGN',
  READY: 'READY', OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
  COMPLETED: 'COMPLETED', CANCELLED: 'CANCELLED',
};

const PAYMENT_MAP: Record<string, OrderPaymentStatus> = {
  Unpaid: 'UNPAID', Partial: 'PARTIAL', Paid: 'PAID',
  UNPAID: 'UNPAID', PARTIAL: 'PARTIAL', PAID: 'PAID',
};

/** Derive inventory status from order state (not stored in DB) */
function deriveInventoryStatus(dto: any): 'NONE' | 'RESERVED' | 'DEDUCTED' | 'RELEASED' {
  const fulfillment = FULFILLMENT_MAP[dto.fulfillmentStatus] ?? 'DRAFT';
  const payment = PAYMENT_MAP[dto.paymentStatus] ?? 'UNPAID';
  const status = dto.status ?? dto.orderStatus ?? '';

  // Completed / Delivered orders → inventory already deducted
  if (fulfillment === 'COMPLETED' || status === 'Delivered' || status === 'DELIVERED')
    return 'DEDUCTED';

  // Cancelled → inventory released
  if (fulfillment === 'CANCELLED' || status === 'Cancelled' || status === 'CANCELLED')
    return 'RELEASED';

  // Confirmed + paid → deducted (walk-in take-now)
  if (payment === 'PAID' && (fulfillment === 'CONFIRMED' || fulfillment === 'READY'))
    return 'DEDUCTED';

  // Confirmed but not fully paid → reserved
  if (fulfillment === 'CONFIRMED' || fulfillment === 'IN_DESIGN' || fulfillment === 'OUT_FOR_DELIVERY')
    return 'RESERVED';

  return 'NONE';
}

/** Map an API OrderListDto to the frontend Order type */
function mapApiOrderToOrder(dto: any): Order {
  const fulfillment = FULFILLMENT_MAP[dto.fulfillmentStatus] ?? 'DRAFT';
  const payment = PAYMENT_MAP[dto.paymentStatus] ?? 'UNPAID';
  const orderStatus = dto.status ?? dto.orderStatus ?? '';

  // Derive a display-friendly order status
  let resolvedOrderStatus = dto.orderStatus;
  if (orderStatus === 'Delivered' || fulfillment === 'COMPLETED') resolvedOrderStatus = 'PAID';
  else if (payment === 'PAID') resolvedOrderStatus = 'PAID';
  else if (payment === 'PARTIAL') resolvedOrderStatus = 'PARTIALLY_PAID';

  return {
    id: dto.id,
    orderNumber: dto.orderNumber ?? '',
    orderSource: SOURCE_MAP[dto.orderSource] ?? 'WALK_IN',
    fulfillmentStatus: fulfillment,
    paymentStatus: payment,
    customerName: dto.customerName ?? '',
    recipientName: dto.recipientName ?? undefined,
    deliveryDate: dto.deliveryDate,
    totalAmount: dto.totalAmount ?? 0,
    isPriceEditable: false,
    items: dto.items ?? [],
    totals: dto.totals ?? {
      subtotal: dto.totalAmount ?? 0,
      taxTotal: 0,
      discountTotal: 0,
      orderDiscountAmount: 0,
      grandTotal: dto.totalAmount ?? 0,
      totalCost: 0,
      marginPercent: 0,
      marginWarning: false,
      itemCount: dto.itemCount ?? 0,
      lineCount: dto.itemCount ?? 0,
      taxBreakdown: [],
    },
    inventoryStatus: deriveInventoryStatus(dto),
    createdAt: dto.orderDate ?? dto.createdAt ?? new Date().toISOString(),
    updatedAt: dto.updatedAt ?? dto.orderDate ?? new Date().toISOString(),
    ...(dto.deliveryPriority && { deliveryPriority: dto.deliveryPriority }),
    ...(dto.orderType && { orderType: dto.orderType }),
    ...(resolvedOrderStatus && { orderStatus: resolvedOrderStatus }),
  };
}

export const OrderProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(orderReducer, initialState);
  const [loading, setLoading] = React.useState(true);

  // Reusable load function
  const loadOrders = useCallback(async () => {
    setLoading(true);
    try {
      const result = await searchOrders({ PageSize: 200 });
      const rawOrders = result?.items ?? (Array.isArray(result) ? result : []);
      const orders = rawOrders.map(mapApiOrderToOrder);
      dispatch({ type: 'LOAD_ORDERS', orders });
    } catch (err) {
      console.error('Failed to load orders:', err);
    } finally {
      setLoading(false);
    }
  }, []);

  // Load orders from API on mount
  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

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
        refreshOrders: loadOrders,
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
