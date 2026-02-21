/**
 * OrderTypeTab.tsx — Tab 1: Choose Order Intent
 *
 * Three large, selectable cards:
 *  - TAKE NOW
 *  - DELIVERY
 *  - PICKUP LATER
 *
 * Default highlights TAKE_NOW. User must select one to proceed.
 */
import React from 'react';
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
  icon: React.ReactNode;
  color: string;       // border + ring
  bgActive: string;    // active background
  iconBg: string;      // icon circle bg
  iconColor: string;   // icon color
}

const INTENT_CARDS: IntentCard[] = [
  {
    value: 'TAKE_NOW',
    label: 'Take Now',
    description: 'Customer takes the order immediately from the counter.',
    icon: <TakeNowIcon sx={{ fontSize: 40 }} />,
    color: 'purple',
    bgActive: 'bg-purple-50 border-purple-500 ring-purple-200',
    iconBg: 'bg-purple-100',
    iconColor: 'text-purple-600',
  },
  {
    value: 'DELIVERY',
    label: 'Delivery',
    description: 'Order will be delivered to a specified address.',
    icon: <DeliveryIcon sx={{ fontSize: 40 }} />,
    color: 'blue',
    bgActive: 'bg-blue-50 border-blue-500 ring-blue-200',
    iconBg: 'bg-blue-100',
    iconColor: 'text-blue-600',
  },
  {
    value: 'PICKUP_LATER',
    label: 'Pickup Later',
    description: 'Customer will pick up the order at a scheduled time.',
    icon: <PickupIcon sx={{ fontSize: 40 }} />,
    color: 'amber',
    bgActive: 'bg-amber-50 border-amber-500 ring-amber-200',
    iconBg: 'bg-amber-100',
    iconColor: 'text-amber-600',
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
  return (
    <div className="h-full flex flex-col items-center justify-center px-6 py-8 bg-gray-50">
      {/* Heading */}
      <h2 className="text-2xl font-bold text-gray-900 mb-2">How is this order fulfilled?</h2>
      <p className="text-sm text-gray-500 mb-8">Select the order type to get started.</p>

      {/* Cards grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5 w-full max-w-3xl">
        {INTENT_CARDS.map((card) => {
          const isActive = selected === card.value;
          return (
            <button
              key={card.value}
              onClick={() => onSelect(card.value)}
              className={`
                relative flex flex-col items-center text-center p-8 rounded-2xl border-2 transition-all
                focus:outline-none focus-visible:ring-4
                ${isActive
                  ? `${card.bgActive} ring-2 shadow-md`
                  : 'border-gray-200 bg-white hover:border-gray-300 hover:shadow-sm'
                }
              `}
            >
              {/* Selection indicator */}
              {isActive && (
                <span className="absolute top-3 right-3 w-5 h-5 rounded-full bg-green-500 flex items-center justify-center">
                  <svg className="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" />
                  </svg>
                </span>
              )}

              {/* Icon */}
              <div className={`w-20 h-20 rounded-2xl ${isActive ? card.iconBg : 'bg-gray-100'} flex items-center justify-center mb-5`}>
                <span className={isActive ? card.iconColor : 'text-gray-400'}>{card.icon}</span>
              </div>

              {/* Label */}
              <h3 className={`text-lg font-bold mb-1 ${isActive ? 'text-gray-900' : 'text-gray-700'}`}>
                {card.label}
              </h3>

              {/* Description */}
              <p className={`text-xs leading-relaxed ${isActive ? 'text-gray-600' : 'text-gray-400'}`}>
                {card.description}
              </p>
            </button>
          );
        })}
      </div>

      {/* Next button */}
      <button
        onClick={onNext}
        disabled={!selected}
        className="mt-10 px-10 py-3 bg-purple-600 text-white text-base font-semibold rounded-xl
                   hover:bg-purple-700 transition-colors shadow-sm
                   disabled:bg-gray-300 disabled:cursor-not-allowed disabled:shadow-none"
      >
        Continue to Products →
      </button>
    </div>
  );
};

export default OrderTypeTab;
