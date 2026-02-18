/**
 * Basic Info Section
 * Core product information fields
 */

import { Box, Grid, IconButton, Tooltip, Typography, Chip } from '@mui/material';
import AutorenewIcon from '@mui/icons-material/Autorenew';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import SectionCard from '../SectionCard';
import { FormTextField, FormSelect, FormSwitch } from '../FormFields';
import {
  PRODUCT_TYPES,
  UNITS_OF_MEASURE,
} from '../../types/product.types';
import type { FormSectionProps } from '../../types/product.types';
import { generateSku } from '../../utils/product.utils';

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

  const handleGenerateSku = () => {
    if (productName && productType) {
      const newSku = generateSku(productType, productName);
      setValue('sku', newSku);
    }
  };

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

        {/* Barcode */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormTextField
            name="barcode"
            control={control}
            label="Barcode"
            placeholder="e.g., 123456789012"
            tooltip={isPerishable ? 'Disabled for perishables (use batch QR instead)' : 'UPC, EAN, or other barcode format'}
            disabled={isPerishable}
            darkMode={darkMode}
          />
          {isPerishable && (
            <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 0.5 }}>
              Barcode is disabled for perishables. Use batch labels instead.
            </Typography>
          )}
        </Grid>

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
