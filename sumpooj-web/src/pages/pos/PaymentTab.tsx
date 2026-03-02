/**
 * PaymentTab.tsx — Tab 4: Payment
 *
 * Automatically starts the payment lifecycle when the tab is entered.
 * Shows the POSPaymentDrawerV2 inline (full-width) instead of as a drawer.
 * Validates intent-specific rules before allowing payment completion.
 */
import React, { useEffect } from 'react';
import { usePOS } from './POSContext';
import POSPaymentDrawerV2 from './POSPaymentDrawerV2';
import { formatCurrency } from '../../core/i18n';

// ─── Props ──────────────────────────────────────────────────

interface PaymentTabProps {
  onBack: () => void;
}

// ─── Component ──────────────────────────────────────────────

const PaymentTab: React.FC<PaymentTabProps> = ({ onBack }) => {
  const { state, startPayment } = usePOS();

  // Auto-enter payment lifecycle when tab is active
  useEffect(() => {
    if (state.lifecycle === 'active' && state.items.length > 0) {
      startPayment();
    }
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <div className="h-full flex flex-col overflow-hidden">
      {/* Toolbar */}
      <div className="shrink-0 flex items-center justify-between px-6 py-3 border-b border-gray-200 bg-white">
        <button
          onClick={onBack}
          className="px-5 py-2 border border-gray-300 text-gray-700 text-sm font-semibold rounded-xl
                     hover:bg-gray-50 transition-colors"
        >
          ← Back to Details
        </button>

        <div className="text-right">
          <p className="text-xs text-gray-500 uppercase tracking-wide">Total Due</p>
          <p className="text-2xl font-bold text-purple-700">
            {formatCurrency(state.totals.grandTotal)}
          </p>
        </div>
      </div>

      {/* Payment Drawer rendered inline */}
      <div className="flex-1 overflow-hidden">
        <POSPaymentDrawerV2 />
      </div>
    </div>
  );
};

export default PaymentTab;
