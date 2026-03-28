import React, { useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import {
  deleteIncompleteOrders,
  previewIncompleteOrders,
  type CleanupDeleteResponse,
  type CleanupPreviewResponse,
} from '../../api/data-cleanup.api';
import { useToast } from '../../hooks/useToast';

const parseOrderNumbers = (value: string) =>
  value
    .split(/[\n,]+/)
    .map((part) => part.trim())
    .filter((part) => part.length > 0);

const DataCleanupPage: React.FC = () => {
  const toast = useToast();
  const [orderInput, setOrderInput] = useState('');
  const [preview, setPreview] = useState<CleanupPreviewResponse | null>(null);
  const [deleteSummary, setDeleteSummary] = useState<CleanupDeleteResponse | null>(null);
  const [loadingPreview, setLoadingPreview] = useState(false);
  const [loadingDelete, setLoadingDelete] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);

  const targetedOrders = useMemo(() => parseOrderNumbers(orderInput), [orderInput]);

  const handlePreview = async () => {
    try {
      setLoadingPreview(true);
      setDeleteSummary(null);
      const result = await previewIncompleteOrders({
        orderNumbers: targetedOrders.length > 0 ? targetedOrders : undefined,
      });
      setPreview(result);
      toast.success(`Preview ready: ${result.selectedOrders} order(s)`);
    } catch (error) {
      console.error(error);
      toast.error('Failed to load cleanup preview');
    } finally {
      setLoadingPreview(false);
    }
  };

  const handleDelete = async () => {
    try {
      setLoadingDelete(true);
      const result = await deleteIncompleteOrders({
        orderNumbers: targetedOrders.length > 0 ? targetedOrders : undefined,
      });
      setDeleteSummary(result);
      setPreview(result);
      setConfirmOpen(false);
      toast.success(`Cleanup complete: deleted ${result.ordersDeleted} order(s)`);
    } catch (error) {
      console.error(error);
      toast.error('Cleanup delete failed');
    } finally {
      setLoadingDelete(false);
    }
  };

  const candidates = preview?.candidates ?? [];

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h5" fontWeight={700} gutterBottom>
        Incomplete Flow Cleanup
      </Typography>
      <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
        Finds completed and paid orders missing accounting flow entries (payment, revenue, COGS, or inventory reduction) and safely removes them.
      </Typography>

      <Card sx={{ mb: 2 }}>
        <CardContent>
          <Stack spacing={2}>
            <TextField
              label="Target order numbers (optional)"
              value={orderInput}
              onChange={(event) => setOrderInput(event.target.value)}
              placeholder="ORD-20260328-FF73BE99, ORD-20260328-63ECB5FC"
              multiline
              minRows={3}
              helperText="Leave blank to preview all incomplete orders. Separate values with comma or new line."
              fullWidth
            />

            <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1}>
              <Button variant="contained" onClick={handlePreview} disabled={loadingPreview || loadingDelete}>
                {loadingPreview ? 'Loading Preview...' : 'Preview'}
              </Button>
              <Button
                color="error"
                variant="outlined"
                disabled={loadingPreview || loadingDelete || candidates.length === 0}
                onClick={() => setConfirmOpen(true)}
              >
                Delete Previewed Orders
              </Button>
            </Stack>
          </Stack>
        </CardContent>
      </Card>

      {preview && (
        <Grid container spacing={2} sx={{ mb: 2 }}>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card><CardContent><Typography variant="overline">Incomplete Orders</Typography><Typography variant="h6">{preview.totalIncompleteOrders}</Typography></CardContent></Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card><CardContent><Typography variant="overline">Selected Orders</Typography><Typography variant="h6">{preview.selectedOrders}</Typography></CardContent></Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card><CardContent><Typography variant="overline">Targeted Inputs</Typography><Typography variant="h6">{preview.targetedOrderNumbers.length}</Typography></CardContent></Card>
          </Grid>
          <Grid size={{ xs: 12, sm: 6, md: 3 }}>
            <Card><CardContent><Typography variant="overline">Not Found Inputs</Typography><Typography variant="h6">{preview.notFoundOrderNumbers.length}</Typography></CardContent></Card>
          </Grid>
        </Grid>
      )}

      {preview && preview.notFoundOrderNumbers.length > 0 && (
        <Alert severity="warning" sx={{ mb: 2 }}>
          Some target orders were not found in incomplete candidates: {preview.notFoundOrderNumbers.join(', ')}
        </Alert>
      )}

      {deleteSummary && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Deleted {deleteSummary.ordersDeleted} orders, {deleteSummary.orderItemsDeleted} order items,
          {` ${deleteSummary.paymentsDeleted}`} payments, {deleteSummary.paymentTransactionsDeleted} payment transactions,
          {` ${deleteSummary.journalEntriesDeleted}`} journal entries, and {deleteSummary.inventoryLedgersDeleted} inventory ledgers.
        </Alert>
      )}

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Preview Candidates
          </Typography>
          {candidates.length === 0 ? (
            <Alert severity="info">No matching incomplete orders found.</Alert>
          ) : (
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Order Number</TableCell>
                    <TableCell>Order Date</TableCell>
                    <TableCell align="right">Total</TableCell>
                    <TableCell align="center">Payment</TableCell>
                    <TableCell align="center">Revenue</TableCell>
                    <TableCell align="center">COGS</TableCell>
                    <TableCell align="center">Inventory</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {candidates.map((candidate) => (
                    <TableRow key={candidate.orderId} hover>
                      <TableCell>
                        <Stack direction="row" spacing={1} alignItems="center">
                          <Typography variant="body2" fontWeight={600}>{candidate.orderNumber}</Typography>
                          <Chip size="small" color="warning" label="Incomplete" />
                        </Stack>
                      </TableCell>
                      <TableCell>{new Date(candidate.orderDate).toLocaleString()}</TableCell>
                      <TableCell align="right">{candidate.totalAmount.toFixed(2)}</TableCell>
                      <TableCell align="center">{candidate.paymentEntries}</TableCell>
                      <TableCell align="center">{candidate.revenueEntries}</TableCell>
                      <TableCell align="center">{candidate.cogsEntries}</TableCell>
                      <TableCell align="center">{candidate.inventoryReductionEntries}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Confirm Cleanup Delete</DialogTitle>
        <DialogContent>
          <Stack spacing={2}>
            <Alert severity="error">
              This will permanently delete previewed incomplete orders and all linked records.
            </Alert>
            <Typography variant="body2">
              Orders to delete now: {candidates.length}
            </Typography>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setConfirmOpen(false)} disabled={loadingDelete}>Cancel</Button>
          <Button color="error" variant="contained" onClick={handleDelete} disabled={loadingDelete}>
            {loadingDelete ? 'Deleting...' : 'Delete Now'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DataCleanupPage;
