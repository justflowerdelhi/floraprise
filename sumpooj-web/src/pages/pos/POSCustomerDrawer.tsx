/**
 * POSCustomerDrawer.tsx — Slide-in customer selector drawer
 * Search and select customers, or continue as walk-in
 */
import React, { useState, useMemo, useCallback } from 'react';
import {
  Close as CloseIcon,
  Search as SearchIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Check as CheckIcon,
} from '@mui/icons-material';
import { Drawer } from '@mui/material';
import type { POSCustomer } from './POSTypes';

interface POSCustomerDrawerProps {
  open: boolean;
  onClose: () => void;
  customers: POSCustomer[];
  selectedCustomer: POSCustomer | null;
  onSelectCustomer: (customer: POSCustomer | null) => void;
}

const POSCustomerDrawer: React.FC<POSCustomerDrawerProps> = ({
  open,
  onClose,
  customers,
  selectedCustomer,
  onSelectCustomer,
}) => {
  const [searchQuery, setSearchQuery] = useState('');

  const filteredCustomers = useMemo(() => {
    if (!searchQuery.trim()) return customers.slice(0, 50); // Limit initial display

    const query = searchQuery.toLowerCase();
    return customers.filter(
      (c) =>
        c.name.toLowerCase().includes(query) ||
        c.phone.replace(/\s/g, '').includes(query.replace(/\s/g, '')) ||
        (c.email && c.email.toLowerCase().includes(query))
    ).slice(0, 50);
  }, [customers, searchQuery]);

  const handleSelect = useCallback((customer: POSCustomer) => {
    onSelectCustomer(customer);
    onClose();
  }, [onSelectCustomer, onClose]);

  const handleWalkIn = useCallback(() => {
    onSelectCustomer(null);
    onClose();
  }, [onSelectCustomer, onClose]);

  return (
    <Drawer
      anchor="right"
      open={open}
      onClose={onClose}
      PaperProps={{
        sx: { width: 380, maxWidth: '100vw' },
      }}
    >
      <div className="h-full flex flex-col bg-white">
        {/* Header */}
        <header className="px-4 py-3 border-b border-gray-200 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-gray-900">Select Customer</h2>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <CloseIcon className="w-5 h-5" />
          </button>
        </header>

        {/* Search */}
        <div className="px-4 py-3 border-b border-gray-200">
          <div className="relative">
            <SearchIcon className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by name, phone, or email..."
              className="w-full h-10 pl-10 pr-4 text-sm border border-gray-200 rounded-lg
                         focus:outline-none focus:ring-2 focus:ring-purple-500 focus:border-transparent"
              autoFocus
            />
          </div>
        </div>

        {/* Walk-in Option */}
        <div className="px-4 py-3 border-b border-gray-200">
          <button
            onClick={handleWalkIn}
            className={`
              w-full flex items-center gap-3 p-3 rounded-lg border transition-colors
              ${!selectedCustomer
                ? 'border-purple-500 bg-purple-50'
                : 'border-gray-200 hover:bg-gray-50'
              }
            `}
          >
            <span className="w-10 h-10 flex items-center justify-center bg-gray-100 rounded-full text-gray-500">
              <PersonIcon className="w-5 h-5" />
            </span>
            <div className="flex-1 text-left">
              <span className="block text-sm font-medium text-gray-900">Walk-in Customer</span>
              <span className="block text-xs text-gray-500">No customer info required</span>
            </div>
            {!selectedCustomer && (
              <CheckIcon className="w-5 h-5 text-purple-600" />
            )}
          </button>
        </div>

        {/* Customer List */}
        <div className="flex-1 overflow-y-auto">
          {filteredCustomers.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center px-4">
              <div className="w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mb-3">
                <PersonIcon className="w-6 h-6 text-gray-400" />
              </div>
              <p className="text-gray-500 text-sm">No customers found</p>
              <p className="text-gray-400 text-xs mt-1">Try a different search term</p>
            </div>
          ) : (
            <ul className="divide-y divide-gray-100">
              {filteredCustomers.map((customer) => {
                const isSelected = selectedCustomer?.id === customer.id;
                return (
                  <li key={customer.id}>
                    <button
                      onClick={() => handleSelect(customer)}
                      className={`
                        w-full flex items-center gap-3 p-4 text-left transition-colors
                        ${isSelected ? 'bg-purple-50' : 'hover:bg-gray-50'}
                      `}
                    >
                      {/* Avatar */}
                      <span className="w-10 h-10 flex items-center justify-center bg-purple-100 rounded-full text-purple-600 font-semibold text-sm shrink-0">
                        {customer.name.charAt(0).toUpperCase()}
                      </span>

                      {/* Info */}
                      <div className="flex-1 min-w-0">
                        <span className="block text-sm font-medium text-gray-900 truncate">
                          {customer.name}
                        </span>
                        <div className="flex items-center gap-3 mt-0.5">
                          <span className="flex items-center gap-1 text-xs text-gray-500">
                            <PhoneIcon className="w-3 h-3" />
                            {customer.phone}
                          </span>
                          {customer.email && (
                            <span className="flex items-center gap-1 text-xs text-gray-500 truncate">
                              <EmailIcon className="w-3 h-3" />
                              {customer.email}
                            </span>
                          )}
                        </div>
                      </div>

                      {/* Selected indicator */}
                      {isSelected && (
                        <CheckIcon className="w-5 h-5 text-purple-600 shrink-0" />
                      )}
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </div>

        {/* Selected customer summary */}
        {selectedCustomer && (
          <footer className="px-4 py-3 bg-gray-50 border-t border-gray-200">
            <div className="flex items-center gap-3">
              <span className="w-8 h-8 flex items-center justify-center bg-purple-600 rounded-full text-white font-semibold text-xs">
                {selectedCustomer.name.charAt(0).toUpperCase()}
              </span>
              <div className="flex-1 min-w-0">
                <span className="block text-sm font-medium text-gray-900 truncate">
                  {selectedCustomer.name}
                </span>
                <span className="block text-xs text-gray-500">
                  {selectedCustomer.totalOrders || 0} orders • {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(selectedCustomer.lifetimeValue || 0)} lifetime
                </span>
              </div>
            </div>
          </footer>
        )}
      </div>
    </Drawer>
  );
};

export default POSCustomerDrawer;
