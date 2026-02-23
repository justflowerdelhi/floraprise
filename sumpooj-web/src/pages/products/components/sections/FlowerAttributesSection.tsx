/**
 * Flower Attributes Section (Advanced)
 * Specific attributes for flower products
 */

import { useEffect } from 'react';
import {
  Grid,
  Collapse,
  FormControlLabel,
  Switch,
  TextField,
} from '@mui/material';
import ColorLensIcon from '@mui/icons-material/ColorLens';
import { Controller } from 'react-hook-form';
import SectionCard from '../SectionCard';
import { FormTextField, FormSelect, FormMultiSelect } from '../FormFields';
import {
  FLOWER_GRADES,
  COUNTRIES,
  SEASONALITY_OPTIONS,
} from '../../types/product.types';
import type { FormSectionProps } from '../../types/product.types';
import { COMMON_FLOWER_COLORS } from '../../utils/product.utils';

interface FlowerAttributesSectionProps extends FormSectionProps {
  isFlowerProduct: boolean;
}

const FlowerAttributesSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
  isFlowerProduct,
}: FlowerAttributesSectionProps) => {
  const isMultiUnit = watch('isMultiUnit');

  // Auto-set avgUnitsPerStem to 1 when isMultiUnit is disabled
  useEffect(() => {
    if (!isMultiUnit) {
      setValue('avgUnitsPerStem', 1);
    }
  }, [isMultiUnit, setValue]);

  return (
    <Collapse in={isFlowerProduct}>
      <SectionCard
        title="Flower Attributes"
        subtitle="Specific details for flower products"
        icon={ColorLensIcon}
        darkMode={darkMode}
        accentColor="#e91e63"
        collapsible
        defaultExpanded={true}
      >
        <Grid container spacing={2.5}>
          {/* Color */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="color"
              control={control}
              label="Color"
              placeholder="e.g., Red, Pink, White"
              tooltip="Primary color of the flower"
              darkMode={darkMode}
            />
          </Grid>

          {/* Variety */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="variety"
              control={control}
              label="Variety"
              placeholder="e.g., Freedom, Mondial, Vendela"
              tooltip="Specific variety or cultivar name"
              darkMode={darkMode}
            />
          </Grid>

          {/* Grade */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormSelect
              name="grade"
              control={control}
              label="Grade"
              options={FLOWER_GRADES}
              placeholder="Select grade..."
              tooltip="Quality grade classification"
              darkMode={darkMode}
            />
          </Grid>

          {/* Country of Origin */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormSelect
              name="countryOfOrigin"
              control={control}
              label="Country of Origin"
              options={COUNTRIES}
              placeholder="Select country..."
              tooltip="Where the flowers are grown"
              darkMode={darkMode}
            />
          </Grid>

          {/* Seasonality */}
          <Grid size={{ xs: 12 }}>
            <FormMultiSelect
              name="seasonality"
              control={control}
              label="Seasonality"
              options={SEASONALITY_OPTIONS}
              tooltip="When this flower is typically available"
              darkMode={darkMode}
            />
          </Grid>

          {/* Multi-unit Switch */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Controller
              name="isMultiUnit"
              control={control}
              render={({ field }) => (
                <FormControlLabel
                  control={
                    <Switch
                      checked={field.value ?? false}
                      onChange={(e) => field.onChange(e.target.checked)}
                      color="primary"
                    />
                  }
                  label="Multi-bud flower"
                  sx={{
                    '& .MuiFormControlLabel-label': {
                      fontSize: '0.875rem',
                      color: darkMode ? 'grey.300' : 'grey.700',
                    },
                  }}
                />
              )}
            />
          </Grid>

          {/* Average Units Per Stem */}
          <Grid size={{ xs: 12, md: 6 }}>
            <Collapse in={isMultiUnit}>
              <Controller
                name="avgUnitsPerStem"
                control={control}
                render={({ field }) => (
                  <TextField
                    {...field}
                    type="number"
                    label="Avg units per stem"
                    fullWidth
                    size="small"
                    slotProps={{
                      input: {
                        inputProps: { min: 2 },
                      },
                    }}
                    value={field.value ?? 2}
                    onChange={(e) => {
                      const val = parseInt(e.target.value, 10);
                      field.onChange(isNaN(val) ? 2 : Math.max(2, val));
                    }}
                    error={!!errors?.avgUnitsPerStem}
                    helperText={
                      errors?.avgUnitsPerStem?.message ??
                      'Usable buds/blooms per stem'
                    }
                    sx={{
                      '& .MuiOutlinedInput-root': {
                        bgcolor: darkMode ? 'grey.900' : 'grey.50',
                      },
                    }}
                  />
                )}
              />
            </Collapse>
          </Grid>
        </Grid>
      </SectionCard>
    </Collapse>
  );
};

export default FlowerAttributesSection;
