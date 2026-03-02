/**
 * DetailsTab.tsx — Tab 3: Order Details (delivery / pickup / take-now)
 *
 * Shows the appropriate form based on the selected order intent:
 *  - TAKE_NOW   → simple confirmation, no extra fields
 *  - DELIVERY   → DeliveryDetailsForm (address, date, fee)
 *  - PICKUP_LATER → PickupDetailsForm (date, contact)
 *
 * Also shows an order summary sidebar so the operator can confirm items.
 */
import React from 'react';
import {
  Store as TakeNowIcon,
  LocalShipping as DeliveryIcon,
  ShoppingBag as PickupIcon,
  Check as CheckIcon,
  ErrorOutline as ErrorIcon,
} from '@mui/icons-material';
import DeliveryDetailsForm from './DeliveryDetailsForm';
import PickupDetailsForm from './PickupDetailsForm';
import { usePOS } from './POSContext';
import type { OrderIntent } from './POSTypes';
import { formatCurrency } from '../../core/i18n';

// ─── Props ──────────────────────────────────────────────────

interface DetailsTabProps {
  onNext: () => void;
  onBack: () => void;
}

// ─── Intent badge helper ────────────────────────────────────

const INTENT_META: Record<OrderIntent, { label: string; icon: React.ReactNode; color: string; bg: string }> = {
  TAKE_NOW: { label: 'Take Now', icon: <TakeNowIcon fontSize="small" />, color: 'text-purple-700', bg: 'bg-purple-100' },
  DELIVERY: { label: 'Delivery', icon: <DeliveryIcon fontSize="small" />, color: 'text-blue-700', bg: 'bg-blue-100' },
  PICKUP_LATER: { label: 'Pickup Later', icon: <PickupIcon fontSize="small" />, color: 'text-amber-700', bg: 'bg-amber-100' },
};

// ─── Component ──────────────────────────────────────────────

const DetailsTab: React.FC<DetailsTabProps> = ({ onNext, onBack }) => {
  const {
    state,
    setDeliveryDetails,
    setPickupDetails,
    intentErrors,
    canEditCart,
  } = usePOS();

  const intent = state.orderIntent;
  const meta = INTENT_META[intent];
  const isLocked = !canEditCart;
  const hasErrors = intentErrors.length > 0;



  return (
    <div className="h-full flex overflow-hidden">
      {/* ─── Left: Form ──────────────────────────────────── */}
      <div className="flex-1 overflow-y-auto bg-gray-50 p-6">
        {/* Header */}
        <div className="mb-6">
          <div className="flex items-center gap-2 mb-1">
            <span className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold ${meta.bg} ${meta.color}`}>
              {meta.icon}
              {meta.label}
            </span>
          </div>
          <h2 className="text-xl font-bold text-gray-900">Order Details</h2>
          <p className="text-sm text-gray-500 mt-1">
            {intent === 'TAKE_NOW' && 'No additional details needed. Proceed to payment.'}
            {intent === 'DELIVERY' && 'Enter delivery address, date, and fee.'}
            {intent === 'PICKUP_LATER' && 'Set the pickup date and contact info.'}
          </p>
        </div>

        {/* ─── TAKE_NOW ────────────────────────────────────── */}
        {intent === 'TAKE_NOW' && (
          <div className="flex flex-col items-center justify-center py-16 bg-white rounded-2xl border border-gray-200">
            <div className="w-16 h-16 rounded-full bg-green-100 flex items-center justify-center mb-4">
              <CheckIcon sx={{ fontSize: 32 }} className="text-green-600" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 mb-1">Ready for Payment</h3>
            <p className="text-sm text-gray-500">
              No delivery or pickup details are required for walk-in orders.
            </p>
          </div>
        )}

        {/* ─── DELIVERY form ───────────────────────────────── */}
        {intent === 'DELIVERY' && (
          <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
            <DeliveryDetailsForm
              value={state.deliveryDetails}
              onChange={setDeliveryDetails}
              disabled={isLocked}
              showErrors={hasErrors}
            />
          </div>
        )}

        {/* ─── PICKUP form ─────────────────────────────────── */}
        {intent === 'PICKUP_LATER' && (
          <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
            <PickupDetailsForm
              value={state.pickupDetails}
              onChange={setPickupDetails}
              disabled={isLocked}
              showErrors={hasErrors}
            />
          </div>
        )}

        {/* Validation errors */}
        {hasErrors && (
          <div className="mt-4 p-3 bg-red-50 border border-red-200 rounded-xl">
            {intentErrors.map((err, i) => (
              <div key={i} className="flex items-center gap-2 py-0.5">
                <ErrorIcon className="w-4 h-4 text-red-500 shrink-0" />
                <span className="text-sm text-red-600">{err}</span>
              </div>
            ))}
          </div>
        )}

        {/* Navigation */}
        <div className="flex items-center justify-between mt-8">
          <button
            onClick={onBack}
            className="px-6 py-2.5 border border-gray-300 text-gray-700 text-sm font-semibold rounded-xl
                       hover:bg-gray-50 transition-colors"
          >
            ← Back to Products
          </button>
          <button
            onClick={onNext}
            disabled={hasErrors}
            className="px-8 py-2.5 bg-purple-600 text-white text-sm font-semibold rounded-xl
                       hover:bg-purple-700 transition-colors shadow-sm
                       disabled:bg-gray-300 disabled:cursor-not-allowed disabled:shadow-none"
          >
            Continue to Payment →
          </button>
        </div>
      </div>

      {/* ─── Right: Order Summary ────────────────────────── */}
      <aside className="w-80 shrink-0 bg-white border-l border-gray-200 overflow-y-auto hidden lg:block">
        <div className="p-4 border-b border-gray-200">
          <h3 className="text-sm font-semibold text-gray-900">Order Summary</h3>
          <p className="text-xs text-gray-500 mt-0.5">
            {state.totals.itemCount} {state.totals.itemCount === 1 ? 'item' : 'items'}
          </p>
        </div>

        {/* Items */}
        <ul className="divide-y divide-gray-100">
          {state.items.map((item) => (
            <li key={item.id} className="px-4 py-3 flex items-start gap-2">
              <div className="flex-1 min-w-0">
                <p className="text-sm font-medium text-gray-900 truncate">{item.productName}</p>
                <p className="text-xs text-gray-500">
                  {item.quantity} × {formatCurrency(item.unitPrice)}
                </p>
              </div>
              <span className="text-sm font-semibold text-gray-900 shrink-0">
                {formatCurrency(item.lineTotal)}
              </span>
            </li>
          ))}
        </ul>

        {/* Totals */}
        <div className="p-4 border-t border-gray-200 space-y-1.5">
          <div className="flex justify-between text-sm">
            <span className="text-gray-500">Subtotal</span>
            <span className="text-gray-900">{formatCurrency(state.totals.subtotal)}</span>
          </div>
          {state.totals.discountTotal > 0 && (
            <div className="flex justify-between text-sm">
              <span className="text-gray-500">Discount</span>
              <span className="text-green-600">-{formatCurrency(state.totals.discountTotal)}</span>
            </div>
          )}
          {intent === 'DELIVERY' && state.deliveryDetails.deliveryFee > 0 && (
            <div className="flex justify-between text-sm">
              <span className="text-gray-500">Delivery Fee</span>
              <span className="text-gray-900">{formatCurrency(state.deliveryDetails.deliveryFee)}</span>
            </div>
          )}
          {/* Dynamic Tax Breakdown */}
          {state.totals.taxBreakdown.length > 0 ? (
            state.totals.taxBreakdown.map((tax) => (
              <div key={tax.taxRuleId} className="flex justify-between text-sm">
                <span className="text-gray-500">
                  {tax.taxRuleName}
                  <span className="text-gray-400 text-xs ml-1">
                    ({(tax.rate * 100).toFixed(1)}%{tax.isInclusive ? ' incl.' : ''})
                  </span>
                </span>
                <span className="text-gray-900">{formatCurrency(tax.taxAmount)}</span>
              </div>
            ))
          ) : state.totals.taxTotal > 0 ? (
            <div className="flex justify-between text-sm">
              <span className="text-gray-500">Tax</span>
              <span className="text-gray-900">{formatCurrency(state.totals.taxTotal)}</span>
            </div>
          ) : null}
          <div className="pt-2 border-t border-gray-200 flex justify-between">
            <span className="text-base font-semibold text-gray-900">Total</span>
            <span className="text-lg font-bold text-purple-700">{formatCurrency(state.totals.grandTotal)}</span>
          </div>
        </div>

        {/* Customer */}
        {state.customer && (
          <div className="p-4 border-t border-gray-200">
            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-1">Customer</p>
            <p className="text-sm font-medium text-gray-900">{state.customer.name}</p>
            {state.customer.phone && <p className="text-xs text-gray-500">{state.customer.phone}</p>}
          </div>
        )}
      </aside>
    </div>
  );
};

export default DetailsTab;
