/**
 * Pricing Section
 * Price management with real-time margin calculation
 */

import { useEffect, useState } from 'react';
import { Grid, Box, Typography, Chip, Alert } from '@mui/material';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import SectionCard from '../SectionCard';
import { FormCurrencyField, FormSelect } from '../FormFields';
import { TAX_CATEGORIES } from '../../types/product.types';
import type { FormSectionProps } from '../../types/product.types';
import { calculateMargin, formatCurrency, formatPercent } from '../../utils/product.utils';

const PricingSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
}: FormSectionProps) => {
  const retailPrice = watch('retailPrice') || 0;
  const costPrice = watch('costPrice') || 0;
  const wholesalePrice = watch('wholesalePrice');
  const weddingEventPrice = watch('weddingEventPrice');

  const [margin, setMargin] = useState(0);
  const [profit, setProfit] = useState(0);

  useEffect(() => {
    const calculatedMargin = calculateMargin(retailPrice, costPrice);
    const calculatedProfit = retailPrice - costPrice;
    setMargin(calculatedMargin);
    setProfit(calculatedProfit);
  }, [retailPrice, costPrice]);

  const isValidPricing = retailPrice >= costPrice;
  const isHighMargin = margin >= 50;
  const isLowMargin = margin < 20 && margin > 0;

  return (
    <SectionCard
      title="Pricing"
      subtitle="Set prices and tax settings"
      icon={AttachMoneyIcon}
      darkMode={darkMode}
      accentColor="#ff9800"
    >
      <Grid container spacing={2.5}>
        {/* Cost Price */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormCurrencyField
            name="costPrice"
            control={control}
            label="Cost Price"
            required
            placeholder="0.00"
            tooltip="Your purchase cost per unit"
            darkMode={darkMode}
          />
        </Grid>

        {/* Retail Price */}
        <Grid size={{ xs: 12, md: 6 }}>
          <FormCurrencyField
            name="retailPrice"
            control={control}
            label="Retail Price"
            required
            placeholder="0.00"
            tooltip="Customer-facing price"
            darkMode={darkMode}
          />
        </Grid>

        {/* Real-time Margin Calculator */}
        <Grid size={{ xs: 12 }}>
          <Box
            sx={{
              p: 2,
              borderRadius: 2,
              backgroundColor: darkMode
                ? isValidPricing
                  ? 'rgba(76, 175, 80, 0.1)'
                  : 'rgba(244, 67, 54, 0.1)'
                : isValidPricing
                  ? 'rgba(76, 175, 80, 0.08)'
                  : 'rgba(244, 67, 54, 0.08)',
              border: '1px solid',
              borderColor: darkMode
                ? isValidPricing
                  ? 'rgba(76, 175, 80, 0.3)'
                  : 'rgba(244, 67, 54, 0.3)'
                : isValidPricing
                  ? 'rgba(76, 175, 80, 0.2)'
                  : 'rgba(244, 67, 54, 0.2)',
            }}
          >
            <Grid container spacing={2}>
              {/* Gross Margin */}
              <Grid size={{ xs: 6, sm: 4 }}>
                <Typography
                  variant="caption"
                  sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
                >
                  GROSS MARGIN
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mt: 0.5 }}>
                  {margin >= 0 ? (
                    <TrendingUpIcon
                      sx={{
                        fontSize: 20,
                        color: isHighMargin
                          ? 'success.main'
                          : isLowMargin
                            ? 'warning.main'
                            : 'primary.main',
                      }}
                    />
                  ) : (
                    <TrendingDownIcon sx={{ fontSize: 20, color: 'error.main' }} />
                  )}
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 700,
                      color: isValidPricing
                        ? isHighMargin
                          ? 'success.main'
                          : isLowMargin
                            ? 'warning.main'
                            : darkMode
                              ? 'grey.100'
                              : 'grey.800'
                        : 'error.main',
                    }}
                  >
                    {formatPercent(margin)}
                  </Typography>
                </Box>
              </Grid>

              {/* Profit per Unit */}
              <Grid size={{ xs: 6, sm: 4 }}>
                <Typography
                  variant="caption"
                  sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
                >
                  PROFIT PER UNIT
                </Typography>
                <Typography
                  variant="h6"
                  sx={{
                    fontWeight: 700,
                    mt: 0.5,
                    color: profit >= 0
                      ? darkMode
                        ? 'success.light'
                        : 'success.dark'
                      : 'error.main',
                  }}
                >
                  {formatCurrency(profit)}
                </Typography>
              </Grid>

              {/* Margin Status Chip */}
              <Grid size={{ xs: 12, sm: 4 }}>
                <Typography
                  variant="caption"
                  sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
                >
                  STATUS
                </Typography>
                <Box sx={{ mt: 0.5 }}>
                  <Chip
                    label={
                      !isValidPricing
                        ? 'Loss'
                        : isHighMargin
                          ? 'High Margin'
                          : isLowMargin
                            ? 'Low Margin'
                            : 'Good Margin'
                    }
                    size="small"
                    color={
                      !isValidPricing
                        ? 'error'
                        : isHighMargin
                          ? 'success'
                          : isLowMargin
                            ? 'warning'
                            : 'primary'
                    }
                    sx={{ fontWeight: 600 }}
                  />
                </Box>
              </Grid>
            </Grid>
          </Box>
        </Grid>

        {/* Pricing Error Alert */}
        {!isValidPricing && retailPrice > 0 && (
          <Grid size={{ xs: 12 }}>
            <Alert severity="error">
              Retail price must be greater than or equal to cost price
            </Alert>
          </Grid>
        )}

        {/* Wholesale Price */}
        <Grid size={{ xs: 12, md: 6 }}>
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
        <Grid size={{ xs: 12, md: 6 }}>
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
        <Grid size={{ xs: 12, md: 6 }}>
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
    </SectionCard>
  );
};

export default PricingSection;
