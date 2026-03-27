/**
 * POSPaymentDrawerV2.tsx — Payment Drawer using POSContext
 * 
 * Features:
 * - Automatic open/close based on lifecycle
 * - Split payment support
 * - Billing info management
 * - Auto-reset after completion
 */
import React, { useState, useCallback, useEffect, useMemo } from 'react';
import {
  Close as CloseIcon,
  CurrencyRupee as CashIcon,
  CreditCard as CardIcon,
  QrCode as UpiIcon,
  AccountBalanceWallet as StoreCreditIcon,
  CardGiftcard as GiftCardIcon,
  Delete as DeleteIcon,
  CheckCircle as CheckIcon,
} from '@mui/icons-material';
import { Drawer } from '@mui/material';
import { usePOS } from './POSContext';
import type { POSPaymentMethod, POSPaymentEntry, POSBillingInfo } from './POSTypes';
import { formatCurrency } from '../../core/i18n';
import { createOrder } from '../../api/order.api';
import { searchCustomers } from '../../api/customer.api';
import { getCrmCustomer360 } from '../../api/crm.api';

interface CustomerSuggestion {
  id: string;
  name: string;
  phone: string;
  email?: string;
}

const normalizePhone = (phone: string) => phone.replace(/[^\d+]/g, '');

const formatLastOrderDate = (value?: string) => {
  if (!value) return 'No previous orders';
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) return 'No previous orders';
  return parsed.toLocaleDateString();
};

const PAYMENT_METHODS: { method: POSPaymentMethod; label: string; icon: React.ReactElement }[] = [
  { method: 'CASH', label: 'Cash', icon: <CashIcon /> },
  { method: 'CARD', label: 'Card', icon: <CardIcon /> },
  { method: 'UPI', label: 'UPI', icon: <UpiIcon /> },
  { method: 'STORE_CREDIT', label: 'Credit', icon: <StoreCreditIcon /> },
  { method: 'GIFT_CARD', label: 'Gift Card', icon: <GiftCardIcon /> },
];

const POSPaymentDrawerV2: React.FC = () => {
  const {
    state,
    cancelPayment,
    addPayment,
    removePayment,
    setBillingInfo,
    setCustomer,
    completeTransaction,
    paidAmount,
    remainingAmount,
    isFullyPaid,
  } = usePOS();

  const isOpen = state.lifecycle === 'payment';
  const grandTotal = state.totals.grandTotal;

  // Local form state
  const [selectedMethod, setSelectedMethod] = useState<POSPaymentMethod>('CASH');
  const [inputAmount, setInputAmount] = useState('');
  const [localBilling, setLocalBilling] = useState<POSBillingInfo>({
    name: '',
    email: '',
    phone: '',
  });
  const [customerSuggestions, setCustomerSuggestions] = useState<CustomerSuggestion[]>([]);
  const [activeSuggestField, setActiveSuggestField] = useState<'name' | 'phone' | null>(null);
  const [isSearchingCustomers, setIsSearchingCustomers] = useState(false);

  // Initialize billing from customer when drawer opens
  useEffect(() => {
    if (isOpen && state.customer) {
      setLocalBilling({
        name: state.customer.name || '',
        email: state.customer.email || '',
        phone: state.customer.phone || '',
      });
    }
    if (isOpen) {
      // Default to remaining amount
      setInputAmount(remainingAmount.toFixed(2));
    }
  }, [isOpen, state.customer, remainingAmount]);

  // Dynamic autosuggest while typing in name/phone fields.
  useEffect(() => {
    if (!isOpen || !activeSuggestField) return;

    const query = (activeSuggestField === 'phone' ? (localBilling.phone ?? '') : localBilling.name).trim();
    if (query.length < 2) {
      setCustomerSuggestions([]);
      return;
    }

    let cancelled = false;
    const timer = setTimeout(async () => {
      setIsSearchingCustomers(true);
      try {
        const data = await searchCustomers({ Query: query, PageSize: 20 });
        const items = Array.isArray(data) ? data : data?.items ?? [];
        if (cancelled) return;
        setCustomerSuggestions(
          items
            .filter((customer: CustomerSuggestion) => !!(customer?.name || customer?.phone))
            .map((customer: CustomerSuggestion) => ({
              id: customer.id,
              name: customer.name || '',
              phone: customer.phone || '',
              email: customer.email || '',
            })),
        );
      } catch {
        if (!cancelled) setCustomerSuggestions([]);
      } finally {
        if (!cancelled) setIsSearchingCustomers(false);
      }
    }, 250);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [isOpen, activeSuggestField, localBilling.name, localBilling.phone]);

  useEffect(() => {
    if (isOpen) return;
    setCustomerSuggestions([]);
    setActiveSuggestField(null);
    setIsSearchingCustomers(false);
  }, [isOpen]);

  // Auto-match customer when suggestions load (handles datalist selection timing gap)
  useEffect(() => {
    if (!isOpen || !customerSuggestions.length) return;

    const name = localBilling.name.trim();
    const phone = normalizePhone(localBilling.phone ?? '');

    const match =
      customerSuggestions.find((c) => c.name.trim().toLowerCase() === name.toLowerCase()) ??
      (phone ? customerSuggestions.find((c) => normalizePhone(c.phone || '') === phone) : undefined);

    if (match && match.id !== state.customer?.id) {
      enrichCustomerFromMatch(match.id, match);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [customerSuggestions]);

  // Update context billing when local changes
  useEffect(() => {
    if (isOpen && (localBilling.name || localBilling.email)) {
      setBillingInfo(localBilling);
    }
  }, [localBilling, setBillingInfo, isOpen]);

  const handleAddPayment = useCallback(() => {
    const amount = parseFloat(inputAmount);
    if (isNaN(amount) || amount <= 0) return;

    // Cap at remaining
    const actualAmount = Math.min(amount, remainingAmount);
    if (actualAmount <= 0) return;

    const newPayment: POSPaymentEntry = {
      id: `pay_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      method: selectedMethod,
      amount: actualAmount,
    };

    addPayment(newPayment);
    setInputAmount('');
  }, [inputAmount, selectedMethod, remainingAmount, addPayment]);

  const handleQuickAmount = useCallback((amount: number) => {
    setInputAmount(amount.toFixed(2));
  }, []);

  const enrichCustomerFromMatch = useCallback(async (matchId: string, fallback: CustomerSuggestion) => {
    // Only fetch if not already set to this customer
    if (state.customer?.id === matchId) return;
    try {
      const data = await getCrmCustomer360(matchId);
      if (data?.customer) {
        setCustomer({
          id: data.customer.id,
          tenantId: (data.customer as any).tenantId ?? '',
          name: data.customer.name,
          phone: data.customer.phone ?? '',
          email: data.customer.email ?? '',
          preferredAddress: (data.customer as any).preferredAddress ?? '',
          createdAt: (data.customer as any).createdAt ?? '',
          tags: data.customer.tags ?? [],
          lifetimeValue: data.customer.lifetimeValue ?? 0,
          totalOrders: data.customer.totalOrders ?? 0,
          averageOrderValue: data.customer.averageOrderValue ?? 0,
          referralCount: data.customer.referralCount ?? 0,
          loyaltyPoints: data.customer.loyaltyPoints ?? 0,
          loyaltyTier: data.customer.loyaltyTier ?? '',
          loyaltyPointsEarned: data.customer.loyaltyPointsEarned ?? 0,
          loyaltyPointsRedeemed: data.customer.loyaltyPointsRedeemed ?? 0,
          totalProfit: data.customer.totalProfit ?? 0,
          profitMargin: data.customer.profitMargin ?? 0,
          marketingConsent: data.customer.marketingConsent ?? false,
          lastOrderDate: data.customer.lastOrderDate,
          notes: (data.customer as any).notes,
        });
      }
    } catch {
      // Non-critical — silently ignore
    }
  }, [state.customer?.id, setCustomer]);

  const handleNameChange = useCallback((name: string) => {
    setLocalBilling((prev) => {
      const next = { ...prev, name };
      const match = customerSuggestions.find(
        (customer) => customer.name.trim().toLowerCase() === name.trim().toLowerCase(),
      );
      if (!match) return next;
      enrichCustomerFromMatch(match.id, match);
      return {
        ...next,
        phone: next.phone || match.phone || '',
        email: next.email || match.email || '',
      };
    });
  }, [customerSuggestions, enrichCustomerFromMatch]);

  const handlePhoneChange = useCallback((phone: string) => {
    setLocalBilling((prev) => {
      const next = { ...prev, phone };
      const normalized = normalizePhone(phone);
      if (!normalized) return next;
      const match = customerSuggestions.find((customer) => {
        const candidate = normalizePhone(customer.phone || '');
        return candidate && candidate === normalized;
      });
      if (!match) return next;
      enrichCustomerFromMatch(match.id, match);
      return {
        ...next,
        name: next.name || match.name || '',
        email: next.email || match.email || '',
      };
    });
  }, [customerSuggestions, enrichCustomerFromMatch]);

  const handleComplete = useCallback(async () => {
    const canComplete = isFullyPaid || (state.orderIntent === 'PICKUP_LATER' && paidAmount > 0);
    if (!canComplete) return;

    try {
      console.log('FINAL ORDER PAYLOAD', {
        locationId: state.session.locationId,
        customerId: state.customer?.id,
        payments: state.payments,
      });

      await createOrder({
        customerId: state.customer?.id ?? null,
        deliveryDate: state.deliveryDetails?.deliveryDate ?? null,
        deliveryAddress: state.deliveryDetails?.address ?? null,
        recipientName: state.billingInfo?.name ?? null,
        recipientPhone: state.billingInfo?.phone ?? null,
        cardMessage: null,
        deliveryPriority: 'STANDARD',
        timeSlot: state.deliveryDetails?.deliveryTimeSlot ?? state.pickupDetails?.pickupTimeSlot ?? null,
        orderSource: 'POS',
        orderIntent: state.orderIntent ?? 'TAKE_NOW',
        pickupDate: state.pickupDetails?.pickupDate ?? null,
        pickupTimeSlot: state.pickupDetails?.pickupTimeSlot ?? null,
        deliveryFee: 0,
        discountAmount: state.totals.discountTotal,
        internalNotes: null,
        items: state.items.map(item => ({
          productId: item.productId,
          productName: item.productName,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          unit: 'pcs',
        })),
        payments: state.payments.map((payment) => ({
          method: payment.method,
          amount: payment.amount,
        })),
      });
    } catch (err) {
      console.error('Failed to create order:', err);
    }

    completeTransaction();
  }, [isFullyPaid, paidAmount, state, completeTransaction]);

  const handleClose = useCallback(() => {
    cancelPayment();
    setInputAmount('');
  }, [cancelPayment]);

  const getMethodIcon = (method: POSPaymentMethod) => {
    return PAYMENT_METHODS.find((m) => m.method === method)?.icon || <CashIcon />;
  };

  // Check if billing is required
  const requiresBilling = state.payments.some((p) => p.method === 'CARD');
  const isBillingValid =
    !requiresBilling || (localBilling.name.trim() && localBilling.email.trim());

  // Pickup orders can be completed with partial payment (deposit)
  const isPickup = state.orderIntent === 'PICKUP_LATER';
  const canCompletePayment = isFullyPaid || (isPickup && paidAmount > 0);

  return (
    <Drawer
      anchor="right"
      open={isOpen}
      onClose={handleClose}
      PaperProps={{
        sx: { width: 420, maxWidth: '100vw' },
      }}
    >
      <div className="h-full flex flex-col bg-gray-50">
        {/* Header */}
        <header className="px-6 py-4 bg-white border-b border-gray-200 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">Payment</h2>
            {isPickup && (
              <span className="inline-flex items-center gap-1 mt-1 px-2 py-0.5 bg-amber-100 text-amber-700 text-[10px] font-bold rounded-full uppercase">
                📅 Pickup — Deposit OK
              </span>
            )}
          </div>
          <button
            onClick={handleClose}
            className="w-8 h-8 flex items-center justify-center text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <CloseIcon className="w-5 h-5" />
          </button>
        </header>

        {/* Content */}
        <div className="flex-1 overflow-y-auto">
          {/* Amount Summary */}
          <div className="px-6 py-4 bg-white border-b border-gray-200">
            <div className="grid grid-cols-3 gap-4 text-center">
              <div>
                <span className="block text-xs text-gray-500 uppercase tracking-wide">
                  Total
                </span>
                <span className="text-lg font-bold text-gray-900">
                  {formatCurrency(grandTotal)}
                </span>
              </div>
              <div>
                <span className="block text-xs text-gray-500 uppercase tracking-wide">
                  Paid
                </span>
                <span className="text-lg font-bold text-green-600">
                  {formatCurrency(paidAmount)}
                </span>
              </div>
              <div>
                <span className="block text-xs text-gray-500 uppercase tracking-wide">
                  Remaining
                </span>
                <span
                  className={`text-lg font-bold ${
                    remainingAmount > 0 ? 'text-amber-600' : 'text-gray-400'
                  }`}
                >
                  {formatCurrency(remainingAmount)}
                </span>
              </div>
            </div>

            {isFullyPaid && (
              <div className="mt-3 flex items-center justify-center gap-2 text-green-600">
                <CheckIcon className="w-5 h-5" />
                <span className="text-sm font-medium">Fully paid</span>
              </div>
            )}
          </div>

          {/* Payment Entries */}
          {state.payments.length > 0 && (
            <div className="px-6 py-4 bg-white border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-700 mb-3">Payments</h3>
              <ul className="space-y-2">
                {state.payments.map((payment) => (
                  <li
                    key={payment.id}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div className="flex items-center gap-3">
                      <span className="w-8 h-8 flex items-center justify-center bg-white rounded-lg border border-gray-200 text-gray-600">
                        {getMethodIcon(payment.method)}
                      </span>
                      <span className="text-sm font-medium text-gray-900">
                        {PAYMENT_METHODS.find((m) => m.method === payment.method)?.label}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-semibold text-gray-900">
                        {formatCurrency(payment.amount)}
                      </span>
                      <button
                        onClick={() => removePayment(payment.id)}
                        className="w-6 h-6 flex items-center justify-center text-gray-400 hover:text-red-500 rounded transition-colors"
                      >
                        <DeleteIcon className="w-4 h-4" />
                      </button>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {/* Add Payment Section */}
          {remainingAmount > 0 && (
            <div className="px-6 py-4 bg-white border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-700 mb-3">Add Payment</h3>

              {/* Payment Method Buttons */}
              <div className="grid grid-cols-5 gap-2 mb-4">
                {PAYMENT_METHODS.map(({ method, label, icon }) => (
                  <button
                    key={method}
                    onClick={() => setSelectedMethod(method)}
                    className={`
                      flex flex-col items-center justify-center py-2 px-1 rounded-lg border transition-colors
                      ${
                        selectedMethod === method
                          ? 'border-purple-500 bg-purple-50 text-purple-700'
                          : 'border-gray-200 bg-white text-gray-600 hover:border-gray-300'
                      }
                    `}
                  >
                    <span className="w-5 h-5 mb-1">{icon}</span>
                    <span className="text-[10px] font-medium">{label}</span>
                  </button>
                ))}
              </div>

              {/* Amount Input */}
              <div className="flex gap-2 mb-3">
                <div className="flex-1 relative">
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">
                    Rs
                  </span>
                  <input
                    type="number"
                    value={inputAmount}
                    onChange={(e) => setInputAmount(e.target.value)}
                    placeholder="0.00"
                    step="0.01"
                    min="0"
                    className="w-full h-10 pl-7 pr-3 text-sm border border-gray-200 rounded-lg
                               focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                  />
                </div>
                <button
                  onClick={handleAddPayment}
                  disabled={!inputAmount || parseFloat(inputAmount) <= 0}
                  className="px-4 h-10 bg-purple-600 text-white text-sm font-medium rounded-lg
                             hover:bg-purple-700 transition-colors
                             disabled:bg-gray-300 disabled:cursor-not-allowed"
                >
                  Add
                </button>
              </div>

              {/* Quick Amounts */}
              <div className="flex flex-wrap gap-2">
                <button
                  onClick={() => handleQuickAmount(remainingAmount)}
                  className="px-3 py-1.5 text-xs font-medium text-purple-700 bg-purple-50 border border-purple-200 rounded-lg hover:bg-purple-100 transition-colors"
                >
                  Exact ({formatCurrency(remainingAmount)})
                </button>
                {[10, 20, 50, 100].map((amount) => (
                  <button
                    key={amount}
                    onClick={() => handleQuickAmount(amount)}
                    className="px-3 py-1.5 text-xs font-medium text-gray-600 bg-gray-50 border border-gray-200 rounded-lg hover:bg-gray-100 transition-colors"
                  >
                    Rs {amount}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Customer 360 Summary — always visible when a customer is selected */}
          {state.customer && (
            <div className="px-6 py-3 bg-white border-b border-gray-200">
              <div className="rounded-lg border border-purple-100 bg-purple-50 px-3 py-2">
                <p className="text-xs text-gray-700">
                  <span className="font-semibold">Customer:</span> {state.customer.name}
                  {state.customer.phone ? ` (${state.customer.phone})` : ''}
                </p>
                <p className="mt-0.5 text-xs text-gray-600">
                  Total Orders: <span className="font-medium text-gray-800">{state.customer.totalOrders ?? 0}</span>
                  {' • '}
                  Last Order: <span className="font-medium text-gray-800">{formatLastOrderDate(state.customer.lastOrderDate)}</span>
                  {state.customer.loyaltyPoints ? (
                    <>
                      {' • '}
                      Points: <span className="font-medium text-gray-800">{state.customer.loyaltyPoints}</span>
                    </>
                  ) : null}
                </p>
              </div>
            </div>
          )}

          {/* Billing Info */}
          {(requiresBilling || isFullyPaid) && (
            <div className="px-6 py-4 bg-white border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-700 mb-3">
                Billing Info
                {requiresBilling && <span className="text-red-500 ml-1">*</span>}
              </h3>

              <div className="space-y-3">
                {/* Name field with custom suggestion dropdown */}
                <div className="relative">
                  <input
                    type="text"
                    autoComplete="new-password"
                    value={localBilling.name}
                    onFocus={() => setActiveSuggestField('name')}
                    onBlur={() => setTimeout(() => setActiveSuggestField(null), 150)}
                    onChange={(e) => { setActiveSuggestField('name'); handleNameChange(e.target.value); }}
                    placeholder="Customer Name"
                    className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                               focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                  />
                  {activeSuggestField === 'name' && customerSuggestions.length > 0 && (
                    <ul className="absolute z-50 left-0 right-0 top-11 bg-white border border-gray-200 rounded-lg shadow-lg max-h-48 overflow-y-auto">
                      {customerSuggestions.map((c) => (
                        <li
                          key={c.id}
                          onMouseDown={() => {
                            handleNameChange(c.name);
                            setLocalBilling((prev) => ({
                              ...prev,
                              name: c.name,
                              phone: prev.phone || c.phone || '',
                              email: prev.email || c.email || '',
                            }));
                            enrichCustomerFromMatch(c.id, c);
                            setActiveSuggestField(null);
                          }}
                          className="flex items-center justify-between px-3 py-2 text-sm cursor-pointer hover:bg-purple-50"
                        >
                          <span className="font-medium text-gray-800">{c.name}</span>
                          <span className="text-xs text-gray-500">{c.phone}</span>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>

                {/* Phone field with custom suggestion dropdown */}
                <div className="relative">
                  <input
                    type="text"
                    inputMode="numeric"
                    autoComplete="new-password"
                    value={localBilling.phone || ''}
                    onFocus={() => setActiveSuggestField('phone')}
                    onBlur={() => setTimeout(() => setActiveSuggestField(null), 150)}
                    onChange={(e) => { setActiveSuggestField('phone'); handlePhoneChange(e.target.value); }}
                    placeholder="Phone"
                    className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                               focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                  />
                  {activeSuggestField === 'phone' && customerSuggestions.length > 0 && (
                    <ul className="absolute z-50 left-0 right-0 top-11 bg-white border border-gray-200 rounded-lg shadow-lg max-h-48 overflow-y-auto">
                      {customerSuggestions.map((c) => (
                        <li
                          key={c.id}
                          onMouseDown={() => {
                            handlePhoneChange(c.phone);
                            setLocalBilling((prev) => ({
                              ...prev,
                              phone: c.phone,
                              name: prev.name || c.name || '',
                              email: prev.email || c.email || '',
                            }));
                            enrichCustomerFromMatch(c.id, c);
                            setActiveSuggestField(null);
                          }}
                          className="flex items-center justify-between px-3 py-2 text-sm cursor-pointer hover:bg-purple-50"
                        >
                          <span className="font-medium text-gray-800">{c.phone}</span>
                          <span className="text-xs text-gray-500">{c.name}</span>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>

                <input
                  type="text"
                  autoComplete="new-password"
                  value={localBilling.email}
                  onChange={(e) =>
                    setLocalBilling((prev) => ({ ...prev, email: e.target.value }))
                  }
                  placeholder="Email (optional)"
                  className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
                {isSearchingCustomers && (
                  <p className="text-[11px] text-gray-500">Searching customers...</p>
                )}
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <footer className="px-6 py-4 bg-white border-t border-gray-200 space-y-2">
          {canCompletePayment ? (
            <button
              onClick={handleComplete}
              disabled={!isBillingValid}
              className={`w-full py-3 font-semibold rounded-lg transition-colors
                         disabled:bg-gray-300 disabled:cursor-not-allowed ${
                           isFullyPaid
                             ? 'bg-purple-600 text-white hover:bg-purple-700'
                             : 'bg-amber-500 text-white hover:bg-amber-600'
                         }`}
            >
              {isFullyPaid
                ? 'Complete Payment'
                : `Save as Reserved (Deposit ${formatCurrency(paidAmount)})`}
            </button>
          ) : (
            <button
              disabled
              className="w-full py-3 bg-gray-200 text-gray-500 font-semibold rounded-lg cursor-not-allowed"
            >
              {isPickup ? 'Add deposit to reserve' : 'Add payment to continue'}
            </button>
          )}
          <button
            onClick={handleClose}
            className="w-full py-2 text-sm text-gray-600 hover:text-gray-800 transition-colors"
          >
            Cancel & Return to Cart
          </button>
        </footer>
      </div>
    </Drawer>
  );
};

export default POSPaymentDrawerV2;
