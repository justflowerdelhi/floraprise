/**
 * Purchase Entry Form (Goods Receipt Note)
 * Main form for creating purchase orders, receiving inventory,
 * batch entries, and perishable flower tracking.
 *
 * Florist POS + ERP SaaS Platform
 */

import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm, useFieldArray, useWatch } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Box,
  Container,
  Typography,
  Button,
  Paper,
  Grid,
  IconButton,
  Tooltip,
  CircularProgress,
  useTheme,
  useMediaQuery,
  alpha,
  Chip,
  Divider,
  TextField,
  MenuItem,
  Autocomplete,
  Alert,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import SaveIcon from '@mui/icons-material/Save';
import AddIcon from '@mui/icons-material/Add';
import DraftsIcon from '@mui/icons-material/Drafts';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import InventoryIcon from '@mui/icons-material/Inventory';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import ReceiptIcon from '@mui/icons-material/Receipt';
import { Controller } from 'react-hook-form';

import PurchaseItemRow from './components/PurchaseItemRow';
import OrderSummaryPanel from './components/OrderSummaryPanel';
import QuickAddSupplierModal from './components/QuickAddSupplierModal';

import { purchaseFormSchema } from './schemas/purchase.schema';
import type { PurchaseFormSchemaType } from './schemas/purchase.schema';
import type { Supplier, Product } from './types/purchase.types';
import {
  PAYMENT_TERMS,
  TAX_RATES,
  createEmptyItem,
  defaultPurchaseHeader,
} from './types/purchase.types';
import { createPurchaseOrder } from './api/purchase.api';
import { getAllSuppliers } from '../../api/supplier.api';
import { searchProducts } from '../../api/product.api';
import { calcOrderSummary } from './utils/purchase.utils';
import { showError, showInfo, showSuccess } from '../../utils/toast';
import { useLocation } from '../../core/location/LocationContext';

// ============================================
// MAIN COMPONENT
// ============================================

const PurchaseEntryForm = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const navigate = useNavigate();

  // Hooks
  const { currentLocationId, accessibleLocations } = useLocation();

  // State
  const [darkMode, setDarkMode] = useState(false);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [products, setProducts] = useState<Product[]>([]);
  const [supplierModalOpen, setSupplierModalOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Draft saving state
  const [isSavingDraft, setIsSavingDraft] = useState(false);

  // Load suppliers and products on mount
  useEffect(() => {
    const loadData = async () => {
      try {
        const [suppliersRes, productsRes] = await Promise.all([
          getAllSuppliers(),
          searchProducts(),
        ]);
        setSuppliers(suppliersRes?.items ?? suppliersRes ?? []);
        setProducts(productsRes?.items ?? productsRes ?? []);
      } catch {
        showError('Failed to load suppliers or products.');
      }
    };
    loadData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Form setup
  const {
    control,
    handleSubmit,
    watch,
    setValue,
    reset,
    formState: { errors, isDirty },
  } = useForm<PurchaseFormSchemaType>({
    resolver: zodResolver(purchaseFormSchema) as any,
    defaultValues: {
      header: { ...defaultPurchaseHeader },
      items: [createEmptyItem()],
    },
    mode: 'onChange',
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'items',
  });

  // useWatch keeps summary reactive for first-item edits in field-array rows.
  const watchedItems = useWatch({ control, name: 'items' });
  const watchedTaxRate = useWatch({ control, name: 'header.taxRate' });
  const watchedShipping = useWatch({ control, name: 'header.shippingCost' });
  const watchedSupplierId = useWatch({ control, name: 'header.supplierId' });

  // Live order summary
  const summary = useMemo(
    () => calcOrderSummary(watchedItems || [], watchedTaxRate || 0, watchedShipping || 0),
    [watchedItems, watchedTaxRate, watchedShipping]
  );

  // Pre-fill location from the current store location
  useEffect(() => {
    if (currentLocationId && currentLocationId !== 'ALL') {
      setValue('header.location', currentLocationId);
    }
  }, [currentLocationId, setValue]);

  // Set supplier defaults when selected
  useEffect(() => {
    if (watchedSupplierId) {
      const sup = suppliers.find((s) => s.id === watchedSupplierId);
      if (sup?.defaultPaymentTerms) {
        setValue('header.paymentTerms', sup.defaultPaymentTerms);
      }
    }
  }, [watchedSupplierId, suppliers, setValue]);

  // Keyboard shortcut: Ctrl+S to save, Ctrl+Shift+S to save draft
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key === 's') {
        e.preventDefault();
        if (e.shiftKey) {
          handleSaveDraft();
        } else {
          handleSubmit(onSubmit)();
        }
      }
      // Ctrl+N to add new row
      if ((e.ctrlKey || e.metaKey) && e.key === 'n') {
        e.preventDefault();
        handleAddItem();
      }
    };
    window.addEventListener('keydown', handler);
    return () => window.removeEventListener('keydown', handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Handlers
  const handleAddItem = useCallback(() => {
    append(createEmptyItem());
  }, [append]);

  const normalizeUnitForSubmit = (item: PurchaseFormSchemaType['items'][number]) => {
    const rawUnit = (item.unit || '').toLowerCase();
    if (item.isPerishable && rawUnit === 'stem') {
      return 'each';
    }
    return rawUnit || null;
  };

  const onSubmit = async (data: PurchaseFormSchemaType) => {
    setIsSubmitting(true);
    try {
      await createPurchaseOrder({
        supplierId: data.header.supplierId,
        expectedDeliveryDate: data.header.expectedDeliveryDate,
        notes: data.header.notes || null,
        items: data.items.map((item) => ({
          productId: item.productId,
          productName: item.productName,
          sku: item.sku || null,
          unit: normalizeUnitForSubmit(item),
          quantity: item.quantity,
          expectedCostPerUnit: item.expectedCostPerUnit,
          // Keep legacy alias for older backend builds.
          costPerUnit: item.expectedCostPerUnit,
          isPerishable: item.isPerishable,
          shelfLifeDays: item.shelfLifeDays,
          sellingPrice: item.sellingPrice || null,
        })),
      });

      showSuccess('Purchase Order Created Successfully');
      reset();
      navigate('/purchases');
    } catch {
      showError('Failed to create purchase order');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleSaveDraft = async () => {
    setIsSavingDraft(true);
    const values = watch();
    try {
      localStorage.setItem('purchase_draft', JSON.stringify({
        header: values.header,
        items: values.items,
      }));
      showInfo('Draft saved locally.');
    } catch {
      showError('Failed to save draft.');
    } finally {
      setIsSavingDraft(false);
    }
  };

  const handleAddSupplier = (supplier: Supplier) => {
    setSuppliers((prev) => [...prev, supplier]);
    setValue('header.supplierId', supplier.id);
    setSupplierModalOpen(false);
    showSuccess(`Supplier "${supplier.name}" added!`);
  };

  // Dark mode field sx
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

  // Background
  const bgColor = darkMode
    ? theme.palette.grey[900]
    : theme.palette.grey[50];

  const cardBg = darkMode
    ? alpha(theme.palette.grey[900], 0.8)
    : 'white';

  const borderColor = darkMode
    ? theme.palette.grey[800]
    : theme.palette.grey[200];

  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: bgColor,
        transition: 'background-color 0.3s ease',
        pb: 4,
      }}
    >
      {/* ====== TOP BAR ====== */}
      <Paper
        elevation={0}
        sx={{
          position: 'sticky',
          top: 0,
          zIndex: 10,
          px: { xs: 2, md: 3 },
          py: 1.5,
          borderBottom: `1px solid ${borderColor}`,
          backgroundColor: darkMode
            ? alpha(theme.palette.grey[900], 0.95)
            : alpha('#fff', 0.95),
          backdropFilter: 'blur(8px)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 1,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <IconButton size="small" onClick={() => window.history.back()}>
            <ArrowBackIcon sx={{ color: darkMode ? 'grey.400' : 'grey.700' }} />
          </IconButton>
          <Box>
            <Typography variant="h6" fontWeight={700} sx={{ color: darkMode ? 'grey.100' : 'grey.900', lineHeight: 1.2 }}>
              New Purchase Order
            </Typography>
            <Typography variant="caption" sx={{ color: darkMode ? 'grey.500' : 'grey.500' }}>
              Planning-only PO. Stock details are captured at receive time.
            </Typography>
          </Box>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          {isDirty && (
            <Chip
              label="Unsaved"
              size="small"
              color="warning"
              variant="outlined"
              sx={{ height: 24 }}
            />
          )}
          <Tooltip title="Toggle dark mode">
            <IconButton onClick={() => setDarkMode(!darkMode)} size="small">
              {darkMode ? (
                <LightModeIcon sx={{ color: 'amber.A400' }} />
              ) : (
                <DarkModeIcon sx={{ color: 'grey.600' }} />
              )}
            </IconButton>
          </Tooltip>
          <Tooltip title="Save Draft (Ctrl+Shift+S)">
            <Button
              variant="outlined"
              size="small"
              startIcon={isSavingDraft ? <CircularProgress size={16} /> : <DraftsIcon />}
              onClick={handleSaveDraft}
              disabled={isSavingDraft}
              sx={{ textTransform: 'none' }}
            >
              {isMobile ? '' : 'Draft'}
            </Button>
          </Tooltip>
          <Tooltip title="Submit Order (Ctrl+S)">
            <Button
              variant="contained"
              size="small"
              startIcon={isSubmitting ? <CircularProgress size={16} color="inherit" /> : <SaveIcon />}
              onClick={handleSubmit(onSubmit)}
              disabled={isSubmitting}
              sx={{ textTransform: 'none' }}
            >
              {isSubmitting ? 'Saving…' : isMobile ? 'Save' : 'Submit Order'}
            </Button>
          </Tooltip>
        </Box>
      </Paper>

      {/* ====== FORM BODY ====== */}
      <Container maxWidth="xl" sx={{ mt: 3 }}>
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: { xs: '1fr', lg: '1fr 320px' },
            gap: 3,
            alignItems: 'start',
          }}
        >
          {/* ====== LEFT: FORM ====== */}
          <Box>
            {/* ---- SECTION 1: PURCHASE HEADER ---- */}
            <Paper
              elevation={0}
              sx={{
                p: { xs: 2, md: 3 },
                borderRadius: 2,
                border: `1px solid ${borderColor}`,
                backgroundColor: cardBg,
                mb: 3,
              }}
            >
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 2.5 }}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 36,
                    height: 36,
                    borderRadius: 1.5,
                    backgroundColor: alpha(theme.palette.primary.main, darkMode ? 0.2 : 0.1),
                  }}
                >
                  <ReceiptIcon sx={{ fontSize: 20, color: theme.palette.primary.main }} />
                </Box>
                <Box>
                  <Typography variant="subtitle1" fontWeight={600} sx={{ color: darkMode ? 'grey.100' : 'grey.800' }}>
                    Purchase Header
                  </Typography>
                  <Typography variant="caption" sx={{ color: darkMode ? 'grey.500' : 'grey.600' }}>
                    Supplier and expected delivery planning
                  </Typography>
                </Box>
              </Box>

              <Grid container spacing={2}>
                {/* Supplier */}
                <Grid size={{ xs: 12, sm: 6, md: 4 }}>
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    <Controller
                      name="header.supplierId"
                      control={control}
                      render={({ field }) => (
                        <Autocomplete
                          options={suppliers}
                          getOptionLabel={(opt) =>
                            typeof opt === 'string'
                              ? suppliers.find((s) => s.id === opt)?.name || opt
                              : opt.name
                          }
                          value={suppliers.find((s) => s.id === field.value) || null}
                          onChange={(_, val) => field.onChange(val ? (val as Supplier).id : '')}
                          renderOption={(props, option) => (
                            <Box component="li" {...props} key={option.id}>
                              <Box>
                                <Typography variant="body2" fontWeight={500}>
                                  {option.name}
                                </Typography>
                                <Typography variant="caption" color="text.secondary">
                                  {option.contactPerson} · {option.address}
                                </Typography>
                              </Box>
                            </Box>
                          )}
                          renderInput={(params) => (
                            <TextField
                              {...params}
                              label="Supplier *"
                              size="small"
                              error={!!errors.header?.supplierId}
                              helperText={errors.header?.supplierId?.message}
                              sx={fieldSx}
                            />
                          )}
                          fullWidth
                          size="small"
                          isOptionEqualToValue={(opt, val) => opt.id === val?.id}
                        />
                      )}
                    />
                    <Tooltip title="Quick add supplier">
                      <IconButton
                        size="small"
                        color="primary"
                        onClick={() => setSupplierModalOpen(true)}
                        sx={{ mt: 0.5 }}
                      >
                        <PersonAddIcon fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </Box>
                </Grid>

                {/* Expected Delivery Date */}
                <Grid size={{ xs: 12, sm: 6, md: 8 }}>
                  <Controller
                    name="header.expectedDeliveryDate"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        label="Expected Delivery *"
                        type="date"
                        fullWidth
                        size="small"
                        error={!!errors.header?.expectedDeliveryDate}
                        helperText={errors.header?.expectedDeliveryDate?.message}
                        slotProps={{ inputLabel: { shrink: true } }}
                        sx={fieldSx}
                      />
                    )}
                  />
                </Grid>

                {/* Payment Terms */}
                <Grid size={{ xs: 12, sm: 6, md: 4 }}>
                  <Controller
                    name="header.paymentTerms"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        label="Payment Terms *"
                        select
                        fullWidth
                        size="small"
                        error={!!errors.header?.paymentTerms}
                        helperText={errors.header?.paymentTerms?.message}
                        sx={fieldSx}
                      >
                        {PAYMENT_TERMS.map((pt) => (
                          <MenuItem key={pt.value} value={pt.value}>
                            {pt.label}
                          </MenuItem>
                        ))}
                      </TextField>
                    )}
                  />
                </Grid>

                {/* Location */}
                <Grid size={{ xs: 12, sm: 6, md: 4 }}>
                  <Controller
                    name="header.location"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        label="Location *"
                        select
                        fullWidth
                        size="small"
                        error={!!errors.header?.location}
                        helperText={errors.header?.location?.message}
                        sx={fieldSx}
                      >
                        {accessibleLocations.map((loc) => (
                          <MenuItem key={loc.id} value={loc.id}>
                            {loc.name}
                          </MenuItem>
                        ))}
                      </TextField>
                    )}
                  />
                </Grid>

                <Grid size={12}>
                  <Divider sx={{ borderColor: darkMode ? 'grey.800' : 'grey.100' }} />
                </Grid>

                {/* Tax Rate (optional planning metadata) */}
                <Grid size={{ xs: 12, sm: 6, md: 4 }}>
                  <Controller
                    name="header.taxRate"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        label="Tax Rate"
                        select
                        fullWidth
                        size="small"
                        value={field.value ?? 0}
                        onChange={(e) => field.onChange(Number(e.target.value))}
                        sx={fieldSx}
                      >
                        {TAX_RATES.map((t) => (
                          <MenuItem key={t.value} value={t.value}>
                            {t.label}
                          </MenuItem>
                        ))}
                      </TextField>
                    )}
                  />
                </Grid>

                {/* Shipping Cost (optional planning metadata) */}
                <Grid size={{ xs: 12, sm: 6, md: 4 }}>
                  <Controller
                    name="header.shippingCost"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        label="Shipping Cost ($)"
                        type="number"
                        fullWidth
                        size="small"
                        value={field.value ?? ''}
                        onChange={(e) =>
                          field.onChange(e.target.value === '' ? 0 : Number(e.target.value))
                        }
                        inputProps={{ min: 0, step: 0.01 }}
                        sx={fieldSx}
                      />
                    )}
                  />
                </Grid>

                {/* Notes */}
                <Grid size={{ xs: 12, md: 4 }}>
                  <Controller
                    name="header.notes"
                    control={control}
                    render={({ field }) => (
                      <TextField
                        {...field}
                        label="Notes"
                        fullWidth
                        size="small"
                        multiline
                        rows={1}
                        error={!!errors.header?.notes}
                        helperText={errors.header?.notes?.message}
                        sx={fieldSx}
                      />
                    )}
                  />
                </Grid>
              </Grid>
            </Paper>

            {/* ---- SECTION 2: PURCHASE ITEMS ---- */}
            <Paper
              elevation={0}
              sx={{
                p: { xs: 2, md: 3 },
                borderRadius: 2,
                border: `1px solid ${borderColor}`,
                backgroundColor: cardBg,
              }}
            >
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  mb: 2.5,
                  flexWrap: 'wrap',
                  gap: 1,
                }}
              >
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                  <Box
                    sx={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      width: 36,
                      height: 36,
                      borderRadius: 1.5,
                      backgroundColor: alpha(theme.palette.success.main, darkMode ? 0.2 : 0.1),
                    }}
                  >
                    <InventoryIcon sx={{ fontSize: 20, color: theme.palette.success.main }} />
                  </Box>
                  <Box>
                    <Typography variant="subtitle1" fontWeight={600} sx={{ color: darkMode ? 'grey.100' : 'grey.800' }}>
                      Purchase Items
                    </Typography>
                    <Typography variant="caption" sx={{ color: darkMode ? 'grey.500' : 'grey.600' }}>
                      Add products, quantities, and costs · {fields.length} item{fields.length !== 1 ? 's' : ''}
                    </Typography>
                  </Box>
                </Box>
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={handleAddItem}
                  sx={{ textTransform: 'none' }}
                >
                  Add Item (Ctrl+N)
                </Button>
              </Box>

              {/* Items validation error */}
              {errors.items && typeof errors.items === 'object' && 'message' in errors.items && (
                <Alert severity="error" sx={{ mb: 2 }}>
                  {(errors.items as any).message}
                </Alert>
              )}

              {/* Item rows */}
              {fields.map((field, index) => (
                <PurchaseItemRow
                  key={field.id}
                  index={index}
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  products={products}
                  onRemove={() => remove(index)}
                  canRemove={fields.length > 1}
                  darkMode={darkMode}
                />
              ))}

              {/* Add item button (bottom) */}
              <Box sx={{ display: 'flex', justifyContent: 'center', mt: 2 }}>
                <Button
                  variant="text"
                  startIcon={<AddIcon />}
                  onClick={handleAddItem}
                  sx={{ textTransform: 'none', color: darkMode ? 'grey.400' : 'grey.600' }}
                >
                  Add another item
                </Button>
              </Box>
            </Paper>

            {/* Mobile summary (shown below on small screens) */}
            {isMobile && (
              <Box sx={{ mt: 3 }}>
                <OrderSummaryPanel summary={summary} darkMode={darkMode} />
              </Box>
            )}
          </Box>

          {/* ====== RIGHT: STICKY SUMMARY (desktop) ====== */}
          {!isMobile && (
            <OrderSummaryPanel summary={summary} darkMode={darkMode} />
          )}
        </Box>
      </Container>

      {/* ====== QUICK ADD SUPPLIER MODAL ====== */}
      <QuickAddSupplierModal
        open={supplierModalOpen}
        onClose={() => setSupplierModalOpen(false)}
        onAdd={handleAddSupplier}
        darkMode={darkMode}
      />

    </Box>
  );
};

export default PurchaseEntryForm;
