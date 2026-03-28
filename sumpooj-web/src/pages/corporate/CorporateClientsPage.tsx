import { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  TextField,
  Typography,
  Chip,
  TablePagination,
} from '@mui/material';
import { useNavigate } from 'react-router-dom';
import { createCorporateClient, searchCorporateClients, type CreateCorporateClientRequest, type CorporateClient } from '../../api/corporate.api';
import { useApiCall } from '../../hooks/useApiCall';

const initialForm: CreateCorporateClientRequest = {
  name: '',
  billingEmail: '',
  phone: '',
  creditLimit: undefined,
  paymentTerms: 'Net 30',
  billingCycle: 'MONTHLY',
  defaultMessage: '',
};

export default function CorporateClientsPage() {
  const navigate = useNavigate();
  const { execute, loading } = useApiCall();

  const [items, setItems] = useState<CorporateClient[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(0);
  const [pageSize] = useState(10);
  const [query, setQuery] = useState('');

  const [openCreate, setOpenCreate] = useState(false);
  const [form, setForm] = useState<CreateCorporateClientRequest>(initialForm);

  const load = useCallback(async () => {
    const res = await execute(
      () => searchCorporateClients({ query, page: page + 1, pageSize }),
      { errorMessage: 'Failed to load corporate clients' }
    );
    if (res) {
      setItems(res.items ?? []);
      setTotal(res.totalCount ?? 0);
    }
  }, [execute, page, pageSize, query]);

  useEffect(() => {
    load();
  }, [load]);

  const handleCreate = async () => {
    if (!form.name?.trim() || !form.billingEmail?.trim()) {
      return;
    }

    const created = await execute(
      () => createCorporateClient({
        ...form,
        name: form.name.trim(),
        billingEmail: form.billingEmail.trim(),
      }),
      { successMessage: 'Corporate client created', errorMessage: 'Failed to create corporate client' }
    );

    if (created) {
      setOpenCreate(false);
      setForm(initialForm);
      load();
    }
  };

  return (
    <Paper sx={{ p: 2 }}>
      <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" spacing={2} mb={2}>
        <Box>
          <Typography variant="h5" fontWeight={700}>Corporate Clients</Typography>
          <Typography variant="body2" color="text.secondary">
            B2B credit accounts with consolidated billing
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <TextField
            size="small"
            placeholder="Search by name or billing email"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
          />
          <Button variant="contained" onClick={() => setOpenCreate(true)}>Add Client</Button>
        </Stack>
      </Stack>

      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Client</TableCell>
            <TableCell>Billing Email</TableCell>
            <TableCell>Terms</TableCell>
            <TableCell align="right">Credit Limit</TableCell>
            <TableCell align="right">Outstanding</TableCell>
            <TableCell align="center">Employees</TableCell>
            <TableCell align="center">Status</TableCell>
            <TableCell align="right">Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {items.map((c) => (
            <TableRow key={c.id} hover>
              <TableCell>
                <Button size="small" onClick={() => navigate(`/corporate/clients/${c.id}`)}>
                  {c.name}
                </Button>
              </TableCell>
              <TableCell>{c.billingEmail}</TableCell>
              <TableCell>{c.paymentTerms || 'Net 30'}</TableCell>
              <TableCell align="right">{c.creditLimit != null ? c.creditLimit.toFixed(2) : '—'}</TableCell>
              <TableCell align="right">{(c.outstandingAmount ?? 0).toFixed(2)}</TableCell>
              <TableCell align="center">{c.activeEmployees ?? 0}</TableCell>
              <TableCell align="center">
                <Chip size="small" color={c.isActive ? 'success' : 'default'} label={c.isActive ? 'Active' : 'Inactive'} />
              </TableCell>
              <TableCell align="right">
                <Button size="small" onClick={() => navigate(`/corporate/clients/${c.id}`)}>Dashboard</Button>
                <Button size="small" onClick={() => navigate(`/corporate/invoices?clientId=${c.id}`)}>Invoices</Button>
                <Button size="small" onClick={() => navigate(`/corporate/orders?clientId=${c.id}`)}>New Order</Button>
              </TableCell>
            </TableRow>
          ))}
          {!loading && items.length === 0 && (
            <TableRow>
              <TableCell colSpan={8} align="center">No corporate clients found.</TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>

      <TablePagination
        component="div"
        count={total}
        page={page}
        onPageChange={(_, newPage) => setPage(newPage)}
        rowsPerPage={pageSize}
        rowsPerPageOptions={[10]}
      />

      <Dialog open={openCreate} onClose={() => setOpenCreate(false)} fullWidth maxWidth="sm">
        <DialogTitle>Create Corporate Client</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              required
              label="Client Name"
              value={form.name}
              onChange={(e) => setForm((prev) => ({ ...prev, name: e.target.value }))}
            />
            <TextField
              required
              label="Billing Email"
              type="email"
              value={form.billingEmail}
              onChange={(e) => setForm((prev) => ({ ...prev, billingEmail: e.target.value }))}
            />
            <TextField
              label="Phone"
              value={form.phone}
              onChange={(e) => setForm((prev) => ({ ...prev, phone: e.target.value }))}
            />
            <TextField
              label="Credit Limit"
              type="number"
              value={form.creditLimit ?? ''}
              onChange={(e) => setForm((prev) => ({ ...prev, creditLimit: e.target.value ? Number(e.target.value) : undefined }))}
            />
            <TextField
              label="Payment Terms"
              value={form.paymentTerms}
              onChange={(e) => setForm((prev) => ({ ...prev, paymentTerms: e.target.value }))}
            />
            <TextField
              label="Default Message"
              multiline
              minRows={2}
              value={form.defaultMessage}
              onChange={(e) => setForm((prev) => ({ ...prev, defaultMessage: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenCreate(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleCreate}>Create</Button>
        </DialogActions>
      </Dialog>
    </Paper>
  );
}
