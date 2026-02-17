/**
 * Settings Section
 * Product behavior flags and toggles
 */

import { Grid, Box, Typography, Divider } from '@mui/material';
import SettingsIcon from '@mui/icons-material/Settings';
import SectionCard from '../SectionCard';
import { FormSwitch, FormTagInput } from '../FormFields';
import { FormSectionProps } from '../../types/product.types';

const SettingsSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
}: FormSectionProps) => {
  const suggestedTags = [
    'roses',
    'wedding',
    'romantic',
    'seasonal',
    'premium',
    'budget',
    'tropical',
    'local',
    'imported',
    'fragrant',
    'long-lasting',
    'sympathy',
    'birthday',
    'anniversary',
    'valentines',
    'mothers-day',
  ];

  return (
    <SectionCard
      title="Settings"
      subtitle="Product options and visibility"
      icon={SettingsIcon}
      darkMode={darkMode}
      accentColor="#607d8b"
      collapsible
      defaultExpanded={true}
    >
      <Grid container spacing={2.5}>
        {/* Toggle Settings */}
        <Grid size={{ xs: 12 }}>
          <Typography
            variant="subtitle2"
            sx={{
              color: darkMode ? 'grey.400' : 'grey.600',
              mb: 1.5,
              fontWeight: 600,
            }}
          >
            Product Options
          </Typography>
          <Box
            sx={{
              display: 'flex',
              flexDirection: { xs: 'column', sm: 'row' },
              flexWrap: 'wrap',
              gap: { xs: 1, sm: 3 },
            }}
          >
            <FormSwitch
              name="allowAsRawMaterial"
              control={control}
              label="Allow as Raw Material"
              tooltip="Can be used in arrangements and bouquets"
              darkMode={darkMode}
            />

            <FormSwitch
              name="availableOnline"
              control={control}
              label="Available Online"
              tooltip="Show this product on your web store"
              darkMode={darkMode}
            />

            <FormSwitch
              name="commissionEligible"
              control={control}
              label="Commission Eligible"
              tooltip="Include in sales commission calculations"
              darkMode={darkMode}
            />
          </Box>
        </Grid>

        <Grid size={{ xs: 12 }}>
          <Divider sx={{ my: 1 }} />
        </Grid>

        {/* Tags */}
        <Grid size={{ xs: 12 }}>
          <Typography
            variant="subtitle2"
            sx={{
              color: darkMode ? 'grey.400' : 'grey.600',
              mb: 1.5,
              fontWeight: 600,
            }}
          >
            Product Tags
          </Typography>
          <FormTagInput
            name="tags"
            control={control}
            label="Tags"
            suggestions={suggestedTags}
            placeholder="Type tag and press Enter..."
            darkMode={darkMode}
          />
        </Grid>
      </Grid>
    </SectionCard>
  );
};

export default SettingsSection;
