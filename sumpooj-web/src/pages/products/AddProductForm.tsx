/**
 * Add Product Form
 * Main form component for creating new products
 * Florist POS + ERP SaaS Platform
 */

import { useState, useEffect, useCallback } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Box,
  Container,
  Typography,
  Button,
  Paper,
  Stack,
  Grid,
  IconButton,
  Tooltip,
  Snackbar,
  Alert,
  CircularProgress,
  useTheme,
  useMediaQuery,
  alpha,
  Chip,
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

import {
  BasicInfoSection,
  InventorySection,
  PerishableSection,
  PricingSection,
  AccountingSection,
  SettingsSection,
  FlowerAttributesSection,
  SupplierSection,
  ImageUploadSection,
} from './components/sections';

import QuickAddSupplierModal from './components/QuickAddSupplierModal';

import { productFormSchema } from './schemas/product.schema';
import type { ProductFormSchema } from './schemas/product.schema';
import type { ProductFormData, Supplier } from './types/product.types';
import { defaultProductFormValues } from './types/product.types';
import {
  createProduct,
  saveDraft,
  fetchSuppliers,
  mockSuppliers,
} from './api/product.api';
import {
  saveDraftToStorage,
  loadDraftFromStorage,
  clearDraftFromStorage,
} from './utils/product.utils';

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

  // State
  const [darkMode, setDarkMode] = useState(false);
  const [suppliers, setSuppliers] = useState<Supplier[]>(mockSuppliers);
  const [loadingSuppliers, setLoadingSuppliers] = useState(false);
  const [supplierModalOpen, setSupplierModalOpen] = useState(false);
  const [images, setImages] = useState<File[]>([]);
  const [imageUrls, setImageUrls] = useState<string[]>([]);

  // Submission states
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isSavingDraft, setIsSavingDraft] = useState(false);
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
    reset,
    formState: { errors, isValid, isDirty },
  } = useForm<ProductFormSchema>({
    resolver: zodResolver(productFormSchema),
    defaultValues: {
      ...defaultProductFormValues,
      ...initialData,
    },
    mode: 'onChange',
  });

  // Watched values for conditional rendering
  const productType = watch('productType');
  const trackInventory = watch('trackInventory');
  const isPerishable = watch('isPerishable');

  // Fresh flower logic
  const isFreshFlower = productType === 'fresh_flower';
  const isFlowerProduct = ['fresh_flower', 'dried_flower', 'plant', 'arrangement', 'bouquet'].includes(productType);

  // Auto-enable perishable for fresh flowers
  useEffect(() => {
    if (isFreshFlower) {
      setValue('isPerishable', true);
    }
  }, [isFreshFlower, setValue]);

  useEffect(() => {
    if (isPerishable) {
      setValue('barcode', '');
      setValue('trackBatch', true);
    }
  }, [isPerishable, setValue]);

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
    if (!initialData && !isDuplicate) {
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
  }, [initialData, isDuplicate, setValue]);

  // Handle image changes
  const handleImagesChange = useCallback((files: File[], urls: string[]) => {
    setImages(files);
    setImageUrls(urls);
  }, []);

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

      const response = await createProduct(formData);

      if (response.success && response.data) {
        clearDraftFromStorage();
        
        setNotification({
          open: true,
          message: response.message || 'Product created successfully!',
          severity: 'success',
        });

        if (submitAction === 'saveAndNew') {
          // Reset form for new entry
          reset(defaultProductFormValues);
          setImages([]);
          setImageUrls([]);
        } else {
          // Navigate away or notify parent
          onProductCreated?.(response.data.id);
        }
      } else {
        setNotification({
          open: true,
          message: response.error || 'Failed to create product',
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
        onBack?.();
      }
    } else {
      onBack?.();
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
                    {isDuplicate ? 'Duplicate Product' : 'Add New Product'}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    Fill in the details below to create a new product
                  </Typography>
                </Box>
              </Box>
            </Box>

            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
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
      <Container maxWidth="lg" sx={{ py: 3 }}>
        <form onSubmit={handleSubmit(onSubmit)}>
          <Grid container spacing={3}>
            {/* Left Column - Main Sections */}
            <Grid size={{ xs: 12, lg: 8 }}>
              <Stack spacing={3}>
                {/* Basic Info */}
                <BasicInfoSection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                />

                {/* Pricing */}
                <PricingSection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                />

                {/* Inventory (conditional) */}
                <InventorySection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                  isEnabled={trackInventory}
                />

                {/* Perishable (conditional) */}
                <PerishableSection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                  isPerishable={isPerishable}
                  isAutoEnabled={isFreshFlower}
                />

                {/* Flower Attributes (conditional) */}
                <FlowerAttributesSection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                  isFlowerProduct={isFlowerProduct}
                />
              </Stack>
            </Grid>

            {/* Right Column - Secondary Sections */}
            <Grid size={{ xs: 12, lg: 4 }}>
              <Stack spacing={3}>
                {/* Accounting */}
                <AccountingSection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                />

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

                {/* Settings */}
                <SettingsSection
                  control={control}
                  errors={errors}
                  watch={watch}
                  setValue={setValue}
                  darkMode={darkMode}
                />
              </Stack>
            </Grid>
          </Grid>
        </form>
      </Container>

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
                disabled={isSubmitting || isSavingDraft}
                startIcon={<CloseIcon />}
              >
                Cancel
              </Button>

              {/* Save as Draft */}
              <Button
                variant="outlined"
                onClick={handleSaveDraft}
                disabled={isSubmitting || isSavingDraft}
                startIcon={isSavingDraft ? <CircularProgress size={18} /> : <DraftsIcon />}
              >
                {isMobile ? 'Draft' : 'Save Draft'}
              </Button>

              {/* Save & Add New */}
              <Button
                variant="outlined"
                color="primary"
                onClick={() => {
                  setSubmitAction('saveAndNew');
                  handleSubmit(onSubmit)();
                }}
                disabled={!isValid || isSubmitting || isSavingDraft}
                startIcon={isSubmitting && submitAction === 'saveAndNew' ? <CircularProgress size={18} /> : <AddIcon />}
              >
                {isMobile ? 'Save+New' : 'Save & Add New'}
              </Button>

              {/* Save */}
              <Button
                variant="contained"
                color="primary"
                onClick={() => {
                  setSubmitAction('save');
                  handleSubmit(onSubmit)();
                }}
                disabled={!isValid || isSubmitting || isSavingDraft}
                startIcon={isSubmitting && submitAction === 'save' ? <CircularProgress size={18} /> : <SaveIcon />}
                sx={{
                  background: 'linear-gradient(135deg, #e91e63 0%, #9c27b0 100%)',
                  '&:hover': {
                    background: 'linear-gradient(135deg, #c2185b 0%, #7b1fa2 100%)',
                  },
                }}
              >
                Save Product
              </Button>
            </Box>
          </Box>
        </Container>
      </Paper>

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
