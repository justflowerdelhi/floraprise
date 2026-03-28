/**
 * MaintenanceModal.tsx — Finished Goods Repair Workflow
 *
 * Features:
 * - Replace spoiled/wilted components in active finished batches
 * - Select replacement material and quantity
 * - Choose wastage reason
 * - Logs wastage + repair entries
 * - Does NOT change finished goods quantity
 */

import { useState, useEffect, useMemo } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Box, Typography, Button, TextField, Table, TableHead,
  TableBody, TableRow, TableCell, IconButton, FormControl,
  Select, MenuItem, Alert, Chip, useTheme, alpha,
  CircularProgress,
} from '@mui/material';
import {
  Add as AddIcon,
  Delete as DeleteIcon,
  Build as RepairIcon,
  Warning as WarningIcon,
} from '@mui/icons-material';
import type {
  FinishedGoodsBatch,
  MaintenanceReplacement,
  InventoryProduct,
  WastageReason,
} from './types/ProductionTypes';
import { WASTAGE_REASONS } from './types/ProductionTypes';
import { getInventoryProducts, performMaintenance } from './api/production.api';
// import { formatCurrency } from './utils/production.utils';

interface MaintenanceModalProps {
  open: boolean;
  batch: FinishedGoodsBatch;
  onClose: () => void;
  onComplete: () => void;
}

interface ReplacementRow extends MaintenanceReplacement {
  _key: string;
}

const MaintenanceModal = ({ open, batch, onClose, onComplete }: MaintenanceModalProps) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // ── State ──────────────────────────────────────────────────
  const [inventoryProducts, setInventoryProducts] = useState<InventoryProduct[]>([]);
  const [replacements, setReplacements] = useState<ReplacementRow[]>([]);
  const [notes, setNotes] = useState('');
  const [_loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const replacementAvailability = useMemo(
    () =>
      replacements.map((row) => {
        const product = inventoryProducts.find((item) => item.id === row.productId);
        const available = product?.quantityAvailable ?? 0;
        return {
          key: row._key,
          available,
          insufficient: Boolean(row.productId) && row.quantityReplaced > available,
        };
      }),
    [inventoryProducts, replacements],
  );

  const hasInsufficientStock = replacementAvailability.some((row) => row.insufficient);

  // ── Load inventory for the batch's location ────────────────
  useEffect(() => {
    if (!open) return;
    const load = async () => {
      setLoading(true);
      try {
        const products = await getInventoryProducts(batch.locationId);
        setInventoryProducts(products);
      } catch {
        setError('Failed to load inventory');
      } finally {
        setLoading(false);
      }
    };
    load();
    // Reset form on open
    setReplacements([]);
    setNotes('');
    setError('');
    setSuccess(false);
  }, [open, batch.locationId]);

  // ── Replacement management ─────────────────────────────────
  const addReplacement = () => {
    setReplacements((prev) => [
      ...prev,
      {
        _key: `rep-${Date.now()}`,
        productId: '',
        productName: '',
        quantityReplaced: 1,
        reason: 'WILTED',
      },
    ]);
  };

  const updateReplacement = (key: string, field: keyof ReplacementRow, value: string | number) => {
    setReplacements((prev) =>
      prev.map((r) => {
        if (r._key !== key) return r;
        if (field === 'productId') {
          const product = inventoryProducts.find((p) => p.id === value);
          return { ...r, productId: value as string, productName: product?.name ?? '' };
        }
        return { ...r, [field]: value };
      }),
    );
  };

  const removeReplacement = (key: string) => {
    setReplacements((prev) => prev.filter((r) => r._key !== key));
  };

  // ── Validation ─────────────────────────────────────────────
  const isValid = useMemo(() => {
    if (replacements.length === 0) return false;
    return replacements.every((r) => r.productId && r.quantityReplaced > 0 && r.reason) && !hasInsufficientStock;
  }, [hasInsufficientStock, replacements]);

  // ── Cannot maintain if qty = 0 ────────────────────────────
  const canMaintain = batch.quantityAvailable > 0 && batch.status === 'ACTIVE';

  // ── Submit ─────────────────────────────────────────────────
  const handleSubmit = async () => {
    if (!isValid || !canMaintain) return;
    setSubmitting(true);
    setError('');

    try {
      await performMaintenance({
        finishedBatchId: batch.id,
        replacements: replacements.map(({ _key, ...rest }) => rest),
        notes: notes || undefined,
      });
      setSuccess(true);
      setTimeout(() => onComplete(), 1500);
    } catch {
      setError('Maintenance failed. Please try again.');
    } finally {
      setSubmitting(false);
    }
  };

  // ── Wastage reason colors ─────────────────────────────────
  const reasonColor = (reason: WastageReason): string => {
    switch (reason) {
      case 'SPOILED': return '#f44336';
      case 'WILTED': return '#ff9800';
      case 'DAMAGED': return '#9c27b0';
      default: return '#757575';
    }
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <RepairIcon sx={{ color: '#ff9800' }} />
        Repair Ready Product
        <Chip
          label={batch.batchCode}
          size="small"
          variant="outlined"
          sx={{ ml: 'auto', fontFamily: 'monospace' }}
        />
      </DialogTitle>

      <DialogContent dividers>
        {!canMaintain && (
          <Alert severity="error" sx={{ mb: 2, borderRadius: 1.5 }}>
            Cannot perform maintenance: batch has zero available quantity or is not active.
          </Alert>
        )}

        {success ? (
          <Box sx={{ py: 4, textAlign: 'center' }}>
            <RepairIcon sx={{ fontSize: 48, color: '#4caf50', mb: 1 }} />
            <Typography variant="h6" fontWeight={700} color="success.main">Repair Complete!</Typography>
            <Typography color="text.secondary">
              Replacement components were deducted from inventory and damaged/spoiled items were logged as wastage.
            </Typography>
          </Box>
        ) : (
          <>
            {/* Batch Info */}
            <Box sx={{ display: 'flex', gap: 3, mb: 3, flexWrap: 'wrap' }}>
              <Box>
                <Typography variant="caption" color="text.secondary">Recipe</Typography>
                <Typography fontWeight={600}>{batch.recipeName}</Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">Location</Typography>
                <Typography>{batch.locationName}</Typography>
              </Box>
              <Box>
                <Typography variant="caption" color="text.secondary">Available</Typography>
                <Typography fontWeight={700} color="primary">{batch.quantityAvailable}</Typography>
              </Box>
            </Box>

            {error && <Alert severity="error" sx={{ mb: 2, borderRadius: 1.5 }}>{error}</Alert>}

            {/* Replacements */}
            <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
              <Typography variant="subtitle2" fontWeight={700}>
                <WarningIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'text-bottom', color: '#ff9800' }} />
                Components to Repair
              </Typography>
              <Button
                size="small"
                startIcon={<AddIcon />}
                onClick={addReplacement}
                disabled={!canMaintain}
                sx={{ textTransform: 'none' }}
              >
                Add
              </Button>
            </Box>

            {replacements.length === 0 ? (
              <Box
                sx={{
                  p: 3, textAlign: 'center', borderRadius: 2,
                  border: `2px dashed ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`,
                  bgcolor: dk ? 'rgba(255,255,255,0.02)' : 'rgba(0,0,0,0.02)',
                }}
              >
                <Typography color="text.secondary" variant="body2">
                  Add damaged or spoiled components that must be replaced from available inventory
                </Typography>
              </Box>
            ) : (
              <Table size="small" sx={{ mb: 2 }}>
                <TableHead>
                  <TableRow sx={{ '& th': { fontWeight: 700, fontSize: '0.8rem' } }}>
                    <TableCell>Replacement Material</TableCell>
                    <TableCell sx={{ width: 80 }}>Qty</TableCell>
                    <TableCell sx={{ width: 140 }}>Reason</TableCell>
                    <TableCell sx={{ width: 50 }} />
                  </TableRow>
                </TableHead>
                <TableBody>
                  {replacements.map((rep) => (
                    <TableRow key={rep._key}>
                      <TableCell>
                        <FormControl fullWidth size="small">
                          <Select
                            value={rep.productId}
                            onChange={(e) => updateReplacement(rep._key, 'productId', e.target.value)}
                            displayEmpty
                          >
                            <MenuItem value="" disabled>Select material...</MenuItem>
                            {inventoryProducts.map((p) => (
                              <MenuItem key={p.id} value={p.id}>
                                {p.name} ({p.quantityAvailable} avail.)
                              </MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      </TableCell>
                      <TableCell>
                        <TextField
                          type="number"
                          size="small"
                          value={rep.quantityReplaced}
                          onChange={(e) => updateReplacement(rep._key, 'quantityReplaced', Number(e.target.value))}
                          inputProps={{ min: 1 }}
                          sx={{ width: 70 }}
                          error={replacementAvailability.find((item) => item.key === rep._key)?.insufficient ?? false}
                        />
                      </TableCell>
                      <TableCell>
                        <FormControl fullWidth size="small">
                          <Select
                            value={rep.reason}
                            onChange={(e) => updateReplacement(rep._key, 'reason', e.target.value)}
                          >
                            {WASTAGE_REASONS.map((r) => (
                              <MenuItem key={r} value={r}>
                                <Chip
                                  label={r}
                                  size="small"
                                  sx={{ bgcolor: alpha(reasonColor(r), 0.12), color: reasonColor(r), fontWeight: 600, fontSize: '0.75rem' }}
                                />
                              </MenuItem>
                            ))}
                          </Select>
                        </FormControl>
                      </TableCell>
                      <TableCell>
                        <IconButton size="small" color="error" onClick={() => removeReplacement(rep._key)}>
                          <DeleteIcon fontSize="small" />
                        </IconButton>
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}

            {hasInsufficientStock && (
              <Alert severity="error" sx={{ mb: 2, borderRadius: 1.5 }}>
                One or more repair rows exceed available inventory. Reduce the quantity or choose another component.
              </Alert>
            )}

            {/* Notes */}
            <TextField
              label="Notes (optional)"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              fullWidth
              multiline
              rows={2}
              placeholder="e.g. Replaced wilted roses from overnight storage"
              sx={{ mt: 1 }}
            />

            <Alert severity="info" sx={{ mt: 2, borderRadius: 1.5 }} icon={<RepairIcon />}>
              <strong>What happens:</strong> Repair quantities are deducted from raw inventory and a wastage entry is created for the damaged component against this finished batch. Finished goods quantity remains unchanged.
            </Alert>
          </>
        )}
      </DialogContent>

      <DialogActions>
        <Button onClick={onClose}>
          {success ? 'Close' : 'Cancel'}
        </Button>
        {!success && (
          <Button
            variant="contained"
            onClick={handleSubmit}
            disabled={!isValid || !canMaintain || submitting}
            startIcon={submitting ? <CircularProgress size={18} color="inherit" /> : <RepairIcon />}
            sx={{ bgcolor: '#ff9800', '&:hover': { bgcolor: '#f57c00' } }}
          >
            {submitting ? 'Processing...' : 'Perform Repair'}
          </Button>
        )}
      </DialogActions>
    </Dialog>
  );
};

export default MaintenanceModal;
