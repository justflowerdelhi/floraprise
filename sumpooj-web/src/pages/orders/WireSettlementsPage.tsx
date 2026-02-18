import React from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  useTheme,
  alpha,
} from '@mui/material';
import { MOCK_WIRE_SETTLEMENTS } from './WireMockData';
import { fmtCurrency } from '../cart/CartUtils';
import type { SettlementStatus } from './OrderTypes';

const STATUS_COLOR: Record<SettlementStatus, 'default' | 'warning' | 'success' | 'info'> = {
  PENDING: 'warning',
  SENT: 'info',
  CLEARED: 'success',
};

const WireSettlementsPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bg = dk ? '#0f0f0f' : '#f8f9fa';

  const headerSx = {
    fontWeight: 700,
    fontSize: '0.7rem',
    textTransform: 'uppercase' as const,
    letterSpacing: 0.5,
    whiteSpace: 'nowrap' as const,
    color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
    bgcolor: dk ? '#1a1a2e' : '#f5f5f5',
    borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.08)' : '#ddd'}`,
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      <Typography variant="h4" sx={{ fontWeight: 800, mb: 0.5 }}>
        Wire Settlements
      </Typography>
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}>
        Track outgoing wire payments to vendor florists
      </Typography>

      <TableContainer
        component={Paper}
        elevation={dk ? 0 : 1}
        sx={{
          bgcolor: dk ? '#0f0f0f' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          borderRadius: 2,
        }}
      >
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell sx={headerSx}>Order #</TableCell>
              <TableCell sx={headerSx}>Vendor</TableCell>
              <TableCell sx={headerSx} align="right">Amount</TableCell>
              <TableCell sx={headerSx} align="right">Settlement Status</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {MOCK_WIRE_SETTLEMENTS.map((row) => (
              <TableRow
                key={row.orderNumber}
                hover
                sx={{ '&:hover': { bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02) } }}
              >
                <TableCell>
                  <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: 'monospace', fontSize: '0.82rem' }}>
                    {row.orderNumber}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>{row.vendorName}</Typography>
                </TableCell>
                <TableCell align="right">
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(row.amount)}</Typography>
                </TableCell>
                <TableCell align="right">
                  <Chip
                    label={row.status}
                    size="small"
                    color={STATUS_COLOR[row.status]}
                    variant={dk ? 'outlined' : 'filled'}
                    sx={{ fontWeight: 700 }}
                  />
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>
    </Box>
  );
};

export default WireSettlementsPage;