/**
 * Additional Pricing Section
 * Wholesale, wedding/event pricing and tax category
 * For use inside Business & Accounting accordion
 */

import { Grid, Typography, Box } from '@mui/material';
import { FormCurrencyField, FormSelect } from '../FormFields';
import { TAX_CATEGORIES } from '../../types/product.types';
import type { FormSectionProps } from '../../types/product.types';

const AdditionalPricingSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
}: FormSectionProps) => {
  return (
    <Box>
      <Typography
        variant="subtitle2"
        sx={{
          fontWeight: 600,
          mb: 2,
          color: darkMode ? 'grey.300' : 'grey.700',
        }}
      >
        Additional Pricing
      </Typography>
      <Grid container spacing={2}>
        {/* Wholesale Price */}
        <Grid size={{ xs: 12, sm: 6 }}>
          <FormCurrencyField
            name="wholesalePrice"
            control={control}
            label="Wholesale Price"
            placeholder="0.00"
            tooltip="Price for bulk/wholesale customers"
            darkMode={darkMode}
          />
        </Grid>

        {/* Wedding/Event Price */}
        <Grid size={{ xs: 12, sm: 6 }}>
          <FormCurrencyField
            name="weddingEventPrice"
            control={control}
            label="Wedding/Event Price"
            placeholder="0.00"
            tooltip="Special pricing for wedding and event orders"
            darkMode={darkMode}
          />
        </Grid>

        {/* Tax Category */}
        <Grid size={{ xs: 12, sm: 6 }}>
          <FormSelect
            name="taxCategory"
            control={control}
            label="Tax Category"
            options={TAX_CATEGORIES}
            required
            tooltip="Tax classification for this product"
            darkMode={darkMode}
          />
        </Grid>
      </Grid>
    </Box>
  );
};

export default AdditionalPricingSection;
