/**
 * Wastage Summary Panel — Right-side summary
 * Today's adjustments, month wastage, top wasted product, shrinkage %
 */

import {
  Box,
  Paper,
  Typography,
  Divider,
  Skeleton,
  LinearProgress,
  useTheme,
  alpha,
} from '@mui/material';
import TodayIcon from '@mui/icons-material/Today';
import CalendarMonthIcon from '@mui/icons-material/CalendarMonth';
import TrendingDownIcon from '@mui/icons-material/TrendingDown';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import type { WastageSummary } from '../data/adjustment.data';
import { fmt } from '../utils/adjustment.utils';

interface SummaryPanelProps {
  summary: WastageSummary | null;
  loading: boolean;
  darkMode: boolean;
}

interface StatItemDef {
  icon: React.ReactNode;
  label: string;
  getValue: (s: WastageSummary) => string;
  getSubtext: (s: WastageSummary) => string;
  accent: string;
}

const WastageSummaryPanel = ({ summary, loading, darkMode }: SummaryPanelProps) => {
  const theme = useTheme();

  const stats: StatItemDef[] = [
    {
      icon: <TodayIcon sx={{ fontSize: 20 }} />,
      label: "Today's Adjustments",
      getValue: (s) => fmt(s.todayTotalValue),
      getSubtext: (s) => `${s.todayCount} adjustment${s.todayCount !== 1 ? 's' : ''} today`,
      accent: '#e65100',
    },
    {
      icon: <CalendarMonthIcon sx={{ fontSize: 20 }} />,
      label: 'This Month Wastage',
      getValue: (s) => fmt(s.monthTotalValue),
      getSubtext: (s) => `${s.monthCount} adjustment${s.monthCount !== 1 ? 's' : ''} this month`,
      accent: '#c62828',
    },
    {
      icon: <LocalFloristIcon sx={{ fontSize: 20 }} />,
      label: 'Top Wasted Product',
      getValue: (s) => s.topWastedProduct,
      getSubtext: (s) => `${fmt(s.topWastedValue)} total waste`,
      accent: '#d81b60',
    },
    {
      icon: <TrendingDownIcon sx={{ fontSize: 20 }} />,
      label: 'Total Shrinkage',
      getValue: (s) => `${s.totalShrinkagePercent.toFixed(2)}%`,
      getSubtext: () => 'Of total inventory value',
      accent: '#6a1b9a',
    },
  ];

  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];

  return (
    <Paper
      elevation={0}
      sx={{
        p: 3,
        borderRadius: 2,
        border: `1px solid ${borderColor}`,
        backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
      }}
    >
      <Typography
        variant="subtitle2"
        sx={{
          fontWeight: 700,
          color: darkMode ? 'grey.400' : 'grey.700',
          textTransform: 'uppercase',
          letterSpacing: 0.5,
          fontSize: '0.7rem',
          mb: 2.5,
        }}
      >
        Wastage Overview
      </Typography>

      <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        {stats.map((stat, idx) => (
          <Box key={idx}>
            <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 1.5 }}>
              {/* Icon */}
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  width: 36,
                  height: 36,
                  borderRadius: 1.5,
                  flexShrink: 0,
                  backgroundColor: alpha(stat.accent, darkMode ? 0.15 : 0.1),
                  color: stat.accent,
                }}
              >
                {stat.icon}
              </Box>

              {/* Content */}
              <Box sx={{ flex: 1, minWidth: 0 }}>
                <Typography
                  variant="caption"
                  sx={{
                    color: darkMode ? 'grey.500' : 'grey.600',
                    fontWeight: 600,
                    fontSize: '0.65rem',
                    textTransform: 'uppercase',
                    letterSpacing: 0.5,
                  }}
                >
                  {stat.label}
                </Typography>

                {loading || !summary ? (
                  <>
                    <Skeleton variant="text" width="70%" height={24} />
                    <Skeleton variant="text" width="90%" height={14} />
                  </>
                ) : (
                  <>
                    <Typography
                      variant="body1"
                      sx={{
                        fontWeight: 700,
                        color: darkMode ? 'grey.100' : 'grey.900',
                        lineHeight: 1.2,
                        fontSize: '0.95rem',
                        mt: 0.25,
                      }}
                    >
                      {stat.getValue(summary)}
                    </Typography>
                    <Typography
                      variant="caption"
                      sx={{ color: darkMode ? 'grey.500' : 'grey.500', fontSize: '0.7rem' }}
                    >
                      {stat.getSubtext(summary)}
                    </Typography>
                  </>
                )}
              </Box>
            </Box>

            {idx < stats.length - 1 && (
              <Divider sx={{ mt: 2, borderColor: darkMode ? 'grey.800' : 'grey.200' }} />
            )}
          </Box>
        ))}
      </Box>

      {/* Shrinkage progress bar */}
      {summary && (
        <Box sx={{ mt: 3 }}>
          <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
            <Typography
              variant="caption"
              sx={{ color: darkMode ? 'grey.500' : 'grey.600', fontWeight: 600, fontSize: '0.65rem' }}
            >
              Shrinkage Rate
            </Typography>
            <Typography
              variant="caption"
              sx={{
                fontWeight: 700,
                color:
                  summary.totalShrinkagePercent > 5
                    ? '#c62828'
                    : summary.totalShrinkagePercent > 2
                      ? '#e65100'
                      : '#2e7d32',
                fontSize: '0.7rem',
              }}
            >
              {summary.totalShrinkagePercent.toFixed(2)}%
            </Typography>
          </Box>
          <LinearProgress
            variant="determinate"
            value={Math.min(summary.totalShrinkagePercent, 10) * 10} // scale 0-10% → 0-100
            sx={{
              height: 6,
              borderRadius: 3,
              backgroundColor: darkMode ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.06)',
              '& .MuiLinearProgress-bar': {
                borderRadius: 3,
                backgroundColor:
                  summary.totalShrinkagePercent > 5
                    ? '#c62828'
                    : summary.totalShrinkagePercent > 2
                      ? '#e65100'
                      : '#2e7d32',
              },
            }}
          />
          <Typography
            variant="caption"
            sx={{ color: darkMode ? 'grey.600' : 'grey.400', fontSize: '0.6rem', mt: 0.5, display: 'block' }}
          >
            Industry benchmark: &lt; 2%
          </Typography>
        </Box>
      )}
    </Paper>
  );
};

export default WastageSummaryPanel;
