/**
 * POSTopBar.tsx — Top transaction bar for FloraEdge POS
 * Fixed 64px height with search, customer selector, order type, location, and grand total
 */
import React, { useRef, useEffect, useCallback } from 'react';
import {
  Search as SearchIcon,
  Person as PersonIcon,
  KeyboardArrowDown as ArrowDownIcon,
  LocationOn as LocationIcon,
} from '@mui/icons-material';
import type { OrderIntent, POSCustomer } from './POSTypes';
import { POS_SHORTCUTS } from './POSTypes';
import OrderIntentSwitcher from './OrderIntentSwitcher';

interface POSTopBarProps {
  searchValue: string;
  onSearchChange: (value: string) => void;
  onSearchSubmit: () => void;
  selectedCustomer: POSCustomer | null;
  onCustomerClick: () => void;
  orderType: OrderIntent;
  onOrderTypeChange: (type: OrderIntent) => void;
  locationName: string;
  onLocationClick: () => void;
  grandTotal: number;
  hasItems: boolean;
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
  onLocationClick,
  grandTotal,
  hasItems,
}) => {
  const searchRef = useRef<HTMLInputElement>(null);

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

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 2,
    }).format(amount);
  };

  return (
    <header className="h-16 bg-white border-b border-gray-200 flex items-center px-4 gap-4 shrink-0">
      {/* Search / Barcode Input */}
      <div className="flex-1 max-w-md">
        <div className="relative">
          <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            ref={searchRef}
            type="text"
            placeholder="Search products or scan barcode... (F2)"
            value={searchValue}
            onChange={(e) => onSearchChange(e.target.value)}
            onKeyDown={handleKeyDown}
            className="w-full h-10 pl-10 pr-4 text-sm border border-gray-200 rounded-lg 
                       focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent
                       placeholder:text-gray-400"
          />
        </div>
      </div>

      {/* Customer Selector */}
      <button
        onClick={onCustomerClick}
        className="flex items-center gap-2 h-10 px-3 border border-gray-200 rounded-lg
                   hover:bg-gray-50 transition-colors min-w-[140px]"
      >
        <PersonIcon className="w-5 h-5 text-gray-500" />
        <span className="text-sm text-gray-700 truncate max-w-[100px]">
          {selectedCustomer ? selectedCustomer.name : 'Walk-in'}
        </span>
        <ArrowDownIcon className="w-4 h-4 text-gray-400 ml-auto" />
      </button>

      {/* Order Intent Segmented Control */}
      <OrderIntentSwitcher
        value={orderType}
        onChange={onOrderTypeChange}
        hasItems={hasItems}
      />

      {/* Location Dropdown */}
      <button
        onClick={onLocationClick}
        className="flex items-center gap-2 h-10 px-3 border border-gray-200 rounded-lg
                   hover:bg-gray-50 transition-colors"
      >
        <LocationIcon className="w-5 h-5 text-gray-500" />
        <span className="text-sm text-gray-700">{locationName}</span>
        <ArrowDownIcon className="w-4 h-4 text-gray-400" />
      </button>

      {/* Grand Total */}
      <div className="ml-auto pl-4 border-l border-gray-200">
        <div className="text-right">
          <span className="text-xs text-gray-500 uppercase tracking-wide">Total</span>
          <p className="text-xl font-bold text-purple-700">
            {formatCurrency(grandTotal)}
          </p>
        </div>
      </div>
    </header>
  );
};

export default POSTopBar;
