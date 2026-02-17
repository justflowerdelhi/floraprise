/**
 * Inventory Section
 * Stock management and reorder settings
 */

import { Grid, Alert, Collapse } from '@mui/material';
import InventoryIcon from '@mui/icons-material/Inventory';
import SectionCard from '../SectionCard';
import { FormTextField } from '../FormFields';
import type { FormSectionProps } from '../../types/product.types';

interface InventorySectionProps extends FormSectionProps {
  isEnabled: boolean;
}

const InventorySection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
  isEnabled,
}: InventorySectionProps) => {
  const openingStock = watch('openingStock');
  const reorderLevel = watch('reorderLevel');

  const isLowStock = openingStock !== undefined && 
    reorderLevel !== undefined && 
    openingStock <= reorderLevel;

  return (
    <Collapse in={isEnabled}>
      <SectionCard
        title="Inventory"
        subtitle="Stock management settings"
        icon={InventoryIcon}
        darkMode={darkMode}
        accentColor="#2196f3"
      >
        <Grid container spacing={2.5}>
          {/* Opening Stock */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="openingStock"
              control={control}
              label="Opening Stock"
              type="number"
              required={isEnabled}
              placeholder="e.g., 100"
              tooltip="Current quantity available in inventory"
              darkMode={darkMode}
            />
          </Grid>

          {/* Reorder Level */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="reorderLevel"
              control={control}
              label="Reorder Level"
              type="number"
              required={isEnabled}
              placeholder="e.g., 25"
              tooltip="Alert when stock falls below this level"
              darkMode={darkMode}
            />
          </Grid>

          {/* Low Stock Warning */}
          <Grid size={{ xs: 12 }}>
            <Collapse in={isLowStock}>
              <Alert 
                severity="warning" 
                sx={{ 
                  mt: 1,
                  '& .MuiAlert-icon': {
                    alignItems: 'center',
                  },
                }}
              >
                Opening stock is at or below the reorder level. Consider ordering more inventory.
              </Alert>
            </Collapse>
          </Grid>
        </Grid>
      </SectionCard>
    </Collapse>
  );
};

export default InventorySection;
