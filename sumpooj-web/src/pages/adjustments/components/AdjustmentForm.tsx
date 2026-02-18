/**
 * Adjustment Form — Left-side form panel
 * Product search, batch selector, type, quantity, smart calculations,
 * inline validation, high-value warning.
 */

import { useEffect, useState, useMemo } from 'react';
import {
  Box,
  Paper,
  Typography,
  TextField,
  MenuItem,
  Autocomplete,
  Alert,
  Divider,
  Skeleton,
  useTheme,
  alpha,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import { Controller } from 'react-hook-form';
import type { Control, FieldErrors, UseFormWatch, UseFormSetValue } from 'react-hook-form';

import type { AdjustmentProduct, ProductBatch } from '../data/adjustment.data';
import { ADJUSTMENT_TYPES, STAFF_MEMBERS, MOCK_BATCHES } from '../data/adjustment.data';
import type { AdjustmentSchemaType } from '../schemas/adjustment.schema';
import {
  fmt,
  fmtDate,
  calcAdjustmentValue,
  calcBatchPercent,
  calcRemainingStock,
  isHighValueAdjustment,
} from '../utils/adjustment.utils';

interface AdjustmentFormProps {
  control: Control<AdjustmentSchemaType>;
  errors: FieldErrors<AdjustmentSchemaType>;
  watch: UseFormWatch<AdjustmentSchemaType>;
  setValue: UseFormSetValue<AdjustmentSchemaType>;
  products: AdjustmentProduct[];
  loading: boolean;
  darkMode: boolean;
}

const AdjustmentForm = ({
  control,
  errors,
  watch,
  setValue,
  products,
  loading,
  darkMode,
}: AdjustmentFormProps) => {
  const theme = useTheme();
  const [batches, setBatches] = useState<ProductBatch[]>([]);

  const watchProductId = watch('productId');
  const watchBatchId = watch('batchId');
  const watchQty = watch('quantity');
  const watchType = watch('adjustmentType');

  // Selected product
  const selectedProduct = useMemo(
    () => products.find((p) => p.id === watchProductId),
    [products, watchProductId],
  );

  // Selected batch
  const selectedBatch = useMemo(
    () => batches.find((b) => b.id === watchBatchId),
    [batches, watchBatchId],
  );

  // Load batches when product changes
  useEffect(() => {
    if (watchProductId) {
      const filtered = MOCK_BATCHES.filter((b) => b.productId === watchProductId);
      setBatches(filtered);
      setValue('batchId', '');
    } else {
      setBatches([]);
      setValue('batchId', '');
    }
  }, [watchProductId, setValue]);

  // Smart calculations
  const currentStock = selectedProduct?.currentStock ?? 0;
  const costPerUnit = selectedProduct?.costPerUnit ?? 0;
  const adjustmentValue = calcAdjustmentValue(watchQty || 0, costPerUnit);
  const remainingStock = calcRemainingStock(currentStock, watchQty || 0);
  const batchPercent = selectedBatch
    ? calcBatchPercent(watchQty || 0, selectedBatch.quantityRemaining)
    : 0;
  const highValue = isHighValueAdjustment(adjustmentValue);
  const exceedsStock = (watchQty || 0) > currentStock;

  // Perishable → batch required
  const needsBatch = selectedProduct?.isPerishable ?? false;
  const batchMissing = needsBatch && !watchBatchId;
  const reasonRequired = watchType === 'spoiled' || watchType === 'damaged';

  // ── Style helpers ──────────────────────────────────────────
  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];

  const fieldSx: SxProps<Theme> = darkMode
    ? {
        '& .MuiOutlinedInput-root': {
          color: '#e0e0e0',
          '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' },
          '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.3)' },
          '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
        },
        '& .MuiInputLabel-root': { color: 'rgba(255,255,255,0.5)' },
        '& .MuiSelect-icon': { color: 'rgba(255,255,255,0.5)' },
      }
    : {};

  const sectionTitle = (text: string) => (
    <Typography
      variant="subtitle2"
      sx={{
        fontWeight: 700,
        color: darkMode ? 'grey.400' : 'grey.700',
        textTransform: 'uppercase',
        letterSpacing: 0.5,
        fontSize: '0.7rem',
        mb: 2,
      }}
    >
      {text}
    </Typography>
  );

  if (loading) {
    return (
      <Paper
        elevation={0}
        sx={{
          p: 3,
          borderRadius: 2,
          border: `1px solid ${borderColor}`,
          backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
        }}
      >
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} variant="rounded" height={48} sx={{ mb: 2 }} />
        ))}
      </Paper>
    );
  }

  return (
    <Paper
      elevation={0}
      sx={{
        p: 3,
        borderRadius: 2,
        border: `1px solid ${borderColor}`,
        backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
      }}
    >
      {sectionTitle('Adjustment Details')}

      {/* ── Product (Autocomplete) ──────────────────────── */}
      <Controller
        name="productId"
        control={control}
        render={({ field }) => (
          <Autocomplete
            options={products}
            getOptionLabel={(o) => `${o.name} (${o.sku})`}
            value={products.find((p) => p.id === field.value) ?? null}
            onChange={(_, val) => {
              field.onChange(val?.id ?? '');
            }}
            renderInput={(params) => (
              <TextField
                {...params}
                label="Product *"
                placeholder="Search product…"
                error={!!errors.productId}
                helperText={errors.productId?.message}
                size="small"
                sx={{ mb: 2.5, ...fieldSx }}
              />
            )}
            renderOption={(props, option) => (
              <Box component="li" {...props} key={option.id}>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {option.name}
                  </Typography>
                  <Typography variant="caption" sx={{ color: 'grey.500' }}>
                    {option.sku} · {option.category} · Stock: {option.currentStock}
                  </Typography>
                </Box>
              </Box>
            )}
            isOptionEqualToValue={(opt, val) => opt.id === val.id}
            noOptionsText="No products found"
          />
        )}
      />

      {/* ── Batch (show only if product selected & perishable) ── */}
      {selectedProduct && needsBatch && (
        <Controller
          name="batchId"
          control={control}
          render={({ field }) => (
            <TextField
              {...field}
              select
              label="Batch *"
              size="small"
              fullWidth
              error={batchMissing && !!errors.productId}
              helperText={
                batchMissing
                  ? 'Batch is required for perishable products'
                  : selectedBatch
                    ? `Remaining: ${selectedBatch.quantityRemaining} · Expiry: ${fmtDate(selectedBatch.expiryDate)} · ${selectedBatch.storageLocation}`
                    : ''
              }
              sx={{ mb: 2.5, ...fieldSx }}
            >
              <MenuItem value="" disabled>
                Select batch…
              </MenuItem>
              {batches.map((b) => (
                <MenuItem key={b.id} value={b.id}>
                  {b.batchNumber} — Qty: {b.quantityRemaining} · Exp: {fmtDate(b.expiryDate)}
                </MenuItem>
              ))}
            </TextField>
          )}
        />
      )}

      {/* Non-perishable info */}
      {selectedProduct && !needsBatch && (
        <Alert severity="info" sx={{ mb: 2.5, fontSize: '0.78rem' }}>
          Non-perishable product — batch selection not required.
        </Alert>
      )}

      {/* ── Adjustment Type ────────────────────────────── */}
      <Controller
        name="adjustmentType"
        control={control}
        render={({ field }) => (
          <TextField
            {...field}
            select
            label="Adjustment Type *"
            size="small"
            fullWidth
            error={!!errors.adjustmentType}
            helperText={errors.adjustmentType?.message}
            sx={{ mb: 2.5, ...fieldSx }}
          >
            <MenuItem value="" disabled>
              Select type…
            </MenuItem>
            {ADJUSTMENT_TYPES.map((t) => (
              <MenuItem key={t.value} value={t.value}>
                {t.label}
              </MenuItem>
            ))}
          </TextField>
        )}
      />

      {/* ── Quantity ───────────────────────────────────── */}
      <Controller
        name="quantity"
        control={control}
        render={({ field }) => (
          <TextField
            {...field}
            onChange={(e) => {
              const v = e.target.value === '' ? 0 : Number(e.target.value);
              field.onChange(v);
            }}
            type="number"
            label="Quantity *"
            size="small"
            fullWidth
            error={!!errors.quantity || exceedsStock}
            helperText={
              exceedsStock
                ? `Cannot exceed available stock (${currentStock})`
                : errors.quantity?.message
            }
            sx={{ mb: 2.5, ...fieldSx }}
            slotProps={{ htmlInput: { min: 0 } }}
          />
        )}
      />

      {/* ── Reason ─────────────────────────────────────── */}
      <Controller
        name="reason"
        control={control}
        render={({ field }) => (
          <TextField
            {...field}
            label={reasonRequired ? 'Reason *' : 'Reason'}
            size="small"
            fullWidth
            multiline
            minRows={2}
            maxRows={4}
            error={!!errors.reason}
            helperText={
              errors.reason?.message ??
              (reasonRequired ? 'Required for Spoiled or Damaged adjustments' : '')
            }
            sx={{ mb: 2.5, ...fieldSx }}
          />
        )}
      />

      {/* ── Adjusted By ────────────────────────────────── */}
      <Controller
        name="adjustedBy"
        control={control}
        render={({ field }) => (
          <TextField
            {...field}
            select
            label="Adjusted By *"
            size="small"
            fullWidth
            error={!!errors.adjustedBy}
            helperText={errors.adjustedBy?.message}
            sx={{ mb: 2.5, ...fieldSx }}
          >
            <MenuItem value="" disabled>
              Select staff…
            </MenuItem>
            {STAFF_MEMBERS.map((s) => (
              <MenuItem key={s} value={s}>
                {s}
              </MenuItem>
            ))}
          </TextField>
        )}
      />

      {/* ── Adjustment Date ────────────────────────────── */}
      <Controller
        name="adjustmentDate"
        control={control}
        render={({ field }) => (
          <TextField
            {...field}
            type="date"
            label="Adjustment Date *"
            size="small"
            fullWidth
            error={!!errors.adjustmentDate}
            helperText={errors.adjustmentDate?.message}
            sx={{ mb: 3, ...fieldSx }}
            slotProps={{ inputLabel: { shrink: true } }}
          />
        )}
      />

      {/* ── Smart Calculations Panel ──────────────────── */}
      {selectedProduct && (watchQty || 0) > 0 && (
        <>
          <Divider sx={{ mb: 2, borderColor: darkMode ? 'grey.800' : 'grey.200' }} />
          {sectionTitle('Financial Impact')}

          {/* High-value warning */}
          {highValue && (
            <Alert
              severity="warning"
              icon={<WarningAmberIcon />}
              sx={{
                mb: 2,
                borderRadius: 1.5,
                fontWeight: 600,
                fontSize: '0.78rem',
                backgroundColor: darkMode ? alpha('#e65100', 0.12) : '#fff3e0',
                color: darkMode ? '#ffb74d' : '#e65100',
                border: `1px solid ${darkMode ? alpha('#e65100', 0.3) : alpha('#e65100', 0.2)}`,
                '& .MuiAlert-icon': { color: darkMode ? '#ffb74d' : '#e65100' },
              }}
            >
              High-value adjustment — {fmt(adjustmentValue)} impact
            </Alert>
          )}

          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, 1fr)',
              gap: 1.5,
            }}
          >
            {[
              { label: 'Current Stock', value: String(currentStock) },
              { label: 'Remaining After', value: String(remainingStock), warn: exceedsStock },
              { label: 'Cost Per Unit', value: fmt(costPerUnit) },
              { label: 'Total Adjustment Value', value: fmt(adjustmentValue), bold: true },
              ...(selectedBatch
                ? [{ label: '% of Batch', value: `${batchPercent.toFixed(1)}%` }]
                : []),
            ].map((item, i) => (
              <Box
                key={i}
                sx={{
                  p: 1.5,
                  borderRadius: 1.5,
                  backgroundColor: darkMode
                    ? alpha(theme.palette.grey[800], 0.5)
                    : '#f8f9fa',
                  border: `1px solid ${
                    'warn' in item && item.warn
                      ? '#c62828'
                      : darkMode
                        ? theme.palette.grey[800]
                        : theme.palette.grey[200]
                  }`,
                }}
              >
                <Typography
                  variant="caption"
                  sx={{
                    color: darkMode ? 'grey.500' : 'grey.600',
                    fontSize: '0.65rem',
                    textTransform: 'uppercase',
                    letterSpacing: 0.5,
                    fontWeight: 600,
                  }}
                >
                  {item.label}
                </Typography>
                <Typography
                  variant="body2"
                  sx={{
                    fontWeight: 'bold' in item && item.bold ? 800 : 700,
                    color:
                      'warn' in item && item.warn
                        ? '#c62828'
                        : 'bold' in item && item.bold
                          ? darkMode
                            ? '#ef5350'
                            : '#c62828'
                          : darkMode
                            ? 'grey.100'
                            : 'grey.900',
                    fontSize: '0.9rem',
                    mt: 0.25,
                  }}
                >
                  {item.value}
                </Typography>
              </Box>
            ))}
          </Box>
        </>
      )}
    </Paper>
  );
};

export default AdjustmentForm;
