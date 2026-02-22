/**
 * OrderTypeTab.tsx — Tab 1: Choose Order Intent
 *
 * Large, prominent pill-style buttons for intent selection.
 * Each intent describes its behavior below the icon.
 * Keyboard shortcuts: F5 / F6 / F7.
 */
import React, { useEffect } from 'react';
import {
  Store as TakeNowIcon,
  LocalShipping as DeliveryIcon,
  ShoppingBag as PickupIcon,
} from '@mui/icons-material';
import type { OrderIntent } from './POSTypes';

// ─── Card Data ──────────────────────────────────────────────

interface IntentCard {
  value: OrderIntent;
  label: string;
  description: string;
  behaviorHints: string[];
  icon: React.ReactNode;
  shortcut: string;
  // tailwind classes
  ring: string;
  bgActive: string;
  iconBg: string;
  iconBgActive: string;
  iconColor: string;
  pillBg: string;
  pillText: string;
}

const INTENT_CARDS: IntentCard[] = [
  {
    value: 'TAKE_NOW',
    label: 'Take Now',
    description: 'Customer takes the order from the counter immediately.',
    behaviorHints: ['No delivery section', 'Immediate full payment', 'Order printed on receipt'],
    icon: <TakeNowIcon sx={{ fontSize: 44 }} />,
    shortcut: 'F5',
    ring: 'ring-purple-300',
    bgActive: 'bg-purple-50 border-purple-500',
    iconBg: 'bg-gray-100',
    iconBgActive: 'bg-purple-100',
    iconColor: 'text-purple-600',
    pillBg: 'bg-purple-600',
    pillText: 'text-white',
  },
  {
    value: 'DELIVERY',
    label: 'Delivery',
    description: 'Order will be delivered to a specified address.',
    behaviorHints: ['ZIP code required', 'Delivery fee auto-calculated', 'Address & date mandatory'],
    icon: <DeliveryIcon sx={{ fontSize: 44 }} />,
    shortcut: 'F6',
    ring: 'ring-blue-300',
    bgActive: 'bg-blue-50 border-blue-500',
    iconBg: 'bg-gray-100',
    iconBgActive: 'bg-blue-100',
    iconColor: 'text-blue-600',
    pillBg: 'bg-blue-600',
    pillText: 'text-white',
  },
  {
    value: 'PICKUP_LATER',
    label: 'Pickup Later',
    description: 'Customer will pick up the order at a scheduled time.',
    behaviorHints: ['Pickup date & time required', 'Partial payment allowed', 'Order marked as Reserved'],
    icon: <PickupIcon sx={{ fontSize: 44 }} />,
    shortcut: 'F7',
    ring: 'ring-amber-300',
    bgActive: 'bg-amber-50 border-amber-500',
    iconBg: 'bg-gray-100',
    iconBgActive: 'bg-amber-100',
    iconColor: 'text-amber-600',
    pillBg: 'bg-amber-500',
    pillText: 'text-white',
  },
];

// ─── Props ──────────────────────────────────────────────────

interface OrderTypeTabProps {
  selected: OrderIntent;
  onSelect: (intent: OrderIntent) => void;
  onNext: () => void;
}

// ─── Component ──────────────────────────────────────────────

const OrderTypeTab: React.FC<OrderTypeTabProps> = ({ selected, onSelect, onNext }) => {
  // Keyboard shortcuts (F5 / F6 / F7)
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'F5') { e.preventDefault(); onSelect('TAKE_NOW'); }
      if (e.key === 'F6') { e.preventDefault(); onSelect('DELIVERY'); }
      if (e.key === 'F7') { e.preventDefault(); onSelect('PICKUP_LATER'); }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
  }, [onSelect]);

  return (
    <div className="h-full flex flex-col items-center justify-center px-6 py-8 bg-gray-50">
      {/* Heading */}
      <h2 className="text-2xl font-bold text-gray-900 mb-1">How is this order fulfilled?</h2>
      <p className="text-sm text-gray-500 mb-10">Select the order type to get started. This controls which fields are required.</p>

      {/* Cards grid — large pill-style buttons */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6 w-full max-w-4xl">
        {INTENT_CARDS.map((card) => {
          const isActive = selected === card.value;
          return (
            <button
              key={card.value}
              onClick={() => onSelect(card.value)}
              className={`
                relative flex flex-col items-center text-center px-6 py-10 rounded-3xl border-2 transition-all duration-200
                focus:outline-none focus-visible:ring-4 ${card.ring}
                ${isActive
                  ? `${card.bgActive} shadow-lg scale-[1.02]`
                  : 'border-gray-200 bg-white hover:border-gray-300 hover:shadow-md'
                }
              `}
            >
              {/* Selection indicator */}
              {isActive && (
                <span className="absolute top-3 right-3 w-6 h-6 rounded-full bg-green-500 flex items-center justify-center shadow-sm">
                  <svg className="w-3.5 h-3.5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                  </svg>
                </span>
              )}

              {/* Keyboard shortcut badge */}
              <span className="absolute top-3 left-3 px-2 py-0.5 text-[10px] font-bold text-gray-400 bg-gray-100 rounded">
                {card.shortcut}
              </span>

              {/* Icon */}
              <div className={`w-24 h-24 rounded-3xl ${isActive ? card.iconBgActive : card.iconBg} flex items-center justify-center mb-5 transition-colors`}>
                <span className={isActive ? card.iconColor : 'text-gray-400'}>{card.icon}</span>
              </div>

              {/* Label pill */}
              <span className={`inline-flex px-5 py-1.5 rounded-full text-sm font-bold mb-3 transition-colors ${
                isActive ? `${card.pillBg} ${card.pillText}` : 'bg-gray-100 text-gray-600'
              }`}>
                {card.label}
              </span>

              {/* Description */}
              <p className={`text-xs leading-relaxed mb-4 ${isActive ? 'text-gray-600' : 'text-gray-400'}`}>
                {card.description}
              </p>

              {/* Behavior hints */}
              <ul className="space-y-1">
                {card.behaviorHints.map((hint, i) => (
                  <li key={i} className={`flex items-center gap-1.5 text-[11px] ${isActive ? 'text-gray-500' : 'text-gray-300'}`}>
                    <span className={`w-1.5 h-1.5 rounded-full shrink-0 ${isActive ? 'bg-green-400' : 'bg-gray-300'}`} />
                    {hint}
                  </li>
                ))}
              </ul>
            </button>
          );
        })}
      </div>

      {/* Next button */}
      <button
        onClick={onNext}
        disabled={!selected}
        className="mt-10 px-12 py-3.5 bg-purple-600 text-white text-base font-semibold rounded-2xl
                   hover:bg-purple-700 transition-colors shadow-md
                   disabled:bg-gray-300 disabled:cursor-not-allowed disabled:shadow-none"
      >
        Continue to Products →
      </button>
    </div>
  );
};

export default OrderTypeTab;
