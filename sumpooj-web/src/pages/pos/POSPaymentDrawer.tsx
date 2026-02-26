/**
 * POSPaymentDrawer.tsx — Slide-in payment drawer for FloraPrice POS
 * Supports partial and split payments with billing info
 */
import React, { useState, useMemo, useEffect, useCallback } from 'react';
import {
  Close as CloseIcon,
  AttachMoney as CashIcon,
  CreditCard as CardIcon,
  QrCode as UpiIcon,
  AccountBalanceWallet as StoreCreditIcon,
  CardGiftcard as GiftCardIcon,
  Delete as DeleteIcon,
  CheckCircle as CheckIcon,
} from '@mui/icons-material';
import { Drawer } from '@mui/material';
import type { POSPaymentMethod, POSPaymentEntry, POSBillingInfo } from './POSTypes';
import type { POSCustomer } from './POSCustomerTypes';

interface POSPaymentDrawerProps {
  open: boolean;
  onClose: () => void;
  grandTotal: number;
  selectedCustomer: POSCustomer | null;
  onComplete: (payments: POSPaymentEntry[], billingInfo: POSBillingInfo) => void;
  onPartialSave?: (payments: POSPaymentEntry[], billingInfo: POSBillingInfo, paidAmount: number, remainingAmount: number) => void;
  initialMethod?: 'cash' | 'card' | 'split' | 'more';
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
  onComplete,
  onPartialSave,
  initialMethod = 'split',
}) => {
  const [payments, setPayments] = useState<POSPaymentEntry[]>([]);
  const [selectedMethod, setSelectedMethod] = useState<POSPaymentMethod>('CASH');
  const [inputAmount, setInputAmount] = useState('');
  const [billingInfo, setBillingInfo] = useState<POSBillingInfo>({
    name: '',
    email: '',
    phone: '',
  });

  // Auto-fill billing from customer
  useEffect(() => {
    if (open && selectedCustomer) {
      setBillingInfo({
        name: selectedCustomer.name || '',
        email: selectedCustomer.email || '',
        phone: selectedCustomer.phone || '',
      });
    }
  }, [open, selectedCustomer]);

  // Reset state when opening
  useEffect(() => {
    if (open) {
      setPayments([]);
      setInputAmount('');
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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(amount);
  };

  const paidTotal = useMemo(
    () => payments.reduce((sum, p) => sum + p.amount, 0),
    [payments]
  );

  const remaining = useMemo(
    () => Math.max(0, Math.round((grandTotal - paidTotal) * 100) / 100),
    [grandTotal, paidTotal]
  );

  const isFullyPaid = remaining === 0 && payments.length > 0;
  const hasPartialPayment = payments.length > 0 && remaining > 0;

  // Check if billing is required (for card/split or email receipt)
  const requiresBilling = payments.some(p => p.method === 'CARD') || hasPartialPayment;
  const isBillingValid = !requiresBilling || (billingInfo.name.trim() && billingInfo.email.trim());

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
      onComplete(payments, billingInfo);
    }
  }, [isFullyPaid, isBillingValid, payments, billingInfo, onComplete]);

  const handlePartialSave = useCallback(() => {
    if (hasPartialPayment && isBillingValid && onPartialSave) {
      onPartialSave(payments, billingInfo, paidTotal, remaining);
    }
  }, [hasPartialPayment, isBillingValid, payments, billingInfo, paidTotal, remaining, onPartialSave]);

  const getMethodIcon = (method: POSPaymentMethod) => {
    return PAYMENT_METHODS.find(m => m.method === method)?.icon || <CashIcon />;
  };

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

            {isFullyPaid && (
              <div className="mt-3 flex items-center justify-center gap-2 text-green-600">
                <CheckIcon className="w-5 h-5" />
                <span className="text-sm font-medium">Fully paid</span>
              </div>
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
                  <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400">$</span>
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
                    ${amount}
                  </button>
                ))}
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
                <input
                  type="text"
                  value={billingInfo.name}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, name: e.target.value }))}
                  placeholder="Name"
                  className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
                <input
                  type="email"
                  value={billingInfo.email}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, email: e.target.value }))}
                  placeholder="Email"
                  className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
                <input
                  type="tel"
                  value={billingInfo.phone || ''}
                  onChange={(e) => setBillingInfo(prev => ({ ...prev, phone: e.target.value }))}
                  placeholder="Phone (optional)"
                  className="w-full h-10 px-3 text-sm border border-gray-200 rounded-lg
                             focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
                />
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <footer className="px-6 py-4 bg-white border-t border-gray-200 space-y-2">
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
        </footer>
      </div>
    </Drawer>
  );
};

export default POSPaymentDrawer;
