import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Button,
  Chip,
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
  useMediaQuery,
  useTheme,
} from '@mui/material';
import { useApiCall } from '../../hooks/useApiCall';
import {
  generateCorporateInvoice,
  listCorporateInvoices,
  payCorporateInvoice,
  searchCorporateClients,
  type CorporateClient,
  type CorporateInvoice,
  type CorporateInvoiceStatus,
} from '../../api/corporate.api';

const monthStart = () => {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1).toISOString().slice(0, 10);
};

const monthEnd = () => {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth() + 1, 0).toISOString().slice(0, 10);
};

export default function CorporateInvoicesPage() {
  const { execute, loading } = useApiCall();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const [clients, setClients] = useState<CorporateClient[]>([]);
  const [invoices, setInvoices] = useState<CorporateInvoice[]>([]);
  const [status, setStatus] = useState<CorporateInvoiceStatus | ''>('');
  const [clientId, setClientId] = useState('');

  const [fromDate, setFromDate] = useState(monthStart());
  const [toDate, setToDate] = useState(monthEnd());

  const [paying, setPaying] = useState<CorporateInvoice | null>(null);
  const [amount, setAmount] = useState('');
  const [mode, setMode] = useState('BANK');
  const [reference, setReference] = useState('');
  const [notes, setNotes] = useState('');

  const [error, setError] = useState<string | null>(null);

  const clientNameById = useMemo(() => {
    const map = new Map<string, string>();
    clients.forEach((c) => map.set(c.id, c.name));
    return map;
  }, [clients]);

  const loadClients = useCallback(async () => {
    const res = await execute(() => searchCorporateClients({ page: 1, pageSize: 200 }), {
      errorMessage: 'Failed to load corporate clients',
    });
    if (res) setClients(res.items ?? []);
  }, [execute]);

  const loadInvoices = useCallback(async () => {
    setError(null);
    const res = await execute(
      () => listCorporateInvoices({ clientId: clientId || undefined, status: status || undefined }),
      { errorMessage: 'Failed to load invoices' }
    );
    if (res) setInvoices(res);
  }, [clientId, execute, status]);

  useEffect(() => {
    loadClients();
    loadInvoices();
  }, [loadClients, loadInvoices]);

  const totalOutstanding = useMemo(
    () =>
      invoices.reduce((s, inv) => {
        const statusText = String(inv.status);
        const outstanding = statusText === 'Paid' || statusText === '4' ? 0 : Number(inv.totalAmount ?? 0);
        return s + outstanding;
      }, 0),
    [invoices]
  );

  const generate = async () => {
    if (!clientId) {
      setError('Select a corporate client before generating invoice.');
      return;
    }

    const created = await execute(
      () =>
        generateCorporateInvoice({
          clientId,
          startDate: new Date(fromDate).toISOString(),
          endDate: new Date(toDate).toISOString(),
        }),
      { successMessage: 'Corporate invoice generated', errorMessage: 'Failed to generate invoice' }
    );

    if (created) {
      await loadInvoices();
    }
  };

  const openPayDialog = (invoice: CorporateInvoice) => {
    setPaying(invoice);
    const statusText = String(invoice.status);
    const outstanding = statusText === 'Paid' || statusText === '4' ? 0 : Number(invoice.totalAmount ?? 0);
    setAmount(String(outstanding));
    setMode('BANK');
    setReference('');
    setNotes('');
  };

  const pay = async () => {
    if (!paying) return;
    const amountNum = Number(amount || 0);
    if (amountNum <= 0) return;

    const ok = await execute(
      () =>
        payCorporateInvoice(paying.id, {
          amount: amountNum,
          paymentDate: new Date().toISOString(),
          paymentMode: mode,
          referenceNumber: reference || undefined,
          notes: notes || undefined,
        }),
      { successMessage: 'Invoice payment posted', errorMessage: 'Failed to post invoice payment' }
    );

    if (ok !== undefined) {
      setPaying(null);
      await loadInvoices();
    }
  };

  return (
    <Paper sx={{ p: { xs: 1.25, sm: 2 } }}>
      <Typography variant={isMobile ? 'h6' : 'h5'} fontWeight={700} mb={0.5}>Corporate Invoices</Typography>
      <Typography variant="body2" color="text.secondary" mb={2}>
        Generate monthly invoices and post customer payments against receivables.
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Stack spacing={2}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <TextField
            select
            label="Corporate Client"
            value={clientId}
            onChange={(e) => setClientId(e.target.value)}
            fullWidth
          >
            {clients.map((c) => (
              <MenuItem key={c.id} value={c.id}>{c.name}</MenuItem>
            ))}
          </TextField>

          <TextField
            select
            label="Status"
            value={status}
            onChange={(e) => setStatus(e.target.value as CorporateInvoiceStatus | '')}
            sx={{ minWidth: { md: 180 } }}
            fullWidth={isMobile}
          >
            <MenuItem value="">All</MenuItem>
            <MenuItem value="Draft">Draft</MenuItem>
            <MenuItem value="Issued">Issued</MenuItem>
            <MenuItem value="PartiallyPaid">Partially Paid</MenuItem>
            <MenuItem value="Paid">Paid</MenuItem>
            <MenuItem value="Overdue">Overdue</MenuItem>
          </TextField>

          <Button variant="outlined" onClick={loadInvoices} disabled={loading} fullWidth={isMobile}>Refresh</Button>
        </Stack>

        <Paper variant="outlined" sx={{ p: 2 }}>
          <Typography variant="subtitle1" fontWeight={600} mb={1}>Generate Monthly Invoice</Typography>
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
            <TextField
              label="Period Start"
              type="date"
              value={fromDate}
              onChange={(e) => setFromDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
            />
            <TextField
              label="Period End"
              type="date"
              value={toDate}
              onChange={(e) => setToDate(e.target.value)}
              InputLabelProps={{ shrink: true }}
            />
            <Button variant="contained" onClick={generate} disabled={loading || !clientId} fullWidth={isMobile}>Generate</Button>
          </Stack>
        </Paper>

        <Typography variant="body2" color="text.secondary">
          Total Outstanding in View: {totalOutstanding.toFixed(2)}
        </Typography>

        {isMobile ? (
          <Stack spacing={1}>
            {invoices.map((inv) => {
              const isPaid = String(inv.status) === 'Paid' || String(inv.status) === '4';
              return (
                <Paper key={inv.id} variant="outlined" sx={{ p: 1.1 }}>
                  <Stack spacing={0.8}>
                    <Stack direction="row" justifyContent="space-between" alignItems="center" spacing={1}>
                      <Typography variant="subtitle2" fontWeight={700}>{inv.id.slice(0, 8).toUpperCase()}</Typography>
                      <Chip size="small" label={String(inv.status)} color={isPaid ? 'success' : 'default'} />
                    </Stack>

                    <Typography variant="body2">
                      {clientNameById.get(inv.clientId) ?? inv.clientId.slice(0, 8)}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                      {new Date(inv.startDateUtc).toLocaleDateString()} - {new Date(inv.endDateUtc).toLocaleDateString()}
                    </Typography>

                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="caption" color="text.secondary">Total</Typography>
                      <Typography variant="body2">{Number(inv.totalAmount ?? 0).toFixed(2)}</Typography>
                    </Stack>
                    <Stack direction="row" justifyContent="space-between">
                      <Typography variant="caption" color="text.secondary">Outstanding</Typography>
                      <Typography variant="body2">{(isPaid ? 0 : Number(inv.totalAmount ?? 0)).toFixed(2)}</Typography>
                    </Stack>

                    <Button
                      size="small"
                      variant="contained"
                      onClick={() => openPayDialog(inv)}
                      disabled={isPaid}
                      fullWidth
                    >
                      Pay
                    </Button>
                  </Stack>
                </Paper>
              );
            })}

            {invoices.length === 0 && (
              <Paper variant="outlined" sx={{ p: 2, textAlign: 'center' }}>
                <Typography variant="body2" color="text.secondary">No invoices found.</Typography>
              </Paper>
            )}
          </Stack>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Invoice #</TableCell>
                <TableCell>Client</TableCell>
                <TableCell>Period</TableCell>
                <TableCell>Total</TableCell>
                <TableCell>Outstanding</TableCell>
                <TableCell>Status</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {invoices.map((inv) => (
                <TableRow key={inv.id} hover>
                  <TableCell>{inv.id.slice(0, 8).toUpperCase()}</TableCell>
                  <TableCell>{clientNameById.get(inv.clientId) ?? inv.clientId.slice(0, 8)}</TableCell>
                  <TableCell>
                    {new Date(inv.startDateUtc).toLocaleDateString()} - {new Date(inv.endDateUtc).toLocaleDateString()}
                  </TableCell>
                  <TableCell>{Number(inv.totalAmount ?? 0).toFixed(2)}</TableCell>
                  <TableCell>{(String(inv.status) === 'Paid' || String(inv.status) === '4' ? 0 : Number(inv.totalAmount ?? 0)).toFixed(2)}</TableCell>
                  <TableCell>{String(inv.status)}</TableCell>
                  <TableCell align="right">
                    <Button
                      size="small"
                      variant="contained"
                      onClick={() => openPayDialog(inv)}
                      disabled={String(inv.status) === 'Paid' || String(inv.status) === '4'}
                    >
                      Pay
                    </Button>
                  </TableCell>
                </TableRow>
              ))}

              {invoices.length === 0 && (
                <TableRow>
                  <TableCell colSpan={7} align="center">
                    <Typography variant="body2" color="text.secondary" py={2}>No invoices found.</Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        )}
      </Stack>

      <Dialog open={Boolean(paying)} onClose={() => setPaying(null)} fullWidth maxWidth="sm" fullScreen={isMobile}>
        <DialogTitle>Record Invoice Payment</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField label="Invoice" value={paying ? paying.id.slice(0, 8).toUpperCase() : ''} InputProps={{ readOnly: true }} />
            <TextField label="Amount" type="number" value={amount} onChange={(e) => setAmount(e.target.value)} />
            <TextField select label="Payment Mode" value={mode} onChange={(e) => setMode(e.target.value)}>
              <MenuItem value="BANK">Bank</MenuItem>
              <MenuItem value="UPI">UPI</MenuItem>
              <MenuItem value="NEFT">NEFT</MenuItem>
              <MenuItem value="CASH">Cash</MenuItem>
            </TextField>
            <TextField label="Reference" value={reference} onChange={(e) => setReference(e.target.value)} />
            <TextField label="Notes" value={notes} onChange={(e) => setNotes(e.target.value)} multiline minRows={2} />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPaying(null)}>Close</Button>
          <Button variant="contained" onClick={pay} disabled={loading}>Record Payment</Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
}
