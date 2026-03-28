import { useCallback, useEffect, useState } from 'react';
import {
  Alert,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { useApiCall } from '../../hooks/useApiCall';
import {
  approveAutoCreatedOrder,
  cancelAutoCreatedOrder,
  getPendingAutoCreatedOrders,
  type PendingCorporateApprovalOrder,
} from '../../api/corporate.api';

export default function AutoCreatedCorporateOrdersPage() {
  const { execute, loading } = useApiCall();
  const [items, setItems] = useState<PendingCorporateApprovalOrder[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [selected, setSelected] = useState<PendingCorporateApprovalOrder | null>(null);
  const [timeSlot, setTimeSlot] = useState('10:00-13:00');

  const load = useCallback(async () => {
    setError(null);
    const result = await execute(() => getPendingAutoCreatedOrders(), {
      errorMessage: 'Failed to load pending approvals',
    });
    if (result) setItems(result);
  }, [execute]);

  useEffect(() => {
    load();
  }, [load]);

  const approve = async () => {
    if (!selected) return;
    const ok = await execute(
      () => approveAutoCreatedOrder(selected.orderId, { approvedTimeSlot: timeSlot }),
      { successMessage: 'Auto-created order approved', errorMessage: 'Approval failed' }
    );
    if (ok !== undefined) {
      setSelected(null);
      await load();
    }
  };

  const cancel = async (orderId: string) => {
    const ok = await execute(
      () => cancelAutoCreatedOrder(orderId),
      { successMessage: 'Auto-created order cancelled', errorMessage: 'Cancellation failed' }
    );
    if (ok !== undefined) {
      await load();
    }
  };

  return (
    <Paper sx={{ p: 2 }}>
      <Typography variant="h5" fontWeight={700} mb={0.5}>Auto-Created Orders Approval</Typography>
      <Typography variant="body2" color="text.secondary" mb={2}>
        Review and approve automation-generated B2B orders before execution.
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Order No</TableCell>
            <TableCell>Corporate Client</TableCell>
            <TableCell>Employee</TableCell>
            <TableCell>Auto Date</TableCell>
            <TableCell>Delivery Date</TableCell>
            <TableCell>Amount</TableCell>
            <TableCell>Status</TableCell>
            <TableCell align="right">Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {items.map((row) => (
            <TableRow key={row.orderId} hover>
              <TableCell>{row.orderNumber}</TableCell>
              <TableCell>{row.clientName}</TableCell>
              <TableCell>{row.employeeName ?? '-'}</TableCell>
              <TableCell>{row.automationDateUtc ? new Date(row.automationDateUtc).toLocaleDateString() : '-'}</TableCell>
              <TableCell>{new Date(row.deliveryDateUtc).toLocaleString()}</TableCell>
              <TableCell>{Number(row.totalAmount ?? 0).toFixed(2)}</TableCell>
              <TableCell>{row.needsApproval ? 'Pending' : 'Ready'}</TableCell>
              <TableCell align="right">
                <Stack direction="row" spacing={1} justifyContent="flex-end">
                  <Button size="small" variant="contained" onClick={() => setSelected(row)}>
                    Approve
                  </Button>
                  <Button size="small" color="error" variant="outlined" onClick={() => cancel(row.orderId)}>
                    Cancel
                  </Button>
                </Stack>
              </TableCell>
            </TableRow>
          ))}

          {items.length === 0 && (
            <TableRow>
              <TableCell colSpan={8} align="center">
                <Typography variant="body2" color="text.secondary" py={2}>
                  No auto-created orders are pending approval.
                </Typography>
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      <Dialog open={Boolean(selected)} onClose={() => setSelected(null)} fullWidth maxWidth="sm">
        <DialogTitle>Approve Auto-Created Order</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="Order" value={selected?.orderNumber ?? ''} InputProps={{ readOnly: true }} />
            <TextField
              select
              label="Approved Time Slot"
              value={timeSlot}
              onChange={(e) => setTimeSlot(e.target.value)}
            >
              <MenuItem value="08:00-11:00">08:00-11:00</MenuItem>
              <MenuItem value="10:00-13:00">10:00-13:00</MenuItem>
              <MenuItem value="13:00-16:00">13:00-16:00</MenuItem>
              <MenuItem value="16:00-19:00">16:00-19:00</MenuItem>
            </TextField>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setSelected(null)}>Close</Button>
          <Button variant="contained" onClick={approve} disabled={loading}>Approve</Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
}
