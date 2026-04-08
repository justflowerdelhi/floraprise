/**
 * Purchase Item Row Component
 * Dynamic row for the items table with perishable support, margin preview,
 * expiry indicators, and inline validation.
 */

import { useEffect, useMemo } from 'react';
import {
  TextField,
  Autocomplete,
  MenuItem,
  IconButton,
  Tooltip,
  Chip,
  Box,
  Typography,
  alpha,
  useTheme,
} from '@mui/material';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import AcUnitIcon from '@mui/icons-material/AcUnit';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import type { SxProps, Theme } from '@mui/material';
import type { Control, FieldErrors, UseFormSetValue, UseFormWatch } from 'react-hook-form';
import { Controller } from 'react-hook-form';
import type { Product } from '../types/purchase.types';
import { UNITS } from '../types/purchase.types';
import type { PurchaseFormSchemaType } from '../schemas/purchase.schema';
import {
  calcRowTotal,
  calcMargin,
  getMarginColor,
  fmt,
} from '../utils/purchase.utils';

interface PurchaseItemRowProps {
  index: number;
  control: Control<PurchaseFormSchemaType>;
  errors: FieldErrors<PurchaseFormSchemaType>;
  watch: UseFormWatch<PurchaseFormSchemaType>;
  setValue: UseFormSetValue<PurchaseFormSchemaType>;
  products: Product[];
  onRemove: () => void;
  canRemove: boolean;
  darkMode?: boolean;
}

const PurchaseItemRow = ({
  index,
  control,
  errors,
  watch,
  setValue,
  products,
  onRemove,
  canRemove,
  darkMode = false,
}: PurchaseItemRowProps) => {
  const theme = useTheme();
  // Watch row fields
  const productId = watch(`items.${index}.productId`);
  const quantity = watch(`items.${index}.quantity`);
  const expectedCostPerUnit = watch(`items.${index}.expectedCostPerUnit`);
  const isPerishable = watch(`items.${index}.isPerishable`);
  const sellingPrice = watch(`items.${index}.sellingPrice`);
  const shelfLifeDays = watch(`items.${index}.shelfLifeDays`);

  // Error helpers
  const itemErrors = errors?.items?.[index] as Record<string, { message?: string }> | undefined;
  const err = (field: string) => itemErrors?.[field]?.message;

  // Auto-calculate total
  useEffect(() => {
    const total = calcRowTotal(quantity || 0, expectedCostPerUnit || 0);
    setValue(`items.${index}.total`, total);
  }, [quantity, expectedCostPerUnit, index, setValue]);

  // Auto-calculate margin
  useEffect(() => {
    const { marginAmount, marginPercent } = calcMargin(expectedCostPerUnit || 0, sellingPrice || 0);
    setValue(`items.${index}.marginAmount`, marginAmount);
    setValue(`items.${index}.marginPercent`, marginPercent);
  }, [expectedCostPerUnit, sellingPrice, index, setValue]);

  // Live computed
  const total = calcRowTotal(quantity || 0, expectedCostPerUnit || 0);
  const margin = calcMargin(expectedCostPerUnit || 0, sellingPrice || 0);

  const selectedProduct = useMemo(
    () => products.find((p) => p.id === productId) || null,
    [products, productId]
  );

  // Shared sx for dark mode fields
  const fieldSx: SxProps<Theme> = darkMode
    ? {
        '& .MuiOutlinedInput-root': {
          backgroundColor: 'grey.900',
          color: 'grey.100',
          '& fieldset': { borderColor: 'grey.700' },
          '&:hover fieldset': { borderColor: 'grey.500' },
          '&.Mui-focused fieldset': { borderColor: 'primary.main' },
        },
        '& .MuiInputLabel-root': { color: 'grey.400' },
        '& .MuiInputLabel-root.Mui-focused': { color: 'primary.light' },
        '& .MuiInputBase-input': { color: 'grey.100' },
        '& .MuiSelect-icon': { color: 'grey.400' },
      }
    : {};

  const handleProductSelect = (product: Product | null) => {
    if (!product) {
      setValue(`items.${index}.productId`, '');
      setValue(`items.${index}.productName`, '');
      setValue(`items.${index}.sku`, '');
      setValue(`items.${index}.isPerishable`, false);
      setValue(`items.${index}.unit`, 'stem');
      setValue(`items.${index}.sellingPrice`, 0);
      setValue(`items.${index}.shelfLifeDays`, 0);
      return;
    }
    setValue(`items.${index}.productId`, product.id);
    setValue(`items.${index}.productName`, product.name);
    setValue(`items.${index}.sku`, product.sku);
    setValue(`items.${index}.isPerishable`, product.isPerishable);
    const normalizedUnit = (product.defaultUnit || 'stem').toLowerCase();
    setValue(`items.${index}.unit`, product.isPerishable && normalizedUnit === 'each' ? 'stem' : normalizedUnit);
    setValue(`items.${index}.sellingPrice`, product.sellingPrice || 0);
    if (product.lastCost) {
      setValue(`items.${index}.expectedCostPerUnit`, product.lastCost);
    }
    if (product.isPerishable) {
      setValue(`items.${index}.shelfLifeDays`, product.defaultShelfLifeDays || 7);
    }
  };

  return (
    <Box
      sx={{
        border: `1px solid ${darkMode ? theme.palette.grey[800] : theme.palette.grey[200]}`,
        borderRadius: 2,
        p: 2,
        mb: 2,
        backgroundColor: darkMode
          ? alpha(theme.palette.grey[900], 0.6)
          : alpha(theme.palette.grey[50], 0.5),
        transition: 'all 0.2s ease',
        '&:hover': {
          borderColor: darkMode ? theme.palette.grey[600] : theme.palette.grey[300],
          boxShadow: darkMode
            ? '0 2px 8px rgba(0,0,0,0.3)'
            : '0 2px 8px rgba(0,0,0,0.06)',
        },
      }}
    >
      {/* Row Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 1.5 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Chip
            label={`#${index + 1}`}
            size="small"
            sx={{
              fontWeight: 700,
              backgroundColor: darkMode
                ? alpha(theme.palette.primary.main, 0.2)
                : alpha(theme.palette.primary.main, 0.1),
              color: theme.palette.primary.main,
            }}
          />
          {selectedProduct && (
            <Typography variant="caption" sx={{ color: darkMode ? 'grey.500' : 'grey.600' }}>
              {selectedProduct.sku}
            </Typography>
          )}
          {isPerishable && (
            <Chip
              icon={<AcUnitIcon sx={{ fontSize: 14 }} />}
              label="Perishable"
              size="small"
              color="info"
              variant="outlined"
              sx={{ height: 22, '& .MuiChip-label': { px: 0.5, fontSize: '0.7rem' } }}
            />
          )}
        </Box>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {/* Margin badge */}
          {sellingPrice > 0 && expectedCostPerUnit > 0 && (
            <Tooltip title={`Margin: ${fmt(margin.marginAmount)} (${margin.marginPercent}%)`}>
              <Chip
                icon={
                  margin.marginPercent >= 15 ? (
                    <TrendingUpIcon sx={{ fontSize: 14 }} />
                  ) : (
                    <TrendingDownIcon sx={{ fontSize: 14 }} />
                  )
                }
                label={`${margin.marginPercent}%`}
                size="small"
                sx={{
                  height: 22,
                  fontWeight: 700,
                  backgroundColor: alpha(getMarginColor(margin.marginPercent), 0.15),
                  color: getMarginColor(margin.marginPercent),
                  '& .MuiChip-label': { px: 0.5, fontSize: '0.7rem' },
                }}
              />
            </Tooltip>
          )}
          {/* Total */}
          <Typography
            variant="subtitle2"
            sx={{ fontWeight: 700, color: darkMode ? 'grey.200' : 'grey.800', minWidth: 70, textAlign: 'right' }}
          >
            {fmt(total)}
          </Typography>
          {/* Remove */}
          <Tooltip title={canRemove ? 'Remove item' : 'Cannot remove last item'}>
            <span>
              <IconButton
                onClick={onRemove}
                disabled={!canRemove}
                sx={{ color: 'error.main' }}
              >
                <DeleteOutlineIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
        </Box>
      </Box>

      {/* Main fields grid */}
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr', sm: '2.5fr 1fr 1fr 1fr', md: '3fr 1fr 1fr 1fr 1fr' },
          gap: 1.5,
          alignItems: 'start',
        }}
      >
        {/* Product Search */}
        <Controller
          name={`items.${index}.productId`}
          control={control}
          render={({ field }) => (
            <Autocomplete
              options={products}
              getOptionLabel={(opt) => (typeof opt === 'string' ? opt : `${opt.name} (${opt.sku})`)}
              value={selectedProduct}
              onChange={(_, val) => {
                handleProductSelect(val as Product | null);
                field.onChange(val ? (val as Product).id : '');
              }}
              renderOption={(props, option) => (
                <Box component="li" {...props} key={option.id}>
                  <Box>
                    <Typography variant="body2" fontWeight={500}>
                      {option.name}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {option.sku} · {option.category}
                      {option.isPerishable ? ' · 🌿 Perishable' : ''}
                      {option.lastCost ? ` · Last: ${fmt(option.lastCost)}` : ''}
                    </Typography>
                  </Box>
                </Box>
              )}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Product *"
                  size="small"
                  error={!!err('productId')}
                  helperText={err('productId')}
                  sx={fieldSx}
                />
              )}
              size="small"
              isOptionEqualToValue={(opt, val) => opt.id === val?.id}
            />
          )}
        />

        {/* Unit */}
        <Controller
          name={`items.${index}.unit`}
          control={control}
          render={({ field }) => (
            <TextField
              {...field}
              select
              label="Unit"
              size="small"
              error={!!err('unit')}
              helperText={err('unit')}
              sx={fieldSx}
            >
              {UNITS.map((u) => (
                <MenuItem key={u.value} value={u.value}>
                  {u.label}
                </MenuItem>
              ))}
            </TextField>
          )}
        />

        {/* Quantity */}
        <Controller
          name={`items.${index}.quantity`}
          control={control}
          render={({ field }) => (
            <TextField
              {...field}
              label="Qty *"
              type="number"
              size="small"
              error={!!err('quantity')}
              helperText={err('quantity')}
              value={field.value ?? ''}
              onChange={(e) => field.onChange(e.target.value === '' ? '' : Number(e.target.value))}
              inputProps={{ min: 0, step: 1 }}
              sx={fieldSx}
            />
          )}
        />

        {/* Cost per Unit */}
        <Controller
          name={`items.${index}.expectedCostPerUnit`}
          control={control}
          render={({ field }) => (
            <TextField
              {...field}
              label="Expected Cost ($) *"
              type="number"
              size="small"
              error={!!err('expectedCostPerUnit')}
              helperText={err('expectedCostPerUnit') || 'Final cost will be confirmed when stock is received'}
              value={field.value ?? ''}
              onChange={(e) => field.onChange(e.target.value === '' ? '' : Number(e.target.value))}
              inputProps={{ min: 0, step: 0.01 }}
              sx={fieldSx}
            />
          )}
        />

        {/* Selling Price (margin preview) — visible on md+ */}
        <Box sx={{ display: { xs: 'none', md: 'block' } }}>
          <Controller
            name={`items.${index}.sellingPrice`}
            control={control}
            render={({ field }) => (
              <TextField
                {...field}
                label="Sell ($)"
                type="number"
                size="small"
                value={field.value ?? ''}
                onChange={(e) => field.onChange(e.target.value === '' ? '' : Number(e.target.value))}
                inputProps={{ min: 0, step: 0.01 }}
                sx={fieldSx}
              />
            )}
          />
        </Box>
      </Box>

      {/* Low margin warning */}
      {sellingPrice > 0 && expectedCostPerUnit > 0 && margin.marginPercent < 15 && (
        <Box
          sx={{
            mt: 1,
            display: 'flex',
            alignItems: 'center',
            gap: 0.5,
            px: 1.5,
            py: 0.5,
            borderRadius: 1,
            backgroundColor: alpha('#e65100', 0.08),
          }}
        >
          <WarningAmberIcon sx={{ fontSize: 16, color: '#e65100' }} />
          <Typography variant="caption" sx={{ color: '#e65100', fontWeight: 500 }}>
            Low margin alert — only {margin.marginPercent}% margin ({fmt(margin.marginAmount)}/unit).
            Consider renegotiating cost or adjusting sell price.
          </Typography>
        </Box>
      )}

      {/* Product shelf-life hint for planning only */}
      {isPerishable && shelfLifeDays > 0 && (
        <Box
          sx={{
            mt: 1,
            display: 'flex',
            alignItems: 'center',
            gap: 0.5,
            px: 1.5,
            py: 0.5,
            borderRadius: 1,
            backgroundColor: alpha(theme.palette.info.main, 0.08),
          }}
        >
          <AcUnitIcon sx={{ fontSize: 16, color: theme.palette.info.main }} />
          <Typography variant="caption" sx={{ color: theme.palette.info.main, fontWeight: 500 }}>
            Perishable product: receiving will capture batch/expiry/storage. Suggested shelf life: {shelfLifeDays} day(s).
          </Typography>
        </Box>
      )}
    </Box>
  );
};

export default PurchaseItemRow;
