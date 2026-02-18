/**
 * Ledger Summary Panel — Opening / Closing Balance, Total In / Out
 */

import {
  Box,
  Paper,
  Typography,
  Skeleton,
  Divider,
  alpha,
  useTheme,
} from '@mui/material';
import ArrowUpwardIcon from '@mui/icons-material/ArrowUpward';
import ArrowDownwardIcon from '@mui/icons-material/ArrowDownward';
import InventoryIcon from '@mui/icons-material/Inventory';
import AccountBalanceIcon from '@mui/icons-material/AccountBalance';

import type { LedgerSummary } from '../data/ledger.data';
import { fmt } from '../utils/ledger.utils';

interface Props {
  summary: LedgerSummary | null;
  loading: boolean;
  darkMode: boolean;
}

interface CardDef {
  label: string;
  getValue: (s: LedgerSummary) => string;
  getSubtext: (s: LedgerSummary) => string;
  color: string;
  icon: React.ReactNode;
}

const cards: CardDef[] = [
  {
    label: 'Opening Balance',
    getValue: (s) => `${s.openingBalance} units`,
    getSubtext: () => 'Start of filtered period',
    color: '#616161',
    icon: <InventoryIcon sx={{ fontSize: 20 }} />,
  },
  {
    label: 'Total In',
    getValue: (s) => `+${s.totalIn} units`,
    getSubtext: (s) => `Cost: ${fmt(s.totalCostIn)}`,
    color: '#2e7d32',
    icon: <ArrowUpwardIcon sx={{ fontSize: 20 }} />,
  },
  {
    label: 'Total Out',
    getValue: (s) => `−${s.totalOut} units`,
    getSubtext: (s) => `Cost: ${fmt(s.totalCostOut)}`,
    color: '#c62828',
    icon: <ArrowDownwardIcon sx={{ fontSize: 20 }} />,
  },
  {
    label: 'Closing Balance',
    getValue: (s) => `${s.closingBalance} units`,
    getSubtext: (s) => `Net change: ${s.totalIn - s.totalOut >= 0 ? '+' : ''}${s.totalIn - s.totalOut}`,
    color: '#1565c0',
    icon: <AccountBalanceIcon sx={{ fontSize: 20 }} />,
  },
];

const LedgerSummaryPanel = ({ summary, loading, darkMode }: Props) => {
  const theme = useTheme();
  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];

  return (
    <Paper
      elevation={0}
      sx={{
        p: 2.5,
        borderRadius: 2,
        border: `1px solid ${borderColor}`,
        backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
      }}
    >
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: '1fr 1fr', md: '1fr auto 1fr auto 1fr auto 1fr' },
          gap: { xs: 2, md: 0 },
          alignItems: 'center',
        }}
      >
        {cards.map((card, i) => (
          <Box key={card.label} sx={{ display: 'contents' }}>
            {/* Divider between cards (md+) */}
            {i > 0 && (
              <Divider
                orientation="vertical"
                flexItem
                sx={{
                  display: { xs: 'none', md: 'block' },
                  mx: 2,
                  borderColor: darkMode ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
                }}
              />
            )}
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, px: 1 }}>
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
              <Box>
                <Typography
                  variant="caption"
                  sx={{
                    color: darkMode ? 'grey.500' : 'grey.500',
                    fontSize: '0.68rem',
                    fontWeight: 600,
                    textTransform: 'uppercase',
                    letterSpacing: 0.5,
                  }}
                >
                  {card.label}
                </Typography>
                {loading || !summary ? (
                  <Skeleton variant="text" width={80} height={28} />
                ) : (
                  <>
                    <Typography
                      variant="h6"
                      sx={{
                        fontWeight: 800,
                        fontSize: '1.05rem',
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
          </Box>
        ))}
      </Box>
    </Paper>
  );
};

export default LedgerSummaryPanel;
