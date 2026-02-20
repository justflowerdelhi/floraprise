// =============================================================================
// GLOBAL CURRENCY FORMATTER
// =============================================================================
// Uses Intl.NumberFormat. No hardcoded currency symbols anywhere.
// Usage:
//   formatCurrency(1500)          → uses current tenant currency
//   formatCurrency(1500, 'INR')   → "₹1,500.00"
//   formatCurrency(29.99, 'USD')  → "$29.99"
//   formatCurrency(100, 'AED')    → "AED 100.00"

const formatterCache = new Map<string, Intl.NumberFormat>();

/** Map currency code → locale for optimal formatting */
const CURRENCY_LOCALE_MAP: Record<string, string> = {
  USD: 'en-US',
  INR: 'en-IN',
  AED: 'en-AE',
  EUR: 'en-DE',
  GBP: 'en-GB',
  CAD: 'en-CA',
  AUD: 'en-AU',
};

// ─── Module-level current currency (set by TenantContext) ───

let _currentCurrency = 'USD';

/** Called by TenantContext on mount/change to set the active currency. */
export function setCurrentCurrency(code: string): void {
  _currentCurrency = code;
}

/** Get the active tenant currency code. */
export function getCurrentCurrency(): string {
  return _currentCurrency;
}

// ─── Formatter factory ──────────────────────────────────────

function getFormatter(currencyCode: string): Intl.NumberFormat {
  const cached = formatterCache.get(currencyCode);
  if (cached) return cached;

  const locale = CURRENCY_LOCALE_MAP[currencyCode] ?? 'en-US';
  const fmt = new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: currencyCode,
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  });
  formatterCache.set(currencyCode, fmt);
  return fmt;
}

/**
 * Format a number as currency using Intl.NumberFormat.
 * When `currencyCode` is omitted, uses the current tenant currency.
 */
export function formatCurrency(amount: number, currencyCode?: string): string {
  return getFormatter(currencyCode ?? _currentCurrency).format(amount);
}

/**
 * Compact currency format for dashboards.
 * e.g. $1.2M, ₹4.5L, AED 12K
 */
export function formatCurrencyCompact(amount: number, currencyCode?: string): string {
  const code = currencyCode ?? _currentCurrency;
  const symbol = getFormatter(code).formatToParts(0).find((p) => p.type === 'currency')?.value ?? code;

  if (code === 'INR') {
    // Indian numbering: Lakhs & Crores
    if (Math.abs(amount) >= 10_000_000) return `${symbol}${(amount / 10_000_000).toFixed(1)}Cr`;
    if (Math.abs(amount) >= 100_000) return `${symbol}${(amount / 100_000).toFixed(1)}L`;
    if (Math.abs(amount) >= 1_000) return `${symbol}${(amount / 1_000).toFixed(1)}K`;
    return `${symbol}${amount.toFixed(0)}`;
  }

  // Western numbering
  if (Math.abs(amount) >= 1_000_000) return `${symbol}${(amount / 1_000_000).toFixed(1)}M`;
  if (Math.abs(amount) >= 1_000) return `${symbol}${(amount / 1_000).toFixed(1)}K`;
  return `${symbol}${amount.toFixed(0)}`;
}

/**
 * Format a percentage value.
 */
export function formatPercent(value: number): string {
  return `${value.toFixed(1)}%`;
}
