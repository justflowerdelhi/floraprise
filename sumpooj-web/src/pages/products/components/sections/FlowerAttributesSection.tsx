/**
 * Flower Attributes Section (Advanced)
 * Specific attributes for flower products
 */

import { Grid, Collapse } from '@mui/material';
import ColorLensIcon from '@mui/icons-material/ColorLens';
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
        </Grid>
      </SectionCard>
    </Collapse>
  );
};

export default FlowerAttributesSection;
