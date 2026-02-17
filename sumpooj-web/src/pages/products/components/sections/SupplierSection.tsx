/**
 * Supplier Section
 * Supplier selection and lead time
 */

import { useState, useEffect } from 'react';
import {
  Grid,
  Box,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormHelperText,
  CircularProgress,
  Typography,
} from '@mui/material';
import LocalShippingIcon from '@mui/icons-material/LocalShipping';
import AddIcon from '@mui/icons-material/Add';
import { Controller } from 'react-hook-form';
import SectionCard from '../SectionCard';
import { FormTextField } from '../FormFields';
import { FormSectionProps, Supplier } from '../../types/product.types';
import { fetchSuppliers } from '../../api/product.api';

interface SupplierSectionProps extends FormSectionProps {
  onOpenSupplierModal: () => void;
  suppliers: Supplier[];
  loadingSuppliers: boolean;
}

const SupplierSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
  onOpenSupplierModal,
  suppliers,
  loadingSuppliers,
}: SupplierSectionProps) => {
  const selectedSupplierId = watch('supplierId');
  const selectedSupplier = suppliers.find((s) => s.id === selectedSupplierId);

  // Auto-fill lead time when supplier is selected
  useEffect(() => {
    if (selectedSupplier?.leadTime && !watch('leadTimeDays')) {
      setValue('leadTimeDays', selectedSupplier.leadTime);
    }
  }, [selectedSupplier, setValue, watch]);

  return (
    <SectionCard
      title="Supplier"
      subtitle="Vendor and lead time information"
      icon={LocalShippingIcon}
      darkMode={darkMode}
      accentColor="#00bcd4"
      collapsible
      defaultExpanded={false}
    >
      <Grid container spacing={2.5}>
        {/* Supplier Select with Quick Add */}
        <Grid size={{ xs: 12, md: 6 }}>
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-start' }}>
            <Box sx={{ flex: 1 }}>
              <Controller
                name="supplierId"
                control={control}
                render={({ field, fieldState: { error } }) => (
                  <FormControl fullWidth error={!!error}>
                    <InputLabel>Supplier</InputLabel>
                    <Select
                      {...field}
                      label="Supplier"
                      value={field.value ?? ''}
                      disabled={loadingSuppliers}
                      sx={{
                        backgroundColor: darkMode ? 'grey.900' : 'white',
                      }}
                      startAdornment={
                        loadingSuppliers ? (
                          <CircularProgress size={20} sx={{ mr: 1 }} />
                        ) : undefined
                      }
                    >
                      <MenuItem value="">
                        <em>None</em>
                      </MenuItem>
                      {suppliers.map((supplier) => (
                        <MenuItem key={supplier.id} value={supplier.id}>
                          <Box>
                            <Typography variant="body2">{supplier.name}</Typography>
                            <Typography variant="caption" color="text.secondary">
                              {supplier.code}
                              {supplier.leadTime && ` • ${supplier.leadTime} day lead time`}
                            </Typography>
                          </Box>
                        </MenuItem>
                      ))}
                    </Select>
                    {error && <FormHelperText>{error.message}</FormHelperText>}
                  </FormControl>
                )}
              />
            </Box>
            <Button
              variant="outlined"
              size="large"
              onClick={onOpenSupplierModal}
              sx={{
                minWidth: 'auto',
                px: 1.5,
                mt: 0.5,
                height: 56,
              }}
            >
              <AddIcon />
            </Button>
          </Box>
        </Grid>

        {/* Lead Time */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormTextField
            name="leadTimeDays"
            control={control}
            label="Lead Time"
            type="number"
            placeholder="e.g., 5"
            endAdornment="days"
            tooltip="Days from order to delivery"
            darkMode={darkMode}
          />
        </Grid>

        {/* Selected Supplier Info */}
        {selectedSupplier && (
          <Grid size={{ xs: 12 }}>
            <Box
              sx={{
                p: 2,
                borderRadius: 2,
                backgroundColor: darkMode
                  ? 'rgba(0, 188, 212, 0.1)'
                  : 'rgba(0, 188, 212, 0.08)',
                border: '1px solid',
                borderColor: darkMode
                  ? 'rgba(0, 188, 212, 0.3)'
                  : 'rgba(0, 188, 212, 0.2)',
              }}
            >
              <Typography variant="subtitle2" sx={{ fontWeight: 600, mb: 0.5 }}>
                {selectedSupplier.name}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Code: {selectedSupplier.code}
                {selectedSupplier.email && ` • ${selectedSupplier.email}`}
                {selectedSupplier.phone && ` • ${selectedSupplier.phone}`}
              </Typography>
            </Box>
          </Grid>
        )}
      </Grid>
    </SectionCard>
  );
};

export default SupplierSection;
