import { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Alert,
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Grid,
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
import {
  addCorporateEmployee,
  getCorporateClientInvoices,
  getCorporateEmployees,
  searchCorporateClients,
  type CorporateClient,
  type CorporateEmployee,
  type CorporateInvoice,
  type CreateCorporateEmployeeRequest,
} from '../../api/corporate.api';
import { useApiCall } from '../../hooks/useApiCall';

const formatAmount = (value: number) =>
  new Intl.NumberFormat('en-IN', {
    style: 'currency',
    currency: 'INR',
    maximumFractionDigits: 0,
  }).format(value || 0);

const monthBoundariesUtc = () => {
  const now = new Date();
  const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1, 0, 0, 0));
  const end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1, 0, 0, 0));
  return { start, end };
};

const isOverdueStatus = (status: string | number) => {
  const value = String(status).toLowerCase();
  return value === 'overdue' || value === '5';
};

const initialEmployeeForm: CreateCorporateEmployeeRequest = {
  name: '',
  dateOfBirth: '',
  address: '',
};

type ViewTab = 'dashboard' | 'employees';

export default function CorporateClientWorkspacePage() {
  const { clientId = '' } = useParams();
  const navigate = useNavigate();
  const { execute, loading } = useApiCall();

  const [client, setClient] = useState<CorporateClient | null>(null);
  const [invoices, setInvoices] = useState<CorporateInvoice[]>([]);
  const [employees, setEmployees] = useState<CorporateEmployee[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<ViewTab>('dashboard');

  const [openAddEmployee, setOpenAddEmployee] = useState(false);
  const [employeeForm, setEmployeeForm] = useState<CreateCorporateEmployeeRequest>(initialEmployeeForm);

  const load = useCallback(async () => {
    if (!clientId) return;

    setError(null);
    const [clientsRes, invoicesRes, employeesRes] = await Promise.all([
      execute(() => searchCorporateClients({ page: 1, pageSize: 1000 }), {
        errorMessage: 'Failed to load corporate client',
        showErrorToast: false,
      }),
      execute(() => getCorporateClientInvoices(clientId), {
        errorMessage: 'Failed to load corporate invoices',
        showErrorToast: false,
      }),
      execute(() => getCorporateEmployees(clientId, false), {
        errorMessage: 'Failed to load employees',
        showErrorToast: false,
      }),
    ]);

    if (!clientsRes || !invoicesRes || !employeesRes) {
      setError('Unable to load corporate client workspace right now.');
      return;
    }

    const selectedClient = (clientsRes.items ?? []).find((c) => c.id === clientId) ?? null;
    if (!selectedClient) {
      setError('Corporate client not found.');
      return;
    }

    setClient(selectedClient);
    setInvoices(invoicesRes);
    setEmployees(employeesRes);
  }, [clientId, execute]);

  useEffect(() => {
    load();
  }, [load]);

  const summary = useMemo(() => {
    const { start, end } = monthBoundariesUtc();

    let totalSales = 0;
    let overdueAmount = 0;
    let invoicesThisMonth = 0;

    invoices.forEach((invoice) => {
      const amount = Number(invoice.totalAmount ?? 0);
      totalSales += amount;
      if (isOverdueStatus(invoice.status)) {
        overdueAmount += amount;
      }

      const createdAt = new Date(invoice.createdAtUtc);
      if (createdAt >= start && createdAt < end) {
        invoicesThisMonth += 1;
      }
    });

    return {
      totalSales,
      outstanding: Number(client?.outstandingAmount ?? 0),
      overdueAmount,
      invoicesThisMonth,
      employeeCount: employees.length,
    };
  }, [client, invoices, employees.length]);

  const createEmployee = async () => {
    if (!clientId || !employeeForm.name.trim() || !employeeForm.dateOfBirth) {
      return;
    }

    const created = await execute(
      () =>
        addCorporateEmployee(clientId, {
          name: employeeForm.name.trim(),
          dateOfBirth: new Date(employeeForm.dateOfBirth).toISOString(),
          address: employeeForm.address?.trim() || undefined,
        }),
      { successMessage: 'Employee added', errorMessage: 'Failed to add employee' }
    );

    if (created) {
      setOpenAddEmployee(false);
      setEmployeeForm(initialEmployeeForm);
      load();
    }
  };

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} mb={0.5}>
        {client?.name ?? 'Corporate Client'}
      </Typography>
      <Typography variant="body2" color="text.secondary" mb={2}>
        Client workspace
      </Typography>

      <Stack direction={{ xs: 'column', sm: 'row' }} spacing={1} mb={2}>
        <Button variant={tab === 'dashboard' ? 'contained' : 'outlined'} onClick={() => setTab('dashboard')}>
          Dashboard
        </Button>
        <Button variant="outlined" onClick={() => navigate(`/corporate/orders?clientId=${clientId}`)}>
          Orders
        </Button>
        <Button variant="outlined" onClick={() => navigate(`/corporate/invoices?clientId=${clientId}`)}>
          Invoices
        </Button>
        <Button variant={tab === 'employees' ? 'contained' : 'outlined'} onClick={() => setTab('employees')}>
          Employees
        </Button>
        <Button variant="outlined" onClick={() => navigate(`/corporate/orders/auto-created?clientId=${clientId}`)}>
          Auto Orders
        </Button>
      </Stack>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      {tab === 'dashboard' && (
        <>
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Paper sx={{ p: 2, borderRadius: 2, bgcolor: '#E3F2FD' }}>
                <Typography variant="subtitle2" color="text.secondary">Total Corporate Sales</Typography>
                <Typography variant="h6" fontWeight={700}>{formatAmount(summary.totalSales)}</Typography>
              </Paper>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Paper sx={{ p: 2, borderRadius: 2, bgcolor: '#FFF3E0' }}>
                <Typography variant="subtitle2" color="text.secondary">Outstanding</Typography>
                <Typography variant="h6" fontWeight={700}>{formatAmount(summary.outstanding)}</Typography>
              </Paper>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Paper sx={{ p: 2, borderRadius: 2, bgcolor: '#FFEBEE' }}>
                <Typography variant="subtitle2" color="text.secondary">Overdue Amount</Typography>
                <Typography variant="h6" fontWeight={700}>{formatAmount(summary.overdueAmount)}</Typography>
              </Paper>
            </Grid>
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Paper sx={{ p: 2, borderRadius: 2, bgcolor: '#E8F5E9' }}>
                <Typography variant="subtitle2" color="text.secondary">Invoices This Month</Typography>
                <Typography variant="h6" fontWeight={700}>{summary.invoicesThisMonth}</Typography>
              </Paper>
            </Grid>
          </Grid>

          <Paper sx={{ mt: 3, p: 2, borderRadius: 2 }}>
            <Typography variant="h6" fontWeight={700} mb={1.5}>Recent Invoices</Typography>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Invoice</TableCell>
                  <TableCell>Period</TableCell>
                  <TableCell align="right">Amount</TableCell>
                  <TableCell>Status</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {invoices.slice(0, 5).map((inv) => (
                  <TableRow key={inv.id} hover>
                    <TableCell>{inv.id.slice(0, 8).toUpperCase()}</TableCell>
                    <TableCell>
                      {new Date(inv.startDateUtc).toLocaleDateString()} - {new Date(inv.endDateUtc).toLocaleDateString()}
                    </TableCell>
                    <TableCell align="right">{formatAmount(Number(inv.totalAmount ?? 0))}</TableCell>
                    <TableCell>{String(inv.status)}</TableCell>
                  </TableRow>
                ))}
                {invoices.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={4} align="center">No invoices yet.</TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </Paper>
        </>
      )}

      {tab === 'employees' && (
        <Paper sx={{ p: 2, borderRadius: 2 }}>
          <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.5}>
            <Typography variant="h6" fontWeight={700}>Employees ({summary.employeeCount})</Typography>
            <Button variant="contained" onClick={() => setOpenAddEmployee(true)} disabled={loading}>Add Employee</Button>
          </Stack>

          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>Date of Birth</TableCell>
                <TableCell>Address</TableCell>
                <TableCell>Status</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {employees.map((e) => (
                <TableRow key={e.id} hover>
                  <TableCell>{e.name}</TableCell>
                  <TableCell>{new Date(e.dateOfBirth).toLocaleDateString()}</TableCell>
                  <TableCell>{e.address || '-'}</TableCell>
                  <TableCell>{e.isActive ? 'Active' : 'Inactive'}</TableCell>
                </TableRow>
              ))}
              {employees.length === 0 && (
                <TableRow>
                  <TableCell colSpan={4} align="center">No employees yet.</TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </Paper>
      )}

      <Dialog open={openAddEmployee} onClose={() => setOpenAddEmployee(false)} fullWidth maxWidth="sm">
        <DialogTitle>Add Employee</DialogTitle>
        <DialogContent>
          <Stack spacing={2} mt={1}>
            <TextField
              required
              label="Name"
              value={employeeForm.name}
              onChange={(e) => setEmployeeForm((prev) => ({ ...prev, name: e.target.value }))}
            />
            <TextField
              required
              type="date"
              label="Date of Birth"
              InputLabelProps={{ shrink: true }}
              value={employeeForm.dateOfBirth}
              onChange={(e) => setEmployeeForm((prev) => ({ ...prev, dateOfBirth: e.target.value }))}
            />
            <TextField
              label="Address"
              value={employeeForm.address}
              onChange={(e) => setEmployeeForm((prev) => ({ ...prev, address: e.target.value }))}
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenAddEmployee(false)}>Cancel</Button>
          <Button variant="contained" onClick={createEmployee}>Create</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
