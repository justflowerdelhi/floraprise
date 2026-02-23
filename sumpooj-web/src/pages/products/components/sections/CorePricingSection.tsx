/**
 * Core Pricing Section
 * Shows retail/cost prices with real-time margin calculation
 * For the main product form - primary fields only
 */

import { useEffect, useState } from 'react';
import { Grid, Box, Typography, Chip } from '@mui/material';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import SectionCard from '../SectionCard';
import { FormCurrencyField } from '../FormFields';
import type { FormSectionProps } from '../../types/product.types';
import { calculateMargin, formatCurrency, formatPercent } from '../../utils/product.utils';

const CorePricingSection = ({
  control,
  errors,
  watch,
  setValue,
  darkMode = false,
}: FormSectionProps) => {
  const retailPrice = watch('retailPrice') || 0;
  const costPrice = watch('costPrice') || 0;

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
      subtitle="Cost and retail prices"
      icon={AttachMoneyIcon}
      darkMode={darkMode}
      accentColor="#ff9800"
    >
      <Grid container spacing={2.5}>
        {/* Cost Price */}
        <Grid size={{ xs: 12, sm: 6 }}>
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
        <Grid size={{ xs: 12, sm: 6 }}>
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
              <Grid size={{ xs: 4 }}>
                <Typography
                  variant="caption"
                  sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
                >
                  MARGIN
                </Typography>
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.5 }}>
                  {margin >= 0 ? (
                    <TrendingUpIcon
                      sx={{
                        fontSize: 18,
                        color: isHighMargin
                          ? 'success.main'
                          : isLowMargin
                            ? 'warning.main'
                            : 'primary.main',
                      }}
                    />
                  ) : (
                    <TrendingDownIcon sx={{ fontSize: 18, color: 'error.main' }} />
                  )}
                  <Typography
                    variant="body1"
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
              <Grid size={{ xs: 4 }}>
                <Typography
                  variant="caption"
                  sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
                >
                  PROFIT
                </Typography>
                <Typography
                  variant="body1"
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

              {/* Status */}
              <Grid size={{ xs: 4 }}>
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
                          ? 'High'
                          : isLowMargin
                            ? 'Low'
                            : 'Good'
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
                    sx={{ fontWeight: 600, fontSize: '0.7rem' }}
                  />
                </Box>
              </Grid>
            </Grid>
          </Box>
        </Grid>
      </Grid>
    </SectionCard>
  );
};

export default CorePricingSection;
