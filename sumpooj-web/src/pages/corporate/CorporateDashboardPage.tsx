import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Chip,
  Grid,
  Paper,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableRow,
  Typography,
} from '@mui/material';
import { listCorporateInvoices, searchCorporateClients, type CorporateClient, type CorporateInvoice } from '../../api/corporate.api';
import { useApiCall } from '../../hooks/useApiCall';

type TopClientRow = {
  clientId: string;
  clientName: string;
  totalSales: number;
  outstanding: number;
  invoiceCount: number;
};

type TopPayingClientRow = {
  clientId: string;
  clientName: string;
  paidAmount: number;
  totalSales: number;
  outstanding: number;
};

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

export default function CorporateDashboardPage() {
  const { execute, loading } = useApiCall();
  const [clients, setClients] = useState<CorporateClient[]>([]);
  const [invoices, setInvoices] = useState<CorporateInvoice[]>([]);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setError(null);

    const [clientsRes, invoicesRes] = await Promise.all([
      execute(() => searchCorporateClients({ page: 1, pageSize: 1000 }), {
        errorMessage: 'Failed to load corporate clients',
        showErrorToast: false,
      }),
      execute(() => listCorporateInvoices(), {
        errorMessage: 'Failed to load corporate invoices',
        showErrorToast: false,
      }),
    ]);

    if (!clientsRes || !invoicesRes) {
      setError('Unable to load corporate dashboard data right now.');
      return;
    }

    setClients(clientsRes.items ?? []);
    setInvoices(invoicesRes);
  }, [execute]);

  useEffect(() => {
    load();
  }, [load]);

  const { totalSales, outstanding, overdueAmount, invoicesThisMonth, creditUsagePercent, topClients, topPayingClients } = useMemo(() => {
    const clientNameById = new Map<string, string>();
    const outstandingByClient = new Map<string, number>();
    const creditLimitByClient = new Map<string, number>();

    clients.forEach((client) => {
      clientNameById.set(client.id, client.name);
      outstandingByClient.set(client.id, Number(client.outstandingAmount ?? 0));
      creditLimitByClient.set(client.id, Number(client.creditLimit ?? 0));
    });

    const byClient = new Map<string, { totalSales: number; invoiceCount: number }>();

    let sales = 0;
    let overdue = 0;
    let monthCount = 0;
    const { start, end } = monthBoundariesUtc();

    invoices.forEach((invoice) => {
      const amount = Number(invoice.totalAmount ?? 0);
      sales += amount;

      if (isOverdueStatus(invoice.status)) {
        overdue += amount;
      }

      const createdAt = new Date(invoice.createdAtUtc);
      if (createdAt >= start && createdAt < end) {
        monthCount += 1;
      }

      const existing = byClient.get(invoice.clientId) ?? { totalSales: 0, invoiceCount: 0 };
      existing.totalSales += amount;
      existing.invoiceCount += 1;
      byClient.set(invoice.clientId, existing);
    });

    const top = Array.from(byClient.entries())
      .map(([clientId, metrics]) => ({
        clientId,
        clientName: clientNameById.get(clientId) ?? 'Corporate Client',
        totalSales: metrics.totalSales,
        outstanding: outstandingByClient.get(clientId) ?? 0,
        invoiceCount: metrics.invoiceCount,
      }))
      .sort((a, b) => b.totalSales - a.totalSales)
      .slice(0, 5);

    const topPayers = Array.from(byClient.entries())
      .map(([clientId, metrics]) => {
        const outstandingForClient = outstandingByClient.get(clientId) ?? 0;
        const paidAmount = Math.max(metrics.totalSales - outstandingForClient, 0);
        return {
          clientId,
          clientName: clientNameById.get(clientId) ?? 'Corporate Client',
          paidAmount,
          totalSales: metrics.totalSales,
          outstanding: outstandingForClient,
        };
      })
      .sort((a, b) => b.paidAmount - a.paidAmount)
      .slice(0, 5);

    const totalOutstanding = clients.reduce((sum, c) => sum + Number(c.outstandingAmount ?? 0), 0);
    const totalCreditLimit = clients.reduce((sum, c) => sum + Number(c.creditLimit ?? 0), 0);
    const usage = totalCreditLimit > 0 ? (totalOutstanding / totalCreditLimit) * 100 : 0;

    return {
      totalSales: sales,
      outstanding: totalOutstanding,
      overdueAmount: overdue,
      invoicesThisMonth: monthCount,
      creditUsagePercent: Math.min(usage, 999),
      topClients: top,
      topPayingClients: topPayers,
    };
  }, [clients, invoices]);

  const kpis = [
    { label: 'Total Corporate Sales', value: formatAmount(totalSales), color: '#E3F2FD' },
    { label: 'Outstanding', value: formatAmount(outstanding), color: '#FFF3E0' },
    { label: 'Overdue Amount', value: formatAmount(overdueAmount), color: '#FFEBEE' },
    { label: 'Invoices This Month', value: String(invoicesThisMonth), color: '#E8F5E9' },
    { label: 'Credit Usage %', value: `${creditUsagePercent.toFixed(1)}%`, color: '#E0F2F1' },
    { label: 'Total Corporate Clients', value: String(clients.length), color: '#F3E5F5' },
  ];

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} mb={0.5}>
        Corporate Dashboard
      </Typography>
      <Typography variant="body2" color="text.secondary" mb={2}>
        Snapshot of B2B sales, receivables, invoicing activity, and top-performing clients.
      </Typography>

      {error && <Alert severity="error" sx={{ mb: 2 }}>{error}</Alert>}

      <Grid container spacing={2}>
        {kpis.map((kpi) => (
          <Grid key={kpi.label} size={{ xs: 12, sm: 6, md: 4 }}>
            <Paper sx={{ p: 2, borderRadius: 2, bgcolor: kpi.color, minHeight: 100 }}>
              <Typography variant="subtitle2" color="text.secondary" mb={0.5}>{kpi.label}</Typography>
              <Typography variant="h5" fontWeight={700}>{kpi.value}</Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>

      <Paper sx={{ mt: 3, p: 2, borderRadius: 2 }}>
        <Stack direction="row" justifyContent="space-between" alignItems="center" mb={1.5}>
          <Typography variant="h6" fontWeight={700}>Top Clients</Typography>
          <Chip
            size="small"
            label={loading ? 'Refreshing...' : `Updated: ${new Date().toLocaleTimeString()}`}
            color={loading ? 'warning' : 'default'}
          />
        </Stack>

        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Client</TableCell>
              <TableCell align="right">Sales</TableCell>
              <TableCell align="right">Outstanding</TableCell>
              <TableCell align="right">Invoices</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {topClients.map((row: TopClientRow) => (
              <TableRow key={row.clientId} hover>
                <TableCell>{row.clientName}</TableCell>
                <TableCell align="right">{formatAmount(row.totalSales)}</TableCell>
                <TableCell align="right">{formatAmount(row.outstanding)}</TableCell>
                <TableCell align="right">{row.invoiceCount}</TableCell>
              </TableRow>
            ))}

            {topClients.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} align="center">
                  <Typography variant="body2" color="text.secondary" py={2}>
                    No corporate data available yet.
                  </Typography>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Paper>

      <Paper sx={{ mt: 3, p: 2, borderRadius: 2 }}>
        <Typography variant="h6" fontWeight={700} mb={1.5}>Top Paying Clients</Typography>

        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell>Client</TableCell>
              <TableCell align="right">Paid</TableCell>
              <TableCell align="right">Sales</TableCell>
              <TableCell align="right">Outstanding</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {topPayingClients.map((row: TopPayingClientRow) => (
              <TableRow key={row.clientId} hover>
                <TableCell>{row.clientName}</TableCell>
                <TableCell align="right">{formatAmount(row.paidAmount)}</TableCell>
                <TableCell align="right">{formatAmount(row.totalSales)}</TableCell>
                <TableCell align="right">{formatAmount(row.outstanding)}</TableCell>
              </TableRow>
            ))}

            {topPayingClients.length === 0 && (
              <TableRow>
                <TableCell colSpan={4} align="center">
                  <Typography variant="body2" color="text.secondary" py={2}>
                    No payment trend data available yet.
                  </Typography>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Paper>
    </Box>
  );
}
