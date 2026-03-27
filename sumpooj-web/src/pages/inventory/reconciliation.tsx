import { useEffect, useState } from 'react';
import {
  Checkbox,
  Box,
  Button,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControlLabel,
  Paper,
  TextField,
  Switch,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
  Alert,
} from '@mui/material';
import {
  applyInventoryReconciliationFix,
  getInventoryReconciliation,
  type ReconciliationApplyResult,
  type InventoryReconciliationRow,
} from '../../api/inventory.api';

export default function InventoryReconciliationPage() {
  const [mismatchesOnly, setMismatchesOnly] = useState(true);
  const [rows, setRows] = useState<InventoryReconciliationRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [applying, setApplying] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [selectedRow, setSelectedRow] = useState<InventoryReconciliationRow | null>(null);
  const [reason, setReason] = useState('Stock reconciliation correction');
  const [notes, setNotes] = useState('');
  const [confirmChecked, setConfirmChecked] = useState(false);

  const load = async (only: boolean) => {
    setLoading(true);
    setError(null);
    setSuccess(null);
    try {
      const data = await getInventoryReconciliation(only);
      setRows(data);
    } catch (err: any) {
      setRows([]);
      setError(err?.response?.data?.message ?? err?.message ?? 'Failed to load reconciliation report.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void load(mismatchesOnly);
  }, [mismatchesOnly]);

  const openApplyDialog = (row: InventoryReconciliationRow) => {
    setSelectedRow(row);
    setReason('Stock reconciliation correction');
    setNotes('');
    setConfirmChecked(false);
    setError(null);
    setSuccess(null);
  };

  const closeApplyDialog = () => {
    if (applying) return;
    setSelectedRow(null);
  };

  const applyFix = async () => {
    if (!selectedRow) return;
    if (!confirmChecked) return;

    setApplying(true);
    setError(null);
    setSuccess(null);

    try {
      const result: ReconciliationApplyResult = await applyInventoryReconciliationFix({
        productId: selectedRow.productId,
        expectedDifference: selectedRow.difference,
        reason,
        notes,
      });

      setSuccess(
        `Applied ${result.appliedAdjustmentType} (${result.appliedQuantity}) for ${result.productName}. Difference ${result.beforeDifference} -> ${result.afterDifference}.`,
      );
      setSelectedRow(null);
      await load(mismatchesOnly);
    } catch (err: any) {
      setError(err?.response?.data?.message ?? err?.message ?? 'Failed to apply correction.');
    } finally {
      setApplying(false);
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2, gap: 2, flexWrap: 'wrap' }}>
        <Box>
          <Typography variant="h5" sx={{ fontWeight: 700 }}>
            Inventory Reconciliation
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Compare Products stock vs sum of active batch stock.
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <FormControlLabel
            control={
              <Switch
                checked={mismatchesOnly}
                onChange={(e) => setMismatchesOnly(e.target.checked)}
              />
            }
            label="Mismatches only"
          />
          <Button variant="outlined" onClick={() => void load(mismatchesOnly)} disabled={loading}>
            {loading ? 'Refreshing...' : 'Refresh'}
          </Button>
        </Box>
      </Box>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}
      {success && <Alert severity="success" sx={{ mb: 2 }}>{success}</Alert>}

      {!loading && !error && rows.length === 0 && (
        <Alert severity="success" sx={{ mb: 2 }}>
          No reconciliation mismatches found.
        </Alert>
      )}

      <Paper variant="outlined">
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Product</TableCell>
              <TableCell align="right">Product Stock</TableCell>
              <TableCell align="right">Batch Stock</TableCell>
              <TableCell align="right">Difference</TableCell>
              <TableCell align="right">Batch Count</TableCell>
              <TableCell>Flags</TableCell>
              <TableCell align="right">Action</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => {
              const severity = row.difference === 0 ? 'default' : row.difference > 0 ? 'warning' : 'error';
              const diffLabel = row.difference > 0 ? `+${row.difference}` : `${row.difference}`;

              return (
                <TableRow key={row.productId} hover>
                  <TableCell sx={{ fontWeight: 600 }}>{row.productName}</TableCell>
                  <TableCell align="right">{row.productStockQuantity}</TableCell>
                  <TableCell align="right">{row.batchStockQuantity}</TableCell>
                  <TableCell align="right">
                    <Chip
                      size="small"
                      color={severity as any}
                      label={diffLabel}
                      variant={row.difference === 0 ? 'outlined' : 'filled'}
                    />
                  </TableCell>
                  <TableCell align="right">{row.batchCount}</TableCell>
                  <TableCell>
                    <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                      <Chip size="small" variant="outlined" label={`TrackInventory: ${row.trackInventory ? 'Yes' : 'No'}`} />
                      <Chip size="small" variant="outlined" label={`TrackBatch: ${row.trackBatch ? 'Yes' : 'No'}`} />
                    </Box>
                  </TableCell>
                  <TableCell align="right">
                    {row.difference !== 0 ? (
                      <Button size="small" variant="contained" onClick={() => openApplyDialog(row)}>
                        Apply Fix
                      </Button>
                    ) : (
                      <Button size="small" variant="outlined" disabled>
                        Synced
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </Paper>

      <Dialog open={!!selectedRow} onClose={closeApplyDialog} maxWidth="sm" fullWidth>
        <DialogTitle>Apply Reconciliation Fix</DialogTitle>
        <DialogContent>
          {selectedRow && (
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
              <Alert severity="warning">
                This will create inventory correction adjustments to align <strong>Batch stock</strong> with <strong>Product stock</strong>.
              </Alert>

              <Typography variant="body2">
                Product: <strong>{selectedRow.productName}</strong>
              </Typography>
              <Typography variant="body2">
                Current difference: <strong>{selectedRow.difference > 0 ? `+${selectedRow.difference}` : selectedRow.difference}</strong>
              </Typography>

              <TextField
                label="Reason"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                fullWidth
                size="small"
                required
              />

              <TextField
                label="Notes (optional)"
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                fullWidth
                size="small"
                multiline
                minRows={2}
              />

              <FormControlLabel
                control={<Checkbox checked={confirmChecked} onChange={(e) => setConfirmChecked(e.target.checked)} />}
                label="I confirm this correction is reviewed and intentional."
              />
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={closeApplyDialog} disabled={applying}>Cancel</Button>
          <Button
            onClick={applyFix}
            variant="contained"
            disabled={applying || !confirmChecked || !reason.trim()}
          >
            {applying ? 'Applying...' : 'Confirm & Apply'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
