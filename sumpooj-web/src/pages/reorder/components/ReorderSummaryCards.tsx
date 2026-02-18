/**
 * ReorderSummaryCards — 4 risk cards + total suggested cost
 */
import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  useTheme,
} from '@mui/material';
import {
  ErrorOutline as StockoutIcon,
  WarningAmber as LowIcon,
  CheckCircleOutline as OptimalIcon,
  Inventory2Outlined as OverstockIcon,
  ShoppingCartCheckout as CostIcon,
} from '@mui/icons-material';
import type { ReorderSummary } from '../data/reorder.data';
import { fmtCurrency } from '../utils/reorder.utils';

interface Props {
  summary: ReorderSummary;
}

interface CardDef {
  label: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
}

const ReorderSummaryCards: React.FC<Props> = ({ summary }) => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';

  const cards: CardDef[] = [
    {
      label: 'Stock-Out Risk',
      value: summary.stockoutRiskCount,
      icon: <StockoutIcon sx={{ fontSize: 32 }} />,
      color: theme.palette.error.main,
    },
    {
      label: 'Low Stock',
      value: summary.lowStockCount,
      icon: <LowIcon sx={{ fontSize: 32 }} />,
      color: theme.palette.warning.main,
    },
    {
      label: 'Optimal',
      value: summary.optimalCount,
      icon: <OptimalIcon sx={{ fontSize: 32 }} />,
      color: theme.palette.success.main,
    },
    {
      label: 'Overstock',
      value: summary.overstockCount,
      icon: <OverstockIcon sx={{ fontSize: 32 }} />,
      color: theme.palette.info.main,
    },
    {
      label: 'Suggested Reorder Cost',
      value: fmtCurrency(summary.totalSuggestedCost),
      icon: <CostIcon sx={{ fontSize: 32 }} />,
      color: darkMode ? '#fdd835' : theme.palette.primary.main,
    },
  ];

  return (
    <Box
      sx={{
        display: 'grid',
        gridTemplateColumns: {
          xs: '1fr',
          sm: 'repeat(2, 1fr)',
          md: 'repeat(5, 1fr)',
        },
        gap: 2,
        mb: 3,
      }}
    >
      {cards.map((c) => (
        <Card
          key={c.label}
          elevation={darkMode ? 0 : 1}
          sx={{
            bgcolor: darkMode ? '#1a1a2e' : '#fff',
            border: darkMode ? '1px solid rgba(255,255,255,0.08)' : 'none',
            borderLeft: `4px solid ${c.color}`,
          }}
        >
          <CardContent
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 2,
              py: 2,
              '&:last-child': { pb: 2 },
            }}
          >
            <Box sx={{ color: c.color }}>{c.icon}</Box>
            <Box>
              <Typography
                variant="body2"
                sx={{ color: darkMode ? 'rgba(255,255,255,0.6)' : 'text.secondary' }}
              >
                {c.label}
              </Typography>
              <Typography variant="h5" sx={{ fontWeight: 700 }}>
                {c.value}
              </Typography>
            </Box>
          </CardContent>
        </Card>
      ))}
    </Box>
  );
};

export default ReorderSummaryCards;
