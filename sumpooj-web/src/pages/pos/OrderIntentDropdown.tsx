/**
 * OrderIntentDropdown.tsx — Intent Pill Selector (Smart Mode)
 *
 * Horizontal pill buttons for order intent with strong visual highlighting.
 * Selected intent controls POS behavior:
 *   - TAKE_NOW: immediate sale, no extra fields
 *   - DELIVERY: requires ZIP, address, date
 *   - PICKUP_LATER: requires pickup date & time slot
 *
 * Confirmation modal when switching with items in the cart.
 */
import React, { useState, useCallback } from 'react';
import {
  WarningAmber as WarningIcon,
  Storefront as StoreIcon,
  LocalShipping as DeliveryIcon,
  ShoppingBag as PickupIcon,
} from '@mui/icons-material';
import type { OrderIntent } from './POSTypes';

// ─── Intent Config ──────────────────────────────────────────

interface IntentConfig {
  value: OrderIntent;
  label: string;
  emoji: string;
  icon: React.ElementType;
  // selected state
  selectedBg: string;
  selectedText: string;
  selectedBorder: string;
  selectedRing: string;
  // unselected state
  unselectedBg: string;
  unselectedText: string;
  unselectedBorder: string;
  hint: string;
}

const INTENT_CONFIG: IntentConfig[] = [
  {
    value: 'TAKE_NOW',
    label: 'Take Now',
    emoji: '🛍',
    icon: StoreIcon,
    selectedBg: 'bg-green-600',
    selectedText: 'text-white',
    selectedBorder: 'border-green-600',
    selectedRing: 'ring-green-300',
    unselectedBg: 'bg-white',
    unselectedText: 'text-gray-600',
    unselectedBorder: 'border-gray-200',
    hint: 'Customer pays & takes order now',
  },
  {
    value: 'DELIVERY',
    label: 'Delivery',
    emoji: '🚚',
    icon: DeliveryIcon,
    selectedBg: 'bg-blue-600',
    selectedText: 'text-white',
    selectedBorder: 'border-blue-600',
    selectedRing: 'ring-blue-300',
    unselectedBg: 'bg-white',
    unselectedText: 'text-gray-600',
    unselectedBorder: 'border-gray-200',
    hint: 'Requires ZIP, address & delivery date',
  },
  {
    value: 'PICKUP_LATER',
    label: 'Pickup Later',
    emoji: '📦',
    icon: PickupIcon,
    selectedBg: 'bg-amber-500',
    selectedText: 'text-white',
    selectedBorder: 'border-amber-500',
    selectedRing: 'ring-amber-300',
    unselectedBg: 'bg-white',
    unselectedText: 'text-gray-600',
    unselectedBorder: 'border-gray-200',
    hint: 'Requires pickup date & time — deposit OK',
  },
];

const getConfig = (value: OrderIntent) =>
  INTENT_CONFIG.find((c) => c.value === value) ?? INTENT_CONFIG[0];

// ─── Confirm Modal ──────────────────────────────────────────

interface ConfirmModalProps {
  open: boolean;
  targetIntent: OrderIntent;
  onConfirm: () => void;
  onCancel: () => void;
}

const ConfirmSwitchModal: React.FC<ConfirmModalProps> = ({
  open,
  targetIntent,
  onConfirm,
  onCancel,
}) => {
  if (!open) return null;

  const target = getConfig(targetIntent);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-xl shadow-xl w-full max-w-sm mx-4 overflow-hidden">
        <div className="flex items-center gap-3 px-5 pt-5 pb-2">
          <span className="w-10 h-10 flex items-center justify-center rounded-full bg-amber-100 text-amber-600">
            <WarningIcon className="w-5 h-5" />
          </span>
          <h3 className="text-base font-semibold text-gray-900">
            Switch to {target.emoji} {target.label}?
          </h3>
        </div>
        <p className="px-5 py-3 text-sm text-gray-600 leading-relaxed">
          Your cart has items. Switching the order intent will clear
          delivery/pickup details. Cart items will be preserved.
        </p>
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
            className={`px-4 py-2 text-sm font-medium text-white rounded-lg
                       transition-colors ${target.selectedBg} hover:opacity-90`}
          >
            Switch to {target.label}
          </button>
        </div>
      </div>
    </div>
  );
};

// ─── Pill Selector ──────────────────────────────────────────

interface OrderIntentDropdownProps {
  value: OrderIntent;
  onChange: (intent: OrderIntent) => void;
  hasItems: boolean;
}

const OrderIntentDropdown: React.FC<OrderIntentDropdownProps> = ({
  value,
  onChange,
  hasItems,
}) => {
  const [pendingIntent, setPendingIntent] = useState<OrderIntent | null>(null);

  const current = getConfig(value);

  const handleSelect = useCallback(
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

  return (
    <>
      <div className="flex items-center gap-2 w-full">
        {/* Pill buttons */}
        <div className="flex items-center gap-2">
          {INTENT_CONFIG.map((opt) => {
            const isActive = value === opt.value;
            const Icon = opt.icon;
            return (
              <button
                key={opt.value}
                type="button"
                onClick={() => handleSelect(opt.value)}
                className={`
                  inline-flex items-center gap-2 h-10 px-4 rounded-full border-2
                  text-sm font-semibold transition-all duration-200 whitespace-nowrap
                  focus:outline-none focus:ring-2 focus:ring-offset-1 ${opt.selectedRing}
                  ${isActive
                    ? `${opt.selectedBg} ${opt.selectedText} ${opt.selectedBorder} shadow-sm`
                    : `${opt.unselectedBg} ${opt.unselectedText} ${opt.unselectedBorder} hover:bg-gray-50`
                  }
                `}
              >
                <Icon sx={{ fontSize: 18 }} />
                <span>{opt.label}</span>
              </button>
            );
          })}
        </div>

        {/* Selected intent hint */}
        <span className="text-xs text-gray-400 ml-2 hidden lg:inline truncate">
          {current.hint}
        </span>
      </div>

      {/* Confirmation Modal */}
      <ConfirmSwitchModal
        open={pendingIntent !== null}
        targetIntent={pendingIntent ?? 'TAKE_NOW'}
        onConfirm={handleConfirm}
        onCancel={handleCancel}
      />
    </>
  );
};

export default OrderIntentDropdown;
