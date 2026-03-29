/**
 * POSPaymentDrawer.tsx — Slide-in payment drawer for FloraPrice POS
 * Supports partial and split payments with billing info
 */
import React, { useState, useMemo, useEffect, useCallback } from 'react';
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
import type { POSPaymentMethod, POSPaymentEntry, POSBillingInfo, OrderIntent } from './POSTypes';
import type { POSCustomer } from './POSCustomerTypes';
import { formatCurrency } from '../../core/i18n';
import { searchCustomers } from '../../api/customer.api';
import { getCrmCustomer360 } from '../../api/crm.api';
import { useTenant } from '../../core/tenant/TenantContext';
import { getPosDiscountRules } from '../../core/settings/discountRules';
import {
  getPosReceiptPrintMode,
  setPosReceiptPrintMode,
  type PosReceiptPrintMode,
} from './utils/posReceiptPrint';

interface POSPaymentDrawerProps {
  open: boolean;
  onClose: () => void;
  grandTotal: number;
  selectedCustomer: POSCustomer | null;
  customers: POSCustomer[];
  onComplete: (payments: POSPaymentEntry[], billingInfo: POSBillingInfo, selectedCustomerId?: string | null) => void;
  onPartialSave?: (payments: POSPaymentEntry[], billingInfo: POSBillingInfo, paidAmount: number, remainingAmount: number, selectedCustomerId?: string | null) => void;
  initialMethod?: 'cash' | 'card' | 'split' | 'more';
  orderIntent?: OrderIntent;
}

const PAYMENT_METHODS: { method: POSPaymentMethod; label: string; icon: React.ReactElement }[] = [
  { method: 'CASH', label: 'Cash', icon: <CashIcon /> },
  { method: 'CARD', label: 'Card', icon: <CardIcon /> },
  { method: 'UPI', label: 'UPI', icon: <UpiIcon /> },
  { method: 'STORE_CREDIT', label: 'Credit', icon: <StoreCreditIcon /> },
  { method: 'GIFT_CARD', label: 'Gift Card', icon: <GiftCardIcon /> },
];

const POSPaymentDrawer: React.FC<POSPaymentDrawerProps> = ({
  open,
  onClose,
  grandTotal,
  selectedCustomer,
  customers,
  onComplete,
  onPartialSave,
  initialMethod = 'split',
  orderIntent = 'TAKE_NOW',
}) => {
  const { tenant } = useTenant();
  const [payments, setPayments] = useState<POSPaymentEntry[]>([]);
  const [selectedMethod, setSelectedMethod] = useState<POSPaymentMethod>('CASH');
  const [inputAmount, setInputAmount] = useState('');
  const [discountType, setDiscountType] = useState<'AMOUNT' | 'PERCENT'>('AMOUNT');
  const [discountInput, setDiscountInput] = useState('');
  const [billingInfo, setBillingInfo] = useState<POSBillingInfo>({
    name: '',
    email: '',
    phone: '',
  });

  const discountRules = useMemo(() => getPosDiscountRules(tenant.id), [tenant.id]);
  const MAX_DISCOUNT_PERCENT = discountRules.maxDiscountPercent;
  const MAX_DISCOUNT_AMOUNT = discountRules.maxDiscountAmount;

  // Live customer search state
  interface CustomerSuggestion { id: string; name: string; phone: string; email?: string; }
  const [customerSuggestions, setCustomerSuggestions] = useState<CustomerSuggestion[]>([]);
  const [activeSuggestField, setActiveSuggestField] = useState<'name' | 'phone' | null>(null);
  const [isSearchingCustomers, setIsSearchingCustomers] = useState(false);
  const [receiptPrintMode, setReceiptPrintModeState] = useState<PosReceiptPrintMode>(() => getPosReceiptPrintMode());
  const [matchedCustomer360, setMatchedCustomer360] = useState<{
    totalOrders: number;
    lastOrderDate?: string;
    lastOrderValue?: number;
    totalValue?: number;
    loyaltyPoints?: number;
  } | null>(null);
  const [matchedCustomerId, setMatchedCustomerId] = useState<string | null>(null);

  // Auto-fill billing from pre-selected customer
  useEffect(() => {
    if (open && selectedCustomer) {
      setBillingInfo({
        name: selectedCustomer.name || '',
        email: selectedCustomer.email || '',
        phone: selectedCustomer.phone || '',
        deliveryAddress: selectedCustomer.preferredAddress || '',
      });
      setMatchedCustomer360({
        totalOrders: selectedCustomer.totalOrders ?? 0,
        lastOrderDate: selectedCustomer.lastOrderDate,
        totalValue: selectedCustomer.lifetimeValue ?? 0,
        loyaltyPoints: selectedCustomer.loyaltyPoints,
      });
      setMatchedCustomerId(selectedCustomer.id);
    }
    if (!open) {
      setCustomerSuggestions([]);
      setActiveSuggestField(null);
      setMatchedCustomer360(null);
      setMatchedCustomerId(null);
    }
  }, [open, selectedCustomer]);

  // Debounced live search
  useEffect(() => {
    if (!open || !activeSuggestField) return;
    const query = (activeSuggestField === 'phone' ? (billingInfo.phone ?? '') : billingInfo.name).trim();
    if (query.length < 2) { setCustomerSuggestions([]); return; }

    let cancelled = false;
    const timer = setTimeout(async () => {
      setIsSearchingCustomers(true);
      try {
        const data = await searchCustomers({ Query: query, PageSize: 20 });
        const items: CustomerSuggestion[] = (Array.isArray(data) ? data : data?.items ?? [])
          .filter((c: any) => !!(c?.name || c?.phone))
          .map((c: any) => ({ id: c.id, name: c.name || '', phone: c.phone || '', email: c.email || '' }));
        if (!cancelled) setCustomerSuggestions(items);
      } catch { if (!cancelled) setCustomerSuggestions([]); }
      finally { if (!cancelled) setIsSearchingCustomers(false); }
    }, 250);
    return () => { cancelled = true; clearTimeout(timer); };
  }, [open, activeSuggestField, billingInfo.name, billingInfo.phone]);

  const enrichFromCustomer = useCallback(async (suggestion: CustomerSuggestion) => {
    setBillingInfo((prev) => ({
      ...prev,
      name: suggestion.name || prev.name,
      phone: suggestion.phone || prev.phone,
      email: suggestion.email || prev.email || '',
    }));
    try {
      const data = await getCrmCustomer360(suggestion.id);
      if (data?.customer) {
        const latestOrder = [...(data.orders ?? [])]
          .sort((a, b) => new Date(b.orderDate).getTime() - new Date(a.orderDate).getTime())[0];

        setMatchedCustomerId(data.customer.id);
        setMatchedCustomer360({
          totalOrders: data.customer.totalOrders ?? 0,
          lastOrderDate: data.customer.lastOrderDate,
          lastOrderValue: latestOrder?.total,
          totalValue: data.customer.lifetimeValue ?? 0,
          loyaltyPoints: data.customer.loyaltyPoints,
        });
      }
    } catch { /* non-critical */ }
  }, []);

  const handleBillingNameChange = useCallback((name: string) => {
    setBillingInfo((prev) => ({ ...prev, name }));
    setMatchedCustomerId(null);
    setMatchedCustomer360(null);
  }, []);

  const handleBillingPhoneChange = useCallback((phone: string) => {
    setBillingInfo((prev) => ({ ...prev, phone }));
    setMatchedCustomerId(null);
    setMatchedCustomer360(null);
  }, []);

  // Reset state when opening
  useEffect(() => {
    if (open) {
      setPayments([]);
      setInputAmount('');
      setDiscountType('AMOUNT');
      setDiscountInput('');
      // Map initial method
      if (initialMethod === 'cash') {
        setSelectedMethod('CASH');
        // Auto-add full cash payment
        setInputAmount(grandTotal.toFixed(2));
      } else if (initialMethod === 'card') {
        setSelectedMethod('CARD');
        setInputAmount(grandTotal.toFixed(2));
      } else {
        setSelectedMethod('CASH');
      }
    }
  }, [open, initialMethod, grandTotal]);

  const paidTotal = useMemo(
    () => payments.reduce((sum, p) => sum + p.amount, 0),
    [payments]
  );

  const parsedDiscountInput = useMemo(() => {
    const value = Number(discountInput);
    return Number.isFinite(value) && value > 0 ? value : 0;
  }, [discountInput]);

  const maxByPercentAmount = useMemo(
    () => (grandTotal * Math.max(0, MAX_DISCOUNT_PERCENT)) / 100,
    [grandTotal, MAX_DISCOUNT_PERCENT]
  );

  const requestedDiscountAmount = useMemo(() => {
    if (parsedDiscountInput <= 0) return 0;
    if (discountType === 'PERCENT') {
      return (grandTotal * parsedDiscountInput) / 100;
    }
    return parsedDiscountInput;
  }, [discountType, parsedDiscountInput, grandTotal]);

  const appliedDiscountAmount = useMemo(() => {
    if (requestedDiscountAmount <= 0) return 0;
    return Math.min(
      requestedDiscountAmount,
      Math.max(0, MAX_DISCOUNT_AMOUNT),
      Math.max(0, maxByPercentAmount),
      grandTotal
    );
  }, [requestedDiscountAmount, MAX_DISCOUNT_AMOUNT, maxByPercentAmount, grandTotal]);

  const discountedTotal = useMemo(
    () => Math.max(0, grandTotal - appliedDiscountAmount),
    [grandTotal, appliedDiscountAmount]
  );

  const discountLimitMessage = useMemo(() => {
    if (parsedDiscountInput <= 0) return '';
    if (Math.abs(requestedDiscountAmount - appliedDiscountAmount) < 0.001) return '';
    return `Discount capped at ${formatCurrency(Math.min(MAX_DISCOUNT_AMOUNT, maxByPercentAmount))} (${MAX_DISCOUNT_PERCENT}% max).`;
  }, [parsedDiscountInput, requestedDiscountAmount, appliedDiscountAmount, MAX_DISCOUNT_AMOUNT, maxByPercentAmount, MAX_DISCOUNT_PERCENT]);

  const remaining = useMemo(
    () => Math.max(0, Math.round((discountedTotal - paidTotal) * 100) / 100),
    [discountedTotal, paidTotal]
  );

  const isFullyPaid = remaining === 0 && payments.length > 0;
  const hasPartialPayment = payments.length > 0 && remaining > 0;

  // Billing name & phone are always required
  const isDelivery = orderIntent === 'DELIVERY';
  const isPickup = orderIntent === 'PICKUP_LATER';
  const isBillingValid = billingInfo.name.trim() !== '' && (billingInfo.phone ?? '').trim() !== ''
    && (!isDelivery || ((billingInfo.deliveryAddress ?? '').trim() !== '' && (billingInfo.deliveryPincode ?? '').trim() !== '' && (billingInfo.recipientName ?? '').trim() !== '' && (billingInfo.recipientPhone ?? '').trim() !== ''));

  const handleAddPayment = useCallback(() => {
    const amount = parseFloat(inputAmount);
    if (isNaN(amount) || amount <= 0) return;

    // Cap at remaining
    const actualAmount = Math.min(amount, remaining);
    if (actualAmount <= 0) return;

    const newPayment: POSPaymentEntry = {
      id: `pay_${Date.now()}_${Math.random().toString(36).substr(2, 4)}`,
      method: selectedMethod,
      amount: actualAmount,
    };

    setPayments((prev) => [...prev, newPayment]);
    setInputAmount('');
  }, [inputAmount, selectedMethod, remaining]);

  const handleRemovePayment = useCallback((paymentId: string) => {
    setPayments((prev) => prev.filter((p) => p.id !== paymentId));
  }, []);

  const handleQuickAmount = useCallback((amount: number) => {
    setInputAmount(amount.toFixed(2));
  }, []);

  const handleComplete = useCallback(() => {
    if (isFullyPaid && isBillingValid) {
      onComplete(
        payments,
        { ...billingInfo, discountAmount: appliedDiscountAmount },
        matchedCustomerId ?? selectedCustomer?.id ?? null
      );
    }
  }, [isFullyPaid, isBillingValid, payments, billingInfo, onComplete, matchedCustomerId, selectedCustomer, appliedDiscountAmount]);

  const handlePartialSave = useCallback(() => {
    if (hasPartialPayment && isBillingValid && onPartialSave) {
      onPartialSave(
        payments,
        { ...billingInfo, discountAmount: appliedDiscountAmount },
        paidTotal,
        remaining,
        matchedCustomerId ?? selectedCustomer?.id ?? null
      );
    }
  }, [hasPartialPayment, isBillingValid, payments, billingInfo, paidTotal, remaining, onPartialSave, matchedCustomerId, selectedCustomer, appliedDiscountAmount]);

  const getMethodIcon = (method: POSPaymentMethod) => {
    return PAYMENT_METHODS.find(m => m.method === method)?.icon || <CashIcon />;
  };

  const handleReceiptPrintModeChange = useCallback((mode: PosReceiptPrintMode) => {
    setReceiptPrintModeState(mode);
    setPosReceiptPrintMode(mode);
  }, []);

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      PaperProps={{
        sx: { width: 420, maxWidth: '100vw' },
      }}
    >
      <div className="h-full flex flex-col bg-gray-50">
        {/* Header */}
        <header className="px-6 py-4 bg-white border-b border-gray-200 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Payment</h2>
          <button
            onClick={onClose}
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
                <span className="block text-xs text-gray-500 uppercase tracking-wide">Total</span>
                <span className="text-lg font-bold text-gray-900">{formatCurrency(grandTotal)}</span>
              </div>
              <div>
                <span className="block text-xs text-gray-500 uppercase tracking-wide">Paid</span>
                <span className="text-lg font-bold text-green-600">{formatCurrency(paidTotal)}</span>
              </div>
              <div>
                <span className="block text-xs text-gray-500 uppercase tracking-wide">Remaining</span>
                <span className={`text-lg font-bold ${remaining > 0 ? 'text-amber-600' : 'text-gray-400'}`}>
                  {formatCurrency(remaining)}
                </span>
              </div>
            </div>

            <div className="mt-3 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 text-xs text-gray-700">
              <div className="flex items-center justify-between">
                <span>Discount Applied</span>
                <span className="font-medium text-green-700">-{formatCurrency(appliedDiscountAmount)}</span>
              </div>
              <div className="mt-1 flex items-center justify-between">
                <span>Payable Total</span>
                <span className="font-semibold text-gray-900">{formatCurrency(discountedTotal)}</span>
              </div>
            </div>

            {isFullyPaid && (
              <div className="mt-3 flex items-center justify-center gap-2 text-green-600">
                <CheckIcon className="w-5 h-5" />
                <span className="text-sm font-medium">Fully paid</span>
              </div>
            )}
          </div>

          {/* Discount Section */}
          <div className="px-6 py-4 bg-white border-b border-gray-200">
            <h3 className="text-sm font-medium text-gray-700 mb-3">Discount (Optional)</h3>
            <div className="grid grid-cols-2 gap-2 mb-3">
              <button
                type="button"
                onClick={() => setDiscountType('AMOUNT')}
                className={`h-9 rounded-lg border text-sm font-medium transition-colors ${discountType === 'AMOUNT' ? 'border-purple-500 bg-purple-50 text-purple-700' : 'border-gray-200 bg-white text-gray-600 hover:border-gray-300'}`}
              >
                Amount (Rs)
              </button>
              <button
                type="button"
                onClick={() => setDiscountType('PERCENT')}
                className={`h-9 rounded-lg border text-sm font-medium transition-colors ${discountType === 'PERCENT' ? 'border-purple-500 bg-purple-50 text-purple-700' : 'border-gray-200 bg-white text-gray-600 hover:border-gray-300'}`}
              >
                Percentage (%)
              </button>
            </div>

            <div className="relative">
              <input
                type="number"
                min="0"
                step="0.01"
                value={discountInput}
                onChange={(e) => setDiscountInput(e.target.value)}
                placeholder={discountType === 'AMOUNT' ? 'Enter discount amount' : 'Enter discount percent'}
                className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              />
            </div>

            <p className="mt-2 text-[11px] text-gray-500">
              Max discount: {MAX_DISCOUNT_PERCENT}% or {formatCurrency(MAX_DISCOUNT_AMOUNT)}, whichever is lower.
            </p>
            {discountLimitMessage && (
              <p className="mt-1 text-[11px] text-amber-600">{discountLimitMessage}</p>
            )}
          </div>

          {/* Payment Entries */}
          {payments.length > 0 && (
            <div className="px-6 py-4 bg-white border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-700 mb-3">Payments</h3>
              <ul className="space-y-2">
                {payments.map((payment) => (
                  <li
                    key={payment.id}
                    className="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                  >
                    <div className="flex items-center gap-3">
                      <span className="w-8 h-8 flex items-center justify-center bg-white rounded-lg border border-gray-200 text-gray-600">
                        {getMethodIcon(payment.method)}
                      </span>
                      <span className="text-sm font-medium text-gray-900">
                        {PAYMENT_METHODS.find(m => m.method === payment.method)?.label}
                      </span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="text-sm font-semibold text-gray-900">
                        {formatCurrency(payment.amount)}
                      </span>
                      <button
                        onClick={() => handleRemovePayment(payment.id)}
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
          {remaining > 0 && (
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
                      ${selectedMethod === method
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
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">Rs</span>
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
                  onClick={() => handleQuickAmount(remaining)}
                  className="px-3 py-1.5 text-xs font-medium text-purple-700 bg-purple-50 border border-purple-200 rounded-lg hover:bg-purple-100 transition-colors"
                >
                  Exact ({formatCurrency(remaining)})
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

          {/* Billing Info — always shown */}
          <div className="px-6 py-4 bg-white border-b border-gray-200">
            <h3 className="text-sm font-medium text-gray-700 mb-3">
              Billing Info <span className="text-red-500 ml-1">*</span>
            </h3>
            <div className="space-y-3">
              {/* Customer 360 info — shows after match */}
              {matchedCustomer360 && (
                <div className="rounded-lg border border-purple-100 bg-purple-50 px-3 py-2">
                  <p className="text-xs text-gray-600">
                    No. of Orders: <span className="font-medium text-gray-800">{matchedCustomer360.totalOrders}</span>
                    {' • '}
                    Total Value: <span className="font-medium text-gray-800">{formatCurrency(matchedCustomer360.totalValue ?? 0)}</span>
                    {' • '}
                    Last Order: <span className="font-medium text-gray-800">
                      {matchedCustomer360.lastOrderDate
                        ? new Date(matchedCustomer360.lastOrderDate).toLocaleDateString()
                        : 'None'}
                    </span>
                    {' • '}
                    Last Order Value: <span className="font-medium text-gray-800">{formatCurrency(matchedCustomer360.lastOrderValue ?? 0)}</span>
                    {matchedCustomer360.loyaltyPoints ? (
                      <> {' • '}Points: <span className="font-medium text-gray-800">{matchedCustomer360.loyaltyPoints}</span></>
                    ) : null}
                  </p>
                </div>
              )}

              {/* Name — custom dropdown */}
              <div className="relative">
                <input
                  type="text"
                  autoComplete="new-password"
                  value={billingInfo.name}
                  onFocus={() => setActiveSuggestField('name')}
                  onBlur={() => setTimeout(() => setActiveSuggestField(null), 150)}
                  onChange={(e) => { setActiveSuggestField('name'); handleBillingNameChange(e.target.value); }}
                  placeholder="Customer Name *"
                  className={`w-full h-10 px-3 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent ${
                    !billingInfo.name.trim() ? 'border-red-300' : 'border-gray-200'
                  }`}
                />
                {activeSuggestField === 'name' && customerSuggestions.length > 0 && (
                  <ul className="absolute z-50 left-0 right-0 top-11 bg-white border border-gray-200 rounded-lg shadow-lg max-h-48 overflow-y-auto">
                    {customerSuggestions.map((c) => (
                      <li
                        key={c.id}
                        onMouseDown={() => { enrichFromCustomer(c); setActiveSuggestField(null); setCustomerSuggestions([]); }}
                        className="flex items-center justify-between px-3 py-2 text-sm cursor-pointer hover:bg-purple-50"
                      >
                        <span className="font-medium text-gray-800">{c.name}</span>
                        <span className="text-xs text-gray-500">{c.phone}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </div>

              {/* Phone — custom dropdown */}
              <div className="relative">
                <input
                  type="text"
                  inputMode="numeric"
                  autoComplete="new-password"
                  value={billingInfo.phone || ''}
                  onFocus={() => setActiveSuggestField('phone')}
                  onBlur={() => setTimeout(() => setActiveSuggestField(null), 150)}
                  onChange={(e) => { setActiveSuggestField('phone'); handleBillingPhoneChange(e.target.value); }}
                  placeholder="Mobile Number *"
                  className={`w-full h-10 px-3 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent ${
                    !(billingInfo.phone ?? '').trim() ? 'border-red-300' : 'border-gray-200'
                  }`}
                />
                {activeSuggestField === 'phone' && customerSuggestions.length > 0 && (
                  <ul className="absolute z-50 left-0 right-0 top-11 bg-white border border-gray-200 rounded-lg shadow-lg max-h-48 overflow-y-auto">
                    {customerSuggestions.map((c) => (
                      <li
                        key={c.id}
                        onMouseDown={() => { enrichFromCustomer(c); setActiveSuggestField(null); setCustomerSuggestions([]); }}
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
                value={billingInfo.email}
                onChange={(e) => setBillingInfo(prev => ({ ...prev, email: e.target.value }))}
                placeholder="Email (optional)"
                className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                           focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              />
              {isSearchingCustomers && (
                <p className="text-[11px] text-gray-500">Searching customers…</p>
              )}
            </div>
          </div>

          {/* Delivery Details — shown when intent is DELIVERY */}
          {isDelivery && (
            <div className="px-6 py-4 bg-white border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-700 mb-3">
                Delivery Details <span className="text-red-500 ml-1">*</span>
              </h3>
              <div className="space-y-3">
                <input
                  type="text"
                  value={billingInfo.recipientName || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, recipientName: e.target.value }))}
                  placeholder="Recipient Name *"
                  className={`w-full h-10 px-3 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent ${
                    !(billingInfo.recipientName ?? '').trim() ? 'border-red-300' : 'border-gray-200'
                  }`}
                />
                <input
                  type="tel"
                  value={billingInfo.recipientPhone || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, recipientPhone: e.target.value }))}
                  placeholder="Recipient Phone *"
                  className={`w-full h-10 px-3 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent ${
                    !(billingInfo.recipientPhone ?? '').trim() ? 'border-red-300' : 'border-gray-200'
                  }`}
                />
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={10}
                  value={billingInfo.deliveryPincode || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, deliveryPincode: e.target.value }))}
                  placeholder="ZIP / Pincode *"
                  className={`w-full h-10 px-3 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent ${
                    !(billingInfo.deliveryPincode ?? '').trim() ? 'border-red-300' : 'border-gray-200'
                  }`}
                />
                <textarea
                  value={billingInfo.deliveryAddress || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, deliveryAddress: e.target.value }))}
                  placeholder="Delivery Address *"
                  rows={2}
                  className={`w-full px-3 py-2 text-sm border rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent ${
                    !(billingInfo.deliveryAddress ?? '').trim() ? 'border-red-300' : 'border-gray-200'
                  }`}
                />
                <div className="grid grid-cols-2 gap-3">
                  <input
                    type="date"
                    value={billingInfo.deliveryDate || ''}
                    onChange={(e) => setBillingInfo(prev => ({ ...prev, deliveryDate: e.target.value }))}
                    className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                               focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                  />
                  <select
                    value={billingInfo.timeSlot || ''}
                    onChange={(e) => setBillingInfo(prev => ({ ...prev, timeSlot: e.target.value }))}
                    className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                               focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                  >
                    <option value="">Time Slot</option>
                    <option value="9AM-12PM">9 AM – 12 PM</option>
                    <option value="12PM-3PM">12 PM – 3 PM</option>
                    <option value="3PM-6PM">3 PM – 6 PM</option>
                    <option value="6PM-9PM">6 PM – 9 PM</option>
                  </select>
                </div>
                <input
                  type="text"
                  value={billingInfo.cardMessage || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, cardMessage: e.target.value }))}
                  placeholder="Card Message (optional)"
                  className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
              </div>
            </div>
          )}

          {/* Pickup Details — shown when intent is PICKUP_LATER */}
          {isPickup && (
            <div className="px-6 py-4 bg-white border-b border-gray-200">
              <h3 className="text-sm font-medium text-gray-700 mb-3">
                Pickup Details
              </h3>
              <div className="grid grid-cols-2 gap-3">
                <input
                  type="date"
                  value={billingInfo.pickupDate || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, pickupDate: e.target.value }))}
                  className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
                <select
                  value={billingInfo.pickupTimeSlot || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, pickupTimeSlot: e.target.value }))}
                  className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                >
                  <option value="">Time Slot</option>
                  <option value="9AM-12PM">9 AM – 12 PM</option>
                  <option value="12PM-3PM">12 PM – 3 PM</option>
                  <option value="3PM-6PM">3 PM – 6 PM</option>
                  <option value="6PM-9PM">6 PM – 9 PM</option>
                </select>
              </div>
            </div>
          )}

          {/* Action buttons — inside scroll so they appear right after the form */}
          <div className="px-6 py-4 bg-white border-t border-gray-200 space-y-2">
            <div className="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 mb-2">
              <label className="text-xs font-medium text-gray-700 block mb-1">Receipt Print</label>
              <select
                value={receiptPrintMode}
                onChange={(e) => handleReceiptPrintModeChange(e.target.value as PosReceiptPrintMode)}
                className="w-full h-9 px-2 text-sm border border-gray-300 rounded-md bg-white focus:outline-none focus:ring-2 focus:ring-purple-500"
              >
                <option value="AUTO">Auto Print</option>
                <option value="ASK">Ask Before Print</option>
                <option value="PDF">PDF Mode</option>
              </select>
            </div>

            {isFullyPaid ? (
              <button
                onClick={handleComplete}
                disabled={!isBillingValid}
                className="w-full py-3 bg-purple-600 text-white font-semibold rounded-lg
                           hover:bg-purple-700 transition-colors
                           disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Complete Payment
              </button>
            ) : hasPartialPayment && onPartialSave ? (
              <button
                onClick={handlePartialSave}
                disabled={!isBillingValid}
                className="w-full py-3 bg-amber-500 text-white font-semibold rounded-lg
                           hover:bg-amber-600 transition-colors
                           disabled:bg-gray-300 disabled:cursor-not-allowed"
              >
                Save with Balance ({formatCurrency(remaining)})
              </button>
            ) : (
              <button
                disabled
                className="w-full py-3 bg-gray-200 text-gray-500 font-semibold rounded-lg cursor-not-allowed"
              >
                Add payment to continue
              </button>
            )}
          </div>
        </div>
      </div>
    </Drawer>
  );
};

export default POSPaymentDrawer;
