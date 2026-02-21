/**
 * Basic Info Section
 * Core product information fields
 */

import { useState, useCallback } from 'react';
import { Box, Grid, IconButton, Tooltip, Typography, Chip, ToggleButton, ToggleButtonGroup, CircularProgress } from '@mui/material';
import AutorenewIcon from '@mui/icons-material/Autorenew';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import QrCodeScannerIcon from '@mui/icons-material/QrCodeScanner';
import AutoModeIcon from '@mui/icons-material/AutoMode';
import BlockIcon from '@mui/icons-material/Block';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';
import SectionCard from '../SectionCard';
import { FormTextField, FormSelect, FormSwitch } from '../FormFields';
import {
  PRODUCT_TYPES,
  UNITS_OF_MEASURE,
} from '../../types/product.types';
import type { FormSectionProps } from '../../types/product.types';
import { generateSku } from '../../utils/product.utils';
import { generateInternalBarcode } from '../../../../components/barcode/BarcodeUtils';

interface BasicInfoSectionProps extends FormSectionProps {
  onGenerateSku?: () => void;
}

const BasicInfoSection = ({
  control,
  errors: _errors,
  watch,
  setValue,
  darkMode = false,
}: BasicInfoSectionProps) => {
  const productType = watch('productType');
  const productName = watch('productName');
  const status = watch('status');
  const isPerishable = watch('isPerishable');
  const barcodeInputMethod = watch('barcodeInputMethod') || 'none';
  const sku = watch('sku');

  const [isValidatingBarcode, setIsValidatingBarcode] = useState(false);
  const [barcodeError, setBarcodeError] = useState<string | null>(null);
  const [barcodeValid, setBarcodeValid] = useState(false);

  const handleGenerateSku = () => {
    if (productName && productType) {
      const newSku = generateSku(productType, productName);
      setValue('sku', newSku);
    }
  };

  const handleBarcodeMethodChange = (_event: React.MouseEvent<HTMLElement>, newMethod: string | null) => {
    if (newMethod) {
      setValue('barcodeInputMethod', newMethod as 'scan' | 'auto_generate' | 'none');
      setBarcodeError(null);
      setBarcodeValid(false);
      
      // Clear barcode fields when switching methods
      if (newMethod === 'none') {
        setValue('barcode', '');
        setValue('internalBarcode', '');
      } else if (newMethod === 'auto_generate') {
        setValue('barcode', ''); // Clear external barcode
        // Auto-generate internal barcode
        if (sku) {
          const internalBarcode = generateInternalBarcode(sku);
          setValue('internalBarcode', internalBarcode);
        }
      } else if (newMethod === 'scan') {
        setValue('internalBarcode', ''); // Clear internal barcode
      }
    }
  };

  const handleGenerateInternalBarcode = useCallback(() => {
    if (sku) {
      const newBarcode = generateInternalBarcode(sku);
      setValue('internalBarcode', newBarcode);
      setBarcodeValid(true);
    }
  }, [sku, setValue]);

  return (
    <SectionCard
      title="Basic Information"
      subtitle="Core product details"
      icon={LocalFloristIcon}
      darkMode={darkMode}
      accentColor="#e91e63"
      badge={
        <Chip
          label={status === 'active' ? 'Active' : 'Inactive'}
          size="small"
          color={status === 'active' ? 'success' : 'default'}
          sx={{ height: 22, fontSize: '0.7rem' }}
        />
      }
    >
      <Grid container spacing={2.5}>
        {/* Product Name */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormTextField
            name="productName"
            control={control}
            label="Product Name"
            required
            placeholder="e.g., Red Freedom Rose"
            autoFocus
            darkMode={darkMode}
          />
        </Grid>

        {/* Product Type */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormSelect
            name="productType"
            control={control}
            label="Product Type"
            options={PRODUCT_TYPES}
            required
            darkMode={darkMode}
          />
        </Grid>

        {/* SKU with Auto-Generate */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-start' }}>
            <Box sx={{ flex: 1 }}>
              <FormTextField
                name="sku"
                control={control}
                label="SKU"
                required
                placeholder="e.g., FLW-ROS-001"
                tooltip="Stock Keeping Unit - unique product identifier"
                darkMode={darkMode}
              />
            </Box>
            <Tooltip title="Auto-generate SKU from product name">
              <IconButton
                onClick={handleGenerateSku}
                disabled={!productName || !productType}
                sx={{
                  mt: 1,
                  backgroundColor: darkMode ? 'grey.800' : 'grey.100',
                  '&:hover': {
                    backgroundColor: darkMode ? 'grey.700' : 'grey.200',
                  },
                }}
              >
                <AutorenewIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </Grid>

        {/* Unit of Measure */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormSelect
            name="unitOfMeasure"
            control={control}
            label="Unit of Measure"
            options={UNITS_OF_MEASURE}
            required
            darkMode={darkMode}
          />
        </Grid>

        {/* Barcode Input Method Selection */}
        <Grid size={{ xs: 12 }}>
          <Box sx={{ mb: 1 }}>
            <Typography variant="subtitle2" sx={{ mb: 1, color: darkMode ? 'grey.300' : 'grey.700' }}>
              Barcode Method
            </Typography>
            <ToggleButtonGroup
              value={barcodeInputMethod}
              exclusive
              onChange={handleBarcodeMethodChange}
              size="small"
              disabled={isPerishable}
              sx={{
                '& .MuiToggleButton-root': {
                  textTransform: 'none',
                  px: 2,
                },
              }}
            >
              <ToggleButton value="scan">
                <QrCodeScannerIcon sx={{ mr: 1, fontSize: 18 }} />
                Scan Manufacturer Barcode
              </ToggleButton>
              <ToggleButton value="auto_generate">
                <AutoModeIcon sx={{ mr: 1, fontSize: 18 }} />
                Auto Generate Internal
              </ToggleButton>
              <ToggleButton value="none">
                <BlockIcon sx={{ mr: 1, fontSize: 18 }} />
                No Barcode
              </ToggleButton>
            </ToggleButtonGroup>
            {isPerishable && (
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
                Barcode is disabled for perishables. Use batch labels instead.
              </Typography>
            )}
          </Box>
        </Grid>

        {/* External Barcode (Scan Mode) */}
        {barcodeInputMethod === 'scan' && !isPerishable && (
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="barcode"
              control={control}
              label="Manufacturer Barcode"
              placeholder="Scan or enter barcode..."
              tooltip="Scan the manufacturer's UPC, EAN, or other barcode"
              darkMode={darkMode}
              startAdornment={<QrCodeScannerIcon sx={{ fontSize: 20, color: darkMode ? 'grey.500' : 'grey.400' }} />}
              endAdornment={
                isValidatingBarcode ? (
                  <CircularProgress size={18} />
                ) : barcodeValid ? (
                  <CheckCircleIcon sx={{ color: 'success.main', fontSize: 20 }} />
                ) : undefined
              }
            />
            {barcodeError && (
              <Typography variant="caption" color="error" sx={{ display: 'block', mt: 0.5 }}>
                {barcodeError}
              </Typography>
            )}
          </Grid>
        )}

        {/* Internal Barcode (Auto-Generate Mode) */}
        {barcodeInputMethod === 'auto_generate' && !isPerishable && (
          <Grid size={{ xs: 12, md: 6 }}>
            <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-start' }}>
              <Box sx={{ flex: 1 }}>
                <FormTextField
                  name="internalBarcode"
                  control={control}
                  label="Internal Barcode"
                  placeholder="Auto-generated barcode"
                  tooltip="Internal barcode for products without manufacturer barcodes"
                  darkMode={darkMode}
                  disabled
                  startAdornment={<AutoModeIcon sx={{ fontSize: 20, color: darkMode ? 'grey.500' : 'grey.400' }} />}
                />
              </Box>
              <Tooltip title="Regenerate internal barcode">
                <IconButton
                  onClick={handleGenerateInternalBarcode}
                  disabled={!sku}
                  sx={{
                    mt: 1,
                    backgroundColor: darkMode ? 'grey.800' : 'grey.100',
                    '&:hover': {
                      backgroundColor: darkMode ? 'grey.700' : 'grey.200',
                    },
                  }}
                >
                  <AutorenewIcon />
                </IconButton>
              </Tooltip>
            </Box>
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
              Internal barcodes are auto-generated and can be printed on labels.
            </Typography>
          </Grid>
        )}

        {/* Brand */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormTextField
            name="brand"
            control={control}
            label="Brand"
            placeholder="e.g., Ecuador Premium"
            darkMode={darkMode}
          />
        </Grid>

        {/* Description */}
        <Grid size={{ xs: 12 }}>
          <FormTextField
            name="description"
            control={control}
            label="Description"
            multiline
            rows={3}
            placeholder="Enter product description..."
            maxLength={1000}
            darkMode={darkMode}
          />
        </Grid>

        {/* Status */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormSelect
            name="status"
            control={control}
            label="Status"
            options={[
              { value: 'active', label: 'Active' },
              { value: 'inactive', label: 'Inactive' },
            ]}
            required
            darkMode={darkMode}
          />
        </Grid>

        {/* Track Inventory */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Box sx={{ mt: 1 }}>
            <FormSwitch
              name="trackInventory"
              control={control}
              label="Track Inventory"
              tooltip="Enable to track stock levels and get low stock alerts"
              darkMode={darkMode}
            />
          </Box>
        </Grid>
      </Grid>
    </SectionCard>
  );
};

export default BasicInfoSection;
