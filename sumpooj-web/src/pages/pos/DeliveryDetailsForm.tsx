/**
 * DeliveryDetailsForm.tsx — Inline delivery form shown in the cart panel
 * when the order intent is DELIVERY.
 *
 * Features:
 * - ZIP code required before payment
 * - Auto-calculates delivery fee from ZIP
 * - Red highlights on empty required fields when showErrors=true
 */
import React, { useEffect, useRef } from 'react';
import {
  LocalShipping as DeliveryIcon,
  CalendarMonth as CalendarIcon,
  ErrorOutline as ErrorIcon,
} from '@mui/icons-material';
import type { DeliveryDetails } from './POSTypes';
import { calcDeliveryFeeFromZip } from './POSTypes';
import { formatCurrency } from '../../core/i18n';

interface DeliveryDetailsFormProps {
  value: DeliveryDetails;
  onChange: (details: DeliveryDetails) => void;
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

const DeliveryDetailsForm: React.FC<DeliveryDetailsFormProps> = ({
  value,
  onChange,
  disabled = false,
  showErrors = false,
}) => {
  const patch = (partial: Partial<DeliveryDetails>) =>
    onChange({ ...value, ...partial });

  // Auto-calculate delivery fee when ZIP changes
  const prevZipRef = useRef(value.zipCode);
  useEffect(() => {
    if (value.zipCode !== prevZipRef.current) {
      prevZipRef.current = value.zipCode;
      const fee = calcDeliveryFeeFromZip(value.zipCode);
      if (fee !== value.deliveryFee) {
        onChange({ ...value, deliveryFee: fee });
      }
    }
  }, [value, onChange]);

  const errBorder = (fieldEmpty: boolean) =>
    showErrors && fieldEmpty
      ? 'border-red-400 ring-1 ring-red-200'
      : 'border-gray-200';

  const errLabel = (fieldEmpty: boolean) =>
    showErrors && fieldEmpty ? 'text-red-500' : 'text-gray-500';

  return (
    <div className="px-4 py-3 space-y-3 bg-blue-50/50 border-b border-blue-100">
      {/* Section Header */}
      <div className="flex items-center gap-2">
        <DeliveryIcon className="w-4 h-4 text-blue-600" />
        <span className="text-xs font-semibold text-blue-700 uppercase tracking-wide">
          Delivery Details
        </span>
      </div>

      {/* ZIP Code — required, auto-fee */}
      <div>
        <label className={`block text-[11px] font-medium ${errLabel(!value.zipCode.trim())} mb-1`}>
          ZIP / Postal Code <span className="text-red-500">*</span>
        </label>
        <input
          type="text"
          value={value.zipCode}
          onChange={(e) => patch({ zipCode: e.target.value })}
          disabled={disabled}
          maxLength={10}
          placeholder="e.g. 10001"
          className={`w-full h-9 px-3 text-xs rounded-lg
                     focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                     disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400
                     ${errBorder(!value.zipCode.trim())}`}
        />
        {value.zipCode.length >= 5 && (
          <p className="mt-1 text-[10px] text-blue-600 font-medium">
            Delivery fee: {formatCurrency(value.deliveryFee)}{value.deliveryFee === 0 ? ' (local zone — free)' : ''}
          </p>
        )}
      </div>

      {/* Delivery Date */}
      <div>
        <label className={`block text-[11px] font-medium ${errLabel(!value.deliveryDate)} mb-1`}>
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
            className={`w-full h-9 pl-8 pr-3 text-xs rounded-lg
                       focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                       disabled:bg-gray-100 disabled:cursor-not-allowed
                       ${errBorder(!value.deliveryDate)}`}
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
        <label className={`block text-[11px] font-medium ${errLabel(!value.address.trim())} mb-1`}>
          Delivery Address <span className="text-red-500">*</span>
        </label>
        <textarea
          value={value.address}
          onChange={(e) => patch({ address: e.target.value })}
          disabled={disabled}
          rows={2}
          placeholder="Street address, city"
          className={`w-full px-3 py-2 text-xs rounded-lg resize-none
                     focus:outline-none focus:ring-2 focus:ring-blue-400 focus:border-transparent
                     disabled:bg-gray-100 disabled:cursor-not-allowed placeholder:text-gray-400
                     ${errBorder(!value.address.trim())}`}
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

      {/* Delivery Fee (read-only, auto-calculated — manual override allowed) */}
      <div>
        <label className="block text-[11px] font-medium text-gray-500 mb-1">
          Delivery Fee ($)
          <span className="ml-1 text-[10px] text-blue-500">auto-calculated</span>
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

      {/* Validation summary */}
      {showErrors && (!value.zipCode.trim() || !value.address.trim() || !value.deliveryDate) && (
        <div className="flex items-start gap-2 p-2 bg-red-50 rounded-lg border border-red-200">
          <ErrorIcon className="w-4 h-4 text-red-500 mt-0.5 shrink-0" />
          <p className="text-[11px] text-red-600 leading-relaxed">
            Fill all required fields (ZIP, address, date) before proceeding to payment.
          </p>
        </div>
      )}
    </div>
  );
};

export default DeliveryDetailsForm;
