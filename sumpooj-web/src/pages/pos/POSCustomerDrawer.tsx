/**
 * POSCustomerDrawer.tsx — Slide-in customer selector drawer
 *
 * Features:
 *   - Phone-first auto-search (live API search while typing)
 *   - Customer details: last order date, lifetime spend, notes
 *   - "Repeat Last Order" button loads items from the customer's most recent order
 *   - Walk-in still allowed (phone captured later)
 */
import React, { useState, useMemo, useCallback, useEffect, useRef } from 'react';
import {
  Close as CloseIcon,
  Search as SearchIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Check as CheckIcon,
  Replay as RepeatIcon,
  StickyNote2 as NoteIcon,
  CalendarToday as CalendarIcon,
  AttachMoney as MoneyIcon,
} from '@mui/icons-material';
import { Drawer, CircularProgress } from '@mui/material';
import type { POSCustomer } from './POSCustomerTypes';
import type { Product } from '../orders/OrderTypes';
import { searchCustomers } from '../../api/customer.api';
import { getOrdersByCustomer } from '../../api/order.api';
import { formatCurrency } from '../../core/i18n';

// ─── Helpers ──────────────────────────────────────────────

const fmt = (n: number) => formatCurrency(n);

const fmtDate = (d: string | undefined | null) => {
  if (!d) return '—';
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

const isPhoneLike = (q: string) => /^\+?[\d\s\-().]{3,}$/.test(q.trim());

// ─── Types ────────────────────────────────────────────────

interface LastOrder {
  id: string;
  orderNumber: string;
  createdAt: string;
  totalAmount: number;
  items: { productId: string; productName: string; quantity: number; unitPrice: number }[];
}

interface POSCustomerDrawerProps {
  open: boolean;
  onClose: () => void;
  customers: POSCustomer[];
  selectedCustomer: POSCustomer | null;
  onSelectCustomer: (customer: POSCustomer | null) => void;
  /** Available POS products — used to resolve "Repeat Last Order" */
  products: Product[];
  /** Add product to cart — called by repeat-last-order */
  onAddProduct: (product: Product, qty?: number) => void;
}

const POSCustomerDrawer: React.FC<POSCustomerDrawerProps> = ({
  open,
  onClose,
  customers,
  selectedCustomer,
  onSelectCustomer,
  products,
  onAddProduct,
}) => {
  const [searchQuery, setSearchQuery] = useState('');

  // API search state
  const [apiResults, setApiResults] = useState<POSCustomer[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const searchTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const lastApiQueryRef = useRef('');

  // Last-order data for selected customer
  const [lastOrder, setLastOrder] = useState<LastOrder | null>(null);
  const [loadingLastOrder, setLoadingLastOrder] = useState(false);
  const [repeatBusy, setRepeatBusy] = useState(false);

  // ─── Local client-side filter (fallback for no-API match) ─

  const localFiltered = useMemo(() => {
    if (!searchQuery.trim()) return customers.slice(0, 50);
    const q = searchQuery.toLowerCase().replace(/\s/g, '');
    return customers
      .filter(
        (c) =>
          c.name.toLowerCase().includes(q) ||
          c.phone.replace(/[\s\-()]/g, '').includes(q) ||
          (c.email && c.email.toLowerCase().includes(q)),
      )
      .slice(0, 50);
  }, [customers, searchQuery]);

  // Merge: prefer API results when a query is active, supplement with local
  const filteredCustomers = useMemo(() => {
    if (!searchQuery.trim()) return localFiltered;
    if (apiResults.length > 0) {
      // Merge: API first, then local (deduplicated)
      const ids = new Set(apiResults.map((c) => c.id));
      const extra = localFiltered.filter((c) => !ids.has(c.id));
      return [...apiResults, ...extra].slice(0, 50);
    }
    return localFiltered;
  }, [searchQuery, apiResults, localFiltered]);

  // ─── Auto-search via API (debounced) ─────────────────────

  useEffect(() => {
    if (!open) return;
    const q = searchQuery.trim();
    if (q.length < 2) {
      setApiResults([]);
      lastApiQueryRef.current = '';
      return;
    }
    // Only hit API when query changes meaningfully
    if (q === lastApiQueryRef.current) return;

    if (searchTimerRef.current) clearTimeout(searchTimerRef.current);
    searchTimerRef.current = setTimeout(async () => {
      lastApiQueryRef.current = q;
      setIsSearching(true);
      try {
        const data = await searchCustomers({ Query: q, PageSize: 20 });
        const items: POSCustomer[] = data?.items ?? data ?? [];
        setApiResults(items);
      } catch {
        // Silently fall back to local results
        setApiResults([]);
      } finally {
        setIsSearching(false);
      }
    }, 300);

    return () => {
      if (searchTimerRef.current) clearTimeout(searchTimerRef.current);
    };
  }, [searchQuery, open]);

  // ─── Fetch last order when a customer is selected ─────────

  useEffect(() => {
    if (!selectedCustomer) {
      setLastOrder(null);
      return;
    }
    let cancelled = false;
    setLoadingLastOrder(true);
    setLastOrder(null);

    getOrdersByCustomer(selectedCustomer.id)
      .then((orders) => {
        if (cancelled) return;
        const arr = Array.isArray(orders) ? orders : orders?.items ?? [];
        // Sort by createdAt desc, take first
        const sorted = arr.sort(
          (a: { createdAt: string }, b: { createdAt: string }) =>
            new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime(),
        );
        if (sorted.length > 0) {
          const o = sorted[0];
          setLastOrder({
            id: o.id,
            orderNumber: o.orderNumber ?? '',
            createdAt: o.createdAt,
            totalAmount: o.totalAmount ?? o.totals?.grandTotal ?? 0,
            items: (o.items ?? []).map((i: { productId: string; productName: string; quantity: number; unitPrice: number }) => ({
              productId: i.productId,
              productName: i.productName,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
            })),
          });
        }
      })
      .catch(() => {
        // Silently ignore
      })
      .finally(() => {
        if (!cancelled) setLoadingLastOrder(false);
      });

    return () => {
      cancelled = true;
    };
  }, [selectedCustomer?.id]);

  // ─── Handlers ─────────────────────────────────────────────

  const handleSelect = useCallback(
    (customer: POSCustomer) => {
      onSelectCustomer(customer);
    },
    [onSelectCustomer],
  );

  const handleWalkIn = useCallback(() => {
    onSelectCustomer(null);
    onClose();
  }, [onSelectCustomer, onClose]);

  const handleRepeatLastOrder = useCallback(() => {
    if (!lastOrder || lastOrder.items.length === 0) return;
    setRepeatBusy(true);
    let added = 0;
    for (const orderItem of lastOrder.items) {
      const product = products.find((p) => p.id === orderItem.productId);
      if (product) {
        onAddProduct(product, orderItem.quantity);
        added++;
      }
    }
    setRepeatBusy(false);
    if (added > 0) onClose();
  }, [lastOrder, products, onAddProduct, onClose]);

  // Reset state when drawer closes
  useEffect(() => {
    if (!open) {
      setSearchQuery('');
      setApiResults([]);
      setIsSearching(false);
      lastApiQueryRef.current = '';
    }
  }, [open]);

  // ─── Render ────────────────────────────────────────────────

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      PaperProps={{
        sx: { width: 400, maxWidth: '100vw' },
      }}
    >
      <div className="h-full flex flex-col bg-white">
        {/* Header */}
        <header className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Select Customer</h2>
            <p className="text-[11px] text-gray-400 mt-0.5">Phone required before payment</p>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <CloseIcon className="w-5 h-5" />
          </button>
        </header>

        {/* Search — phone-first */}
        <div className="px-4 py-3 border-b border-gray-200">
          <div className="relative">
            {isSearching ? (
              <CircularProgress
                size={16}
                className="absolute left-3 top-1/2 -translate-y-1/2"
                sx={{ color: '#9333ea' }}
              />
            ) : (
              <PhoneIcon className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-4 h-4" />
            )}
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Type phone number to find customer…"
              className="w-full h-10 pl-10 pr-4 text-sm border border-gray-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              autoFocus
            />
            {searchQuery && isPhoneLike(searchQuery) && (
              <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[10px] text-purple-500 font-medium">
                Auto-searching…
              </span>
            )}
          </div>
        </div>

        {/* Selected customer detail card (inline, compact) */}
        {selectedCustomer && (
          <div className="px-4 py-3 border-b border-gray-200 bg-purple-50/50">
            <div className="flex items-center gap-3 mb-2">
              <span className="w-9 h-9 flex items-center justify-center bg-purple-600 rounded-full text-white font-semibold text-xs shrink-0">
                {selectedCustomer.name.charAt(0).toUpperCase()}
              </span>
              <div className="flex-1 min-w-0">
                <span className="block text-sm font-semibold text-gray-900 truncate">
                  {selectedCustomer.name}
                </span>
                <span className="block text-xs text-gray-500">{selectedCustomer.phone}</span>
              </div>
              <button
                onClick={() => onSelectCustomer(null)}
                className="text-[10px] text-red-500 hover:text-red-700 font-medium"
              >
                Clear
              </button>
            </div>

            {/* Stats row */}
            <div className="grid grid-cols-3 gap-2 text-center">
              <div className="bg-white rounded-lg px-2 py-1.5 border border-gray-100">
                <CalendarIcon sx={{ fontSize: 13, color: '#9ca3af' }} />
                <p className="text-[10px] text-gray-400 mt-0.5">Last Order</p>
                <p className="text-xs font-semibold text-gray-800">
                  {fmtDate(selectedCustomer.lastOrderDate)}
                </p>
              </div>
              <div className="bg-white rounded-lg px-2 py-1.5 border border-gray-100">
                <MoneyIcon sx={{ fontSize: 13, color: '#9ca3af' }} />
                <p className="text-[10px] text-gray-400 mt-0.5">Lifetime</p>
                <p className="text-xs font-semibold text-gray-800">
                  {fmt(selectedCustomer.lifetimeValue || 0)}
                </p>
              </div>
              <div className="bg-white rounded-lg px-2 py-1.5 border border-gray-100">
                <PersonIcon sx={{ fontSize: 13, color: '#9ca3af' }} />
                <p className="text-[10px] text-gray-400 mt-0.5">Orders</p>
                <p className="text-xs font-semibold text-gray-800">
                  {selectedCustomer.totalOrders ?? 0}
                </p>
              </div>
            </div>

            {/* Notes */}
            {selectedCustomer.notes && (
              <div className="mt-2 flex items-start gap-1.5 bg-amber-50 border border-amber-200 rounded-lg px-2.5 py-1.5">
                <NoteIcon sx={{ fontSize: 14, color: '#d97706', mt: '1px' }} />
                <p className="text-xs text-amber-800 leading-relaxed line-clamp-2">
                  {selectedCustomer.notes}
                </p>
              </div>
            )}

            {/* Repeat Last Order */}
            {loadingLastOrder ? (
              <div className="mt-2 flex items-center gap-2 text-xs text-gray-400">
                <CircularProgress size={12} sx={{ color: '#9ca3af' }} />
                Loading order history…
              </div>
            ) : lastOrder && lastOrder.items.length > 0 ? (
              <button
                onClick={handleRepeatLastOrder}
                disabled={repeatBusy}
                className="mt-2 w-full flex items-center justify-center gap-2 h-8 bg-purple-600 text-white
                           text-xs font-semibold rounded-lg hover:bg-purple-700 transition-colors
                           disabled:opacity-50 disabled:cursor-wait"
              >
                <RepeatIcon sx={{ fontSize: 14 }} />
                Repeat Last Order
                <span className="text-purple-200 font-normal">
                  #{lastOrder.orderNumber} • {fmt(lastOrder.totalAmount)}
                </span>
              </button>
            ) : null}
          </div>
        )}

        {/* Walk-in Option */}
        {!selectedCustomer && (
          <div className="px-4 py-2 border-b border-gray-200">
            <button
              onClick={handleWalkIn}
              className="w-full flex items-center gap-3 p-2.5 rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors"
            >
              <span className="w-8 h-8 flex items-center justify-center bg-gray-100 rounded-full text-gray-500">
                <PersonIcon sx={{ fontSize: 18 }} />
              </span>
              <div className="flex-1 text-left">
                <span className="block text-sm font-medium text-gray-900">Walk-in Customer</span>
                <span className="block text-[10px] text-amber-600">⚠ Phone required before payment</span>
              </div>
            </button>
          </div>
        )}

        {/* Customer List */}
        <div className="flex-1 overflow-y-auto">
          {filteredCustomers.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center px-4">
              <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mb-3">
                <PersonIcon className="w-6 h-6 text-gray-400" />
              </div>
              <p className="text-gray-500 text-sm">No customers found</p>
              <p className="text-gray-400 text-xs mt-1">
                {isPhoneLike(searchQuery)
                  ? 'No matches for this phone number'
                  : 'Try a different search term'}
              </p>
            </div>
          ) : (
            <ul className="divide-y divide-gray-100">
              {filteredCustomers.map((customer) => {
                const isSelected = selectedCustomer?.id === customer.id;
                return (
                  <li key={customer.id}>
                    <button
                      onClick={() => handleSelect(customer)}
                      className={`
                        w-full flex items-center gap-3 px-4 py-3 text-left transition-colors
                        ${isSelected ? 'bg-purple-50' : 'hover:bg-gray-50'}
                      `}
                    >
                      {/* Avatar */}
                      <span className="w-9 h-9 flex items-center justify-center bg-purple-100 rounded-full text-purple-600 font-semibold text-xs shrink-0">
                        {customer.name.charAt(0).toUpperCase()}
                      </span>

                      {/* Info */}
                      <div className="flex-1 min-w-0">
                        <span className="block text-sm font-medium text-gray-900 truncate">
                          {customer.name}
                        </span>
                        <div className="flex items-center gap-3 mt-0.5">
                          <span className="flex items-center gap-1 text-xs text-gray-500">
                            <PhoneIcon sx={{ fontSize: 12 }} />
                            {customer.phone}
                          </span>
                          {customer.email && (
                            <span className="flex items-center gap-1 text-xs text-gray-500 truncate">
                              <EmailIcon sx={{ fontSize: 12 }} />
                              {customer.email}
                            </span>
                          )}
                        </div>
                        {/* Compact stats */}
                        {(customer.totalOrders > 0 || customer.lifetimeValue > 0) && (
                          <span className="text-[10px] text-gray-400 mt-0.5 block">
                            {customer.totalOrders} orders • {fmt(customer.lifetimeValue || 0)}
                          </span>
                        )}
                      </div>

                      {/* Selected indicator */}
                      {isSelected && (
                        <CheckIcon className="w-5 h-5 text-purple-600 shrink-0" />
                      )}
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </div>
    </Drawer>
  );
};

export default POSCustomerDrawer;
