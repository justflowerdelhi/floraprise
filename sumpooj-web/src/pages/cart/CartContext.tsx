/**
 * CartContext.tsx — Reusable Cart Engine (state + actions)
 *
 * Supports all order sources. FIFO batch auto-selection.
 * When isPriceEditable = false (FTD / BloomNation), discount editing is blocked.
 */
import React, { createContext, useContext, useReducer, useCallback, type ReactNode } from 'react';
import type { CartItem, CartSummary, Product, OrderSource, HeldOrder, BatchAllocation } from '../orders/OrderTypes';
import { calcLineItem, calcCartSummary, nextLineId } from './CartUtils';
import { isExternalSource } from '../orders/OrderUtils';

// ─── State ──────────────────────────────────────────────────

interface CartState {
  items: CartItem[];
  totals: CartSummary;
  orderSource: OrderSource;
  isPriceEditable: boolean;
  heldOrders: HeldOrder[];
}

const EMPTY_TOTALS: CartSummary = {
  subtotal: 0, taxTotal: 0, discountTotal: 0, grandTotal: 0,
  totalCost: 0, marginPercent: 0, marginWarning: false, itemCount: 0, lineCount: 0,
};

const initialState: CartState = {
  items: [],
  totals: EMPTY_TOTALS,
  orderSource: 'WALK_IN',
  isPriceEditable: true,
  heldOrders: [],
};

// ─── Actions ────────────────────────────────────────────────

type CartAction =
  | { type: 'ADD_PRODUCT'; product: Product; qty: number }
  | { type: 'REMOVE_ITEM'; lineId: string }
  | { type: 'UPDATE_QTY'; lineId: string; qty: number; product: Product }
  | { type: 'SET_DISCOUNT'; lineId: string; discountPercent: number; product: Product }
  | { type: 'OVERRIDE_BATCH'; lineId: string; allocations: BatchAllocation[]; product: Product }
  | { type: 'CLEAR_CART' }
  | { type: 'SET_ORDER_SOURCE'; source: OrderSource }
  | { type: 'HOLD_ORDER'; label: string; customerName?: string }
  | { type: 'RESUME_ORDER'; heldId: string }
  | { type: 'REMOVE_HELD'; heldId: string }
  | { type: 'LOAD_ITEMS'; items: CartItem[] };

function cartReducer(state: CartState, action: CartAction): CartState {
  const recalc = (items: CartItem[]): CartState => ({
    ...state,
    items,
    totals: calcCartSummary(items),
  });

  switch (action.type) {
    case 'ADD_PRODUCT': {
      // If product already in cart, increment qty
      const existing = state.items.find((i) => i.productId === action.product.id);
      if (existing) {
        const newQty = existing.quantity + action.qty;
        const updated = calcLineItem(action.product, newQty, existing.discountPercent);
        updated.id = existing.id; // preserve line ID
        const items = state.items.map((i) => (i.id === existing.id ? updated : i));
        return recalc(items);
      }
      const item = calcLineItem(action.product, action.qty, 0);
      return recalc([...state.items, item]);
    }

    case 'REMOVE_ITEM': {
      return recalc(state.items.filter((i) => i.id !== action.lineId));
    }

    case 'UPDATE_QTY': {
      if (action.qty <= 0) {
        return recalc(state.items.filter((i) => i.id !== action.lineId));
      }
      const items = state.items.map((i) => {
        if (i.id !== action.lineId) return i;
        const updated = calcLineItem(action.product, action.qty, i.discountPercent);
        updated.id = i.id;
        return updated;
      });
      return recalc(items);
    }

    case 'SET_DISCOUNT': {
      if (!state.isPriceEditable) return state; // FTD lock
      const items = state.items.map((i) => {
        if (i.id !== action.lineId) return i;
        const updated = calcLineItem(action.product, i.quantity, action.discountPercent);
        updated.id = i.id;
        return updated;
      });
      return recalc(items);
    }

    case 'OVERRIDE_BATCH': {
      const items = state.items.map((i) => {
        if (i.id !== action.lineId) return i;
        const updated = calcLineItem(action.product, i.quantity, i.discountPercent, action.allocations);
        updated.id = i.id;
        return updated;
      });
      return recalc(items);
    }

    case 'CLEAR_CART':
      return { ...state, items: [], totals: EMPTY_TOTALS };

    case 'SET_ORDER_SOURCE': {
      const external = isExternalSource(action.source);
      return {
        ...state,
        orderSource: action.source,
        isPriceEditable: !external,
      };
    }

    case 'HOLD_ORDER': {
      const held: HeldOrder = {
        id: `hold_${Date.now()}`,
        label: action.label || `Order #${state.heldOrders.length + 1}`,
        items: [...state.items],
        totals: { ...state.totals },
        heldAt: new Date().toISOString(),
        customerName: action.customerName,
      };
      return {
        ...state,
        items: [],
        totals: EMPTY_TOTALS,
        heldOrders: [...state.heldOrders, held],
      };
    }

    case 'RESUME_ORDER': {
      const held = state.heldOrders.find((h) => h.id === action.heldId);
      if (!held) return state;
      return {
        ...state,
        items: held.items,
        totals: held.totals,
        heldOrders: state.heldOrders.filter((h) => h.id !== action.heldId),
      };
    }

    case 'REMOVE_HELD':
      return {
        ...state,
        heldOrders: state.heldOrders.filter((h) => h.id !== action.heldId),
      };

    case 'LOAD_ITEMS': {
      // Assign new line IDs to avoid collisions
      const items = action.items.map((i) => ({ ...i, id: nextLineId() }));
      return recalc(items);
    }

    default:
      return state;
  }
}

// ─── Context ────────────────────────────────────────────────

interface CartContextValue {
  state: CartState;
  addProduct: (product: Product, qty?: number) => void;
  removeItem: (lineId: string) => void;
  updateQty: (lineId: string, qty: number, product: Product) => void;
  setDiscount: (lineId: string, discountPercent: number, product: Product) => void;
  overrideBatch: (lineId: string, allocations: BatchAllocation[], product: Product) => void;
  clearCart: () => void;
  setOrderSource: (source: OrderSource) => void;
  holdOrder: (label: string, customerName?: string) => void;
  resumeOrder: (heldId: string) => void;
  removeHeld: (heldId: string) => void;
  loadItems: (items: CartItem[]) => void;
}

const CartContext = createContext<CartContextValue | null>(null);

export const CartProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [state, dispatch] = useReducer(cartReducer, initialState);

  const addProduct    = useCallback((product: Product, qty = 1)    => dispatch({ type: 'ADD_PRODUCT', product, qty }), []);
  const removeItem    = useCallback((lineId: string)               => dispatch({ type: 'REMOVE_ITEM', lineId }), []);
  const updateQty     = useCallback((lineId: string, qty: number, product: Product) => dispatch({ type: 'UPDATE_QTY', lineId, qty, product }), []);
  const setDiscount   = useCallback((lineId: string, discountPercent: number, product: Product) => dispatch({ type: 'SET_DISCOUNT', lineId, discountPercent, product }), []);
  const overrideBatch = useCallback((lineId: string, allocations: BatchAllocation[], product: Product) => dispatch({ type: 'OVERRIDE_BATCH', lineId, allocations, product }), []);
  const clearCart      = useCallback(()                             => dispatch({ type: 'CLEAR_CART' }), []);
  const setOrderSource = useCallback((source: OrderSource)         => dispatch({ type: 'SET_ORDER_SOURCE', source }), []);
  const holdOrder      = useCallback((label: string, customerName?: string) => dispatch({ type: 'HOLD_ORDER', label, customerName }), []);
  const resumeOrder    = useCallback((heldId: string)              => dispatch({ type: 'RESUME_ORDER', heldId }), []);
  const removeHeld     = useCallback((heldId: string)              => dispatch({ type: 'REMOVE_HELD', heldId }), []);
  const loadItems      = useCallback((items: CartItem[])           => dispatch({ type: 'LOAD_ITEMS', items }), []);

  return (
    <CartContext.Provider value={{
      state, addProduct, removeItem, updateQty, setDiscount,
      overrideBatch, clearCart, setOrderSource, holdOrder,
      resumeOrder, removeHeld, loadItems,
    }}>
      {children}
    </CartContext.Provider>
  );
};

export const useCart = (): CartContextValue => {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart must be used within CartProvider');
  return ctx;
};
