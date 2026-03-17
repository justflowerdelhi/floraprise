/**
 * POSCartPanel.tsx — Right-side cart panel for FloraPrice POS
 * Shows line items, quantity controls, totals, and payment buttons
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
} from '@mui/icons-material';
import type { CartItem, CartSummary, Product } from './POSTypes';
import { formatCurrency } from '../../core/i18n';

interface POSCartPanelProps {
  items: CartItem[];
  totals: CartSummary;
  products: Product[];
  onUpdateQty: (lineId: string, qty: number, product: Product) => void;
  onRemoveItem: (lineId: string) => void;
  onPayment: (method: 'cash' | 'card' | 'split' | 'more') => void;
}

const POSCartPanel: React.FC<POSCartPanelProps> = ({
  items,
  totals,
  products,
  onUpdateQty,
  onRemoveItem,
  onPayment,
}) => {
  const findProduct = useCallback((productId: string) => {
    return products.find((p) => p.id === productId);
  }, [products]);

  const handleIncrement = useCallback((item: CartItem) => {
    const product = findProduct(item.productId);
    if (product) {
      onUpdateQty(item.id, item.quantity + 1, product);
    }
  }, [findProduct, onUpdateQty]);

  const handleDecrement = useCallback((item: CartItem) => {
    const product = findProduct(item.productId);
    if (product) {
      if (item.quantity <= 1) {
        onRemoveItem(item.id);
      } else {
        onUpdateQty(item.id, item.quantity - 1, product);
      }
    }
  }, [findProduct, onUpdateQty, onRemoveItem]);

  const isEmpty = items.length === 0;

  return (
    <aside className="w-full md:w-80 xl:w-96 bg-white border-t md:border-t-0 md:border-l border-gray-200 flex flex-col h-64 md:h-full shrink-0">
      {/* Cart Header */}
      <header className="px-4 py-3 border-b border-gray-200">
        <div className="flex items-center gap-2">
          <CartIcon className="w-5 h-5 text-gray-600" />
          <h2 className="text-base font-semibold text-gray-900">
            Cart
          </h2>
          <span className="ml-auto text-sm text-gray-500">
            {totals.itemCount} {totals.itemCount === 1 ? 'item' : 'items'}
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
            {items.map((item) => (
              <li key={item.id} className="p-4 hover:bg-gray-50 transition-colors">
                <div className="flex items-start gap-3">
                  {/* Product Info */}
                  <div className="flex-1 min-w-0">
                    <h4 className="text-sm font-medium text-gray-900 truncate">
                      {item.productName}
                    </h4>
                    <p className="text-xs text-gray-500 mt-0.5">
                      {formatCurrency(item.unitPrice)} each
                    </p>

                    {/* Discount indicator */}
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
                  <div className="inline-flex items-center border border-gray-200 rounded-lg">
                    <button
                      onClick={() => handleDecrement(item)}
                      className="w-8 h-8 flex items-center justify-center text-gray-500 hover:bg-gray-100 rounded-l-lg transition-colors"
                    >
                      <RemoveIcon className="w-4 h-4" />
                    </button>
                    <span className="w-10 text-center text-sm font-medium text-gray-900">
                      {item.quantity}
                    </span>
                    <button
                      onClick={() => handleIncrement(item)}
                      className="w-8 h-8 flex items-center justify-center text-gray-500 hover:bg-gray-100 rounded-r-lg transition-colors"
                    >
                      <AddIcon className="w-4 h-4" />
                    </button>
                  </div>

                  <button
                    onClick={() => onRemoveItem(item.id)}
                    className="w-8 h-8 flex items-center justify-center text-gray-400 hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors"
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
            <span className="text-gray-900">{formatCurrency(totals.subtotal)}</span>
          </div>

          {totals.discountTotal > 0 && (
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Discount</span>
              <span className="text-green-600">-{formatCurrency(totals.discountTotal)}</span>
            </div>
          )}

          {/* Dynamic Tax Breakdown */}
          {totals.taxBreakdown && totals.taxBreakdown.length > 0 ? (
            totals.taxBreakdown.map((tax) => (
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
          ) : totals.taxTotal > 0 ? (
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Tax</span>
              <span className="text-gray-900">{formatCurrency(totals.taxTotal)}</span>
            </div>
          ) : null}

          <div className="pt-2 border-t border-gray-200 flex justify-between">
            <span className="text-base font-semibold text-gray-900">Total</span>
            <span className="text-xl font-bold text-purple-700">
              {formatCurrency(totals.grandTotal)}
            </span>
          </div>
        </div>

        {/* Payment Buttons */}
        <div className="px-4 pb-4 grid grid-cols-4 gap-2">
          <button
            onClick={() => onPayment('cash')}
            disabled={isEmpty}
            className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                       hover:bg-gray-50 hover:border-purple-300 transition-colors
                       disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
          >
            <CashIcon className="w-5 h-5 text-gray-600 mb-1" />
            <span className="text-xs font-medium text-gray-700">Cash</span>
          </button>

          <button
            onClick={() => onPayment('card')}
            disabled={isEmpty}
            className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                       hover:bg-gray-50 hover:border-purple-300 transition-colors
                       disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
          >
            <CardIcon className="w-5 h-5 text-gray-600 mb-1" />
            <span className="text-xs font-medium text-gray-700">Card</span>
          </button>

          <button
            onClick={() => onPayment('split')}
            disabled={isEmpty}
            className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                       hover:bg-gray-50 hover:border-purple-300 transition-colors
                       disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
          >
            <SplitIcon className="w-5 h-5 text-gray-600 mb-1" />
            <span className="text-xs font-medium text-gray-700">Split</span>
          </button>

          <button
            onClick={() => onPayment('more')}
            disabled={isEmpty}
            className="flex flex-col items-center justify-center py-3 px-2 bg-white border border-gray-200 rounded-lg
                       hover:bg-gray-50 hover:border-purple-300 transition-colors
                       disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-white disabled:hover:border-gray-200"
          >
            <MoreIcon className="w-5 h-5 text-gray-600 mb-1" />
            <span className="text-xs font-medium text-gray-700">More</span>
          </button>
        </div>

        {/* Checkout Button */}
        <div className="px-4 pb-4">
          <button
            onClick={() => onPayment('split')} // Opens full payment drawer
            disabled={isEmpty}
            className="w-full py-3 bg-purple-600 text-white font-semibold rounded-lg
                       hover:bg-purple-700 transition-colors
                       disabled:bg-gray-300 disabled:cursor-not-allowed"
          >
            Checkout {!isEmpty && `• ${formatCurrency(totals.grandTotal)}`}
          </button>
        </div>
      </div>
    </aside>
  );
};

export default POSCartPanel;
