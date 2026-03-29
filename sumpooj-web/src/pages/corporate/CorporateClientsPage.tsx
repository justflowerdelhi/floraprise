import { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Button,
  Divider,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Paper,
  TableContainer,
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
  useMediaQuery,
  useTheme,
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
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isSmallMobile = useMediaQuery('(max-width:360px)');

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
    <Paper sx={{ p: { xs: 1.25, sm: 2 } }}>
      <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" spacing={2} mb={2}>
        <Box>
          <Typography variant={isMobile ? 'h6' : 'h5'} fontWeight={700}>Corporate Clients</Typography>
          <Typography variant={isSmallMobile ? 'caption' : 'body2'} color="text.secondary">
            B2B credit accounts with consolidated billing
          </Typography>
        </Box>
        <Stack
          direction={{ xs: 'column', sm: 'row' }}
          spacing={1}
          sx={{ width: { xs: '100%', sm: 'auto' } }}
        >
          <TextField
            size="small"
            placeholder="Search by name or billing email"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            sx={{ minWidth: { sm: 260 } }}
            fullWidth={isMobile}
          />
          <Button
            variant="contained"
            onClick={() => setOpenCreate(true)}
            fullWidth={isMobile}
          >
            Add Client
          </Button>
        </Stack>
      </Stack>

      {isMobile ? (
        <Stack spacing={1.25}>
          {items.map((c) => (
            <Paper key={c.id} variant="outlined" sx={{ p: { xs: 1, sm: 1.25 } }}>
              <Stack spacing={0.9}>
                <Stack direction="row" justifyContent="space-between" alignItems="center" spacing={1}>
                  <Button
                    size="small"
                    onClick={() => navigate(`/corporate/clients/${c.id}`)}
                    sx={{
                      px: 0,
                      justifyContent: 'flex-start',
                      textAlign: 'left',
                      fontSize: isSmallMobile ? '0.78rem' : '0.85rem',
                      lineHeight: 1.2,
                    }}
                  >
                    {c.name}
                  </Button>
                  <Chip size="small" color={c.isActive ? 'success' : 'default'} label={c.isActive ? 'Active' : 'Inactive'} />
                </Stack>

                <Typography variant={isSmallMobile ? 'caption' : 'body2'} color="text.secondary" noWrap>
                  {c.billingEmail}
                </Typography>

                <Divider />

                <Stack direction="row" justifyContent="space-between" spacing={1}>
                  <Typography variant="caption" color="text.secondary">Terms</Typography>
                  <Typography variant={isSmallMobile ? 'caption' : 'body2'}>{c.paymentTerms || 'Net 30'}</Typography>
                </Stack>
                <Stack direction="row" justifyContent="space-between" spacing={1}>
                  <Typography variant="caption" color="text.secondary">Credit Limit</Typography>
                  <Typography variant={isSmallMobile ? 'caption' : 'body2'}>{c.creditLimit != null ? c.creditLimit.toFixed(2) : '—'}</Typography>
                </Stack>
                <Stack direction="row" justifyContent="space-between" spacing={1}>
                  <Typography variant="caption" color="text.secondary">Outstanding</Typography>
                  <Typography variant={isSmallMobile ? 'caption' : 'body2'}>{(c.outstandingAmount ?? 0).toFixed(2)}</Typography>
                </Stack>
                <Stack direction="row" justifyContent="space-between" spacing={1}>
                  <Typography variant="caption" color="text.secondary">Employees</Typography>
                  <Typography variant={isSmallMobile ? 'caption' : 'body2'}>{c.activeEmployees ?? 0}</Typography>
                </Stack>

                <Stack direction={isSmallMobile ? 'column' : 'row'} spacing={1}>
                  <Button
                    size="small"
                    variant="outlined"
                    fullWidth
                    onClick={() => navigate(`/corporate/clients/${c.id}`)}
                    sx={{ minHeight: 32, fontSize: isSmallMobile ? '0.72rem' : undefined }}
                  >
                    Dashboard
                  </Button>
                  <Button
                    size="small"
                    variant="outlined"
                    fullWidth
                    onClick={() => navigate(`/corporate/invoices?clientId=${c.id}`)}
                    sx={{ minHeight: 32, fontSize: isSmallMobile ? '0.72rem' : undefined }}
                  >
                    Invoices
                  </Button>
                  <Button
                    size="small"
                    variant="contained"
                    fullWidth
                    onClick={() => navigate(`/corporate/orders?clientId=${c.id}`)}
                    sx={{ minHeight: 32, fontSize: isSmallMobile ? '0.72rem' : undefined }}
                  >
                    New Order
                  </Button>
                </Stack>
              </Stack>
            </Paper>
          ))}
          {!loading && items.length === 0 && (
            <Paper variant="outlined" sx={{ p: 2, textAlign: 'center' }}>
              <Typography variant="body2">No corporate clients found.</Typography>
            </Paper>
          )}
        </Stack>
      ) : (
        <TableContainer>
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
        </TableContainer>
      )}

      <TablePagination
        component="div"
        count={total}
        page={page}
        onPageChange={(_, newPage) => setPage(newPage)}
        rowsPerPage={pageSize}
        rowsPerPageOptions={[10]}
        labelRowsPerPage={isMobile ? '' : undefined}
        labelDisplayedRows={({ from, to, count }) =>
          isMobile ? `${from}-${to} / ${count !== -1 ? count : `>${to}`}` : `${from}-${to} of ${count}`
        }
        sx={{
          '& .MuiTablePagination-toolbar': {
            px: { xs: 1, sm: 2 },
            minHeight: { xs: 44, sm: 52 },
            flexWrap: { xs: 'wrap', sm: 'nowrap' },
            rowGap: { xs: 0.5, sm: 0 },
          },
          '& .MuiTablePagination-selectLabel, & .MuiTablePagination-input': {
            display: { xs: 'none', sm: 'block' },
          },
          '& .MuiTablePagination-displayedRows': {
            m: 0,
            width: { xs: '100%', sm: 'auto' },
            textAlign: { xs: 'center', sm: 'left' },
            fontSize: { xs: '0.75rem', sm: '0.875rem' },
          },
          '& .MuiTablePagination-actions': {
            ml: { xs: 'auto', sm: 2 },
          },
        }}
      />

      <Dialog
        open={openCreate}
        onClose={() => setOpenCreate(false)}
        fullWidth
        maxWidth="sm"
        fullScreen={isMobile}
      >
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
