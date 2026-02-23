/**
 * ProductIntentSelector.tsx
 * Large segmented toggle button group for selecting product intent
 */

import React from 'react';
import {
  Box,
  ToggleButtonGroup,
  ToggleButton,
  Typography,
  useTheme,
  alpha,
} from '@mui/material';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import CardGiftcardIcon from '@mui/icons-material/CardGiftcard';
import AutoAwesomeIcon from '@mui/icons-material/AutoAwesome';
import InventoryIcon from '@mui/icons-material/Inventory';
import { Controller, type Control } from 'react-hook-form';

// ─── Product Intent Options ─────────────────────────────────

export const PRODUCT_INTENTS = [
  {
    value: 'fresh_flower',
    label: 'Fresh Flower',
    icon: LocalFloristIcon,
    color: '#e91e63',
  },
  {
    value: 'bouquet',
    label: 'Bouquet',
    icon: AutoAwesomeIcon,
    color: '#9c27b0',
  },
  {
    value: 'gift_item',
    label: 'Gift Item',
    icon: CardGiftcardIcon,
    color: '#ff9800',
  },
  {
    value: 'raw_material',
    label: 'Raw Material',
    icon: InventoryIcon,
    color: '#2196f3',
  },
] as const;

export type ProductIntent = typeof PRODUCT_INTENTS[number]['value'];

// ─── Component Props ────────────────────────────────────────

interface ProductIntentSelectorProps {
  control: Control<any>;
  darkMode?: boolean;
}

const ProductIntentSelector: React.FC<ProductIntentSelectorProps> = ({
  control,
  darkMode = false,
}) => {
  const theme = useTheme();

  return (
    <Box sx={{ mb: 3 }}>
      <Typography
        variant="subtitle2"
        sx={{
          fontWeight: 600,
          mb: 1.5,
          color: darkMode ? 'grey.300' : 'grey.700',
        }}
      >
        What are you adding?
      </Typography>
      <Controller
        name="productIntent"
        control={control}
        defaultValue="fresh_flower"
        render={({ field }) => (
          <ToggleButtonGroup
            {...field}
            exclusive
            fullWidth
            onChange={(_, value) => {
              if (value !== null) {
                field.onChange(value);
              }
            }}
            sx={{
              display: 'grid',
              gridTemplateColumns: { xs: 'repeat(2, 1fr)', sm: 'repeat(4, 1fr)' },
              gap: 1,
              '& .MuiToggleButtonGroup-grouped': {
                border: `1px solid ${darkMode ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.12)'}`,
                borderRadius: '12px !important',
                '&:not(:first-of-type)': {
                  borderLeft: `1px solid ${darkMode ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.12)'}`,
                  marginLeft: 0,
                },
              },
            }}
          >
            {PRODUCT_INTENTS.map((intent) => {
              const Icon = intent.icon;
              const isSelected = field.value === intent.value;

              return (
                <ToggleButton
                  key={intent.value}
                  value={intent.value}
                  sx={{
                    py: 2,
                    px: 2,
                    flexDirection: 'column',
                    gap: 1,
                    textTransform: 'none',
                    bgcolor: isSelected
                      ? alpha(intent.color, darkMode ? 0.2 : 0.1)
                      : darkMode
                        ? 'rgba(255,255,255,0.02)'
                        : 'rgba(0,0,0,0.02)',
                    borderColor: isSelected
                      ? `${intent.color} !important`
                      : undefined,
                    '&:hover': {
                      bgcolor: alpha(intent.color, darkMode ? 0.15 : 0.08),
                    },
                    '&.Mui-selected': {
                      bgcolor: alpha(intent.color, darkMode ? 0.2 : 0.1),
                      borderColor: intent.color,
                      '&:hover': {
                        bgcolor: alpha(intent.color, darkMode ? 0.25 : 0.15),
                      },
                    },
                  }}
                >
                  <Icon
                    sx={{
                      fontSize: 28,
                      color: isSelected
                        ? intent.color
                        : darkMode
                          ? 'grey.400'
                          : 'grey.600',
                    }}
                  />
                  <Typography
                    variant="body2"
                    sx={{
                      fontWeight: isSelected ? 700 : 500,
                      color: isSelected
                        ? intent.color
                        : darkMode
                          ? 'grey.300'
                          : 'grey.700',
                    }}
                  >
                    {intent.label}
                  </Typography>
                </ToggleButton>
              );
            })}
          </ToggleButtonGroup>
        )}
      />
    </Box>
  );
};

export default ProductIntentSelector;
