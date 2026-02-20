// =============================================================================
// DATE & TIME FORMATTING UTILITIES
// =============================================================================
// Respects tenant dateFormat & timeFormat settings.
// Relies on Intl.DateTimeFormat for locale-aware output.

import type { TimeFormat } from '../tenant/TenantTypes';

type DateFormatPattern = 'MM/DD/YYYY' | 'DD/MM/YYYY' | 'YYYY-MM-DD';

/** Simple date formatter respecting tenant config. */
export function formatDate(
  date: Date | string | number,
  pattern: DateFormatPattern = 'MM/DD/YYYY',
): string {
  const d = new Date(date);
  if (isNaN(d.getTime())) return '—';

  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = String(d.getFullYear());

  switch (pattern) {
    case 'DD/MM/YYYY':
      return `${dd}/${mm}/${yyyy}`;
    case 'YYYY-MM-DD':
      return `${yyyy}-${mm}-${dd}`;
    case 'MM/DD/YYYY':
    default:
      return `${mm}/${dd}/${yyyy}`;
  }
}

/** Time formatter respecting 12H / 24H preference. */
export function formatTime(
  date: Date | string | number,
  format: TimeFormat = '12H',
): string {
  const d = new Date(date);
  if (isNaN(d.getTime())) return '—';

  if (format === '24H') {
    return d.toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit' });
  }
  return d.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true });
}

/** Date + time combined. */
export function formatDateTime(
  date: Date | string | number,
  datePattern?: DateFormatPattern,
  timeFormat?: TimeFormat,
): string {
  return `${formatDate(date, datePattern)} ${formatTime(date, timeFormat)}`;
}
