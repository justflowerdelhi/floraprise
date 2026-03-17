/**
 * OrderIntentSwitcher.tsx — Segmented control for switching Order Intent
 *
 * [ Take Now ] [ Delivery ] [ Pickup Later ]
 *
 * Shows a confirmation modal when switching with items in the cart,
 * since delivery/pickup details will be reset.
 */
import React, { useState, useCallback } from 'react';
import {
  Store as StoreIcon,
  LocalShipping as DeliveryIcon,
  ShoppingBag as PickupIcon,
  WarningAmber as WarningIcon,
  KeyboardArrowDown as ArrowDownIcon,
} from '@mui/icons-material';
import type { OrderIntent } from './POSTypes';
import { ORDER_INTENT_OPTIONS } from './POSTypes';

// ─── Icon Map ───────────────────────────────────────────────

const INTENT_ICON: Record<string, React.ReactElement> = {
  Store: <StoreIcon className="w-4 h-4" />,
  LocalShipping: <DeliveryIcon className="w-4 h-4" />,
  ShoppingBag: <PickupIcon className="w-4 h-4" />,
};

// ─── Confirm Modal ──────────────────────────────────────────

interface ConfirmModalProps {
  open: boolean;
  targetIntent: OrderIntent;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmIntentModal: React.FC<ConfirmModalProps> = ({
  open,
  targetIntent,
  onConfirm,
  onCancel,
}) => {
  if (!open) return null;

  const targetLabel =
    ORDER_INTENT_OPTIONS.find((o) => o.value === targetIntent)?.label ?? targetIntent;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4 overflow-hidden">
        {/* Header */}
        <div className="flex items-center gap-3 px-5 pt-5 pb-2">
          <span className="w-10 h-10 flex items-center justify-center rounded-full bg-amber-100 text-amber-600">
            <WarningIcon className="w-5 h-5" />
          </span>
          <h3 className="text-base font-semibold text-gray-900">
            Switch to {targetLabel}?
          </h3>
        </div>

        {/* Body */}
        <p className="px-5 py-3 text-sm text-gray-600 leading-relaxed">
          Your cart has items. Switching the order intent will clear delivery/pickup details.
          Cart items will be preserved.
        </p>

        {/* Actions */}
        <div className="flex items-center justify-end gap-2 px-5 pb-5 pt-2">
          <button
            onClick={onCancel}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-lg
                       hover:bg-gray-200 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={onConfirm}
            className="px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-lg
                       hover:bg-purple-700 transition-colors"
          >
            Switch
          </button>
        </div>
      </div>
    </div>
  );
};

// ─── Segmented Switcher ─────────────────────────────────────

interface OrderIntentSwitcherProps {
  value: OrderIntent;
  onChange: (intent: OrderIntent) => void;
  hasItems: boolean;
}

const OrderIntentSwitcher: React.FC<OrderIntentSwitcherProps> = ({
  value,
  onChange,
  hasItems,
}) => {
  const [pendingIntent, setPendingIntent] = useState<OrderIntent | null>(null);
  const [dropdownOpen, setDropdownOpen] = useState(false);

  const handleClick = useCallback(
    (intent: OrderIntent) => {
      if (intent === value) return;
      if (hasItems) {
        setPendingIntent(intent);
      } else {
        onChange(intent);
      }
    },
    [value, hasItems, onChange],
  );

  const handleConfirm = useCallback(() => {
    if (pendingIntent) {
      onChange(pendingIntent);
      setPendingIntent(null);
    }
  }, [pendingIntent, onChange]);

  const handleCancel = useCallback(() => {
    setPendingIntent(null);
  }, []);

  const activeOption = ORDER_INTENT_OPTIONS.find((o) => o.value === value);

  return (
    <>
      {/* Mobile: Dropdown */}
      <div className="relative sm:hidden shrink-0">
        <button
          onClick={() => setDropdownOpen((v) => !v)}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg
                     bg-white text-purple-700 shadow-sm ring-1 ring-gray-200"
        >
          {activeOption && INTENT_ICON[activeOption.icon]}
          {activeOption?.label}
          <ArrowDownIcon className={`w-4 h-4 text-gray-400 transition-transform ${dropdownOpen ? 'rotate-180' : ''}`} />
        </button>
        {dropdownOpen && (
          <>
            <div className="fixed inset-0 z-40" onClick={() => setDropdownOpen(false)} />
            <div className="absolute left-0 top-full mt-1 z-50 bg-white border border-gray-200 rounded-lg shadow-lg min-w-[160px] py-1">
              {ORDER_INTENT_OPTIONS.map((opt) => {
                const isActive = value === opt.value;
                return (
                  <button
                    key={opt.value}
                    onClick={() => {
                      handleClick(opt.value);
                      setDropdownOpen(false);
                    }}
                    className={`w-full flex items-center gap-2 px-3 py-2 text-left text-sm transition-colors ${
                      isActive ? 'bg-purple-50 text-purple-700 font-semibold' : 'text-gray-700 hover:bg-gray-50'
                    }`}
                  >
                    {INTENT_ICON[opt.icon]}
                    <span>{opt.label}</span>
                  </button>
                );
              })}
            </div>
          </>
        )}
      </div>

      {/* Desktop: Segmented control */}
      <div className="hidden sm:inline-flex items-center bg-gray-100 rounded-lg p-0.5 gap-0.5">
        {ORDER_INTENT_OPTIONS.map((opt) => {
          const isActive = value === opt.value;
          return (
            <button
              key={opt.value}
              onClick={() => handleClick(opt.value)}
              title={opt.shortcut ? `${opt.label} (${opt.shortcut})` : opt.label}
              className={`
                inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-md
                transition-all duration-150
                ${
                  isActive
                    ? 'bg-white text-purple-700 shadow-sm ring-1 ring-gray-200'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-gray-50'
                }
              `}
            >
              {INTENT_ICON[opt.icon]}
              {opt.label}
            </button>
          );
        })}
      </div>

      <ConfirmIntentModal
        open={pendingIntent !== null}
        targetIntent={pendingIntent ?? 'TAKE_NOW'}
        onConfirm={handleConfirm}
        onCancel={handleCancel}
      />
    </>
  );
};

export default OrderIntentSwitcher;
