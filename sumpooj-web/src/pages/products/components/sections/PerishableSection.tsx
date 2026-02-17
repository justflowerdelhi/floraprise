/**
 * Perishable Section
 * Shelf life and expiry management for perishable products
 */

import { Grid, Alert, Box, Typography, Chip, Collapse } from '@mui/material';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import SectionCard from '../SectionCard';
import { FormTextField, FormSwitch } from '../FormFields';
import { FormSectionProps } from '../../types/product.types';
import { calculateExpiryDate, formatDate, isLowShelfLife } from '../../utils/product.utils';

interface PerishableSectionProps extends FormSectionProps {
  isPerishable: boolean;
  isAutoEnabled: boolean; // Auto-enabled for Fresh Flower
}

const PerishableSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
  isPerishable,
  isAutoEnabled,
}: PerishableSectionProps) => {
  const shelfLifeDays = watch('shelfLifeDays');
  const showLowShelfLifeWarning = shelfLifeDays !== undefined && isLowShelfLife(shelfLifeDays);
  const estimatedExpiry = shelfLifeDays ? calculateExpiryDate(shelfLifeDays) : null;

  return (
    <Collapse in={isPerishable || isAutoEnabled}>
      <SectionCard
        title="Perishable Information"
        subtitle="Shelf life and storage requirements"
        icon={LocalFloristIcon}
        darkMode={darkMode}
        accentColor="#4caf50"
        badge={
          isAutoEnabled ? (
            <Chip
              label="Auto-enabled"
              size="small"
              color="success"
              variant="outlined"
              sx={{ height: 22, fontSize: '0.7rem' }}
            />
          ) : undefined
        }
      >
        <Grid container spacing={2.5}>
          {/* Auto-enabled Notice */}
          {isAutoEnabled && (
            <Grid size={{ xs: 12 }}>
              <Alert severity="info" icon={<LocalFloristIcon />}>
                Fresh Flower products are automatically marked as perishable.
                Shelf life is required.
              </Alert>
            </Grid>
          )}

          {/* Perishable Toggle (disabled for auto-enabled) */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormSwitch
              name="isPerishable"
              control={control}
              label="Perishable Product"
              disabled={isAutoEnabled}
              tooltip={
                isAutoEnabled
                  ? 'Automatically enabled for Fresh Flower products'
                  : 'Enable for products with limited shelf life'
              }
              darkMode={darkMode}
            />
          </Grid>

          {/* Shelf Life */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="shelfLifeDays"
              control={control}
              label="Shelf Life"
              type="number"
              required={isPerishable || isAutoEnabled}
              placeholder="e.g., 7"
              endAdornment="days"
              tooltip="Number of days the product remains fresh"
              darkMode={darkMode}
            />
          </Grid>

          {/* Expiry Alert Days */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="expiryAlertDays"
              control={control}
              label="Expiry Alert"
              type="number"
              placeholder="e.g., 2"
              endAdornment="days before"
              tooltip="Get alert this many days before expiry"
              darkMode={darkMode}
            />
          </Grid>

          {/* Temperature Notes */}
          <Grid size={{ xs: 12, md: 6 }}>
            <FormTextField
              name="temperatureNotes"
              control={control}
              label="Temperature Notes"
              placeholder="e.g., Keep refrigerated at 34-38°F"
              tooltip="Storage temperature requirements"
              darkMode={darkMode}
            />
          </Grid>

          {/* Expiry Preview Card */}
          {shelfLifeDays && (
            <Grid size={{ xs: 12 }}>
              <Box
                sx={{
                  p: 2,
                  borderRadius: 2,
                  backgroundColor: darkMode
                    ? 'rgba(76, 175, 80, 0.1)'
                    : 'rgba(76, 175, 80, 0.08)',
                  border: '1px solid',
                  borderColor: darkMode
                    ? 'rgba(76, 175, 80, 0.3)'
                    : 'rgba(76, 175, 80, 0.2)',
                }}
              >
                <Typography
                  variant="caption"
                  sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
                >
                  ESTIMATED EXPIRY DATE (if received today)
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mt: 0.5 }}>
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 600,
                      color: showLowShelfLifeWarning
                        ? '#f57c00'
                        : darkMode
                          ? 'success.light'
                          : 'success.dark',
                    }}
                  >
                    {estimatedExpiry ? formatDate(estimatedExpiry) : '-'}
                  </Typography>
                  {showLowShelfLifeWarning && (
                    <Chip
                      icon={<WarningAmberIcon />}
                      label="Low shelf life"
                      size="small"
                      color="warning"
                      sx={{ height: 24 }}
                    />
                  )}
                </Box>
              </Box>
            </Grid>
          )}

          {/* Low Shelf Life Warning */}
          <Grid size={{ xs: 12 }}>
            <Collapse in={showLowShelfLifeWarning}>
              <Alert severity="warning" icon={<WarningAmberIcon />}>
                <Typography variant="body2" fontWeight={500}>
                  Short Shelf Life Warning
                </Typography>
                <Typography variant="caption">
                  Products with shelf life less than 5 days require careful inventory management
                  and may need expedited shipping options.
                </Typography>
              </Alert>
            </Collapse>
          </Grid>
        </Grid>
      </SectionCard>
    </Collapse>
  );
};

export default PerishableSection;
