/**
 * Expiry Summary Cards — 5 KPI cards
 * Expiring Today, 3 Days, 7 Days, Expired Value, Total Value at Risk
 */

import {
  Box,
  Paper,
  Typography,
  Skeleton,
  useTheme,
  alpha,
} from '@mui/material';
import TodayIcon from '@mui/icons-material/Today';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import DateRangeIcon from '@mui/icons-material/DateRange';
import ReportProblemIcon from '@mui/icons-material/ReportProblem';
import MonetizationOnIcon from '@mui/icons-material/MonetizationOn';
import type { ExpirySummary } from '../data/expiry.data';
import { fmt } from '../utils/expiry.utils';

interface Props {
  summary: ExpirySummary | null;
  loading: boolean;
  darkMode: boolean;
}

interface CardDef {
  title: string;
  getValue: (s: ExpirySummary) => string;
  getSubtext: (s: ExpirySummary) => string;
  icon: React.ReactNode;
  accent: string;
}

const ExpirySummaryCards = ({ summary, loading, darkMode }: Props) => {
  const theme = useTheme();

  const cards: CardDef[] = [
    {
      title: 'Expiring Today',
      getValue: (s) => `${s.expiringToday} batch${s.expiringToday !== 1 ? 'es' : ''}`,
      getSubtext: (s) => s.expiringToday > 0 ? fmt(s.expiringTodayValue) : 'None today',
      icon: <TodayIcon sx={{ fontSize: 22 }} />,
      accent: '#c62828',
    },
    {
      title: 'Expiring in 3 Days',
      getValue: (s) => `${s.expiringIn3Days} batch${s.expiringIn3Days !== 1 ? 'es' : ''}`,
      getSubtext: (s) => s.expiringIn3Days > 0 ? `${fmt(s.expiringIn3DaysValue)} at risk` : 'All clear',
      icon: <WarningAmberIcon sx={{ fontSize: 22 }} />,
      accent: '#e65100',
    },
    {
      title: 'Expiring in 7 Days',
      getValue: (s) => `${s.expiringIn7Days} batch${s.expiringIn7Days !== 1 ? 'es' : ''}`,
      getSubtext: (s) => s.expiringIn7Days > 0 ? `${fmt(s.expiringIn7DaysValue)} at risk` : 'All clear',
      icon: <DateRangeIcon sx={{ fontSize: 22 }} />,
      accent: '#ef6c00',
    },
    {
      title: 'Expired Inventory',
      getValue: (s) => `${s.expiredCount} batch${s.expiredCount !== 1 ? 'es' : ''}`,
      getSubtext: (s) => s.expiredCount > 0 ? `${fmt(s.expiredValue)} loss` : 'No expired stock',
      icon: <ReportProblemIcon sx={{ fontSize: 22 }} />,
      accent: '#616161',
    },
    {
      title: 'Total Value at Risk',
      getValue: (s) => fmt(s.totalValueAtRisk),
      getSubtext: () => `Expired + expiring within 7 days`,
      icon: <MonetizationOnIcon sx={{ fontSize: 22 }} />,
      accent: '#d81b60',
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
          lg: 'repeat(5, 1fr)',
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

          {loading || !summary ? (
            <>
              <Skeleton variant="text" width="75%" height={28} />
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
                  fontSize: '1.05rem',
                }}
              >
                {card.getValue(summary)}
              </Typography>
              <Typography
                variant="caption"
                sx={{ color: darkMode ? 'grey.500' : 'grey.500', fontSize: '0.7rem' }}
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

export default ExpirySummaryCards;
