/**
 * CustomerSearchBar.tsx — Fast customer search & selection for POS
 *
 * Features:
 * - Single input with debounced live search
 * - Dropdown results with keyboard navigation (Arrow + Enter)
 * - ESC to clear selection
 * - Quick create option when no results
 * - Smart phone prefill on create
 */
import React, { useState, useRef, useEffect, useCallback, useMemo } from 'react';
import {
  Box, TextField, InputAdornment, Paper, Typography, Chip,
  CircularProgress, IconButton, useTheme, alpha, ClickAwayListener,
} from '@mui/material';
import {
  Search as SearchIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  Add as AddIcon,
  Close as CloseIcon,
  CheckCircle as SelectedIcon,
} from '@mui/icons-material';
import type { Customer, LoyaltyTier } from '../crm/CRMTypes';
import { LOYALTY_TIER_CONFIGS } from '../crm/CRMTypes';

// ─── Mock Data for Demo ─────────────────────────────────────

const MOCK_CUSTOMERS: Customer[] = [
  {
    id: 'cust_1',
    tenantId: 't1',
    name: 'Priya Sharma',
    phone: '9876543210',
    email: 'priya@email.com',
    tags: ['VIP', 'REPEAT_CUSTOMER'],
    lifetimeValue: 85000,
    totalOrders: 12,
    averageOrderValue: 7083,
    lastOrderDate: '2026-02-15',
    createdAt: '2024-06-10T10:00:00Z',
    loyaltyTier: 'GOLD',
    loyaltyPoints: 850,
  } as Customer & { loyaltyTier: LoyaltyTier; loyaltyPoints: number },
  {
    id: 'cust_2',
    tenantId: 't1',
    name: 'Rahul Mehta',
    phone: '9988776655',
    email: 'rahul.mehta@company.com',
    tags: ['CORPORATE'],
    lifetimeValue: 45000,
    totalOrders: 8,
    averageOrderValue: 5625,
    lastOrderDate: '2026-02-10',
    createdAt: '2025-01-15T10:00:00Z',
    loyaltyTier: 'SILVER',
    loyaltyPoints: 450,
  } as Customer & { loyaltyTier: LoyaltyTier; loyaltyPoints: number },
  {
    id: 'cust_3',
    tenantId: 't1',
    name: 'Anjali Gupta',
    phone: '9123456789',
    email: 'anjali.g@gmail.com',
    tags: ['NEW_CUSTOMER'],
    lifetimeValue: 3500,
    totalOrders: 2,
    averageOrderValue: 1750,
    lastOrderDate: '2026-02-18',
    createdAt: '2026-02-01T10:00:00Z',
    loyaltyTier: 'SILVER',
    loyaltyPoints: 35,
  } as Customer & { loyaltyTier: LoyaltyTier; loyaltyPoints: number },
];

// ─── Types ──────────────────────────────────────────────────

export interface SelectedCustomer {
  id: string;
  name: string;
  phone: string;
  email?: string;
  loyaltyTier?: LoyaltyTier;
}

interface CustomerSearchBarProps {
  selectedCustomer: SelectedCustomer | null;
  onSelectCustomer: (customer: SelectedCustomer | null) => void;
  onCreateNew: (prefillPhone?: string) => void;
  disabled?: boolean;
}

// ─── Component ──────────────────────────────────────────────

export default function CustomerSearchBar({
  selectedCustomer,
  onSelectCustomer,
  onCreateNew,
  disabled = false,
}: CustomerSearchBarProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [query, setQuery] = useState('');
  const [isOpen, setIsOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState<(Customer & { loyaltyTier?: LoyaltyTier })[]>([]);
  const [highlightedIndex, setHighlightedIndex] = useState(-1);

  const inputRef = useRef<HTMLInputElement>(null);
  const debounceRef = useRef<NodeJS.Timeout | null>(null);

  // ─── Debounced Search ─────────────────────────────────────

  const performSearch = useCallback((searchQuery: string) => {
    if (!searchQuery.trim()) {
      setResults([]);
      setIsOpen(false);
      return;
    }

    setLoading(true);
    
    // Simulate API delay
    setTimeout(() => {
      const q = searchQuery.toLowerCase();
      const filtered = MOCK_CUSTOMERS.filter(
        (c) =>
          c.name.toLowerCase().includes(q) ||
          c.phone.includes(q) ||
          (c.email && c.email.toLowerCase().includes(q))
      );
      setResults(filtered);
      setIsOpen(true);
      setLoading(false);
      setHighlightedIndex(-1);
    }, 150);
  }, []);

  useEffect(() => {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    
    if (query.trim()) {
      debounceRef.current = setTimeout(() => {
        performSearch(query);
      }, 200);
    } else {
      setResults([]);
      setIsOpen(false);
    }

    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [query, performSearch]);

  // ─── Keyboard Navigation ──────────────────────────────────

  const totalItems = results.length + 1; // +1 for "Create New" option

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!isOpen) {
      if (e.key === 'ArrowDown' && query.trim()) {
        setIsOpen(true);
        return;
      }
      return;
    }

    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault();
        setHighlightedIndex((prev) => (prev < totalItems - 1 ? prev + 1 : 0));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setHighlightedIndex((prev) => (prev > 0 ? prev - 1 : totalItems - 1));
        break;
      case 'Enter':
        e.preventDefault();
        if (highlightedIndex >= 0 && highlightedIndex < results.length) {
          handleSelectCustomer(results[highlightedIndex]);
        } else if (highlightedIndex === results.length || results.length === 0) {
          handleCreateNew();
        }
        break;
      case 'Escape':
        e.preventDefault();
        setIsOpen(false);
        setQuery('');
        if (selectedCustomer) {
          onSelectCustomer(null);
        }
        break;
    }
  }, [isOpen, highlightedIndex, results, totalItems, selectedCustomer, onSelectCustomer, query]);

  // ─── Handlers ─────────────────────────────────────────────

  const handleSelectCustomer = (customer: Customer & { loyaltyTier?: LoyaltyTier }) => {
    onSelectCustomer({
      id: customer.id,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      loyaltyTier: customer.loyaltyTier,
    });
    setQuery('');
    setIsOpen(false);
  };

  const handleCreateNew = () => {
    // If query looks like a phone number, prefill it
    const isPhone = /^[0-9+\-\s()]{7,}$/.test(query.trim());
    onCreateNew(isPhone ? query.trim().replace(/\D/g, '') : undefined);
    setQuery('');
    setIsOpen(false);
  };

  const handleClearSelection = () => {
    onSelectCustomer(null);
    inputRef.current?.focus();
  };

  // ─── Render Selected Customer Badge ───────────────────────

  if (selectedCustomer) {
    const tierConfig = selectedCustomer.loyaltyTier
      ? LOYALTY_TIER_CONFIGS[selectedCustomer.loyaltyTier]
      : null;

    return (
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 1.5,
          p: 1.5,
          borderRadius: 2,
          bgcolor: dk ? alpha('#4caf50', 0.15) : alpha('#4caf50', 0.08),
          border: `1px solid ${alpha('#4caf50', 0.3)}`,
          transition: 'all 0.15s',
        }}
      >
        <SelectedIcon sx={{ color: '#4caf50', fontSize: 20 }} />
        <Box sx={{ flex: 1, minWidth: 0 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="body2" sx={{ fontWeight: 700, color: dk ? '#fff' : 'text.primary' }} noWrap>
              {selectedCustomer.name}
            </Typography>
            {tierConfig && (
              <Chip
                label={tierConfig.label}
                size="small"
                sx={{
                  height: 20,
                  fontSize: '0.65rem',
                  fontWeight: 700,
                  bgcolor: tierConfig.backgroundColor,
                  color: tierConfig.color,
                }}
              />
            )}
          </Box>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}>
            {selectedCustomer.phone}
            {selectedCustomer.email && ` · ${selectedCustomer.email}`}
          </Typography>
        </Box>
        <IconButton
          size="small"
          onClick={handleClearSelection}
          sx={{
            width: 32,
            height: 32,
            color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
            '&:hover': { bgcolor: alpha('#f44336', 0.1), color: '#f44336' },
          }}
        >
          <CloseIcon sx={{ fontSize: 18 }} />
        </IconButton>
      </Box>
    );
  }

  // ─── Render Search Input ──────────────────────────────────

  return (
    <ClickAwayListener onClickAway={() => setIsOpen(false)}>
      <Box sx={{ position: 'relative' }}>
        <TextField
          inputRef={inputRef}
          fullWidth
          size="small"
          placeholder="Search customer by name, phone, or email..."
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          onFocus={() => query.trim() && setIsOpen(true)}
          disabled={disabled}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <PersonIcon sx={{ fontSize: 20, color: dk ? 'rgba(255,255,255,0.4)' : 'text.secondary' }} />
                </InputAdornment>
              ),
              endAdornment: loading ? (
                <InputAdornment position="end">
                  <CircularProgress size={18} />
                </InputAdornment>
              ) : null,
            },
          }}
          sx={{
            '& .MuiOutlinedInput-root': {
              minHeight: 44,
              bgcolor: dk ? 'rgba(255,255,255,0.04)' : '#fff',
              ...(dk && { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } }),
            },
          }}
        />

        {/* Dropdown Results */}
        {isOpen && (
          <Paper
            elevation={dk ? 0 : 4}
            sx={{
              position: 'absolute',
              top: '100%',
              left: 0,
              right: 0,
              mt: 0.5,
              zIndex: 1300,
              maxHeight: 320,
              overflow: 'auto',
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.1)' : 'none',
              borderRadius: 2,
            }}
          >
            {results.length > 0 ? (
              <>
                {results.map((customer, index) => {
                  const tierConfig = customer.loyaltyTier
                    ? LOYALTY_TIER_CONFIGS[customer.loyaltyTier]
                    : null;
                  const isHighlighted = index === highlightedIndex;

                  return (
                    <Box
                      key={customer.id}
                      onClick={() => handleSelectCustomer(customer)}
                      sx={{
                        px: 2,
                        py: 1.5,
                        cursor: 'pointer',
                        bgcolor: isHighlighted
                          ? dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)'
                          : 'transparent',
                        borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.05)' : '#f0f0f0'}`,
                        transition: 'background-color 0.1s',
                        '&:hover': {
                          bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.04)',
                        },
                        '&:last-of-type': { borderBottom: 'none' },
                      }}
                    >
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 0.5 }}>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {customer.name}
                        </Typography>
                        {tierConfig && (
                          <Chip
                            label={tierConfig.label}
                            size="small"
                            sx={{
                              height: 18,
                              fontSize: '0.6rem',
                              fontWeight: 700,
                              bgcolor: tierConfig.backgroundColor,
                              color: tierConfig.color,
                            }}
                          />
                        )}
                      </Box>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                        <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                          <PhoneIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                          <Typography variant="caption" color="text.secondary">
                            {customer.phone}
                          </Typography>
                        </Box>
                        {customer.email && (
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                            <EmailIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                            <Typography variant="caption" color="text.secondary" noWrap>
                              {customer.email}
                            </Typography>
                          </Box>
                        )}
                      </Box>
                    </Box>
                  );
                })}
              </>
            ) : (
              <Box sx={{ px: 2, py: 2, textAlign: 'center' }}>
                <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                  No customers found
                </Typography>
              </Box>
            )}

            {/* Create New Option */}
            <Box
              onClick={handleCreateNew}
              sx={{
                px: 2,
                py: 1.5,
                cursor: 'pointer',
                display: 'flex',
                alignItems: 'center',
                gap: 1.5,
                bgcolor: highlightedIndex === results.length
                  ? dk ? 'rgba(76, 175, 80, 0.15)' : 'rgba(76, 175, 80, 0.08)'
                  : dk ? 'rgba(255,255,255,0.03)' : '#fafafa',
                borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
                transition: 'background-color 0.1s',
                '&:hover': {
                  bgcolor: dk ? 'rgba(76, 175, 80, 0.15)' : 'rgba(76, 175, 80, 0.08)',
                },
              }}
            >
              <Box
                sx={{
                  width: 32,
                  height: 32,
                  borderRadius: '50%',
                  bgcolor: alpha('#4caf50', 0.15),
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <AddIcon sx={{ fontSize: 18, color: '#4caf50' }} />
              </Box>
              <Box>
                <Typography variant="body2" sx={{ fontWeight: 600, color: '#4caf50' }}>
                  Create New Customer
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  Quick add with minimal details
                </Typography>
              </Box>
            </Box>
          </Paper>
        )}
      </Box>
    </ClickAwayListener>
  );
}
