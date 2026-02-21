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
} from '@mui/icons-material';
import { usePOS } from './POSContext';
import type { Product } from '../orders/OrderTypes';

interface POSCartPanelV2Props {
  products: Product[];
}

const POSCartPanelV2: React.FC<POSCartPanelV2Props> = ({ products }) => {
  const {
    state,
    updateQty,
    removeItem,
    startPayment,
    canCheckout,
    canEditCart,
  } = usePOS();

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
        startPayment();
      }
    },
    [canCheckout, startPayment]
  );

  const isEmpty = state.items.length === 0;
  const isLocked = state.isLocked;
  const isPayment = state.lifecycle === 'payment';

  return (
    <aside className="w-80 xl:w-96 bg-white border-l border-gray-200 flex flex-col h-full shrink-0">
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

          <div className="flex justify-between text-sm">
            <span className="text-gray-600">Tax</span>
            <span className="text-gray-900">{formatCurrency(state.totals.taxTotal)}</span>
          </div>

          <div className="pt-2 border-t border-gray-200 flex justify-between">
            <span className="text-base font-semibold text-gray-900">Total</span>
            <span className="text-xl font-bold text-purple-700">
              {formatCurrency(state.totals.grandTotal)}
            </span>
          </div>
        </div>

        {/* Payment Buttons - Hidden during payment */}
        {!isPayment && (
          <div className="px-4 pb-4 grid grid-cols-4 gap-2">
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
            disabled={!canCheckout || isPayment}
            className={`w-full py-3 font-semibold rounded-lg transition-colors ${
              isPayment
                ? 'bg-amber-500 text-white cursor-wait'
                : canCheckout
                ? 'bg-purple-600 text-white hover:bg-purple-700'
                : 'bg-gray-300 text-gray-500 cursor-not-allowed'
            }`}
          >
            {isPayment
              ? 'Processing Payment...'
              : `Checkout${!isEmpty ? ` • ${formatCurrency(state.totals.grandTotal)}` : ''}`}
          </button>
        </div>
      </div>
    </aside>
  );
};

export default POSCartPanelV2;
