/**
 * Summary Cards — Top-of-dashboard KPI cards
 * 6 cards: Total Value, Expiring in 3 Days, Expired, Low Stock,
 *          Fresh Flower Value, Average Days Remaining
 */

import {
  Box,
  Paper,
  Typography,
  Skeleton,
  useTheme,
  alpha,
} from '@mui/material';
import InventoryIcon from '@mui/icons-material/Inventory2';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import ReportProblemIcon from '@mui/icons-material/ReportProblem';
import ProductionQuantityLimitsIcon from '@mui/icons-material/ProductionQuantityLimits';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import ScheduleIcon from '@mui/icons-material/Schedule';
import type { DashboardSummary } from '../data/inventory.data';
import { fmt } from '../utils/inventory.utils';

interface SummaryCardsProps {
  summary: DashboardSummary | null;
  loading: boolean;
  darkMode: boolean;
}

interface CardDef {
  title: string;
  getValue: (s: DashboardSummary) => string;
  getSubtext: (s: DashboardSummary) => string;
  icon: React.ReactNode;
  accent: string;
}

const SummaryCards = ({ summary, loading, darkMode }: SummaryCardsProps) => {
  const theme = useTheme();

  const cards: CardDef[] = [
    {
      title: 'Total Inventory Value',
      getValue: (s) => fmt(s.totalInventoryValue),
      getSubtext: (s) => `${s.totalBatches} batches · ${s.totalProducts} products`,
      icon: <InventoryIcon sx={{ fontSize: 22 }} />,
      accent: theme.palette.primary.main,
    },
    {
      title: 'Expiring in 3 Days',
      getValue: (s) => `${s.expiringIn3Days} batches`,
      getSubtext: (s) =>
        s.expiringIn3Days > 0 ? `${fmt(s.expiringIn3DaysValue)} at risk` : 'No batches at risk',
      icon: <WarningAmberIcon sx={{ fontSize: 22 }} />,
      accent: '#e65100',
    },
    {
      title: 'Expired Inventory',
      getValue: (s) => `${s.expiredCount} batches`,
      getSubtext: (s) =>
        s.expiredCount > 0 ? `${fmt(s.expiredValue)} loss` : 'All stock is valid',
      icon: <ReportProblemIcon sx={{ fontSize: 22 }} />,
      accent: '#c62828',
    },
    {
      title: 'Low Stock Items',
      getValue: (s) => String(s.lowStockCount),
      getSubtext: () => 'Below 20% remaining',
      icon: <ProductionQuantityLimitsIcon sx={{ fontSize: 22 }} />,
      accent: '#6a1b9a',
    },
    {
      title: 'Fresh Flower Value',
      getValue: (s) => fmt(s.freshFlowerValue),
      getSubtext: (s) => {
        const pct = s.totalInventoryValue > 0
          ? ((s.freshFlowerValue / s.totalInventoryValue) * 100).toFixed(0)
          : '0';
        return `${pct}% of total inventory`;
      },
      icon: <LocalFloristIcon sx={{ fontSize: 22 }} />,
      accent: '#d81b60',
    },
    {
      title: 'Avg Days Remaining',
      getValue: (s) => `${s.averageDaysRemaining.toFixed(1)} days`,
      getSubtext: () => 'Across perishable batches',
      icon: <ScheduleIcon sx={{ fontSize: 22 }} />,
      accent: '#00838f',
    },
  ];

  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];

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
      }}
    >
      {cards.map((card, idx) => (
        <Paper
          key={idx}
          elevation={0}
          sx={{
            p: 2.5,
            borderRadius: 2,
            border: `1px solid ${borderColor}`,
            backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
            display: 'flex',
            flexDirection: 'column',
            gap: 1.5,
            transition: 'all 0.2s ease',
            '&:hover': {
              borderColor: darkMode ? theme.palette.grey[600] : theme.palette.grey[300],
              boxShadow: darkMode
                ? '0 4px 20px rgba(0,0,0,0.35)'
                : '0 4px 20px rgba(0,0,0,0.06)',
              transform: 'translateY(-1px)',
            },
          }}
        >
          {/* Icon */}
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 40,
              height: 40,
              borderRadius: 1.5,
              backgroundColor: alpha(card.accent, darkMode ? 0.18 : 0.1),
              color: card.accent,
            }}
          >
            {card.icon}
          </Box>

          {/* Title */}
          <Typography
            variant="caption"
            sx={{
              color: darkMode ? 'grey.500' : 'grey.600',
              fontWeight: 600,
              textTransform: 'uppercase',
              letterSpacing: 0.5,
              fontSize: '0.65rem',
              lineHeight: 1.2,
            }}
          >
            {card.title}
          </Typography>

          {/* Value */}
          {loading || !summary ? (
            <>
              <Skeleton variant="text" width="75%" height={32} />
              <Skeleton variant="text" width="90%" height={14} />
            </>
          ) : (
            <>
              <Typography
                variant="h6"
                sx={{
                  fontWeight: 700,
                  color: darkMode ? 'grey.100' : 'grey.900',
                  lineHeight: 1.1,
                  fontSize: '1.1rem',
                }}
              >
                {card.getValue(summary)}
              </Typography>
              <Typography
                variant="caption"
                sx={{
                  color: darkMode ? 'grey.500' : 'grey.500',
                  fontSize: '0.7rem',
                }}
              >
                {card.getSubtext(summary)}
              </Typography>
            </>
          )}
        </Paper>
      ))}
    </Box>
  );
};

export default SummaryCards;
