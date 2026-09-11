/**
 * RetailStockHistoryModal.tsx — Floraprise ERP Retail View Stock History Audit Drawer/Modal
 *
 * Provides retail florists with an immediate, clear audit trail:
 * - Direct lookup via GET /api/inventory/products/{productId}/history
 * - Displays date, operation (+In, -Out, Wastage, Adjustment), quantity change, balance transition
 * - Displays reasons, notes, supplier, and transaction source
 */

import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Box,
  Typography,
  Button,
  Chip,
  CircularProgress,
  Alert,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Tooltip,
  useTheme,
  alpha,
  Divider,
} from '@mui/material';
import {
  Close as CloseIcon,
  Refresh as RefreshIcon,
  AddCircleOutline as InIcon,
  RemoveCircleOutline as OutIcon,
  DeleteOutline as WastageIcon,
  Tune as AdjustIcon,
} from '@mui/icons-material';
import {
  getProductInventoryHistory,
  type InventoryHistoryDto,
} from '../../../api/inventory.api';
import type { RetailStockItem } from './RetailStockCard';

interface RetailStockHistoryModalProps {
  open: boolean;
  item: RetailStockItem | null;
  currencySymbol: string;
  onClose: () => void;
}

export const RetailStockHistoryModal: React.FC<RetailStockHistoryModalProps> = ({
  open,
  item,
  currencySymbol,
  onClose,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [history, setHistory] = useState<InventoryHistoryDto[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchHistory = async () => {
    if (!item) return;
    setLoading(true);
    setError(null);
    try {
      const data = await getProductInventoryHistory(item.id);
      const list = Array.isArray(data) ? data : [];
      // Sort newest first
      list.sort((a, b) => new Date(b.createdAtUtc).getTime() - new Date(a.createdAtUtc).getTime());
      setHistory(list);
    } catch (err: any) {
      console.error('Failed to load inventory history:', err);
      setError(err?.message || 'Failed to retrieve stock movement history.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (open && item) {
      fetchHistory();
    } else {
      setHistory([]);
    }
  }, [open, item]);

  if (!item) return null;

  const getOpBadge = (op: string) => {
    const norm = op?.toLowerCase() || '';
    if (norm === 'purchase') {
      return (
        <Chip
          icon={<InIcon sx={{ fontSize: '14px !important' }} />}
          label="Stock In"
          size="small"
          color="success"
          sx={{ fontWeight: 700, fontSize: '0.72rem', borderRadius: 1.5 }}
        />
      );
    }
    if (norm === 'sale') {
      return (
        <Chip
          icon={<OutIcon sx={{ fontSize: '14px !important' }} />}
          label="Stock Out"
          size="small"
          color="info"
          sx={{ fontWeight: 700, fontSize: '0.72rem', borderRadius: 1.5 }}
        />
      );
    }
    if (norm === 'wastage' || norm === 'damaged') {
      return (
        <Chip
          icon={<WastageIcon sx={{ fontSize: '14px !important' }} />}
          label="Wastage"
          size="small"
          color="error"
          sx={{ fontWeight: 700, fontSize: '0.72rem', borderRadius: 1.5 }}
        />
      );
    }
    return (
      <Chip
        icon={<AdjustIcon sx={{ fontSize: '14px !important' }} />}
        label="Adjustment"
        size="small"
        color="secondary"
        sx={{ fontWeight: 700, fontSize: '0.72rem', borderRadius: 1.5 }}
      />
    );
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="md"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 3.5,
          p: 1,
          bgcolor: dk ? '#1E1E1E' : '#FFFFFF',
          minHeight: 480,
        },
      }}
    >
      <DialogTitle sx={{ pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box>
            <Typography variant="h6" fontWeight={800}>
              Stock Movement History
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {item.name} &bull; <span style={{ fontFamily: 'monospace' }}>SKU: {item.sku}</span> &bull; Current:{' '}
              <strong>
                {item.stockQuantity} {item.unitOfMeasure}
              </strong>
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
            <Tooltip title="Refresh History">
              <IconButton size="small" onClick={fetchHistory} disabled={loading}>
                <RefreshIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <IconButton size="small" onClick={onClose}>
              <CloseIcon fontSize="small" />
            </IconButton>
          </Box>
        </Box>
      </DialogTitle>

      <DialogContent sx={{ pt: 1 }}>
        {error && (
          <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>
            {error}
          </Alert>
        )}

        {loading ? (
          <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 8, gap: 2 }}>
            <CircularProgress size={36} />
            <Typography variant="body2" color="text.secondary">
              Retrieving ledger audit entries...
            </Typography>
          </Box>
        ) : history.length === 0 ? (
          <Box sx={{ textAlign: 'center', py: 8 }}>
            <Typography variant="body1" fontWeight={600} color="text.secondary">
              No stock movements recorded yet.
            </Typography>
            <Typography variant="caption" color="text.disabled">
              Stock In, Stock Out, Wastage, and Adjustments will appear here automatically.
            </Typography>
          </Box>
        ) : (
          <TableContainer
            component={Paper}
            elevation={0}
            sx={{
              border: '1px solid',
              borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
              borderRadius: 2.5,
              maxHeight: 440,
            }}
          >
            <Table size="small" stickyHeader>
              <TableHead>
                <TableRow>
                  <TableCell sx={{ fontWeight: 700, bgcolor: dk ? '#252525' : '#F8FAFC' }}>
                    Date & Time
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, bgcolor: dk ? '#252525' : '#F8FAFC' }}>
                    Operation
                  </TableCell>
                  <TableCell
                    align="right"
                    sx={{ fontWeight: 700, bgcolor: dk ? '#252525' : '#F8FAFC' }}
                  >
                    Quantity Change
                  </TableCell>
                  <TableCell
                    align="right"
                    sx={{ fontWeight: 700, bgcolor: dk ? '#252525' : '#F8FAFC' }}
                  >
                    Balance
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, bgcolor: dk ? '#252525' : '#F8FAFC' }}>
                    Reason / Notes
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, bgcolor: dk ? '#252525' : '#F8FAFC' }}>
                    Supplier / Source
                  </TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {history.map((row) => {
                  const isPositive =
                    row.operation?.toLowerCase() === 'purchase' ||
                    (row.operation?.toLowerCase() === 'adjustment' &&
                      row.balanceAfter >= row.previousBalance);

                  return (
                    <TableRow
                      key={row.id}
                      hover
                      sx={{
                        '&:last-child td, &:last-child th': { border: 0 },
                      }}
                    >
                      <TableCell sx={{ whiteSpace: 'nowrap', fontSize: '0.82rem' }}>
                        {new Date(row.createdAtUtc).toLocaleString(undefined, {
                          month: 'short',
                          day: 'numeric',
                          year: 'numeric',
                          hour: '2-digit',
                          minute: '2-digit',
                        })}
                      </TableCell>
                      <TableCell>{getOpBadge(row.operation)}</TableCell>
                      <TableCell align="right">
                        <Typography
                          variant="body2"
                          fontWeight={700}
                          sx={{
                            color: isPositive
                              ? theme.palette.success.main
                              : theme.palette.error.main,
                          }}
                        >
                          {isPositive ? `+${row.quantity}` : `-${row.quantity}`} {item.unitOfMeasure}
                        </Typography>
                      </TableCell>
                      <TableCell align="right" sx={{ whiteSpace: 'nowrap', fontSize: '0.82rem' }}>
                        <Typography variant="caption" color="text.secondary">
                          {row.previousBalance} &rarr;{' '}
                        </Typography>
                        <strong>{row.balanceAfter}</strong>
                      </TableCell>
                      <TableCell sx={{ maxWidth: 220 }}>
                        <Typography variant="body2" fontWeight={600} noWrap>
                          {row.reason || '—'}
                        </Typography>
                        {row.notes && (
                          <Typography variant="caption" color="text.secondary" display="block" noWrap>
                            {row.notes}
                          </Typography>
                        )}
                      </TableCell>
                      <TableCell sx={{ fontSize: '0.82rem', color: 'text.secondary' }}>
                        {row.supplier ? (
                          <span>
                            <strong>{row.supplier}</strong>
                          </span>
                        ) : (
                          row.source || 'Cloud Inventory'
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} variant="outlined" sx={{ fontWeight: 600, borderRadius: 2 }}>
          Close
        </Button>
      </DialogActions>
    </Dialog>
  );
};
