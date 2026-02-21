/**
 * DeliveryDetailsForm.tsx — Inline delivery form shown in the cart panel
 * when the order intent is DELIVERY.
 */
import React from 'react';
import {
  LocalShipping as DeliveryIcon,
  CalendarMonth as CalendarIcon,
} from '@mui/icons-material';
import type { DeliveryDetails } from './POSTypes';

interface DeliveryDetailsFormProps {
  value: DeliveryDetails;
  onChange: (details: DeliveryDetails) => void;
  disabled?: boolean;
}

const TIME_SLOTS = [
  '9:00 AM - 11:00 AM',
  '11:00 AM - 1:00 PM',
  '1:00 PM - 3:00 PM',
  '3:00 PM - 5:00 PM',
  '5:00 PM - 7:00 PM',
];

const DeliveryDetailsForm: React.FC<DeliveryDetailsFormProps> = ({
  value,
  onChange,
  disabled = false,
}) => {
  const patch = (partial: Partial<DeliveryDetails>) =>
    onChange({ ...value, ...partial });

  return (
    <div className="px-4 py-3 space-y-3 bg-blue-50/50 border-b border-blue-100">
      {/* Section Header */}
      <div className="flex items-center gap-2">
        <DeliveryIcon className="w-4 h-4 text-blue-600" />
        <span className="text-xs font-semibold text-blue-700 uppercase tracking-wide">
          Delivery Details
        </span>
      </div>

      {/* Delivery Date */}
      <div>
        <label className="block text-[11px] font-medium text-gray-500 mb-1">
          Delivery Date <span className="text-red-500">*</span>
        </label>
        <div className="relative">
          <CalendarIcon className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="date"
            value={value.deliveryDate}
            onChange={(e) => patch({ deliveryDate: e.target.value })}
            disabled={disabled}
            min={new Date().toISOString().split('T')[0]}
            className="w-full h-9 pl-8 pr-3 text-xs border border-gray-200 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                       disabled:bg-gray-100 disabled:cursor-not-allowed"
          />
        </div>
      </div>

      {/* Time Slot */}
      <div>
        <label className="block text-[11px] font-medium text-gray-500 mb-1">
          Time Slot
        </label>
        <select
          value={value.deliveryTimeSlot || ''}
          onChange={(e) => patch({ deliveryTimeSlot: e.target.value })}
          disabled={disabled}
          className="w-full h-9 px-3 text-xs border border-gray-200 rounded-lg bg-white
                     focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                     disabled:bg-gray-100 disabled:cursor-not-allowed"
        >
          <option value="">Select time slot</option>
          {TIME_SLOTS.map((ts) => (
            <option key={ts} value={ts}>
              {ts}
            </option>
          ))}
        </select>
      </div>

      {/* Address */}
      <div>
        <label className="block text-[11px] font-medium text-gray-500 mb-1">
          Delivery Address <span className="text-red-500">*</span>
        </label>
        <textarea
          value={value.address}
          onChange={(e) => patch({ address: e.target.value })}
          disabled={disabled}
          rows={2}
          placeholder="Street address, city, ZIP"
          className="w-full px-3 py-2 text-xs border border-gray-200 rounded-lg resize-none
                     focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                     disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400"
        />
      </div>

      {/* Recipient */}
      <div className="grid grid-cols-2 gap-2">
        <div>
          <label className="block text-[11px] font-medium text-gray-500 mb-1">
            Recipient Name
          </label>
          <input
            type="text"
            value={value.recipientName}
            onChange={(e) => patch({ recipientName: e.target.value })}
            disabled={disabled}
            placeholder="Name"
            className="w-full h-9 px-3 text-xs border border-gray-200 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                       disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400"
          />
        </div>
        <div>
          <label className="block text-[11px] font-medium text-gray-500 mb-1">
            Recipient Phone
          </label>
          <input
            type="tel"
            value={value.recipientPhone}
            onChange={(e) => patch({ recipientPhone: e.target.value })}
            disabled={disabled}
            placeholder="Phone"
            className="w-full h-9 px-3 text-xs border border-gray-200 rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                       disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400"
          />
        </div>
      </div>

      {/* Delivery Fee */}
      <div>
        <label className="block text-[11px] font-medium text-gray-500 mb-1">
          Delivery Fee ($)
        </label>
        <input
          type="number"
          value={value.deliveryFee || ''}
          onChange={(e) => patch({ deliveryFee: parseFloat(e.target.value) || 0 })}
          disabled={disabled}
          min={0}
          step={0.01}
          placeholder="0.00"
          className="w-full h-9 px-3 text-xs border border-gray-200 rounded-lg
                     focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                     disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400"
        />
      </div>

      {/* Instructions */}
      <div>
        <label className="block text-[11px] font-medium text-gray-500 mb-1">
          Instructions
        </label>
        <input
          type="text"
          value={value.instructions || ''}
          onChange={(e) => patch({ instructions: e.target.value })}
          disabled={disabled}
          placeholder="Gate code, ring bell, etc."
          className="w-full h-9 px-3 text-xs border border-gray-200 rounded-lg
                     focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                     disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400"
        />
      </div>
    </div>
  );
};

export default DeliveryDetailsForm;
