// =============================================================================
// TENANT SETTINGS PAGE — Admin-Only Tenant Configuration
// =============================================================================
// Displays current country / baseCurrency / locale.
// Admin can change currency — gated behind a confirmation checkbox +
// admin-password re-entry dialog.
// Non-admin roles see a read-only view.
// =============================================================================

import React, { useState, useMemo, useCallback } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Grid,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Button,
  Alert,
  Chip,
  Divider,
  Stack,
  useTheme,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControlLabel,
  Checkbox,
} from '@mui/material';
import {
  Warning,
  Save,
  Language,
  AttachMoney,
  Public,
  CalendarMonth,
  AccessTime,
  ReceiptLong,
  Lock,
  Shield,
} from '@mui/icons-material';
import { useTenant } from '../../core/tenant/TenantContext';
import { useRBAC } from '../../core/rbac/RBACContext';
import type { TenantCountry, TaxSystemType, TimeFormat } from '../../core/tenant/TenantTypes';
import type { DateFormat } from '../../core/tenant/TenantTypes';
import {
  COUNTRY_DEFAULTS,
  CURRENCY_SYMBOL_MAP,
  countryCurrencyMap,
  deriveTenantSettings,
} from '../../core/tenant/TenantTypes';
import { getCurrencySymbol } from '../../core/i18n';
import api from '../../api/axios';

// -----------------------------------------------------------------------------
// Constants
// -----------------------------------------------------------------------------

const COUNTRY_OPTIONS: { code: TenantCountry; label: string; flag: string }[] = [
  { code: 'US', label: 'United States', flag: '🇺🇸' },
  { code: 'IN', label: 'India', flag: '🇮🇳' },
  { code: 'AE', label: 'United Arab Emirates', flag: '🇦🇪' },
  { code: 'GB', label: 'United Kingdom', flag: '🇬🇧' },
  { code: 'CA', label: 'Canada', flag: '🇨🇦' },
  { code: 'AU', label: 'Australia', flag: '🇦🇺' },
];

const CURRENCY_OPTIONS = Object.entries(CURRENCY_SYMBOL_MAP).map(([code, symbol]) => ({
  code,
  label: `${code} (${symbol})`,
}));

const LOCALE_OPTIONS = Object.values(countryCurrencyMap).map((m) => m.locale);
const UNIQUE_LOCALES = [...new Set(LOCALE_OPTIONS)].map((l) => ({ value: l, label: l }));

const TAX_SYSTEM_OPTIONS: { value: TaxSystemType; label: string }[] = [
  { value: 'SALES_TAX', label: 'Sales Tax' },
  { value: 'GST', label: 'GST' },
  { value: 'VAT', label: 'VAT' },
];

const DATE_FORMAT_OPTIONS: { value: DateFormat; label: string }[] = [
  { value: 'MM/DD/YYYY', label: 'MM/DD/YYYY (US)' },
  { value: 'DD/MM/YYYY', label: 'DD/MM/YYYY (International)' },
  { value: 'YYYY-MM-DD', label: 'YYYY-MM-DD (ISO)' },
];

const TIME_FORMAT_OPTIONS: { value: TimeFormat; label: string }[] = [
  { value: '12H', label: '12-Hour (AM/PM)' },
  { value: '24H', label: '24-Hour' },
];

// -----------------------------------------------------------------------------
// Main Component
// -----------------------------------------------------------------------------

export default function TenantSettingsPage() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { tenant } = useTenant();
  const { role } = useRBAC();

  const isAdmin = role === 'ADMIN';

  // ── Local form state (initialized from tenant) ──
  const [country, setCountry] = useState<TenantCountry>(tenant.country);
  const [currency, setCurrency] = useState(tenant.currency);
  const [locale, setLocale] = useState(tenant.locale);
  const [taxSystem, setTaxSystem] = useState<TaxSystemType>(tenant.taxSystem);
  const [dateFormat, setDateFormat] = useState<DateFormat>(tenant.dateFormat);
  const [timeFormat, setTimeFormat] = useState<TimeFormat>(tenant.timeFormat);

  // ── Currency change confirmation dialog state ──
  const [showCurrencyWarning, setShowCurrencyWarning] = useState(false);
  const [pendingCurrency, setPendingCurrency] = useState<string | null>(null);
  const [confirmChecked, setConfirmChecked] = useState(false);
  const [adminPassword, setAdminPassword] = useState('');
  const [passwordError, setPasswordError] = useState('');

  // ── Save state ──
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  // Derived settings preview
  const settings = useMemo(
    () =>
      deriveTenantSettings({
        country,
        currency,
        locale: COUNTRY_DEFAULTS[country]?.locale ?? tenant.locale,
      }),
    [country, currency, tenant.locale],
  );

  // Dirty check
  const isDirty =
    country !== tenant.country ||
    currency !== tenant.currency ||
    locale !== tenant.locale ||
    taxSystem !== tenant.taxSystem ||
    dateFormat !== tenant.dateFormat ||
    timeFormat !== tenant.timeFormat;

  // ── When country changes, auto-update related fields via countryCurrencyMap ──
  const handleCountryChange = useCallback(
    (newCountry: TenantCountry) => {
      setCountry(newCountry);
      const mapping = countryCurrencyMap[newCountry];
      const defaults = COUNTRY_DEFAULTS[newCountry];
      if (mapping) {
        setCurrency(mapping.currency);
        setLocale(mapping.locale);
      }
      if (defaults) {
        setTaxSystem(defaults.taxSystem);
        setDateFormat(defaults.dateFormat);
        setTimeFormat(defaults.timeFormat);
      }
    },
    [],
  );

  // ── Currency change with confirmation gate ──
  const handleCurrencyChange = useCallback(
    (newCurrency: string) => {
      if (newCurrency !== tenant.currency) {
        setPendingCurrency(newCurrency);
        setConfirmChecked(false);
        setAdminPassword('');
        setPasswordError('');
        setShowCurrencyWarning(true);
      } else {
        setCurrency(newCurrency);
      }
    },
    [tenant.currency],
  );

  const confirmCurrencyChange = useCallback(async () => {
    if (!adminPassword.trim()) {
      setPasswordError('Admin password is required to change currency.');
      return;
    }
    try {
      const res = await api.post('/auth/verify-password', { password: adminPassword });
      if (!res.data?.verified) {
        setPasswordError('Incorrect password. Please try again.');
        return;
      }
      if (pendingCurrency) {
        setCurrency(pendingCurrency);
      }
      setPendingCurrency(null);
      setShowCurrencyWarning(false);
      setConfirmChecked(false);
      setAdminPassword('');
      setPasswordError('');
    } catch {
      setPasswordError('Password verification failed. Try again.');
    }
  }, [pendingCurrency, adminPassword]);

  const cancelCurrencyChange = useCallback(() => {
    setPendingCurrency(null);
    setShowCurrencyWarning(false);
    setConfirmChecked(false);
    setAdminPassword('');
    setPasswordError('');
  }, []);

  const handleLocaleChange = useCallback((newLocale: string) => {
    setLocale(newLocale);
  }, []);

  // ── Save handler ──
  const handleSave = useCallback(async () => {
    setSaving(true);
    try {
      await api.post('/tenant/settings', {
        currencyCode: currency,
      });
      setSaved(true);
      setTimeout(() => setSaved(false), 3000);
    } catch (err) {
      console.error('Failed to save tenant settings:', err);
    } finally {
      setSaving(false);
    }
  }, [country, currency, locale, taxSystem, dateFormat, timeFormat]);

  // ══════════════════════════════════════════════════════════
  // Non-admin: read-only view
  // ══════════════════════════════════════════════════════════
  if (!isAdmin) {
    return (
      <Box sx={{ p: { xs: 2, sm: 3 }, maxWidth: 700, mx: 'auto' }}>
        <Box sx={{ mb: 3 }}>
          <Typography variant="h5" fontWeight={700}>
            Tenant Settings
          </Typography>
          <Typography variant="body2" color="text.secondary" mt={0.5}>
            View your organization's regional and currency configuration.
          </Typography>
        </Box>

        <Alert severity="info" icon={<Lock />} sx={{ mb: 3 }}>
          Only administrators can modify these settings. Contact your admin for changes.
        </Alert>

        <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
          <CardContent>
            <Stack spacing={2.5}>
              <ReadOnlyRow
                icon={<Public sx={{ color: 'info.main' }} />}
                label="Country"
                value={COUNTRY_OPTIONS.find((c) => c.code === tenant.country)?.label ?? tenant.country}
              />
              <ReadOnlyRow
                icon={<AttachMoney sx={{ color: 'success.main' }} />}
                label="Base Currency"
                value={`${tenant.currency} (${getCurrencySymbol()})`}
              />
              <ReadOnlyRow
                icon={<Language sx={{ color: 'warning.main' }} />}
                label="Locale"
                value={tenant.locale}
              />
              <ReadOnlyRow
                icon={<ReceiptLong sx={{ color: 'secondary.main' }} />}
                label="Tax System"
                value={tenant.taxSystem}
              />
              <ReadOnlyRow label="Date Format" value={tenant.dateFormat} />
              <ReadOnlyRow label="Time Format" value={tenant.timeFormat} />
            </Stack>
          </CardContent>
        </Card>
      </Box>
    );
  }

  // ══════════════════════════════════════════════════════════
  // Admin: full editable view
  // ══════════════════════════════════════════════════════════
  return (
    <Box sx={{ p: { xs: 2, sm: 3 }, maxWidth: 900, mx: 'auto' }}>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>
          Tenant Settings
        </Typography>
        <Typography variant="body2" color="text.secondary" mt={0.5}>
          Configure regional, currency, and formatting preferences for your organization.
        </Typography>
      </Box>

      {/* ── Active Configuration Chips ── */}
      <Card sx={{ mb: 3, bgcolor: dk ? '#1a1a2e' : '#fff' }}>
        <CardContent>
          <Typography variant="subtitle2" color="text.secondary" gutterBottom>
            Active Configuration
          </Typography>
          <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
            <Chip
              icon={<Public sx={{ fontSize: 16 }} />}
              label={COUNTRY_OPTIONS.find((c) => c.code === tenant.country)?.label ?? tenant.country}
              size="small"
              variant="outlined"
            />
            <Chip
              icon={<AttachMoney sx={{ fontSize: 16 }} />}
              label={`${tenant.currency} (${getCurrencySymbol()})`}
              size="small"
              variant="outlined"
              color="primary"
            />
            <Chip
              icon={<Language sx={{ fontSize: 16 }} />}
              label={tenant.locale}
              size="small"
              variant="outlined"
            />
            <Chip
              icon={<ReceiptLong sx={{ fontSize: 16 }} />}
              label={tenant.taxSystem}
              size="small"
              variant="outlined"
            />
          </Stack>
        </CardContent>
      </Card>

      {/* ── Currency & Locale Section (dedicated card) ── */}
      <Card sx={{ mb: 3, bgcolor: dk ? '#1a1a2e' : '#fff', border: '1px solid', borderColor: 'primary.main' }}>
        <CardContent sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2 }}>
            <AttachMoney color="primary" />
            <Typography variant="h6" fontWeight={700}>
              Currency &amp; Locale
            </Typography>
            <Chip label="Admin Only" size="small" color="warning" icon={<Shield sx={{ fontSize: 14 }} />} />
          </Box>

          <Typography variant="body2" color="text.secondary" mb={3}>
            Currency and locale are auto-assigned when you select a country.
            You may override them below — changes affect all monetary displays across the system.
          </Typography>

          <Grid container spacing={3}>
            {/* Country */}
            <Grid size={{ xs: 12, sm: 4 }}>
              <FormControl fullWidth>
                <InputLabel>Country</InputLabel>
                <Select
                  value={country}
                  label="Country"
                  onChange={(e) => handleCountryChange(e.target.value as TenantCountry)}
                >
                  {COUNTRY_OPTIONS.map((c) => (
                    <MenuItem key={c.code} value={c.code}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <span>{c.flag}</span>
                        <span>{c.label}</span>
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Base Currency */}
            <Grid size={{ xs: 12, sm: 4 }}>
              <FormControl fullWidth>
                <InputLabel>Base Currency</InputLabel>
                <Select
                  value={currency}
                  label="Base Currency"
                  onChange={(e) => handleCurrencyChange(e.target.value)}
                >
                  {CURRENCY_OPTIONS.map((c) => (
                    <MenuItem key={c.code} value={c.code}>
                      {c.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              {currency !== tenant.currency && (
                <Typography variant="caption" color="warning.main" sx={{ mt: 0.5, display: 'block' }}>
                  Currency change pending — will affect all financial displays.
                </Typography>
              )}
            </Grid>

            {/* Locale */}
            <Grid size={{ xs: 12, sm: 4 }}>
              <FormControl fullWidth>
                <InputLabel>Locale</InputLabel>
                <Select
                  value={locale}
                  label="Locale"
                  onChange={(e) => handleLocaleChange(e.target.value)}
                >
                  {UNIQUE_LOCALES.map((l) => (
                    <MenuItem key={l.value} value={l.value}>
                      {l.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* ── Regional / Formatting Settings ── */}
      <Card sx={{ mb: 3, bgcolor: dk ? '#1a1a2e' : '#fff' }}>
        <CardContent sx={{ p: 3 }}>
          <Typography variant="h6" fontWeight={700} mb={2}>
            Regional Formatting
          </Typography>

          <Grid container spacing={3}>
            {/* Tax System */}
            <Grid size={{ xs: 12, sm: 4 }}>
              <FormControl fullWidth>
                <InputLabel>Tax System</InputLabel>
                <Select
                  value={taxSystem}
                  label="Tax System"
                  onChange={(e) => setTaxSystem(e.target.value as TaxSystemType)}
                >
                  {TAX_SYSTEM_OPTIONS.map((t) => (
                    <MenuItem key={t.value} value={t.value}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <ReceiptLong sx={{ fontSize: 16, color: 'text.secondary' }} />
                        {t.label}
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Date Format */}
            <Grid size={{ xs: 12, sm: 4 }}>
              <FormControl fullWidth>
                <InputLabel>Date Format</InputLabel>
                <Select
                  value={dateFormat}
                  label="Date Format"
                  onChange={(e) => setDateFormat(e.target.value as DateFormat)}
                >
                  {DATE_FORMAT_OPTIONS.map((d) => (
                    <MenuItem key={d.value} value={d.value}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <CalendarMonth sx={{ fontSize: 16, color: 'text.secondary' }} />
                        {d.label}
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Time Format */}
            <Grid size={{ xs: 12, sm: 4 }}>
              <FormControl fullWidth>
                <InputLabel>Time Format</InputLabel>
                <Select
                  value={timeFormat}
                  label="Time Format"
                  onChange={(e) => setTimeFormat(e.target.value as TimeFormat)}
                >
                  {TIME_FORMAT_OPTIONS.map((t) => (
                    <MenuItem key={t.value} value={t.value}>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <AccessTime sx={{ fontSize: 16, color: 'text.secondary' }} />
                        {t.label}
                      </Box>
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* ── Save Bar ── */}
      <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
        <CardContent sx={{ p: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
            <Button
              variant="contained"
              startIcon={<Save />}
              disabled={!isDirty || saving}
              onClick={handleSave}
              sx={{ minWidth: 140 }}
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </Button>
            {saved && (
              <Typography variant="body2" color="success.main" fontWeight={600}>
                Settings saved successfully.
              </Typography>
            )}
          </Box>

          {isDirty && (
            <Alert severity="info" sx={{ mt: 2 }}>
              <Typography variant="body2">
                <strong>Preview:</strong> Currency will display as{' '}
                <strong>{settings.currencySymbol}</strong> ({settings.baseCurrency}),
                locale <strong>{settings.locale}</strong>.
              </Typography>
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* ══════════════════════════════════════════════════════════
          Currency Change Confirmation Dialog
          — Requires: confirmation checkbox + admin password re-entry
         ══════════════════════════════════════════════════════════ */}
      <Dialog open={showCurrencyWarning} onClose={cancelCurrencyChange} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1, pb: 1 }}>
          <Warning color="warning" />
          Confirm Currency Change
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" sx={{ mb: 2 }}>
            You are about to change the base currency from{' '}
            <strong>
              {tenant.currency} ({CURRENCY_SYMBOL_MAP[tenant.currency] ?? tenant.currency})
            </strong>{' '}
            to{' '}
            <strong>
              {pendingCurrency} ({CURRENCY_SYMBOL_MAP[pendingCurrency ?? ''] ?? pendingCurrency})
            </strong>
            .
          </Typography>

          <Alert severity="warning" sx={{ mb: 2 }}>
            <Typography variant="body2" fontWeight={600}>
              This will affect all financial reports, invoices, and transaction displays.
            </Typography>
            <Typography variant="caption" display="block" mt={0.5}>
              Existing transaction amounts will NOT be converted. Only the display currency
              symbol and formatting will change. Ensure all teams are informed before proceeding.
            </Typography>
          </Alert>

          <Divider sx={{ my: 2 }} />

          {/* Confirmation Checkbox */}
          <FormControlLabel
            control={
              <Checkbox
                checked={confirmChecked}
                onChange={(e) => setConfirmChecked(e.target.checked)}
                color="warning"
              />
            }
            label={
              <Typography variant="body2">
                I understand this change affects all monetary displays and cannot be automatically reversed.
              </Typography>
            }
            sx={{ mb: 2, alignItems: 'flex-start', '& .MuiCheckbox-root': { pt: 0 } }}
          />

          {/* Admin Password Re-entry */}
          <TextField
            fullWidth
            type="password"
            label="Admin Password"
            placeholder="Re-enter your password to confirm"
            value={adminPassword}
            onChange={(e) => {
              setAdminPassword(e.target.value);
              if (passwordError) setPasswordError('');
            }}
            error={!!passwordError}
            helperText={passwordError || 'Required for security verification.'}
            InputProps={{
              startAdornment: <Lock sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />,
            }}
          />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={cancelCurrencyChange}>Cancel</Button>
          <Button
            variant="contained"
            color="warning"
            onClick={confirmCurrencyChange}
            disabled={!confirmChecked || !adminPassword.trim()}
          >
            Confirm Currency Change
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Read-Only Row (for non-admin view)
// -----------------------------------------------------------------------------

interface ReadOnlyRowProps {
  icon?: React.ReactNode;
  label: string;
  value: string;
}

function ReadOnlyRow({ icon, label, value }: ReadOnlyRowProps) {
  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
      {icon && <Box sx={{ display: 'flex', alignItems: 'center' }}>{icon}</Box>}
      <Box>
        <Typography variant="caption" color="text.secondary" display="block">
          {label}
        </Typography>
        <Typography variant="body2" fontWeight={600}>
          {value}
        </Typography>
      </Box>
    </Box>
  );
}
