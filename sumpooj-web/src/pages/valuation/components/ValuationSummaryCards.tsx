/**
 * Valuation Summary Cards — 5 KPI cards
 * Total Inventory Value, Fresh Flowers Value, Hard Goods Value,
 * Total Batches, Average Margin %
 */

import {
  Box,
  Paper,
  Typography,
  Skeleton,
  alpha,
  useTheme,
} from '@mui/material';
import AttachMoneyIcon from '@mui/icons-material/AttachMoney';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import Inventory2Icon from '@mui/icons-material/Inventory2';
import LayersIcon from '@mui/icons-material/Layers';
import TrendingUpIcon from '@mui/icons-material/TrendingUp';

import type { ValuationSummary } from '../data/valuation.data';
import { fmt, fmtPct } from '../utils/valuation.utils';

interface Props {
  summary: ValuationSummary | null;
  loading: boolean;
  darkMode: boolean;
}

interface CardDef {
  label: string;
  getValue: (s: ValuationSummary) => string;
  getSubtext: (s: ValuationSummary) => string;
  color: string;
  icon: React.ReactNode;
}

const cards: CardDef[] = [
  {
    label: 'Total Inventory Value',
    getValue: (s) => fmt(s.totalInventoryValue),
    getSubtext: (s) => `${s.totalProducts} products · ${s.totalQuantity} units`,
    color: '#1565c0',
    icon: <AttachMoneyIcon sx={{ fontSize: 22 }} />,
  },
  {
    label: 'Fresh Flowers Value',
    getValue: (s) => fmt(s.freshFlowersValue),
    getSubtext: (s) =>
      `${fmtPct(s.totalInventoryValue > 0 ? (s.freshFlowersValue / s.totalInventoryValue) * 100 : 0)} of total`,
    color: '#c62828',
    icon: <LocalFloristIcon sx={{ fontSize: 22 }} />,
  },
  {
    label: 'Hard Goods Value',
    getValue: (s) => fmt(s.hardGoodsValue),
    getSubtext: (s) =>
      `${fmtPct(s.totalInventoryValue > 0 ? (s.hardGoodsValue / s.totalInventoryValue) * 100 : 0)} of total`,
    color: '#616161',
    icon: <Inventory2Icon sx={{ fontSize: 22 }} />,
  },
  {
    label: 'Total Batches (FIFO)',
    getValue: (s) => `${s.totalBatches}`,
    getSubtext: (s) =>
      `Across ${s.totalProducts} products`,
    color: '#6a1b9a',
    icon: <LayersIcon sx={{ fontSize: 22 }} />,
  },
  {
    label: 'Avg Margin',
    getValue: (s) => fmtPct(s.averageMarginPct),
    getSubtext: () => 'Weighted avg across products',
    color: '#2e7d32',
    icon: <TrendingUpIcon sx={{ fontSize: 22 }} />,
  },
];

const ValuationSummaryCards = ({ summary, loading, darkMode }: Props) => {
  const theme = useTheme();
  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];

  return (
    <Box
      sx={{
        display: 'grid',
        gridTemplateColumns: {
          xs: '1fr',
          sm: 'repeat(2, 1fr)',
          md: 'repeat(3, 1fr)',
          lg: 'repeat(5, 1fr)',
        },
        gap: 2,
      }}
    >
      {cards.map((card) => (
        <Paper
          key={card.label}
          elevation={0}
          sx={{
            p: 2.5,
            borderRadius: 2,
            border: `1px solid ${borderColor}`,
            backgroundColor: darkMode
              ? alpha(theme.palette.grey[900], 0.85)
              : '#fff',
            transition: 'box-shadow 0.2s',
            '&:hover': {
              boxShadow: darkMode
                ? `0 0 0 1px ${alpha(card.color, 0.3)}`
                : `0 2px 8px ${alpha(card.color, 0.1)}`,
            },
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Box
              sx={{
                width: 40,
                height: 40,
                borderRadius: '10px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                backgroundColor: darkMode
                  ? alpha(card.color, 0.15)
                  : alpha(card.color, 0.08),
                color: card.color,
                flexShrink: 0,
              }}
            >
              {card.icon}
            </Box>
            <Box sx={{ minWidth: 0 }}>
              <Typography
                variant="caption"
                sx={{
                  color: darkMode ? 'grey.500' : 'grey.500',
                  fontSize: '0.65rem',
                  fontWeight: 600,
                  textTransform: 'uppercase',
                  letterSpacing: 0.5,
                }}
              >
                {card.label}
              </Typography>
              {loading || !summary ? (
                <Skeleton variant="text" width={90} height={28} />
              ) : (
                <>
                  <Typography
                    variant="h6"
                    sx={{
                      fontWeight: 800,
                      fontSize: '1.1rem',
                      lineHeight: 1.2,
                      color: darkMode ? '#f5f5f5' : '#1a1a1a',
                    }}
                  >
                    {card.getValue(summary)}
                  </Typography>
                  <Typography
                    variant="caption"
                    sx={{
                      color: darkMode ? 'grey.600' : 'grey.400',
                      fontSize: '0.68rem',
                    }}
                  >
                    {card.getSubtext(summary)}
                  </Typography>
                </>
              )}
            </Box>
          </Box>
        </Paper>
      ))}
    </Box>
  );
};

export default ValuationSummaryCards;
