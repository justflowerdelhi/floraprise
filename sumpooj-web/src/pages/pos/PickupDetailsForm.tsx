/**
 * PickupDetailsForm.tsx — Inline pickup form shown in the cart panel
 * when the order intent is PICKUP_LATER.
 *
 * Features:
 * - Pickup date AND time slot required
 * - Red highlights on empty required fields when showErrors=true
 * - "Reserved" badge to indicate order status
 * - Partial-payment-only notice
 */
import React from 'react';
import {
  ShoppingBag as PickupIcon,
  CalendarMonth as CalendarIcon,
  ErrorOutline as ErrorIcon,
  Bookmark as ReservedIcon,
} from '@mui/icons-material';
import type { PickupDetails } from './POSTypes';

interface PickupDetailsFormProps {
  value: PickupDetails;
  onChange: (details: PickupDetails) => void;
  disabled?: boolean;
  /** When true, empty required fields get a red border */
  showErrors?: boolean;
}

const TIME_SLOTS = [
  '9:00 AM - 11:00 AM',
  '11:00 AM - 1:00 PM',
  '1:00 PM - 3:00 PM',
  '3:00 PM - 5:00 PM',
  '5:00 PM - 7:00 PM',
];

const PickupDetailsForm: React.FC<PickupDetailsFormProps> = ({
  value,
  onChange,
  disabled = false,
  showErrors = false,
}) => {
  const patch = (partial: Partial<PickupDetails>) =>
    onChange({ ...value, ...partial });

  const errBorder = (fieldEmpty: boolean) =>
    showErrors && fieldEmpty
      ? 'border-red-400 ring-1 ring-red-200'
      : 'border-gray-200';

  const errLabel = (fieldEmpty: boolean) =>
    showErrors && fieldEmpty ? 'text-red-500' : 'text-gray-500';

  return (
    <div className="px-4 py-3 space-y-3 bg-amber-50/50 border-b border-amber-100">
      {/* Section Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <PickupIcon className="w-4 h-4 text-amber-600" />
          <span className="text-xs font-semibold text-amber-700 uppercase tracking-wide">
            Pickup Details
          </span>
        </div>
        {/* Reserved badge */}
        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-amber-200 text-amber-800 text-[10px] font-bold rounded-full uppercase tracking-wide">
          <ReservedIcon sx={{ fontSize: 12 }} />
          Reserved
        </span>
      </div>

      {/* Pickup Date — required */}
      <div>
        <label className={`block text-[11px] font-medium ${errLabel(!value.pickupDate)} mb-1`}>
          Pickup Date <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <CalendarIcon className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="date"
            value={value.pickupDate}
            onChange={(e) => patch({ pickupDate: e.target.value })}
            disabled={disabled}
            min={new Date().toISOString().split('T')[0]}
            className={`w-full h-9 pl-8 pr-3 text-xs rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent
                       disabled:bg-gray-100 disabled:cursor-not-allowed
                       ${errBorder(!value.pickupDate)}`}
          />
        </div>
      </div>

      {/* Time Slot — now required */}
      <div>
        <label className={`block text-[11px] font-medium ${errLabel(!value.pickupTimeSlot)} mb-1`}>
          Pickup Time Slot <span className="text-red-500">*</span>
        </label>
        <select
          value={value.pickupTimeSlot || ''}
          onChange={(e) => patch({ pickupTimeSlot: e.target.value })}
          disabled={disabled}
          className={`w-full h-9 px-3 text-xs rounded-lg bg-white
                     focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent
                     disabled:bg-gray-100 disabled:cursor-not-allowed
                     ${errBorder(!value.pickupTimeSlot)}`}
        >
          <option value="">Select time slot</option>
          {TIME_SLOTS.map((ts) => (
            <option key={ts} value={ts}>
              {ts}
            </option>
          ))}
        </select>
      </div>

      {/* Contact Info */}
      <div className="grid grid-cols-2 gap-2">
        <div>
          <label className="block text-[11px] font-medium text-gray-500 mb-1">
            Contact Name
          </label>
          <input
            type="text"
            value={value.contactName}
            onChange={(e) => patch({ contactName: e.target.value })}
            disabled={disabled}
            placeholder="Name"
            className="w-full h-9 px-3 text-xs border border-gray-200 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent
                       disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400"
          />
        </div>
        <div>
          <label className="block text-[11px] font-medium text-gray-500 mb-1">
            Contact Phone
          </label>
          <input
            type="tel"
            value={value.contactPhone}
            onChange={(e) => patch({ contactPhone: e.target.value })}
            disabled={disabled}
            placeholder="Phone"
            className="w-full h-9 px-3 text-xs border border-gray-200 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-amber-400 focus:border-transparent
                       disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400"
          />
        </div>
      </div>

      {/* Partial-payment + reservation notice */}
      <div className="flex items-start gap-2 p-2 bg-amber-100/60 rounded-lg">
        <span className="text-amber-600 text-sm mt-0.5">💡</span>
        <p className="text-[11px] text-amber-800 leading-relaxed">
          Pickup orders allow <strong>partial payment</strong> (deposit). The order will be marked as <strong>Reserved</strong> until the customer picks up.
        </p>
      </div>

      {/* Validation summary */}
      {showErrors && (!value.pickupDate || !value.pickupTimeSlot) && (
        <div className="flex items-start gap-2 p-2 bg-red-50 rounded-lg border border-red-200">
          <ErrorIcon className="w-4 h-4 text-red-500 mt-0.5 shrink-0" />
          <p className="text-[11px] text-red-600 leading-relaxed">
            Fill all required fields (date & time slot) before proceeding to payment.
          </p>
        </div>
      )}
    </div>
  );
};

export default PickupDetailsForm;
