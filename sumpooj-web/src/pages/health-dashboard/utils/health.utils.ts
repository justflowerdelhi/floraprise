/**
 * Inventory Health Dashboard — Utility Functions
 */

const INR = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  minimumFractionDigits: 0,
  maximumFractionDigits: 0,
});

const INR_PRECISE = new Intl.NumberFormat('en-IN', {
  style: 'currency',
  currency: 'INR',
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

const NUM = new Intl.NumberFormat('en-IN');

export const fmtCurrency     = (v: number): string => INR.format(v);
export const fmtCurrencyFull = (v: number): string => INR_PRECISE.format(v);
export const fmtNumber       = (v: number): string => NUM.format(v);
export const fmtPercent      = (v: number): string => `${v.toFixed(1)}%`;
export const fmtRatio        = (v: number): string => `${v.toFixed(1)}×`;

export const fmtDate = (iso: string): string => {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

/**
 * Abbreviate large numbers:  1200 → "₹1.2K",  245800 → "₹2.5L"
 */
export const fmtCompact = (v: number): string => {
  if (v >= 100000) return `₹${(v / 100000).toFixed(1)}L`;
  if (v >= 1000)   return `₹${(v / 1000).toFixed(1)}K`;
  return `₹${v}`;
};

/**
 * Recharts custom tooltip label formatter (short date)
 */
export const tooltipDateLabel = (label: string): string => label;

/**
 * Determine color for metric change — positive/negative
 */
export const trendColor = (value: number, invertGood = false): string => {
  if (value === 0) return '#9e9e9e';
  const isGood = invertGood ? value < 0 : value > 0;
  return isGood ? '#4caf50' : '#f44336';
};
