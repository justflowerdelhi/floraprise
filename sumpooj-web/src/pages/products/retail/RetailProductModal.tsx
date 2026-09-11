/**
 * RetailProductModal.tsx — Floraprise ERP Retail View Add/Edit Product Modal
 *
 * Compact single-step florist product modal:
 * - Direct Add/Edit product workflow matching practical Android florist operations
 * - 11 core fields: Name, SKU, Category, Barcode, Selling Price, Cost Price,
 *   UOM (default 'Stem'), Track Inventory, Track Batch, Reorder Level, Description
 * - Strict TrackBatch and TrackInventory preservation
 * - Non-destructive editing: preserves advanced ERP Professional fields
 */

import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Box,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormControlLabel,
  Switch,
  Typography,
  InputAdornment,
  IconButton,
  Alert,
  CircularProgress,
  Divider,
  useTheme,
  alpha,
  Tooltip,
} from '@mui/material';
import {
  Close as CloseIcon,
  AutoAwesome as AutoSkuIcon,
  Clear as ClearIcon,
  QrCodeScanner as ScannerIcon,
} from '@mui/icons-material';
import { createProduct, updateProduct, validateSku } from '../../../api/product.api';
import type { ProductCategoryDto } from '../../../api/category.api';
import type { RetailProductItem } from './RetailProductCard';

export const FLORIST_UOM_OPTIONS = [
  'Stem',
  'Bunch',
  'Box',
  'Piece',
  'Dozen',
  'Pack',
  'Roll',
  'Set',
  'Meter',
  'Kilogram',
  'Gram',
  'Liter',
] as const;

interface RetailProductModalProps {
  open: boolean;
  onClose: () => void;
  onSuccess: (savedProduct?: any) => void;
  product?: RetailProductItem | null;
  categories: ProductCategoryDto[];
  currencySymbol?: string;
}

export const RetailProductModal: React.FC<RetailProductModalProps> = ({
  open,
  onClose,
  onSuccess,
  product,
  categories,
  currencySymbol = '$',
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const isEdit = Boolean(product);

  // Form State
  const [name, setName] = useState('');
  const [sku, setSku] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [barcode, setBarcode] = useState('');
  const [retailPrice, setRetailPrice] = useState('');
  const [costPrice, setCostPrice] = useState('');
  const [unitOfMeasure, setUnitOfMeasure] = useState('Stem');
  const [trackInventory, setTrackInventory] = useState(false);
  const [trackBatch, setTrackBatch] = useState(false);
  const [reorderLevel, setReorderLevel] = useState('0');
  const [description, setDescription] = useState('');

  // UI / Submission State
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [apiError, setApiError] = useState<string | null>(null);

  // Populate or reset form when modal opens or target changes
  useEffect(() => {
    if (!open) return;

    setApiError(null);
    setErrors({});

    if (product) {
      setName(product.name || '');
      setSku(product.sku || '');
      setCategoryId(product.categoryId || (categories.find((c) => c.name === product.category)?.id ?? ''));
      setBarcode(product.manufacturerBarcode || product.barcode || '');
      setRetailPrice(product.retailPrice ? String(product.retailPrice) : '0');
      setCostPrice(product.costPrice ? String(product.costPrice) : '0');
      setUnitOfMeasure(product.unitOfMeasure || 'Stem');
      setTrackInventory(Boolean(product.trackInventory));
      setTrackBatch(Boolean(product.trackBatch));
      setReorderLevel(String(product.reorderLevel ?? 0));
      setDescription(product.description || '');
    } else {
      setName('');
      setSku('');
      setCategoryId(categories.length > 0 ? categories[0].id : '');
      setBarcode('');
      setRetailPrice('');
      setCostPrice('');
      setUnitOfMeasure('Stem');
      setTrackInventory(true); // Retail florist default
      setTrackBatch(false);
      setReorderLevel('10');
      setDescription('');
    }
  }, [open, product, categories]);

  // When category changes on create, optionally suggest category batch default without forcing
  const handleCategoryChange = (newCatId: string) => {
    setCategoryId(newCatId);
    if (!isEdit) {
      const selected = categories.find((c) => c.id === newCatId);
      if (selected && selected.trackBatchByDefault !== undefined) {
        setTrackBatch(selected.trackBatchByDefault);
      }
    }
  };

  // Helper to auto-generate SKU
  const handleGenerateSku = () => {
    const cleanName = name.trim().replace(/[^a-zA-Z0-9]/g, '').toUpperCase();
    const prefix = cleanName.length >= 3 ? cleanName.substring(0, 3) : 'FLR';
    const rand = Math.floor(1000 + Math.random() * 9000);
    setSku(`${prefix}-${rand}`);
    if (errors.sku) {
      setErrors((prev) => ({ ...prev, sku: '' }));
    }
  };

  // Validation
  const validate = (): boolean => {
    const newErrors: Record<string, string> = {};

    if (!name.trim()) {
      newErrors.name = 'Product name is required';
    }

    if (!sku.trim()) {
      newErrors.sku = 'SKU is required';
    }

    if (!categoryId) {
      newErrors.categoryId = 'Please select a category';
    }

    const parsedRetail = parseFloat(retailPrice);
    if (isNaN(parsedRetail) || parsedRetail < 0) {
      newErrors.retailPrice = 'Valid selling price is required';
    }

    const parsedCost = parseFloat(costPrice);
    if (costPrice.trim() !== '' && (isNaN(parsedCost) || parsedCost < 0)) {
      newErrors.costPrice = 'Cost price must be a positive number';
    }

    if (trackInventory) {
      const parsedReorder = parseInt(reorderLevel, 10);
      if (isNaN(parsedReorder) || parsedReorder < 0) {
        newErrors.reorderLevel = 'Reorder level must be 0 or greater';
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  // Form Submission
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setIsSubmitting(true);
    setApiError(null);

    const selectedCat = categories.find((c) => c.id === categoryId);
    const parsedRetail = parseFloat(retailPrice) || 0;
    const parsedCost = parseFloat(costPrice) || 0;
    const parsedReorder = parseInt(reorderLevel, 10) || 0;

    try {
      if (isEdit && product) {
        // NON-DESTRUCTIVE UPDATE:
        // Only send fields managed by Retail View.
        // Omitted fields are not included, which backend ProductService preserves.
        const updatePayload = {
          productName: name.trim(),
          categoryId: categoryId || undefined,
          barcode: barcode.trim() ? barcode.trim() : null,
          retailPrice: parsedRetail,
          costPrice: parsedCost,
          trackInventory,
          trackBatch, // CRITICAL: Preserves florist batch configuration
          reorderLevel: trackInventory ? parsedReorder : 0,
          description: description.trim() ? description.trim() : null,
        };

        await updateProduct(product.id, updatePayload);
        onSuccess();
      } else {
        // CREATE NEW PRODUCT:
        // Creates standard shared Product entity (no RetailProduct flag)
        const createPayload = {
          productName: name.trim(),
          sku: sku.trim(),
          barcode: barcode.trim() ? barcode.trim() : null,
          productType: 'SingleFlower',
          category: selectedCat?.name || 'Other',
          categoryId: categoryId,
          unitOfMeasure,
          retailPrice: parsedRetail,
          costPrice: parsedCost,
          taxCategory: 'Standard',
          trackInventory,
          trackBatch, // CRITICAL: Preserves florist batch choice
          reorderLevel: trackInventory ? parsedReorder : 0,
          description: description.trim() ? description.trim() : null,
          accounting: {
            incomeAccount: '4000',
            expenseAccount: '5000',
          },
          settings: {
            status: 'active',
            allowAsRawMaterial: false,
            availableOnline: false,
            commissionEligible: false,
          },
        };

        const result = await createProduct(createPayload);
        onSuccess(result);
      }
      onClose();
    } catch (err: any) {
      console.error('Failed to save retail product:', err);
      const msg =
        err?.response?.data?.message ||
        err?.response?.data?.title ||
        err?.message ||
        'Failed to save product. Please check your inputs.';
      setApiError(msg);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Ensure UOM includes any existing custom UOM
  const availableUoms = Array.from(new Set([unitOfMeasure, ...FLORIST_UOM_OPTIONS])).filter(Boolean);

  return (
    <Dialog
      open={open}
      onClose={isSubmitting ? undefined : onClose}
      maxWidth="sm"
      fullWidth
      slotProps={{
        paper: {
          sx: {
            borderRadius: 3,
            bgcolor: dk ? '#1a1a2e' : '#ffffff',
            boxShadow: dk ? '0 12px 36px rgba(0,0,0,0.7)' : '0 12px 36px rgba(0,0,0,0.15)',
          },
        },
      }}
    >
      <form onSubmit={handleSubmit} noValidate>
        {/* Dialog Header */}
        <DialogTitle
          sx={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            px: 3,
            py: 2,
            borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
          }}
        >
          <Box>
            <Typography variant="h6" sx={{ fontWeight: 700, lineHeight: 1.2 }}>
              {isEdit ? 'Edit Product' : 'Add Retail Product'}
            </Typography>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              {isEdit
                ? 'Update product details, pricing, and stock tracking'
                : 'Fast operational product entry for your florist catalog'}
            </Typography>
          </Box>

          <IconButton onClick={onClose} disabled={isSubmitting} size="small" sx={{ color: 'text.secondary' }}>
            <CloseIcon fontSize="small" />
          </IconButton>
        </DialogTitle>

        {/* Dialog Body */}
        <DialogContent sx={{ p: 3 }}>
          {apiError && (
            <Alert severity="error" sx={{ mb: 2.5, borderRadius: 2 }}>
              {apiError}
            </Alert>
          )}

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2.25 }}>
            {/* Row 1: Name */}
            <TextField
              label="Product Name"
              placeholder="e.g. Red Naomi Rose, White Lily, Hand-tied Wrap"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                if (errors.name) setErrors((prev) => ({ ...prev, name: '' }));
              }}
              error={Boolean(errors.name)}
              helperText={errors.name}
              required
              fullWidth
              autoFocus={!isEdit}
              disabled={isSubmitting}
            />

            {/* Row 2: SKU & Category */}
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <TextField
                label="SKU"
                placeholder="e.g. ROS-RED-01"
                value={sku}
                onChange={(e) => {
                  setSku(e.target.value);
                  if (errors.sku) setErrors((prev) => ({ ...prev, sku: '' }));
                }}
                error={Boolean(errors.sku)}
                helperText={errors.sku}
                required
                disabled={isEdit || isSubmitting}
                slotProps={{
                  input: {
                    endAdornment: !isEdit ? (
                      <InputAdornment position="end">
                        <Tooltip title="Generate SKU from name" arrow>
                          <IconButton onClick={handleGenerateSku} edge="end" size="small">
                            <AutoSkuIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </InputAdornment>
                    ) : undefined,
                  },
                }}
              />

              <FormControl fullWidth required error={Boolean(errors.categoryId)} disabled={isSubmitting}>
                <InputLabel id="retail-category-label">Category</InputLabel>
                <Select
                  labelId="retail-category-label"
                  label="Category"
                  value={categoryId}
                  onChange={(e) => handleCategoryChange(e.target.value)}
                >
                  {categories.map((c) => (
                    <MenuItem key={c.id} value={c.id}>
                      {c.name}
                    </MenuItem>
                  ))}
                </Select>
                {errors.categoryId && (
                  <Typography variant="caption" sx={{ color: 'error.main', mt: 0.5, ml: 1.5 }}>
                    {errors.categoryId}
                  </Typography>
                )}
              </FormControl>
            </Box>

            {/* Row 3: Barcode & UOM */}
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1.2fr 0.8fr' }, gap: 2 }}>
              <TextField
                label="Manufacturer Barcode"
                placeholder="Scan or enter barcode"
                value={barcode}
                onChange={(e) => setBarcode(e.target.value)}
                disabled={isSubmitting}
                slotProps={{
                  input: {
                    endAdornment: barcode ? (
                      <InputAdornment position="end">
                        <IconButton onClick={() => setBarcode('')} edge="end" size="small">
                          <ClearIcon fontSize="small" />
                        </IconButton>
                      </InputAdornment>
                    ) : undefined,
                  },
                }}
              />

              <FormControl fullWidth disabled={isSubmitting}>
                <InputLabel id="retail-uom-label">Unit of Measure</InputLabel>
                <Select
                  labelId="retail-uom-label"
                  label="Unit of Measure"
                  value={unitOfMeasure}
                  onChange={(e) => setUnitOfMeasure(e.target.value)}
                >
                  {availableUoms.map((uom) => (
                    <MenuItem key={uom} value={uom}>
                      {uom}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Box>

            {/* Internal Barcode status hint */}
            {isEdit && (product?.internalBarcode || product?.barcode) ? (
              <Box
                sx={{
                  px: 2,
                  py: 1,
                  borderRadius: 1.5,
                  bgcolor: dk ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)',
                  border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1,
                }}
              >
                <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600 }}>
                  FloraPrise Internal Barcode:
                </Typography>
                <Typography variant="caption" sx={{ fontFamily: 'monospace', fontWeight: 700 }}>
                  {product.internalBarcode || product.barcode}
                </Typography>
              </Box>
            ) : !isEdit ? (
              <Typography variant="caption" sx={{ color: 'text.secondary', fontStyle: 'italic', ml: 0.5 }}>
                ℹ️ A FloraPrise barcode will be generated automatically upon saving.
              </Typography>
            ) : null}

            <Divider sx={{ my: 0.5, borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.06)' }} />

            {/* Row 4: Pricing (Selling Price & Cost Price) */}
            <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' }, gap: 2 }}>
              <TextField
                label="Selling Price"
                placeholder="0.00"
                type="number"
                value={retailPrice}
                onChange={(e) => {
                  setRetailPrice(e.target.value);
                  if (errors.retailPrice) setErrors((prev) => ({ ...prev, retailPrice: '' }));
                }}
                error={Boolean(errors.retailPrice)}
                helperText={errors.retailPrice}
                required
                disabled={isSubmitting}
                slotProps={{
                  input: {
                    startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
                  },
                }}
              />

              <TextField
                label="Purchase / Cost Price"
                placeholder="0.00"
                type="number"
                value={costPrice}
                onChange={(e) => {
                  setCostPrice(e.target.value);
                  if (errors.costPrice) setErrors((prev) => ({ ...prev, costPrice: '' }));
                }}
                error={Boolean(errors.costPrice)}
                helperText={errors.costPrice}
                disabled={isSubmitting}
                slotProps={{
                  input: {
                    startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
                  },
                }}
              />
            </Box>

            {/* Row 5: Switches for Track Inventory & Track Batch */}
            <Box
              sx={{
                p: 1.75,
                borderRadius: 2,
                bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)',
                border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e8eaed'}`,
                display: 'flex',
                flexDirection: 'column',
                gap: 1,
              }}
            >
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    Track Inventory
                  </Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Maintain live stock count and trigger low stock alerts
                  </Typography>
                </Box>
                <Switch
                  checked={trackInventory}
                  onChange={(e) => setTrackInventory(e.target.checked)}
                  disabled={isSubmitting}
                  color="primary"
                />
              </Box>

              <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)' }} />

              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    Track Batches & Freshness
                  </Typography>
                  <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                    Enable batch numbers, FIFO rotation, and freshness tracking
                  </Typography>
                </Box>
                <Switch
                  checked={trackBatch}
                  onChange={(e) => setTrackBatch(e.target.checked)}
                  disabled={isSubmitting}
                  color="secondary"
                />
              </Box>

              {trackInventory && (
                <>
                  <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)' }} />
                  <Box sx={{ pt: 0.5 }}>
                    <TextField
                      label="Reorder Alert Level"
                      placeholder="e.g. 10"
                      type="number"
                      size="small"
                      value={reorderLevel}
                      onChange={(e) => setReorderLevel(e.target.value)}
                      error={Boolean(errors.reorderLevel)}
                      helperText={errors.reorderLevel || `Alert when stock reaches or drops below this quantity`}
                      disabled={isSubmitting}
                      sx={{ maxWidth: 260 }}
                    />
                  </Box>
                </>
              )}
            </Box>

            {/* Row 6: Description */}
            <TextField
              label="Description (Optional)"
              placeholder="Stem length, color nuances, special care instructions..."
              multiline
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              disabled={isSubmitting}
              fullWidth
            />
          </Box>
        </DialogContent>

        {/* Dialog Actions */}
        <DialogActions
          sx={{
            px: 3,
            py: 2,
            borderTop: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
            display: 'flex',
            justifyContent: 'flex-end',
            gap: 1.5,
          }}
        >
          <Button onClick={onClose} disabled={isSubmitting} variant="outlined" color="inherit">
            Cancel
          </Button>

          <Button
            type="submit"
            disabled={isSubmitting}
            variant="contained"
            color="primary"
            startIcon={isSubmitting ? <CircularProgress size={16} color="inherit" /> : null}
            sx={{ px: 3, fontWeight: 700 }}
          >
            {isSubmitting ? 'Saving...' : isEdit ? 'Update Product' : 'Create Product'}
          </Button>
        </DialogActions>
      </form>
    </Dialog>
  );
};
