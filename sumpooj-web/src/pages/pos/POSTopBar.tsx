/**
 * POSTopBar.tsx — Top transaction bar for FloraPrice POS
 * Fixed 64px height with search, customer selector, order type, location, and grand total
 */
import React, { useRef, useEffect, useCallback, useState, useMemo } from 'react';
import {
  Search as SearchIcon,
  Person as PersonIcon,
  KeyboardArrowDown as ArrowDownIcon,
  LocationOn as LocationIcon,
  Check as CheckIcon,
  ExitToApp as CloseShiftIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import type { OrderIntent } from './POSTypes';
import type { POSCustomer } from './POSCustomerTypes';
import { POS_SHORTCUTS } from './POSTypes';
import OrderIntentSwitcher from './OrderIntentSwitcher';
import type { Location } from '../../core/location/LocationTypes';
import { formatCurrency } from '../../core/i18n';

/** Compact shift summary for the POS header display */
export interface ShiftHeaderData {
  openingCash: number;
  openedAt: string;
  openedByName: string;
  transactionCount: number;
  cashSales: number;
  totalRefunds: number;
  expectedCash: number;
  /** Cash variance = expectedCash minus a counted value, if available */
  cashDifference: number | null;
}

interface POSTopBarProps {
  searchValue: string;
  onSearchChange: (value: string) => void;
  onSearchSubmit: () => void;
  selectedCustomer: POSCustomer | null;
  onCustomerClick: () => void;
  orderType: OrderIntent;
  onOrderTypeChange: (type: OrderIntent) => void;
  locationName: string;
  accessibleLocations: Location[];
  currentLocationId: string | null;
  onLocationChange: (locationId: string) => void;
  grandTotal: number;
  hasItems: boolean;
  /** Active shift data (null when no shift open) */
  activeShift: ShiftHeaderData | null;
  /** Called when user wants to close the shift */
  onCloseShift: () => void;
  /** Optional style props for search input */
  searchProps?: any;
  /** Optional style props for order intent control */
  orderTypeProps?: any;
  /** Optional style props for location selector */
  locationProps?: any;
  /** Optional style props for close shift button */
  closeShiftProps?: any;
}

const POSTopBar: React.FC<POSTopBarProps> = ({
  searchValue,
  onSearchChange,
  onSearchSubmit,
  selectedCustomer,
  onCustomerClick,
  orderType,
  onOrderTypeChange,
  locationName,
  accessibleLocations,
  currentLocationId,
  onLocationChange,
  grandTotal,
  hasItems,
  activeShift,
  onCloseShift,
  searchProps,
  orderTypeProps,
  locationProps,
  closeShiftProps,
}) => {
  const searchRef = useRef<HTMLInputElement>(null);
  const [locationMenuOpen, setLocationMenuOpen] = useState(false);
  const locationBtnRef = useRef<HTMLButtonElement>(null);

  // Auto-focus search on mount
  useEffect(() => {
    searchRef.current?.focus();
  }, []);

  // Keyboard shortcuts
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === POS_SHORTCUTS.SEARCH) {
        e.preventDefault();
        searchRef.current?.focus();
      }
      if (e.key === POS_SHORTCUTS.CUSTOMER) {
        e.preventDefault();
        onCustomerClick();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onCustomerClick]);

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      onSearchSubmit();
    }
  }, [onSearchSubmit]);

  return (
    <header className="bg-white border-b border-gray-200 shrink-0">
      {/* Row 1: Search + Customer + Total (always visible) */}
      <div className="h-14 sm:h-16 flex items-center px-2 gap-2">
        {/* Search / Barcode Input */}
        <div className="flex-1 min-w-0">
          <div className="relative">
            <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              ref={searchRef}
              type="text"
              placeholder={searchProps?.placeholder || "Search / scan barcode (F2)"}
              value={searchValue}
              onChange={(e) => onSearchChange(e.target.value)}
              onKeyDown={handleKeyDown}
              className={searchProps?.className || "w-full h-10 pl-10 pr-4 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent placeholder:text-gray-400"}
              style={searchProps?.sx}
            />
          </div>
        </div>

        {/* Customer Selector — hidden on xs, shown on sm+ */}
        <button
          onClick={onCustomerClick}
          className="hidden sm:flex items-center gap-1.5 h-9 px-2 border border-gray-200 rounded-md
                     hover:bg-gray-50 transition-colors min-w-[110px] text-xs"
        >
          <PersonIcon className="w-5 h-5 text-gray-500" />
          <span className="text-sm text-gray-700 truncate max-w-[100px]">
            {selectedCustomer ? selectedCustomer.name : 'Walk-in'}
          </span>
          <ArrowDownIcon className="w-4 h-4 text-gray-400 ml-auto" />
        </button>

        {/* Grand Total */}
        <div className="pl-2 sm:pl-4 border-l border-gray-200">
          <div className="text-right">
            <span className="text-[10px] sm:text-xs text-gray-500 uppercase tracking-wide">Total</span>
            <p className="text-lg sm:text-xl font-bold text-purple-700">
              {formatCurrency(grandTotal)}
            </p>
          </div>
        </div>
      </div>

      {/* Row 2: Order Intent + Location + Shift (wraps on mobile) */}
      <div className="flex items-center gap-2 px-2 pb-2 overflow-x-auto scrollbar-hide">
        {/* Order Intent Segmented Control */}
        <OrderIntentSwitcher
          value={orderType}
          onChange={onOrderTypeChange}
          hasItems={hasItems}
          {...(orderTypeProps || {})}
        />

        {/* Location Dropdown */}
        <div className="relative shrink-0">
          <button
            ref={locationBtnRef}
            onClick={() => setLocationMenuOpen((v) => !v)}
            className={locationProps?.className || "flex items-center gap-1 h-8 px-2 border border-gray-200 rounded-md hover:bg-gray-50 transition-colors text-xs"}
            style={locationProps?.sx}
          >
            <LocationIcon className="w-4 h-4 text-green-600" />
            <span className="max-w-[80px] truncate">{locationName}</span>
            <ArrowDownIcon className={`w-3 h-3 text-gray-400 transition-transform ${locationMenuOpen ? 'rotate-180' : ''}`} />
          </button>

          {locationMenuOpen && (
            <>
              <div className="fixed inset-0 z-40" onClick={() => setLocationMenuOpen(false)} />
              <div className="absolute left-0 sm:right-0 sm:left-auto top-full mt-1 z-50 bg-white border border-gray-200 rounded-lg shadow-lg min-w-[220px] py-1">
                {accessibleLocations.map((loc) => {
                  const isSelected = loc.id === currentLocationId;
                  return (
                    <button
                      key={loc.id}
                      onClick={() => {
                        onLocationChange(loc.id);
                        setLocationMenuOpen(false);
                      }}
                      className={`w-full flex items-center gap-2 px-3 py-2 text-left text-sm hover:bg-gray-50 transition-colors ${
                        isSelected ? 'bg-purple-50 text-purple-700 font-semibold' : 'text-gray-700'
                      }`}
                    >
                      <LocationIcon className={`w-4 h-4 ${isSelected ? 'text-purple-600' : 'text-gray-400'}`} />
                      <span className="flex-1 truncate">{loc.name}</span>
                      {isSelected && <CheckIcon className="w-4 h-4 text-purple-600" />}
                    </button>
                  );
                })}
                {accessibleLocations.length === 0 && (
                  <div className="px-3 py-2 text-sm text-gray-400">No locations available</div>
                )}
              </div>
            </>
          )}
        </div>

        {/* Shift Status & Close Button */}
        {activeShift && (
          <ShiftChip shift={activeShift} onClose={onCloseShift} closeShiftProps={closeShiftProps} />
        )}
      </div>
    </header>
  );
};

// ─── ShiftChip — compact shift summary in the POS header ────
const CASH_VARIANCE_THRESHOLD = 5; // $ threshold for yellow warning

interface ShiftChipProps {
  shift: ShiftHeaderData;
  onClose: () => void;
  closeShiftProps?: any;
}

const ShiftChip: React.FC<ShiftChipProps> = ({
  shift,
  onClose,
  closeShiftProps,
}) => {
  const [expanded, setExpanded] = useState(false);

  const fmt = (v: number) => formatCurrency(v);

  const hasVarianceWarning =
    shift.cashDifference !== null &&
    Math.abs(shift.cashDifference) > CASH_VARIANCE_THRESHOLD;

  const isHealthy = !hasVarianceWarning;

  const refundAmount = shift.totalRefunds;

  return (
    <div className="relative flex items-center gap-1 pl-2 border-l border-gray-200">
      {/* Compact shift pill */}
      <button
        onClick={() => setExpanded((v) => !v)}
        className="hidden sm:flex items-center gap-1 px-2 py-1 rounded border border-gray-200 bg-gray-50 hover:bg-gray-100 transition-colors cursor-pointer select-none text-xs"
        title="Click to toggle shift details"
      >
        {/* Health dot */}
        <span
          className={`w-2 h-2 rounded-full shrink-0 ${
            isHealthy ? 'bg-green-500 shadow-[0_0_4px_rgba(34,197,94,0.5)]' : 'bg-yellow-400'
          }`}
        />

        {/* Primary: Txn count | Cash total */}
        <span className="text-[11px] font-semibold text-gray-800 tabular-nums leading-none whitespace-nowrap">
          {shift.transactionCount} txn
        </span>

        <span className="text-gray-300 text-[10px]">|</span>

        <span className="text-[11px] font-semibold text-gray-700 tabular-nums leading-none whitespace-nowrap">
          {fmt(shift.cashSales)} cash
        </span>

        {/* Variance warning icon */}
        {hasVarianceWarning && (
          <WarningIcon className="w-3.5 h-3.5 text-yellow-500 ml-0.5" />
        )}

        {/* Refund badge */}
        {refundAmount > 0 && (
          <span className="ml-0.5 px-1 py-0.5 bg-red-100 text-red-600 text-[9px] font-bold rounded leading-none">
            {fmt(refundAmount)} ref
          </span>
        )}
      </button>

      {/* Expanded mini-card */}
      {expanded && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setExpanded(false)} />
          <div className="absolute right-0 top-full mt-1 z-50 bg-white border border-gray-200 rounded-xl shadow-lg w-56 py-3 px-3.5">
            {/* Header */}
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-1.5">
                <span
                  className={`w-2 h-2 rounded-full ${
                    isHealthy ? 'bg-green-500' : 'bg-yellow-400'
                  }`}
                />
                <span className="text-xs font-semibold text-gray-800">Shift Active</span>
              </div>
              <span className="text-[10px] text-gray-400">
                {new Date(shift.openedAt).toLocaleTimeString([], {
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </span>
            </div>

            {/* Stats grid */}
            <div className="grid grid-cols-2 gap-y-1.5 gap-x-3 text-[11px]">
              <div className="flex justify-between">
                <span className="text-gray-500">Opening</span>
                <span className="font-semibold text-gray-800 tabular-nums">{fmt(shift.openingCash)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Txns</span>
                <span className="font-semibold text-gray-800 tabular-nums">{shift.transactionCount}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Cash Sales</span>
                <span className="font-semibold text-green-700 tabular-nums">{fmt(shift.cashSales)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-500">Refunds</span>
                <span
                  className={`font-semibold tabular-nums ${
                    refundAmount > 0 ? 'text-red-600' : 'text-gray-400'
                  }`}
                >
                  {fmt(refundAmount)}
                </span>
              </div>
              <div className="flex justify-between col-span-2 pt-1 border-t border-gray-100">
                <span className="text-gray-500">Expected Cash</span>
                <span className="font-semibold text-gray-800 tabular-nums">{fmt(shift.expectedCash)}</span>
              </div>
            </div>

            {/* Variance alert */}
            {hasVarianceWarning && (
              <div className="mt-2 flex items-center gap-1.5 px-2 py-1.5 bg-yellow-50 border border-yellow-200 rounded-lg">
                <WarningIcon className="w-3.5 h-3.5 text-yellow-500 shrink-0" />
                <span className="text-[10px] font-medium text-yellow-700">
                  Cash variance: {fmt(Math.abs(shift.cashDifference!))}
                </span>
              </div>
            )}

            {/* Opened by */}
            <p className="mt-2 text-[10px] text-gray-400 truncate">
              Opened by {shift.openedByName}
            </p>
          </div>
        </>
      )}

      {/* Close Shift button */}
      <button
        onClick={onClose}
        className={closeShiftProps?.className || "flex items-center gap-1 h-8 px-2 rounded bg-red-50 text-red-700 border border-red-200 hover:bg-red-100 active:bg-red-200 transition-colors font-medium text-xs min-w-[36px] min-h-[32px] touch-manipulation"}
        style={closeShiftProps?.sx}
        title="Close current shift"
      >
        <CloseShiftIcon className="w-4 h-4" />
        <span className="hidden md:inline">Close Shift</span>
      </button>
    </div>
  );
};

export default POSTopBar;
