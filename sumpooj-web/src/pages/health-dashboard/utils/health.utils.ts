/**
 * Inventory Health Dashboard — Utility Functions
 */
import { formatCurrency, formatCurrencyCompact } from '../../../core/i18n';

const NUM = new Intl.NumberFormat('en-IN');

export const fmtCurrency     = (v: number): string => formatCurrency(v);
export const fmtCurrencyFull = (v: number): string => formatCurrency(v);
export const fmtNumber       = (v: number): string => NUM.format(v);
export const fmtPercent      = (v: number): string => `${v.toFixed(1)}%`;
export const fmtRatio        = (v: number): string => `${v.toFixed(1)}×`;

export const fmtDate = (iso: string): string => {
  const d = new Date(iso);
  return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });
};

/**
 * Abbreviate large numbers using tenant-aware compact format
 */
export const fmtCompact = (v: number): string => formatCurrencyCompact(v);

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
