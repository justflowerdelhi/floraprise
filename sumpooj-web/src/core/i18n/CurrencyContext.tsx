/**
 * CurrencyContext — React context for tenant-aware currency formatting.
 *
 * Reads the active currency from `setCurrentCurrency()` (called by TenantContext)
 * and exposes:
 *   - currencyCode, currencySymbol, locale
 *   - format(amount) — full format  (e.g. $1,500    or  ₹1,500)
 *   - formatCompact(amount) — compact (e.g. $1.5K   or  ₹1.5K)
 *   - symbol — for InputAdornment / labels
 *
 * The provider re-derives its value whenever `currencyCode` (prop) changes,
 * ensuring all consumers update when the tenant currency is switched.
 *
 * Usage:
 *   const { format, symbol } = useCurrency();
 *   <Typography>{format(1500)}</Typography>
 *   <InputAdornment>{symbol}</InputAdornment>
 */
import React, { createContext, useContext, useMemo } from 'react';
import {
  formatCurrency,
  formatCurrencyCompact,
  getCurrencySymbol,
  getCurrentCurrency,
} from './currency';

interface CurrencyContextValue {
  /** ISO 4217 currency code — e.g. 'USD', 'INR' */
  currencyCode: string;
  /** Display symbol — e.g. '$', '₹' */
  currencySymbol: string;
  /** BCP-47 locale — e.g. 'en-US', 'en-IN' */
  locale: string;
  /** Full-format a number: format(1500) → '$1,500.00' */
  format: (amount: number) => string;
  /** Compact-format a number: formatCompact(150000) → '$150K' */
  formatCompact: (amount: number) => string;
}

const CURRENCY_LOCALE_MAP: Record<string, string> = {
  USD: 'en-US',
  INR: 'en-IN',
  AED: 'en-AE',
  EUR: 'en-DE',
  GBP: 'en-GB',
  CAD: 'en-CA',
  AUD: 'en-AU',
};

const CurrencyCtx = createContext<CurrencyContextValue | null>(null);

/**
 * Provider whose value reacts to the currencyCode prop.
 * Typically rendered by TenantProvider with `currencyCode={tenant.currency}`.
 * When omitted, reads the module-level current currency.
 */
export const CurrencyProvider: React.FC<{
  currencyCode?: string;
  children: React.ReactNode;
}> = ({ currencyCode: propCode, children }) => {
  // Use prop if supplied, otherwise fall back to module-level default
  const code = propCode ?? getCurrentCurrency();

  const value = useMemo<CurrencyContextValue>(() => ({
    currencyCode: code,
    currencySymbol: getCurrencySymbol(code),
    locale: CURRENCY_LOCALE_MAP[code] ?? 'en-US',
    format: (amount: number) => formatCurrency(amount, code),
    formatCompact: (amount: number) => formatCurrencyCompact(amount, code),
  }), [code]);

  return <CurrencyCtx.Provider value={value}>{children}</CurrencyCtx.Provider>;
};

/**
 * Hook to access currency formatting in components.
 * Falls back to module-level formatCurrency when used outside provider.
 */
export function useCurrency(): CurrencyContextValue {
  const ctx = useContext(CurrencyCtx);
  if (ctx) return ctx;
  // Fallback — works even without provider
  const code = getCurrentCurrency();
  return {
    currencyCode: code,
    currencySymbol: getCurrencySymbol(code),
    locale: CURRENCY_LOCALE_MAP[code] ?? 'en-US',
    format: (amount: number) => formatCurrency(amount, code),
    formatCompact: (amount: number) => formatCurrencyCompact(amount, code),
  };
}

