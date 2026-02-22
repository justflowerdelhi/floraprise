/**
 * POSCartPanelV2.tsx — Cart Panel using POSContext
 * 
 * Features:
 * - Lifecycle-aware cart editing
 * - Locked state during payment
 * - Visual feedback for cart states
 */
import React, { useCallback } from 'react';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  Delete as DeleteIcon,
  AttachMoney as CashIcon,
  CreditCard as CardIcon,
  CallSplit as SplitIcon,
  MoreHoriz as MoreIcon,
  ShoppingCart as CartIcon,
  Lock as LockIcon,
  ErrorOutline as ErrorIcon,
  TrendingDown as BelowCostIcon,
  InfoOutlined as InfoIcon,
} from '@mui/icons-material';
import { usePOS } from './POSContext';
import type { Product } from '../orders/OrderTypes';
import DeliveryDetailsForm from './DeliveryDetailsForm';
import PickupDetailsForm from './PickupDetailsForm';
import RevenueGuardBanner from './RevenueGuardBanner';

interface POSCartPanelV2Props {
  products: Product[];
}

const POSCartPanelV2: React.FC<POSCartPanelV2Props> = ({ products }) => {
  const {
    state,
    updateQty,
    removeItem,
    startPayment,
    setDeliveryDetails,
    setPickupDetails,
    canCheckout,
    canEditCart,
    intentErrors,
  } = usePOS();

  // Track whether user attempted checkout — enables red error highlights
  const [attemptedCheckout, setAttemptedCheckout] = React.useState(false);

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(amount);
  };

  const findProduct = useCallback(
    (productId: string) => products.find((p) => p.id === productId),
    [products]
  );

  const handleIncrement = useCallback(
    (itemId: string, productId: string, currentQty: number) => {
      const product = findProduct(productId);
      if (product && canEditCart) {
        updateQty(itemId, currentQty + 1, product);
      }
    },
    [findProduct, updateQty, canEditCart]
  );

  const handleDecrement = useCallback(
    (itemId: string, productId: string, currentQty: number) => {
      const product = findProduct(productId);
      if (product && canEditCart) {
        if (currentQty <= 1) {
          removeItem(itemId);
        } else {
          updateQty(itemId, currentQty - 1, product);
        }
      }
    },
    [findProduct, updateQty, removeItem, canEditCart]
  );

  const handleRemove = useCallback(
    (itemId: string) => {
      if (canEditCart) {
        removeItem(itemId);
      }
    },
    [removeItem, canEditCart]
  );

  const handlePaymentStart = useCallback(
    (method: 'cash' | 'card' | 'split' | 'more') => {
      if (canCheckout) {
        setAttemptedCheckout(false);
        startPayment();
      } else {
        // Show red highlights on missing required fields
        setAttemptedCheckout(true);
      }
    },
    [canCheckout, startPayment]
  );

  const isEmpty = state.items.length === 0;
  const isLocked = state.isLocked;
  const isPayment = state.lifecycle === 'payment';

  return (
    <aside className="w-80 xl:w-96 bg-slate-50/60 border-l border-gray-200 flex flex-col h-full shrink-0">
      {/* Cart Header */}
      <header className="px-4 py-3 border-b border-gray-200">
        <div className="flex items-center gap-2">
          <CartIcon className={`w-5 h-5 ${isLocked ? 'text-amber-500' : 'text-gray-600'}`} />
          <h2 className="text-base font-semibold text-gray-900">Cart</h2>
          {isLocked && (
            <span className="flex items-center gap-1 ml-1 px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded">
              <LockIcon className="w-3 h-3" />
              Locked
            </span>
          )}
          <span className="ml-auto text-sm text-gray-500">
            {state.totals.itemCount} {state.totals.itemCount === 1 ? 'item' : 'items'}
          </span>
        </div>
      </header>

      {/* Cart Items */}
      <div className="flex-1 overflow-y-auto">
        {isEmpty ? (
          <div className="flex flex-col items-center justify-center h-full text-center px-4">
            <div className="w-16 h-16 bg-gray-100 rounded-full flex items-center justify-center mb-4">
              <CartIcon className="w-8 h-8 text-gray-300" />
            </div>
            <p className="text-gray-500 text-sm">Cart is empty</p>
            <p className="text-gray-400 text-xs mt-1">Add products to begin</p>
          </div>
        ) : (
          <ul className="divide-y divide-gray-100">
            {state.items.map((item) => (
              <li
                key={item.id}
                className={`p-4 transition-colors ${
                  isLocked ? 'bg-gray-50' : 'hover:bg-gray-50'
                }`}
              >
                <div className="flex items-start gap-3">
                  {/* Product Info */}
                  <div className="flex-1 min-w-0">
                    <h4 className="text-sm font-medium text-gray-900 truncate">
                      {item.productName}
                    </h4>
                    <p className="text-xs text-gray-500 mt-0.5">
                      {formatCurrency(item.unitPrice)} each
                    </p>
                    {item.discountPercent > 0 && (
                      <span className="inline-flex items-center mt-1 px-1.5 py-0.5 bg-green-50 text-green-700 text-[10px] font-medium rounded">
                        -{item.discountPercent}% off
                      </span>
                    )}
                    {/* Revenue Guard: below-cost badge */}
                    {item.lineCost > 0 && item.lineTotal < item.lineCost && (
                      <span className="inline-flex items-center gap-0.5 mt-1 ml-1 px-1.5 py-0.5 bg-red-50 text-red-600 text-[10px] font-bold rounded border border-red-200">
                        <BelowCostIcon className="w-3 h-3" />
                        -{Math.abs(item.marginPercent).toFixed(0)}% margin
                      </span>
                    )}
                  </div>

                  {/* Line Total */}
                  <div className="text-right shrink-0">
                    <span className="text-sm font-semibold text-gray-900">
                      {formatCurrency(item.lineTotal)}
                    </span>
                  </div>
                </div>

                {/* Quantity Controls */}
                <div className="mt-3 flex items-center justify-between">
                  <div
                    className={`inline-flex items-center border rounded-lg ${
                      isLocked
                        ? 'border-gray-100 bg-gray-50'
                        : 'border-gray-200'
                    }`}
                  >
                    <button
                      onClick={() =>
                        handleDecrement(item.id, item.productId, item.quantity)
                      }
                      disabled={isLocked}
                      className="w-8 h-8 flex items-center justify-center text-gray-500 
                                 hover:bg-gray-100 rounded-l-lg transition-colors
                                 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-transparent"
                    >
                      <RemoveIcon className="w-4 h-4" />
                    </button>
                    <span className="w-10 text-center text-sm font-medium text-gray-900">
                      {item.quantity}
                    </span>
                    <button
                      onClick={() =>
                        handleIncrement(item.id, item.productId, item.quantity)
                      }
                      disabled={isLocked}
                      className="w-8 h-8 flex items-center justify-center text-gray-500 
                                 hover:bg-gray-100 rounded-r-lg transition-colors
                                 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-transparent"
                    >
                      <AddIcon className="w-4 h-4" />
                    </button>
                  </div>

                  <button
                    onClick={() => handleRemove(item.id)}
                    disabled={isLocked}
                    className="w-8 h-8 flex items-center justify-center text-gray-400 
                               hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors
                               disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:text-gray-400 disabled:hover:bg-transparent"
                  >
                    <DeleteIcon className="w-4 h-4" />
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}

        {/* Delivery / Pickup Details (below items, above totals) */}
        {state.orderIntent === 'DELIVERY' && (
          <DeliveryDetailsForm
            value={state.deliveryDetails}
            onChange={setDeliveryDetails}
            disabled={isLocked}
            showErrors={attemptedCheckout}
          />
        )}
        {state.orderIntent === 'PICKUP_LATER' && (
          <PickupDetailsForm
            value={state.pickupDetails}
            onChange={setPickupDetails}
            disabled={isLocked}
            showErrors={attemptedCheckout}
          />
        )}

        {/* Intent Validation Errors */}
        {intentErrors.length > 0 && !isEmpty && (
          <div className="px-4 py-2 bg-red-50 border-b border-red-100">
            {intentErrors.map((err, i) => (
              <div key={i} className="flex items-center gap-1.5 py-0.5">
                <ErrorIcon className="w-3.5 h-3.5 text-red-500 shrink-0" />
                <span className="text-[11px] text-red-600">{err}</span>
              </div>
            ))}
          </div>
        )}

        {/* Revenue Guard Warnings */}
        {!isEmpty && (
          <RevenueGuardBanner />
        )}
      </div>

      {/* Totals & Payment Section */}
      <div className="border-t border-gray-200 bg-gray-50">
        {/* Summary */}
        <div className="px-4 py-3 space-y-2">
          <div className="flex justify-between text-sm">
            <span className="text-gray-600">Subtotal</span>
            <span className="text-gray-900">{formatCurrency(state.totals.subtotal)}</span>
          </div>

          {state.totals.discountTotal > 0 && (
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Discount</span>
              <span className="text-green-600">
                -{formatCurrency(state.totals.discountTotal)}
              </span>
            </div>
          )}

          {state.orderIntent === 'DELIVERY' && state.deliveryDetails.deliveryFee > 0 && (
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Delivery Fee</span>
              <span className="text-gray-900">
                {formatCurrency(state.deliveryDetails.deliveryFee)}
              </span>
            </div>
          )}

          {/* Dynamic Tax Breakdown */}
          {state.totals.taxBreakdown.length > 0 ? (
            state.totals.taxBreakdown.map((tax) => (
              <div key={tax.taxRuleId} className="flex justify-between text-sm">
                <span className="text-gray-600">
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
              <span className="text-gray-600">Tax</span>
              <span className="text-gray-900">{formatCurrency(state.totals.taxTotal)}</span>
            </div>
          ) : null}

          <div className="pt-2 border-t border-gray-200 flex justify-between items-baseline">
            <span className="text-lg font-bold text-gray-900">Grand Total</span>
            <span className="text-2xl font-extrabold text-purple-700 tracking-tight">
              {formatCurrency(state.totals.grandTotal)}
            </span>
          </div>

          {/* Revenue Guard: real-time margin % */}
          {state.items.length > 0 && (
            <div
              className={`flex items-center justify-between px-2.5 py-1.5 rounded-lg border text-xs mt-1 ${
                state.totals.marginPercent >= 40
                  ? 'bg-green-50 border-green-200'
                  : state.totals.marginPercent >= 20
                    ? 'bg-amber-50 border-amber-200'
                    : 'bg-red-50 border-red-200'
              }`}
            >
              <span className="text-gray-600 font-medium">Margin</span>
              <span
                className={`font-bold ${
                  state.totals.marginPercent >= 40
                    ? 'text-green-600'
                    : state.totals.marginPercent >= 20
                      ? 'text-amber-600'
                      : 'text-red-600'
                }`}
              >
                {state.totals.marginPercent.toFixed(1)}%
              </span>
            </div>
          )}
        </div>

        {/* Subtle warning banner — shown when cart has items but can't checkout */}
        {!isEmpty && !canCheckout && intentErrors.length > 0 && !isPayment && (
          <div className="mx-4 mb-3 flex items-center gap-2 px-3 py-2 bg-amber-50 border border-amber-200 rounded-lg">
            <InfoIcon sx={{ fontSize: 16, color: '#d97706' }} />
            <span className="text-[11px] text-amber-700 font-medium">
              Complete required fields to enable payment
            </span>
          </div>
        )}

        {/* Payment Buttons - Hidden when cart empty or during payment */}
        {!isPayment && !isEmpty && (
          <div className="px-4 pb-3 grid grid-cols-4 gap-2">
            <button
              onClick={() => handlePaymentStart('cash')}
              disabled={!canCheckout}
              className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                         hover:bg-gray-50 hover:border-purple-300 transition-colors
                         disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
            >
              <CashIcon className="w-5 h-5 text-gray-600 mb-1" />
              <span className="text-xs font-medium text-gray-700">Cash</span>
            </button>

            <button
              onClick={() => handlePaymentStart('card')}
              disabled={!canCheckout}
              className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                         hover:bg-gray-50 hover:border-purple-300 transition-colors
                         disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
            >
              <CardIcon className="w-5 h-5 text-gray-600 mb-1" />
              <span className="text-xs font-medium text-gray-700">Card</span>
            </button>

            <button
              onClick={() => handlePaymentStart('split')}
              disabled={!canCheckout}
              className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                         hover:bg-gray-50 hover:border-purple-300 transition-colors
                         disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
            >
              <SplitIcon className="w-5 h-5 text-gray-600 mb-1" />
              <span className="text-xs font-medium text-gray-700">Split</span>
            </button>

            <button
              onClick={() => handlePaymentStart('more')}
              disabled={!canCheckout}
              className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                         hover:bg-gray-50 hover:border-purple-300 transition-colors
                         disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
            >
              <MoreIcon className="w-5 h-5 text-gray-600 mb-1" />
              <span className="text-xs font-medium text-gray-700">More</span>
            </button>
          </div>
        )}

        {/* Checkout Button */}
        <div className="px-4 pb-4">
          <button
            onClick={() => handlePaymentStart('split')}
            disabled={isPayment || (isEmpty && !isPayment)}
            className={`w-full py-3 font-semibold rounded-lg transition-colors ${
              isPayment
                ? 'bg-amber-500 text-white cursor-wait'
                : canCheckout
                ? 'bg-purple-600 text-white hover:bg-purple-700 shadow-sm'
                : intentErrors.length > 0 && !isEmpty
                ? 'bg-gray-200 text-gray-500 cursor-not-allowed'
                : 'bg-gray-200 text-gray-400 cursor-not-allowed'
            }`}
          >
            {isPayment
              ? 'Processing Payment...'
              : !isEmpty && intentErrors.length > 0
              ? `Fill required fields (${intentErrors.length})`
              : canCheckout
              ? `Pay ${formatCurrency(state.totals.grandTotal)}`
              : isEmpty
              ? 'Add items to cart'
              : 'Checkout'}
          </button>
        </div>
      </div>
    </aside>
  );
};

export default POSCartPanelV2;
