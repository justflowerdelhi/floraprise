/**
 * Add Product Form
 * Main form component for creating new products
 * Florist POS + ERP SaaS Platform
 */

import { useState, useEffect, useCallback } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Button,
  Paper,
  Stack,
  IconButton,
  Tooltip,
  Snackbar,
  Alert,
  CircularProgress,
  useTheme,
  useMediaQuery,
  alpha,
  Chip,
  Drawer,
  Divider,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import SaveIcon from '@mui/icons-material/Save';
import AddIcon from '@mui/icons-material/Add';
import DraftsIcon from '@mui/icons-material/Drafts';
import CloseIcon from '@mui/icons-material/Close';
import ContentCopyIcon from '@mui/icons-material/ContentCopy';
import DarkModeIcon from '@mui/icons-material/DarkMode';
import LightModeIcon from '@mui/icons-material/LightMode';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import TuneIcon from '@mui/icons-material/Tune';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';

import {
  BasicInfoSection,
  InventorySection,
  PerishableSection,
  AccountingSection,
  SettingsSection,
  FlowerAttributesSection,
  SupplierSection,
  ImageUploadSection,
  CorePricingSection,
  AdditionalPricingSection,
} from './components/sections';

import QuickAddSupplierModal from './components/QuickAddSupplierModal';
import QuickAddFlowersModal from './components/QuickAddFlowersModal';
import type { QuickFlowerProduct } from './components/QuickAddFlowersModal';
import ProductIntentSelector from './components/ProductIntentSelector';

import { productFormSchema } from './schemas/product.schema';
import type { ProductFormSchema } from './schemas/product.schema';
import type { ProductFormData, Supplier, CategoryOption } from './types/product.types';
import { defaultProductFormValues } from './types/product.types';
import {
  createProduct,
  fetchProductById,
  saveDraft,
  updateProductById,
  deleteProductById,
  fetchSuppliers,
  type ProductDetailResponse,
} from './api/product.api';
import {
  saveDraftToStorage,
  loadDraftFromStorage,
  clearDraftFromStorage,
} from './utils/product.utils';
import { generateSku } from './utils/product.utils';
import { getCategories } from '../../api/category.api';

// ============================================
// MAIN COMPONENT
// ============================================

interface AddProductFormProps {
  onBack?: () => void;
  onProductCreated?: (productId: string) => void;
  initialData?: Partial<ProductFormData>;
  isDuplicate?: boolean;
}

const AddProductForm = ({
  onBack,
  onProductCreated,
  initialData,
  isDuplicate = false,
}: AddProductFormProps) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const canDeleteProducts = import.meta.env.VITE_ENABLE_PRODUCT_FORCE_DELETE === 'true';
  const navigate = useNavigate();
  const { id } = useParams<{ id: string }>();
  const isEditMode = Boolean(id) && !isDuplicate;

  // State
  const [darkMode, setDarkMode] = useState(false);
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [loadingSuppliers, setLoadingSuppliers] = useState(false);
  const [categories, setCategories] = useState<CategoryOption[]>([]);
  const [loadingCategories, setLoadingCategories] = useState(false);
  const [loadingProduct, setLoadingProduct] = useState(false);
  const [supplierModalOpen, setSupplierModalOpen] = useState(false);
  const [images, setImages] = useState<File[]>([]);
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [quickAddOpen, setQuickAddOpen] = useState(false);

  // Submission states
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSavingDraft, setIsSavingDraft] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [submitAction, setSubmitAction] = useState<'save' | 'saveAndNew' | 'draft'>('save');

  // Notifications
  const [notification, setNotification] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'error' | 'info' | 'warning';
  }>({ open: false, message: '', severity: 'info' });

  // Form setup
  const {
    control,
    handleSubmit,
    watch,
    setValue,
    setFocus,
    reset,
    formState: { errors, isDirty },
  } = useForm<ProductFormSchema>({
    resolver: zodResolver(productFormSchema) as any,
    defaultValues: {
      ...defaultProductFormValues,
      ...initialData,
    },
    mode: 'onChange',
  });

  // Watched values for conditional rendering
  const productType = watch('productType');
  const categoryId = watch('categoryId');
  const trackInventory = watch('trackInventory');
  const isPerishable = watch('isPerishable');
  const productIntent = watch('productIntent');

  // Advanced Settings Drawer state
  const [advancedDrawerOpen, setAdvancedDrawerOpen] = useState(false);

  const inferProductIntent = (productType?: string): ProductFormData['productIntent'] => {
    if (productType === 'gift_item') return 'gift_item';
    if (productType === 'bouquet') return 'bouquet';
    if (productType === 'fresh_flower') return 'fresh_flower';
    return 'raw_material';
  };

  const normalizeEnum = <T extends string>(
    value: string | undefined | null,
    allowed: readonly T[],
    fallback: T,
  ): T => {
    if (!value) return fallback;
    const direct = value as T;
    if (allowed.includes(direct)) return direct;
    const lower = value.toLowerCase() as T;
    if (allowed.includes(lower)) return lower;
    return fallback;
  };

  const toFormValues = (product: ProductDetailResponse): ProductFormData => {
    const productTypes = [
      'fresh_flower',
      'dried_flower',
      'plant',
      'arrangement',
      'bouquet',
      'gift_item',
      'container',
      'ribbon',
      'supply',
      'service',
    ] as const;

    const units = ['each', 'stem', 'bunch', 'box', 'case', 'dozen', 'foot', 'yard', 'roll', 'pack'] as const;
    const taxCategories = ['standard', 'reduced', 'exempt', 'zero'] as const;
    const incomeAccounts = ['4000', '4010', '4020', '4030', '4040', '4050'] as const;
    const expenseAccounts = ['5000', '5010', '5020', '5030', '5040'] as const;

    const seasonalityAllowed = new Set([
      'year_round',
      'spring',
      'summer',
      'fall',
      'winter',
      'valentines',
      'mothers_day',
      'christmas',
      'wedding_season',
    ] as const);

    const seasonalAvailability = product.seasonalAvailability
      ? product.seasonalAvailability
          .split(',')
          .map((s) => s.trim().toLowerCase().replace(/\s+/g, '_'))
          .filter((s) => seasonalityAllowed.has(s as any))
      : [];

    const normalizedProductType = normalizeEnum(product.productType, productTypes, defaultProductFormValues.productType);

    return {
      ...defaultProductFormValues,
      productIntent: inferProductIntent(normalizedProductType),
      productName: product.name || product.productName || '',
      productType: normalizedProductType,
      categoryId: product.categoryId || '',
      sku: product.sku || '',
      barcode: product.barcode || '',
      brand: product.brand || '',
      description: product.description || '',
      unitOfMeasure: normalizeEnum(product.unitOfMeasure, units, defaultProductFormValues.unitOfMeasure),
      retailPrice: Number(product.retailPrice ?? 0),
      costPrice: Number(product.costPrice ?? 0),
      wholesalePrice: product.wholesalePrice ?? undefined,
      weddingEventPrice: product.weddingEventPrice ?? undefined,
      taxCategory: normalizeEnum(product.taxCategory, taxCategories, defaultProductFormValues.taxCategory),
      trackInventory: product.trackInventory ?? defaultProductFormValues.trackInventory,
      trackBatch: product.trackBatch ?? defaultProductFormValues.trackBatch,
      openingStock: product.stockQuantity ?? 0,
      reorderLevel: product.reorderLevel ?? product.minimumStockLevel ?? 0,
      status: product.isActive === false ? 'inactive' : 'active',
      isPerishable: product.isPerishable ?? false,
      shelfLifeDays: product.shelfLifeDays ?? undefined,
      expiryAlertDays: product.expiryAlertDays ?? undefined,
      temperatureNotes: product.temperatureNotes ?? undefined,
      color: product.color ?? undefined,
      variety: product.variety ?? undefined,
      grade: (product.flowerGrade as ProductFormData['grade']) ?? undefined,
      countryOfOrigin: (product.countryOfOrigin as ProductFormData['countryOfOrigin']) ?? undefined,
      seasonality: seasonalAvailability as ProductFormData['seasonality'],
      supplierId: product.defaultSupplierId ?? undefined,
      leadTimeDays: product.leadTimeDays ?? undefined,
      incomeAccount: normalizeEnum(product.incomeAccount, incomeAccounts, defaultProductFormValues.incomeAccount),
      expenseAccount: normalizeEnum(product.expenseAccount, expenseAccounts, defaultProductFormValues.expenseAccount),
      allowAsRawMaterial: product.allowAsRawMaterial ?? defaultProductFormValues.allowAsRawMaterial,
      availableOnline: product.availableOnline ?? defaultProductFormValues.availableOnline,
      commissionEligible: product.commissionEligible ?? defaultProductFormValues.commissionEligible,
      tags: product.tags ?? [],
      isMultiUnit: product.isMultiUnit ?? defaultProductFormValues.isMultiUnit,
      avgUnitsPerStem: product.avgUnitsPerStem ?? defaultProductFormValues.avgUnitsPerStem,
    };
  };

  // Auto-open Advanced Settings drawer for raw_material
  useEffect(() => {
    if (productIntent === 'raw_material') {
      setAdvancedDrawerOpen(true);
    }
  }, [productIntent]);

  // Conditional rendering flags based on productIntent
  const showFlowerAttributes = productIntent === 'fresh_flower';
  const showPerishableSection = productIntent !== 'gift_item';
  const hideBatchTracking = productIntent === 'bouquet';

  // Resolve the selected category object
  const selectedCategory = categories.find((c) => c.id === categoryId);

  // Flower-like logic — show flower attributes if a common flower category is selected
  const isFlowerProduct = selectedCategory
    ? /flower|plant|arrangement|bouquet/i.test(selectedCategory.name)
    : false;

  // Auto-set isPerishable & trackBatch from the selected category
  useEffect(() => {
    if (selectedCategory) {
      setValue('isPerishable', selectedCategory.isPerishable);
      if (selectedCategory.trackBatchByDefault) {
        setValue('trackBatch', true);
      }
    }
  }, [selectedCategory, setValue]);

  useEffect(() => {
    if (isPerishable) {
      setValue('barcode', '');
      setValue('trackBatch', true);
    }
  }, [isPerishable, setValue]);

  // Load categories on mount
  useEffect(() => {
    const loadCategories = async () => {
      setLoadingCategories(true);
      try {
        const data = await getCategories();
        setCategories(
          data.map((c) => ({
            id: c.id,
            name: c.name,
            isPerishable: c.isPerishable,
            trackBatchByDefault: c.trackBatchByDefault,
            isActive: c.isActive,
          })),
        );
      } catch (error) {
        console.error('Failed to load categories:', error);
      } finally {
        setLoadingCategories(false);
      }
    };
    loadCategories();
  }, []);

  // Load product for edit mode
  useEffect(() => {
    if (!isEditMode || !id) return;

    const loadProduct = async () => {
      setLoadingProduct(true);
      try {
        const response = await fetchProductById(id);
        if (response.success && response.data) {
          clearDraftFromStorage();
          reset(toFormValues(response.data));
          return;
        }

        setNotification({
          open: true,
          message: response.error || 'Failed to load product details',
          severity: 'error',
        });
      } catch (error) {
        setNotification({
          open: true,
          message: 'Failed to load product details',
          severity: 'error',
        });
      } finally {
        setLoadingProduct(false);
      }
    };

    loadProduct();
  }, [id, isEditMode, reset]);

  // Load suppliers on mount
  useEffect(() => {
    const loadSuppliers = async () => {
      setLoadingSuppliers(true);
      try {
        const response = await fetchSuppliers();
        if (response.success && response.data) {
          setSuppliers(response.data);
        }
      } catch (error) {
        console.error('Failed to load suppliers:', error);
      } finally {
        setLoadingSuppliers(false);
      }
    };
    loadSuppliers();
  }, []);

  // Auto-save draft on changes
  useEffect(() => {
    if (isDirty) {
      const subscription = watch((data) => {
        saveDraftToStorage(data);
      });
      return () => subscription.unsubscribe();
    }
  }, [watch, isDirty]);

  // Load draft on mount
  useEffect(() => {
    if (!initialData && !isDuplicate && !isEditMode) {
      const draft = loadDraftFromStorage<Partial<ProductFormData>>();
      if (draft) {
        setNotification({
          open: true,
          message: 'Draft restored. Continue where you left off.',
          severity: 'info',
        });
        Object.entries(draft).forEach(([key, value]) => {
          if (value !== undefined) {
            setValue(key as keyof ProductFormSchema, value as any);
          }
        });
      }
    }
  }, [initialData, isDuplicate, isEditMode, setValue]);

  // Handle image changes
  const handleImagesChange = useCallback((files: File[], urls: string[]) => {
    setImages(files);
    setImageUrls(urls);
  }, []);

  // Bulk-create flowers from Quick Add modal
  const handleQuickCreate = async (products: QuickFlowerProduct[]) => {
    const failed: string[] = [];
    for (const product of products) {
      const response = await createProduct({
        ...defaultProductFormValues,
        productName: product.productName,
        productType: product.productType,
        unitOfMeasure: product.unitOfMeasure as any,
        isPerishable: product.isPerishable,
        trackInventory: product.trackInventory,
        trackBatch: product.trackBatch,
        categoryId: product.categoryId,
        color: product.color,
        tags: product.colors.length > 0 ? product.colors : [],
        retailPrice: product.retailPrice,
        costPrice: product.costPrice,
        openingStock: product.openingStock,
        reorderLevel: product.reorderLevel,
        shelfLifeDays: product.shelfLifeDays,
        taxCategory: product.taxCategory,
        incomeAccount: product.incomeAccount,
        expenseAccount: product.expenseAccount,
        status: product.status,
        // Auto-generate a unique SKU so the backend doesn't reject an empty one
        sku: generateSku('fresh_flower', product.productName),
        images: [],
        imageUrls: [],
      });
      if (!response.success) {
        failed.push(product.productName);
      }
    }
    if (failed.length === 0) {
      setNotification({
        open: true,
        message: `${products.length} flower product${products.length > 1 ? 's' : ''} created successfully`,
        severity: 'success',
      });
    } else if (failed.length === products.length) {
      setNotification({
        open: true,
        message: `Failed to create flowers: ${failed.join(', ')}`,
        severity: 'error',
      });
    } else {
      setNotification({
        open: true,
        message: `${products.length - failed.length} created. Failed: ${failed.join(', ')}`,
        severity: 'warning',
      });
    }
  };

  // Handle supplier created
  const handleSupplierCreated = useCallback((supplier: Supplier) => {
    setSuppliers((prev) => [...prev, supplier]);
    setValue('supplierId', supplier.id);
    setNotification({
      open: true,
      message: `Supplier "${supplier.name}" created successfully`,
      severity: 'success',
    });
  }, [setValue]);

  // Form submission
  const onSubmit = async (data: ProductFormSchema) => {
    setIsSubmitting(true);

    try {
      const formData: ProductFormData = {
        ...data,
        images,
        imageUrls,
      };

      const response = isEditMode && id
        ? await updateProductById(id, formData)
        : await createProduct(formData);

      if (response.success) {
        clearDraftFromStorage();
        
        setNotification({
          open: true,
          message: response.message || (isEditMode ? 'Product updated successfully!' : 'Product created successfully!'),
          severity: 'success',
        });

        if (!isEditMode && submitAction === 'saveAndNew') {
          // Reset form for new entry
          reset(defaultProductFormValues);
          setImages([]);
          setImageUrls([]);
        } else {
          // Navigate away or notify parent
          if (!isEditMode && response.data?.id) {
            onProductCreated?.(response.data.id);
          }
          if (!onBack && !onProductCreated) {
            navigate('/products');
          }
        }
      } else {
        setNotification({
          open: true,
          message: response.error || (isEditMode ? 'Failed to update product' : 'Failed to create product'),
          severity: 'error',
        });
      }
    } catch (error) {
      setNotification({
        open: true,
        message: 'An unexpected error occurred',
        severity: 'error',
      });
    } finally {
      setIsSubmitting(false);
    }
  };

  const onInvalidSubmit = (formErrors: typeof errors) => {
    const firstInvalidField = Object.keys(formErrors)[0] as keyof ProductFormSchema | undefined;
    if (!firstInvalidField) return;

    setNotification({
      open: true,
      message: 'Please fill the required fields highlighted in red before saving.',
      severity: 'warning',
    });

    requestAnimationFrame(() => {
      setFocus(firstInvalidField as any);
    });
  };

  const handleDeleteProduct = async () => {
    if (!id || !canDeleteProducts) return;

    setIsDeleting(true);
    try {
      const response = await deleteProductById(id, true);
      if (response.success) {
        setNotification({
          open: true,
          message: response.message || 'Product deleted successfully',
          severity: 'success',
        });
        setDeleteDialogOpen(false);
        navigate('/products');
      } else {
        setNotification({
          open: true,
          message: response.error || 'Failed to delete product',
          severity: 'error',
        });
      }
    } catch (error) {
      setNotification({
        open: true,
        message: 'Failed to delete product',
        severity: 'error',
      });
    } finally {
      setIsDeleting(false);
    }
  };

  // Save draft
  const handleSaveDraft = async () => {
    setIsSavingDraft(true);

    try {
      const currentData = watch();
      const response = await saveDraft(currentData);

      if (response.success) {
        setNotification({
          open: true,
          message: 'Draft saved successfully',
          severity: 'success',
        });
      }
    } catch (error) {
      setNotification({
        open: true,
        message: 'Failed to save draft',
        severity: 'error',
      });
    } finally {
      setIsSavingDraft(false);
    }
  };

  // Handle cancel
  const handleCancel = () => {
    if (isDirty) {
      if (window.confirm('You have unsaved changes. Are you sure you want to leave?')) {
        clearDraftFromStorage();
        if (onBack) {
          onBack();
        } else {
          navigate('/products');
        }
      }
    } else {
      if (onBack) {
        onBack();
      } else {
        navigate('/products');
      }
    }
  };

  // Duplicate product
  const handleDuplicate = () => {
    const currentData = watch();
    setValue('productName', `${currentData.productName} (Copy)`);
    setValue('sku', '');
    setNotification({
      open: true,
      message: 'Product duplicated. Update the SKU before saving.',
      severity: 'info',
    });
  };

  // Background color
  const bgColor = darkMode
    ? theme.palette.grey[900]
    : '#fafafa';

  return (
    <Box
      sx={{
        minHeight: '100vh',
        backgroundColor: bgColor,
        pb: 12, // Space for sticky footer
      }}
    >
      {/* Header */}
      <Paper
        elevation={0}
        sx={{
          position: 'sticky',
          top: 0,
          zIndex: 100,
          backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.95) : alpha('#fff', 0.95),
          backdropFilter: 'blur(8px)',
          borderBottom: `1px solid ${darkMode ? theme.palette.grey[800] : theme.palette.grey[200]}`,
        }}
      >
        <Container maxWidth="lg">
          {loadingProduct && isEditMode && (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 2 }}>
              <CircularProgress size={22} />
            </Box>
          )}
          <Box
            sx={{
              py: 2,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              {onBack && (
                <IconButton onClick={handleCancel} sx={{ mr: 1 }}>
                  <ArrowBackIcon />
                </IconButton>
              )}
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
                <Box
                  sx={{
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    width: 44,
                    height: 44,
                    borderRadius: 2,
                    background: 'linear-gradient(135deg, #e91e63 0%, #9c27b0 100%)',
                  }}
                >
                  <LocalFloristIcon sx={{ color: 'white', fontSize: 24 }} />
                </Box>
                <Box>
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      color: darkMode ? 'grey.100' : 'grey.900',
                    }}
                  >
                    {isDuplicate ? 'Duplicate Product' : isEditMode ? 'Edit Product' : 'Add New Product'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {isEditMode ? 'Update product details and pricing' : 'Fill in the details below to create a new product'}
                  </Typography>
                </Box>
              </Box>
            </Box>

            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              {/* Quick Add Flowers */}
              {!isEditMode && (
                <Button
                  variant="outlined"
                  size="small"
                  startIcon={<AddIcon />}
                  onClick={() => setQuickAddOpen(true)}
                  sx={{ textTransform: 'none', borderRadius: 2 }}
                >
                  {isMobile ? 'Quick Add' : 'Quick Add Flowers'}
                </Button>
              )}

              {/* Duplicate Button */}
              {isDirty && (
                <Tooltip title="Duplicate this product">
                  <IconButton onClick={handleDuplicate}>
                    <ContentCopyIcon />
                  </IconButton>
                </Tooltip>
              )}

              {/* Dark Mode Toggle */}
              <Tooltip title={darkMode ? 'Light mode' : 'Dark mode'}>
                <IconButton onClick={() => setDarkMode(!darkMode)}>
                  {darkMode ? <LightModeIcon /> : <DarkModeIcon />}
                </IconButton>
              </Tooltip>
            </Box>
          </Box>
        </Container>
      </Paper>

      {/* Main Form Content */}
      <Container maxWidth="md" sx={{ py: 3 }}>
        <form onSubmit={handleSubmit(onSubmit as any, onInvalidSubmit)}>
          <Stack spacing={3}>
            {/* ─── Product Intent Selector ────────────────────── */}
            <ProductIntentSelector control={control} darkMode={darkMode} />

            {/* ─── Basic Product (always visible) ─────────────── */}
            
            {/* Basic Info */}
            <BasicInfoSection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
              categories={categories}
              loadingCategories={loadingCategories}
            />

            {/* Core Pricing (retail/cost with margin) */}
            <CorePricingSection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
            />

            {/* Accounting (required fields should remain visible) */}
            <AccountingSection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
            />

            {/* Inventory (core fields) */}
            <InventorySection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
              isEnabled={trackInventory}
              hideBatchTracking={hideBatchTracking}
            />

            {/* Flower Attributes (only for fresh_flower) */}
            {showFlowerAttributes && (
              <FlowerAttributesSection
                control={control}
                errors={errors}
                watch={watch}
                setValue={setValue}
                darkMode={darkMode}
                isFlowerProduct={isFlowerProduct}
              />
            )}

            {/* ─── Advanced Settings Button ──────────────────── */}
            <Button
              variant="outlined"
              startIcon={<TuneIcon />}
              onClick={() => setAdvancedDrawerOpen(true)}
              fullWidth
              sx={{
                py: 1.5,
                borderRadius: 3,
                borderColor: darkMode ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.12)',
                color: darkMode ? 'grey.300' : 'grey.700',
                '&:hover': {
                  borderColor: '#5B2E91',
                  bgcolor: alpha('#5B2E91', 0.08),
                },
              }}
            >
              Advanced Settings
            </Button>
          </Stack>
        </form>
      </Container>

      {/* ─── Advanced Settings Drawer ─────────────────────── */}
      <Drawer
        anchor="right"
        open={advancedDrawerOpen}
        onClose={() => setAdvancedDrawerOpen(false)}
        PaperProps={{
          sx: {
            width: 400,
            maxWidth: '100vw',
            bgcolor: darkMode ? theme.palette.grey[900] : '#fafafa',
          },
        }}
      >
        {/* Drawer Header */}
        <Box
          sx={{
            p: 2,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            borderBottom: `1px solid ${darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
            position: 'sticky',
            top: 0,
            bgcolor: darkMode ? theme.palette.grey[900] : '#fafafa',
            zIndex: 10,
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <TuneIcon sx={{ color: '#5B2E91' }} />
            <Typography variant="h6" sx={{ fontWeight: 600 }}>
              Advanced Settings
            </Typography>
          </Box>
          <IconButton onClick={() => setAdvancedDrawerOpen(false)} size="small">
            <CloseIcon />
          </IconButton>
        </Box>

        {/* Drawer Content */}
        <Box sx={{ p: 2, pb: 10, overflowY: 'auto' }}>
          <Stack spacing={3}>
            {/* Additional Pricing Fields */}
            <AdditionalPricingSection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
            />

            <Divider />

            {/* Supplier */}
            <SupplierSection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
              onOpenSupplierModal={() => setSupplierModalOpen(true)}
              suppliers={suppliers}
              loadingSuppliers={loadingSuppliers}
            />

            <Divider />

            {/* Settings */}
            <SettingsSection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
            />

            <Divider />

            {/* Perishable (conditional - hidden for gift_item) */}
            {showPerishableSection && (
              <>
                <PerishableSection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                  isPerishable={isPerishable}
                  isAutoEnabled={!!selectedCategory?.isPerishable}
                />
                <Divider />
              </>
            )}

            {/* Image Upload */}
            <ImageUploadSection
              control={control}
              errors={errors}
              watch={watch}
              setValue={setValue}
              darkMode={darkMode}
              images={images}
              imageUrls={imageUrls}
              onImagesChange={handleImagesChange}
            />
          </Stack>
        </Box>

        {/* Drawer Footer */}
        <Box
          sx={{
            p: 2,
            display: 'flex',
            gap: 2,
            justifyContent: 'flex-end',
            borderTop: `1px solid ${darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
            position: 'absolute',
            bottom: 0,
            left: 0,
            right: 0,
            bgcolor: darkMode ? theme.palette.grey[900] : '#fafafa',
          }}
        >
          <Button
            variant="outlined"
            onClick={() => setAdvancedDrawerOpen(false)}
            sx={{ borderRadius: 2 }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={() => setAdvancedDrawerOpen(false)}
            sx={{
              borderRadius: 2,
              background: 'linear-gradient(135deg, #5B2E91 0%, #9c27b0 100%)',
            }}
          >
            Save
          </Button>
        </Box>
      </Drawer>

      {/* Sticky Action Bar */}
      <Paper
        elevation={8}
        sx={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          zIndex: 100,
          backgroundColor: darkMode ? theme.palette.grey[900] : 'white',
          borderTop: `1px solid ${darkMode ? theme.palette.grey[800] : theme.palette.grey[200]}`,
        }}
      >
        <Container maxWidth="lg">
          <Box
            sx={{
              py: 2,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              flexWrap: 'wrap',
              gap: 2,
            }}
          >
            {/* Left side - validation status */}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              {Object.keys(errors).length > 0 && (
                <Chip
                  label={`${Object.keys(errors).length} validation error${Object.keys(errors).length > 1 ? 's' : ''}`}
                  color="error"
                  size="small"
                  variant="outlined"
                />
              )}
              {isDirty && (
                <Chip
                  label="Unsaved changes"
                  color="warning"
                  size="small"
                  variant="outlined"
                />
              )}
            </Box>

            {/* Right side - action buttons */}
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                gap: 1.5,
                flexWrap: 'wrap',
              }}
            >
              {/* Cancel */}
              <Button
                variant="outlined"
                color="inherit"
                onClick={handleCancel}
                disabled={isSubmitting || isSavingDraft || isDeleting}
                startIcon={<CloseIcon />}
              >
                Cancel
              </Button>

              {/* Delete Product (edit mode) */}
              {isEditMode && canDeleteProducts && (
                <Button
                  variant="outlined"
                  color="error"
                  onClick={() => setDeleteDialogOpen(true)}
                  disabled={isSubmitting || isSavingDraft || isDeleting}
                  startIcon={isDeleting ? <CircularProgress size={18} /> : <DeleteOutlineIcon />}
                >
                  Delete Product
                </Button>
              )}

              {/* Save as Draft */}
              {!isEditMode && (
                <Button
                  variant="outlined"
                  onClick={handleSaveDraft}
                  disabled={isSubmitting || isSavingDraft || isDeleting}
                  startIcon={isSavingDraft ? <CircularProgress size={18} /> : <DraftsIcon />}
                >
                  {isMobile ? 'Draft' : 'Save Draft'}
                </Button>
              )}

              {/* Save & Add New */}
              {!isEditMode && (
                <Button
                  variant="outlined"
                  color="primary"
                  onClick={() => {
                    setSubmitAction('saveAndNew');
                    handleSubmit(onSubmit as any, onInvalidSubmit)();
                  }}
                  disabled={isSubmitting || isSavingDraft || isDeleting}
                  startIcon={isSubmitting && submitAction === 'saveAndNew' ? <CircularProgress size={18} /> : <AddIcon />}
                >
                  {isMobile ? 'Save+New' : 'Save & Add New'}
                </Button>
              )}

              {/* Save */}
              <Button
                variant="contained"
                color="primary"
                onClick={() => {
                  setSubmitAction('save');
                  handleSubmit(onSubmit as any, onInvalidSubmit)();
                }}
                disabled={isSubmitting || isSavingDraft || isDeleting}
                startIcon={isSubmitting && submitAction === 'save' ? <CircularProgress size={18} /> : <SaveIcon />}
                sx={{
                  background: 'linear-gradient(135deg, #e91e63 0%, #9c27b0 100%)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #c2185b 0%, #7b1fa2 100%)',
                  },
                }}
              >
                {isEditMode ? 'Update Product' : 'Save Product'}
              </Button>
            </Box>
          </Box>
        </Container>
      </Paper>

      {canDeleteProducts && (
        <Dialog open={deleteDialogOpen} onClose={() => !isDeleting && setDeleteDialogOpen(false)}>
          <DialogTitle>Delete Product</DialogTitle>
          <DialogContent>
            <DialogContentText>
              This will permanently delete this product. This action cannot be undone.
            </DialogContentText>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setDeleteDialogOpen(false)} disabled={isDeleting}>
              Cancel
            </Button>
            <Button color="error" onClick={handleDeleteProduct} disabled={isDeleting} startIcon={isDeleting ? <CircularProgress size={16} /> : <DeleteOutlineIcon />}>
              {isDeleting ? 'Deleting...' : 'Delete'}
            </Button>
          </DialogActions>
        </Dialog>
      )}

      {/* Quick Add Flowers Modal */}
      <QuickAddFlowersModal
        open={quickAddOpen}
        onClose={() => setQuickAddOpen(false)}
        onCreate={handleQuickCreate}
        categories={categories}
        defaultCategoryId={categoryId || ''}
      />

      {/* Quick Add Supplier Modal */}
      <QuickAddSupplierModal
        open={supplierModalOpen}
        onClose={() => setSupplierModalOpen(false)}
        onSupplierCreated={handleSupplierCreated}
        darkMode={darkMode}
      />

      {/* Notification Snackbar */}
      <Snackbar
        open={notification.open}
        autoHideDuration={5000}
        onClose={() => setNotification((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
        sx={{ mb: 10 }}
      >
        <Alert
          severity={notification.severity}
          onClose={() => setNotification((prev) => ({ ...prev, open: false }))}
          variant="filled"
        >
          {notification.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default AddProductForm;
