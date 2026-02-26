// =============================================================================
// ONBOARDING WIZARD — Country selection → Auto-fill currency & locale
// =============================================================================
// When a florist signs up / first logs in and tenant.country is not set,
// this wizard collects country, auto-fills baseCurrency + locale via
// countryCurrencyMap, then saves to TenantSettings.
// =============================================================================

import React, { useState, useCallback, useMemo } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Stepper,
  Step,
  StepLabel,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Alert,
  Chip,
  Stack,
  CircularProgress,
  useTheme,
} from '@mui/material';
import {
  Public,
  AttachMoney,
  Language,
  LocalFlorist,
  ArrowForward,
  ArrowBack,
  Check,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { TenantCountry, TaxSystemType } from '../../core/tenant/TenantTypes';
import {
  countryCurrencyMap,
  COUNTRY_DEFAULTS,
  CURRENCY_SYMBOL_MAP,
} from '../../core/tenant/TenantTypes';
import { formatCurrency } from '../../core/i18n';

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

const STEPS = ['Business Info', 'Country & Region', 'Review & Confirm'];

// -----------------------------------------------------------------------------
// Component
// -----------------------------------------------------------------------------

export default function OnboardingWizard() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();

  // Wizard step
  const [activeStep, setActiveStep] = useState(0);

  // Step 1: Business info
  const [businessName, setBusinessName] = useState('');

  // Step 2: Country selection → auto-derived currency/locale
  const [country, setCountry] = useState<TenantCountry | ''>('');

  // Derived from country via countryCurrencyMap
  const derived = useMemo(() => {
    if (!country) return null;
    const mapping = countryCurrencyMap[country];
    const defaults = COUNTRY_DEFAULTS[country];
    return {
      currency: mapping.currency,
      locale: mapping.locale,
      currencySymbol: CURRENCY_SYMBOL_MAP[mapping.currency] ?? mapping.currency,
      taxSystem: defaults.taxSystem,
      dateFormat: defaults.dateFormat,
      timeFormat: defaults.timeFormat,
    };
  }, [country]);

  // Save state
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  // Step validation
  const canAdvance = useCallback((): boolean => {
    switch (activeStep) {
      case 0:
        return businessName.trim().length >= 2;
      case 1:
        return !!country;
      case 2:
        return true;
      default:
        return false;
    }
  }, [activeStep, businessName, country]);

  // Step navigation
  const handleNext = () => {
    if (activeStep < STEPS.length - 1) {
      setActiveStep((s) => s + 1);
    }
  };

  const handleBack = () => {
    if (activeStep > 0) {
      setActiveStep((s) => s - 1);
    }
  };

  // Final submit
  const handleFinish = useCallback(async () => {
    if (!country || !derived) return;
    setSaving(true);
    setError('');
    try {
      // TODO: POST /api/tenant/onboarding {
      //   businessName,
      //   country,
      //   currency: derived.currency,
      //   locale: derived.locale,
      //   taxSystem: derived.taxSystem,
      //   dateFormat: derived.dateFormat,
      //   timeFormat: derived.timeFormat,
      // }
      console.log('[Onboarding] Saving tenant settings:', {
        businessName,
        country,
        currency: derived.currency,
        locale: derived.locale,
        taxSystem: derived.taxSystem,
      });

      // Simulate API delay
      await new Promise((r) => setTimeout(r, 800));

      // After success, redirect to dashboard
      navigate('/dashboard', { replace: true });
    } catch {
      setError('Failed to save settings. Please try again.');
    } finally {
      setSaving(false);
    }
  }, [businessName, country, derived, navigate]);

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: dk ? '#0f0f18' : '#f5f5f5',
        p: 2,
      }}
    >
      <Card
        sx={{
          width: '100%',
          maxWidth: 620,
          bgcolor: dk ? '#1a1a2e' : '#fff',
        }}
      >
        <CardContent sx={{ p: { xs: 3, sm: 4 } }}>
          {/* Logo / Title */}
          <Box sx={{ textAlign: 'center', mb: 3 }}>
            <LocalFlorist sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
            <Typography variant="h5" fontWeight={700}>
              Welcome to FloraPrice
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Let's set up your floral business in under a minute.
            </Typography>
          </Box>

          {/* Stepper */}
          <Stepper activeStep={activeStep} sx={{ mb: 4 }}>
            {STEPS.map((label) => (
              <Step key={label}>
                <StepLabel>{label}</StepLabel>
              </Step>
            ))}
          </Stepper>

          {/* ── Step 0: Business Info ── */}
          {activeStep === 0 && (
            <Box>
              <Typography variant="subtitle1" fontWeight={600} mb={2}>
                What's your business called?
              </Typography>
              <TextField
                fullWidth
                label="Business Name"
                placeholder="e.g. Blooming Florals"
                value={businessName}
                onChange={(e) => setBusinessName(e.target.value)}
                helperText="This will be your shop's display name."
              />
            </Box>
          )}

          {/* ── Step 1: Country Selection ── */}
          {activeStep === 1 && (
            <Box>
              <Typography variant="subtitle1" fontWeight={600} mb={2}>
                Where is your business located?
              </Typography>
              <FormControl fullWidth>
                <InputLabel>Country</InputLabel>
                <Select
                  value={country}
                  label="Country"
                  onChange={(e) => setCountry(e.target.value as TenantCountry)}
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

              {/* Auto-filled preview */}
              {derived && (
                <Box
                  sx={{
                    mt: 3,
                    p: 2,
                    borderRadius: 1,
                    bgcolor: dk ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)',
                    border: '1px solid',
                    borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
                  }}
                >
                  <Typography variant="subtitle2" color="text.secondary" mb={1.5}>
                    Auto-configured for your region:
                  </Typography>
                  <Stack direction="row" spacing={1} flexWrap="wrap" useFlexGap>
                    <Chip
                      icon={<AttachMoney sx={{ fontSize: 16 }} />}
                      label={`Currency: ${derived.currency} (${derived.currencySymbol})`}
                      size="small"
                      color="primary"
                      variant="outlined"
                    />
                    <Chip
                      icon={<Language sx={{ fontSize: 16 }} />}
                      label={`Locale: ${derived.locale}`}
                      size="small"
                      variant="outlined"
                    />
                    <Chip
                      label={`Tax: ${derived.taxSystem}`}
                      size="small"
                      variant="outlined"
                    />
                    <Chip
                      label={`Date: ${derived.dateFormat}`}
                      size="small"
                      variant="outlined"
                    />
                  </Stack>
                  <Typography variant="caption" color="text.secondary" display="block" mt={1.5}>
                    Example price: {formatCurrency(1500, derived.currency)}
                  </Typography>
                </Box>
              )}
            </Box>
          )}

          {/* ── Step 2: Review & Confirm ── */}
          {activeStep === 2 && derived && (
            <Box>
              <Typography variant="subtitle1" fontWeight={600} mb={2}>
                Review your settings
              </Typography>

              <Box
                sx={{
                  p: 2.5,
                  borderRadius: 1.5,
                  bgcolor: dk ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)',
                  border: '1px solid',
                  borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
                }}
              >
                <Stack spacing={2}>
                  <ReviewRow icon={<LocalFlorist sx={{ color: 'primary.main' }} />} label="Business" value={businessName} />
                  <ReviewRow icon={<Public sx={{ color: 'info.main' }} />} label="Country" value={COUNTRY_OPTIONS.find((c) => c.code === country)?.label ?? String(country)} />
                  <ReviewRow icon={<AttachMoney sx={{ color: 'success.main' }} />} label="Base Currency" value={`${derived.currency} (${derived.currencySymbol})`} />
                  <ReviewRow icon={<Language sx={{ color: 'warning.main' }} />} label="Locale" value={derived.locale} />
                  <ReviewRow label="Tax System" value={derived.taxSystem} />
                  <ReviewRow label="Date Format" value={derived.dateFormat} />
                  <ReviewRow label="Time Format" value={derived.timeFormat} />
                </Stack>
              </Box>

              <Alert severity="info" sx={{ mt: 2 }}>
                <Typography variant="body2">
                  You can change currency and locale later from{' '}
                  <strong>Settings → Tenant Settings</strong> (Admin only).
                </Typography>
              </Alert>

              {error && (
                <Alert severity="error" sx={{ mt: 2 }}>
                  {error}
                </Alert>
              )}
            </Box>
          )}

          {/* ── Navigation Buttons ── */}
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 4 }}>
            <Button
              variant="outlined"
              startIcon={<ArrowBack />}
              onClick={handleBack}
              disabled={activeStep === 0}
            >
              Back
            </Button>

            {activeStep < STEPS.length - 1 ? (
              <Button
                variant="contained"
                endIcon={<ArrowForward />}
                onClick={handleNext}
                disabled={!canAdvance()}
              >
                Continue
              </Button>
            ) : (
              <Button
                variant="contained"
                color="success"
                startIcon={saving ? <CircularProgress size={18} color="inherit" /> : <Check />}
                onClick={handleFinish}
                disabled={saving}
              >
                {saving ? 'Setting up...' : 'Complete Setup'}
              </Button>
            )}
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
}

// -----------------------------------------------------------------------------
// Review Row Helper
// -----------------------------------------------------------------------------

interface ReviewRowProps {
  icon?: React.ReactNode;
  label: string;
  value: string;
}

function ReviewRow({ icon, label, value }: ReviewRowProps) {
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
