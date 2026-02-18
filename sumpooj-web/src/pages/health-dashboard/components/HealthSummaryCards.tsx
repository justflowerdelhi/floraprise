/**
 * HealthSummaryCards — 4 executive KPI cards
 *  Inventory Turnover Ratio | Shrinkage % | Value at Risk | Gross Margin %
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
  Autorenew as TurnoverIcon,
  TrendingDown as ShrinkageIcon,
  WarningAmber as RiskIcon,
  ShowChart as MarginIcon,
  Inventory2Outlined as TotalIcon,
  CalendarToday as DaysIcon,
} from '@mui/icons-material';
import type { HealthSummaryMetrics } from '../data/health.data';
import { fmtCurrency, fmtPercent, fmtRatio, fmtNumber } from '../utils/health.utils';

interface Props {
  metrics: HealthSummaryMetrics;
}

interface CardDef {
  label: string;
  value: string;
  subtitle: string;
  icon: React.ReactNode;
  color: string;
}

const HealthSummaryCards: React.FC<Props> = ({ metrics }) => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';

  const cards: CardDef[] = [
    {
      label: 'Inventory Turnover',
      value: fmtRatio(metrics.inventoryTurnoverRatio),
      subtitle: `${fmtNumber(metrics.totalItems)} items · ${fmtCurrency(metrics.totalInventoryValue)} total`,
      icon: <TurnoverIcon sx={{ fontSize: 30 }} />,
      color: theme.palette.primary.main,
    },
    {
      label: 'Shrinkage',
      value: fmtPercent(metrics.shrinkagePercent),
      subtitle: `${fmtCurrency(Math.round(metrics.totalInventoryValue * metrics.shrinkagePercent / 100))} lost`,
      icon: <ShrinkageIcon sx={{ fontSize: 30 }} />,
      color: metrics.shrinkagePercent > 3 ? theme.palette.error.main : theme.palette.warning.main,
    },
    {
      label: 'Value at Risk',
      value: fmtCurrency(metrics.valueAtRisk),
      subtitle: `${fmtPercent(metrics.valueAtRisk / metrics.totalInventoryValue * 100)} of inventory`,
      icon: <RiskIcon sx={{ fontSize: 30 }} />,
      color: theme.palette.error.main,
    },
    {
      label: 'Gross Margin',
      value: fmtPercent(metrics.grossMarginPercent),
      subtitle: `Avg ${metrics.avgDaysOnHand} days on hand`,
      icon: <MarginIcon sx={{ fontSize: 30 }} />,
      color: theme.palette.success.main,
    },
    {
      label: 'Total Inventory Value',
      value: fmtCurrency(metrics.totalInventoryValue),
      subtitle: `${fmtNumber(metrics.totalItems)} active items`,
      icon: <TotalIcon sx={{ fontSize: 30 }} />,
      color: darkMode ? '#fdd835' : theme.palette.info.main,
    },
    {
      label: 'Avg Days on Hand',
      value: `${metrics.avgDaysOnHand} days`,
      subtitle: 'Rolling 30-day average',
      icon: <DaysIcon sx={{ fontSize: 30 }} />,
      color: theme.palette.info.main,
    },
  ];

  return (
    <Box
      sx={{
        display: 'grid',
        gridTemplateColumns: {
          xs: '1fr',
          sm: 'repeat(2, 1fr)',
          md: 'repeat(3, 1fr)',
          lg: 'repeat(6, 1fr)',
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
            borderTop: `3px solid ${c.color}`,
            transition: 'transform 0.15s, box-shadow 0.15s',
            '&:hover': {
              transform: 'translateY(-2px)',
              boxShadow: darkMode
                ? '0 4px 20px rgba(0,0,0,0.4)'
                : '0 4px 20px rgba(0,0,0,0.08)',
            },
          }}
        >
          <CardContent sx={{ py: 2, '&:last-child': { pb: 2 } }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 1 }}>
              <Typography
                variant="caption"
                sx={{
                  fontWeight: 600,
                  textTransform: 'uppercase',
                  letterSpacing: 0.5,
                  color: darkMode ? 'rgba(255,255,255,0.5)' : 'text.secondary',
                }}
              >
                {c.label}
              </Typography>
              <Box sx={{ color: c.color, opacity: 0.8 }}>{c.icon}</Box>
            </Box>
            <Typography variant="h5" sx={{ fontWeight: 800, mb: 0.5 }}>
              {c.value}
            </Typography>
            <Typography
              variant="caption"
              sx={{ color: darkMode ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}
            >
              {c.subtitle}
            </Typography>
          </CardContent>
        </Card>
      ))}
    </Box>
  );
};

export default HealthSummaryCards;
