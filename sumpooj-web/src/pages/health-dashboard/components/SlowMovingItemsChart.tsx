/**
 * SlowMovingItemsChart — Table-style card listing slow-moving inventory
 * with horizontal bars for days-of-stock indication
 */
import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Box,
  Chip,
  useTheme,
  alpha,
  LinearProgress,
} from '@mui/material';
import type { SlowMovingItem } from '../data/health.data';
import { fmtCurrency, fmtDate } from '../utils/health.utils';

interface Props {
  data: SlowMovingItem[];
}

const SlowMovingItemsChart: React.FC<Props> = ({ data }) => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';
  const maxDays = Math.max(...data.map((d) => d.daysOfStock));

  const severityColor = (days: number): 'error' | 'warning' | 'info' => {
    if (days > 100) return 'error';
    if (days > 70)  return 'warning';
    return 'info';
  };

  return (
    <Card
      elevation={darkMode ? 0 : 1}
      sx={{
        bgcolor: darkMode ? '#1a1a2e' : '#fff',
        border: darkMode ? '1px solid rgba(255,255,255,0.08)' : 'none',
        height: '100%',
      }}
    >
      <CardContent sx={{ p: 0, '&:last-child': { pb: 0 } }}>
        <Typography variant="subtitle1" sx={{ fontWeight: 700, px: 2, pt: 2, pb: 1 }}>
          Slow Moving Items
        </Typography>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                {['Product', 'Category', 'Stock', 'Days of Stock', 'Value', 'Last Sold'].map(
                  (h) => (
                    <TableCell
                      key={h}
                      sx={{
                        fontWeight: 700,
                        fontSize: '0.7rem',
                        textTransform: 'uppercase',
                        letterSpacing: 0.5,
                        color: darkMode ? 'rgba(255,255,255,0.5)' : 'text.secondary',
                        bgcolor: darkMode ? '#111122' : '#fafafa',
                        borderBottom: `2px solid ${darkMode ? 'rgba(255,255,255,0.08)' : '#eee'}`,
                        whiteSpace: 'nowrap',
                        py: 1,
                      }}
                    >
                      {h}
                    </TableCell>
                  ),
                )}
              </TableRow>
            </TableHead>
            <TableBody>
              {data.map((item) => (
                <TableRow
                  key={item.productName}
                  hover
                  sx={{
                    '&:hover': {
                      bgcolor: darkMode
                        ? alpha('#fff', 0.03)
                        : alpha('#000', 0.02),
                    },
                  }}
                >
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.82rem' }}>
                      {item.productName}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>
                      {item.category}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>
                      {item.currentStock}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, minWidth: 140 }}>
                      <Chip
                        label={`${item.daysOfStock}d`}
                        size="small"
                        color={severityColor(item.daysOfStock)}
                        variant={darkMode ? 'outlined' : 'filled'}
                        sx={{ fontWeight: 700, fontSize: '0.72rem', minWidth: 48 }}
                      />
                      <LinearProgress
                        variant="determinate"
                        value={Math.min(100, (item.daysOfStock / maxDays) * 100)}
                        color={severityColor(item.daysOfStock)}
                        sx={{
                          flex: 1,
                          height: 6,
                          borderRadius: 3,
                          bgcolor: darkMode ? 'rgba(255,255,255,0.05)' : '#f0f0f0',
                        }}
                      />
                    </Box>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontSize: '0.82rem', fontWeight: 600 }}>
                      {fmtCurrency(item.totalValue)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography
                      variant="body2"
                      sx={{ fontSize: '0.82rem', color: darkMode ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
                    >
                      {fmtDate(item.lastSoldDate)}
                    </Typography>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </CardContent>
    </Card>
  );
};

export default SlowMovingItemsChart;
