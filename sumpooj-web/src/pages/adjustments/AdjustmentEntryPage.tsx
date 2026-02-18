/**
 * Inventory Adjustment / Wastage Entry — Main Page
 * Florist POS + ERP SaaS Platform
 *
 * Orchestrates: AdjustmentForm (left) + WastageSummaryPanel (right)
 * Includes dark mode toggle, smart alerts, loading states, submit action.
 */

import { useState, useEffect, useMemo, useCallback } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Box,
  Container,
  Typography,
  Button,
  IconButton,
  Tooltip,
  Snackbar,
  Alert,
  CircularProgress,
} from '@mui/material';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import DeleteSweepIcon from '@mui/icons-material/DeleteSweep';
import SaveIcon from '@mui/icons-material/Save';
import RefreshIcon from '@mui/icons-material/Refresh';

import type { AdjustmentProduct, AdjustmentRecord } from './data/adjustment.data';
import {
  fetchProducts,
  fetchRecentAdjustments,
  submitAdjustment,
  defaultFormValues,
} from './data/adjustment.data';
import { adjustmentSchema } from './schemas/adjustment.schema';
import type { AdjustmentSchemaType } from './schemas/adjustment.schema';
import { computeWastageSummary, buildPayload, fmt } from './utils/adjustment.utils';

import AdjustmentForm from './components/AdjustmentForm';
import WastageSummaryPanel from './components/WastageSummaryPanel';

const AdjustmentEntryPage = () => {
  // ── State ──────────────────────────────────────────────────
  const [darkMode, setDarkMode] = useState(false);
  const [loading, setLoading] = useState(true);
  const [products, setProducts] = useState<AdjustmentProduct[]>([]);
  const [recentAdjustments, setRecentAdjustments] = useState<AdjustmentRecord[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'warning' | 'info';
  }>({ open: false, message: '', severity: 'info' });

  // ── Form ───────────────────────────────────────────────────
  const {
    control,
    handleSubmit,
    watch,
    setValue,
    reset,
    formState: { errors, isDirty },
  } = useForm<AdjustmentSchemaType>({
    resolver: zodResolver(adjustmentSchema) as any,
    defaultValues: { ...defaultFormValues },
    mode: 'onChange',
  });

  // ── Load data ──────────────────────────────────────────────
  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    Promise.all([fetchProducts(), fetchRecentAdjustments()]).then(
      ([prods, adjs]) => {
        if (!cancelled) {
          setProducts(prods);
          setRecentAdjustments(adjs);
          setLoading(false);
        }
      },
    );
    return () => {
      cancelled = true;
    };
  }, []);

  // ── Wastage summary ───────────────────────────────────────
  const totalInventoryValue = useMemo(
    () => products.reduce((sum, p) => sum + p.currentStock * p.costPerUnit, 0),
    [products],
  );

  const wastageSummary = useMemo(
    () =>
      recentAdjustments.length > 0
        ? computeWastageSummary(recentAdjustments, totalInventoryValue)
        : null,
    [recentAdjustments, totalInventoryValue],
  );

  // ── Submit ─────────────────────────────────────────────────
  const onSubmit = useCallback(
    async (data: AdjustmentSchemaType) => {
      // Extra validation: perishable → batch required
      const product = products.find((p) => p.id === data.productId);
      if (product?.isPerishable && !data.batchId) {
        setSnackbar({
          open: true,
          message: 'Batch is required for perishable products',
          severity: 'error',
        });
        return;
      }

      // Cannot exceed stock
      if (product && data.quantity > product.currentStock) {
        setSnackbar({
          open: true,
          message: `Quantity exceeds available stock (${product.currentStock})`,
          severity: 'error',
        });
        return;
      }

      setIsSubmitting(true);
      try {
        const payload = buildPayload(data, product);
        const result = await submitAdjustment(payload);
        if (result.success) {
          setSnackbar({
            open: true,
            message: `Adjustment recorded — ${fmt(payload.totalValue)} deducted`,
            severity: 'success',
          });
          reset({ ...defaultFormValues });
        }
      } catch {
        setSnackbar({
          open: true,
          message: 'Failed to submit adjustment. Try again.',
          severity: 'error',
        });
      } finally {
        setIsSubmitting(false);
      }
    },
    [products, reset],
  );

  // ── Styling ────────────────────────────────────────────────
  const bgColor = darkMode ? '#0f0f0f' : '#f8f9fa';
  const textPrimary = darkMode ? '#f5f5f5' : '#1a1a1a';
  const textSecondary = darkMode ? '#9e9e9e' : '#666';

  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: bgColor,
        transition: 'background-color 0.3s ease',
        pb: 6,
      }}
    >
      <Container maxWidth="lg" sx={{ pt: 3 }}>
        {/* ── Header ──────────────────────────────────────── */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            mb: 3,
            flexWrap: 'wrap',
            gap: 1,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <DeleteSweepIcon sx={{ fontSize: 28, color: '#c62828' }} />
            <Box>
              <Typography
                variant="h5"
                sx={{ fontWeight: 800, color: textPrimary, lineHeight: 1.2 }}
              >
                Inventory Adjustment
              </Typography>
              <Typography
                variant="body2"
                sx={{ color: textSecondary, fontSize: '0.8rem' }}
              >
                Record spoilage, damage, corrections & internal usage
              </Typography>
            </Box>
          </Box>

          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Tooltip title={darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'}>
              <IconButton
                onClick={() => setDarkMode((v) => !v)}
                sx={{
                  color: darkMode ? '#fdd835' : '#616161',
                  backgroundColor: darkMode
                    ? 'rgba(255,255,255,0.05)'
                    : 'rgba(0,0,0,0.04)',
                  '&:hover': {
                    backgroundColor: darkMode
                      ? 'rgba(255,255,255,0.1)'
                      : 'rgba(0,0,0,0.08)',
                  },
                }}
              >
                {darkMode ? <LightModeIcon /> : <DarkModeIcon />}
              </IconButton>
            </Tooltip>
          </Box>
        </Box>

        {/* ── Layout: Form (left) + Summary (right) ────────── */}
        <Box
          component="form"
          onSubmit={handleSubmit(onSubmit)}
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', md: '1fr 340px' },
            gap: 3,
            alignItems: 'start',
          }}
        >
          {/* Left — Form */}
          <Box>
            <AdjustmentForm
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              products={products}
              loading={loading}
              darkMode={darkMode}
            />

            {/* Submit Actions */}
            <Box
              sx={{
                mt: 2.5,
                display: 'flex',
                gap: 1.5,
                flexWrap: 'wrap',
              }}
            >
              <Button
                type="submit"
                variant="contained"
                disabled={isSubmitting || loading}
                startIcon={
                  isSubmitting ? (
                    <CircularProgress size={18} color="inherit" />
                  ) : (
                    <SaveIcon />
                  )
                }
                sx={{
                  textTransform: 'none',
                  fontWeight: 700,
                  px: 3,
                  backgroundColor: '#c62828',
                  '&:hover': { backgroundColor: '#b71c1c' },
                }}
              >
                {isSubmitting ? 'Recording…' : 'Record Adjustment'}
              </Button>

              <Button
                variant="outlined"
                onClick={() => reset({ ...defaultFormValues })}
                disabled={!isDirty || isSubmitting}
                startIcon={<RefreshIcon />}
                sx={{
                  textTransform: 'none',
                  fontWeight: 600,
                  borderColor: darkMode ? 'rgba(255,255,255,0.15)' : undefined,
                  color: darkMode ? 'grey.300' : undefined,
                  '&:hover': {
                    borderColor: darkMode ? 'rgba(255,255,255,0.3)' : undefined,
                  },
                }}
              >
                Reset Form
              </Button>
            </Box>
          </Box>

          {/* Right — Summary */}
          <Box sx={{ position: { md: 'sticky' }, top: { md: 24 } }}>
            <WastageSummaryPanel
              summary={wastageSummary}
              loading={loading}
              darkMode={darkMode}
            />
          </Box>
        </Box>
      </Container>

      {/* ── Snackbar ──────────────────────────────────────── */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          severity={snackbar.severity}
          variant="filled"
          onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
          sx={{ fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default AdjustmentEntryPage;
