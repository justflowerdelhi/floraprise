import { useEffect, useMemo, useState } from 'react';
import {
  Alert,
  Box,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Typography,
  useTheme,
} from '@mui/material';
import type { SelectChangeEvent } from '@mui/material/Select';
import { ReceiptLong, ShoppingCart, Paid, Schedule } from '@mui/icons-material';
import { useSearchParams } from 'react-router-dom';
import { getCrmCustomer360, getCrmCustomers } from '../../api/crm.api';
import type { Customer, CustomerOrderSummary } from './CRMTypes';
import { formatCurrency } from './CRMTypes';

function StatusChip({ value, kind }: { value: string; kind: 'fulfillment' | 'payment' }) {
  const normalized = value.toUpperCase();

  if (kind === 'payment') {
    const paid = normalized === 'PAID';
    return (
      <Chip
        label={value}
        size="small"
        sx={{
          bgcolor: paid ? 'rgba(76,175,80,0.2)' : 'rgba(255,152,0,0.2)',
          color: paid ? '#4caf50' : '#ff9800',
          fontWeight: 600,
        }}
      />
    );
  }

  const completed = normalized === 'COMPLETED' || normalized === 'DELIVERED';
  return (
    <Chip
      label={value}
      size="small"
      sx={{
        bgcolor: completed ? 'rgba(76,175,80,0.2)' : 'rgba(255,193,7,0.2)',
        color: completed ? '#4caf50' : '#ffc107',
        fontWeight: 600,
      }}
    />
  );
}

export default function CustomerLedgerPage() {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const [searchParams, setSearchParams] = useSearchParams();
  const initialCustomerId = searchParams.get('customerId') ?? '';
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [selectedCustomerId, setSelectedCustomerId] = useState<string>(initialCustomerId);
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [orders, setOrders] = useState<CustomerOrderSummary[]>([]);
  const [loadingCustomers, setLoadingCustomers] = useState(true);
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const groupedCustomers = useMemo(() => {
    const byNamePhone = new Map<
      string,
      {
        id: string;
        name: string;
        phone: string;
        count: number;
        ids: string[];
        totalOrders: number;
      }
    >();

    for (const customer of customers) {
      const normalizedName = customer.name.trim().toLowerCase();
      const normalizedPhone = (customer.phone ?? '').trim().toLowerCase();
      const key = `${normalizedName}::${normalizedPhone}`;

      const existing = byNamePhone.get(key);
      if (existing) {
        existing.count += 1;
        if (!existing.ids.includes(customer.id)) {
          existing.ids.push(customer.id);
        }
        existing.totalOrders += customer.totalOrders ?? 0;
        continue;
      }

      byNamePhone.set(key, {
        id: customer.id,
        name: customer.name,
        phone: customer.phone ?? '',
        count: 1,
        ids: [customer.id],
        totalOrders: customer.totalOrders ?? 0,
      });
    }

    return Array.from(byNamePhone.values()).sort((a, b) => a.name.localeCompare(b.name));
  }, [customers]);

  const selectedGroup = useMemo(
    () => groupedCustomers.find((group) => group.id === selectedCustomerId),
    [groupedCustomers, selectedCustomerId]
  );

  const selectedCustomerRecordCount = selectedGroup?.count ?? 1;

  useEffect(() => {
    let cancelled = false;

    async function loadCustomers() {
      setLoadingCustomers(true);
      setError(null);

      try {
        const response = await getCrmCustomers({ page: 1, pageSize: 500 });
        if (cancelled) return;

        setCustomers(response.items);

        const buildKey = (name: string, phone?: string) => `${name.trim().toLowerCase()}::${(phone ?? '').trim().toLowerCase()}`;

        if (selectedCustomerId) {
          const selected = response.items.find((x) => x.id === selectedCustomerId);
          if (selected) {
            const selectedKey = buildKey(selected.name, selected.phone);
            const representative = response.items.find(
              (x) => buildKey(x.name, x.phone) === selectedKey
            );

            if (representative && representative.id !== selectedCustomerId) {
              setSelectedCustomerId(representative.id);
            }

            return;
          }
        }

        if (response.items.length > 0) {
          setSelectedCustomerId(response.items[0].id);
        }
      } catch (err) {
        if (!cancelled) {
          setError('Failed to load customers.');
        }
      } finally {
        if (!cancelled) {
          setLoadingCustomers(false);
        }
      }
    }

    void loadCustomers();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    if (!selectedCustomerId) {
      setSelectedCustomer(null);
      setOrders([]);
      return;
    }

    setSearchParams({ customerId: selectedCustomerId }, { replace: true });

    let cancelled = false;

    async function loadLedger() {
      setLoadingOrders(true);
      setError(null);

      try {
        const customerIds = selectedGroup?.ids?.length ? selectedGroup.ids : [selectedCustomerId];
        const responses = await Promise.all(customerIds.map((customerId) => getCrmCustomer360(customerId)));
        if (cancelled) return;

        const representative = responses[0]?.customer ?? null;
        if (representative && selectedGroup) {
          setSelectedCustomer({
            ...representative,
            name: selectedGroup.name,
            phone: selectedGroup.phone,
          });
        } else {
          setSelectedCustomer(representative);
        }

        const dedupedOrders = Array.from(
          new Map(
            responses
              .flatMap((response) => response.orders)
              .map((order) => [order.orderId, order])
          ).values()
        ).sort((a, b) => new Date(b.orderDate).getTime() - new Date(a.orderDate).getTime());

        setOrders(dedupedOrders);
      } catch (err) {
        if (!cancelled) {
          setError('Failed to load customer ledger.');
          setSelectedCustomer(null);
          setOrders([]);
        }
      } finally {
        if (!cancelled) {
          setLoadingOrders(false);
        }
      }
    }

    void loadLedger();

    return () => {
      cancelled = true;
    };
  }, [selectedCustomerId, selectedGroup, setSearchParams]);

  const totals = useMemo(() => {
    const totalAmount = orders.reduce((sum, order) => sum + order.total, 0);
    const paidOrders = orders.filter((order) => order.paymentStatus === 'PAID').length;
    const lastOrder = orders.length > 0 ? orders[0].orderDate : null;

    return {
      totalOrders: orders.length,
      totalAmount,
      paidOrders,
      lastOrder,
    };
  }, [orders]);

  const handleCustomerChange = (event: SelectChangeEvent<string>) => {
    setSelectedCustomerId(event.target.value);
  };

  return (
    <Box sx={{ p: 3, bgcolor: dk ? '#0f0f0f' : '#f8f9fa', minHeight: '100vh' }}>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={600}>
          Customer Ledger
        </Typography>
        <Typography variant="body2" sx={{ opacity: 0.7 }}>
          View complete order history and totals for each customer.
        </Typography>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      <Paper sx={{ p: 2, mb: 3, bgcolor: dk ? '#1a1a2e' : '#fff' }}>
        <FormControl fullWidth size="small" disabled={loadingCustomers || groupedCustomers.length === 0}>
          <InputLabel id="customer-ledger-select-label">Customer</InputLabel>
          <Select
            labelId="customer-ledger-select-label"
            label="Customer"
            value={selectedCustomerId}
            onChange={handleCustomerChange}
            renderValue={() => {
              const group = groupedCustomers.find((x) => x.id === selectedCustomerId);
              if (!group) return '';

              const label = `${group.name}${group.phone ? ` (${group.phone})` : ''}`;
              return `${label} • ${group.count} customer records • ${totals.totalOrders} orders`;
            }}
          >
            {groupedCustomers.map((customer) => (
              <MenuItem key={customer.id} value={customer.id}>
                {customer.name} {customer.phone ? `(${customer.phone})` : ''}
                {customer.count > 1 ? ` • ${customer.count} customer records` : ''}
                {customer.totalOrders > 0 ? ` • ${customer.totalOrders} orders` : ''}
              </MenuItem>
            ))}
          </Select>
        </FormControl>
      </Paper>

      {(loadingCustomers || loadingOrders) && (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 6 }}>
          <CircularProgress />
        </Box>
      )}

      {!loadingCustomers && !loadingOrders && selectedCustomer && (
        <>
          <Grid container spacing={2} sx={{ mb: 3 }}>
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
                <CardContent>
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5 }}>
                    <ReceiptLong sx={{ color: '#90caf9', fontSize: 20 }} />
                    <Typography variant="caption" sx={{ opacity: 0.7 }}>
                      Total Orders
                    </Typography>
                  </Stack>
                  <Typography variant="h5" fontWeight={600}>
                    {totals.totalOrders}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>

            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
                <CardContent>
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5 }}>
                    <ShoppingCart sx={{ color: '#ffb74d', fontSize: 20 }} />
                    <Typography variant="caption" sx={{ opacity: 0.7 }}>
                      Customer
                    </Typography>
                  </Stack>
                  <Typography variant="body1" fontWeight={600} noWrap title={selectedCustomer.name}>
                    {selectedCustomer.name}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>

            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
                <CardContent>
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5 }}>
                    <Paid sx={{ color: '#4caf50', fontSize: 20 }} />
                    <Typography variant="caption" sx={{ opacity: 0.7 }}>
                      Total Value
                    </Typography>
                  </Stack>
                  <Typography variant="h6" fontWeight={600} sx={{ color: '#4caf50' }}>
                    {formatCurrency(totals.totalAmount)}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>

            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <Card sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
                <CardContent>
                  <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 0.5 }}>
                    <Schedule sx={{ color: '#ce93d8', fontSize: 20 }} />
                    <Typography variant="caption" sx={{ opacity: 0.7 }}>
                      Last Order
                    </Typography>
                  </Stack>
                  <Typography variant="body1" fontWeight={600}>
                    {totals.lastOrder ? new Date(totals.lastOrder).toLocaleDateString() : 'N/A'}
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          <Paper sx={{ bgcolor: dk ? '#1a1a2e' : '#fff' }}>
            <Box sx={{ px: 2, pt: 2 }}>
              <Typography variant="subtitle1" fontWeight={600}>
                Order Ledger
              </Typography>
              <Typography variant="body2" sx={{ opacity: 0.7 }}>
                Showing {totals.totalOrders} orders from {selectedCustomerRecordCount} customer records • Paid Orders: {totals.paidOrders} / {totals.totalOrders}
              </Typography>
            </Box>

            <TableContainer>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Order #</TableCell>
                    <TableCell>Date</TableCell>
                    <TableCell>Source</TableCell>
                    <TableCell>Fulfillment</TableCell>
                    <TableCell>Payment</TableCell>
                    <TableCell align="right">Items</TableCell>
                    <TableCell align="right">Total</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {orders.map((order) => (
                    <TableRow key={order.orderId} hover>
                      <TableCell>
                        <Typography variant="body2" fontWeight={600} sx={{ color: '#90caf9' }}>
                          {order.orderNumber}
                        </Typography>
                      </TableCell>
                      <TableCell>{new Date(order.orderDate).toLocaleDateString()}</TableCell>
                      <TableCell>
                        <Chip label={order.orderSource} size="small" variant="outlined" />
                      </TableCell>
                      <TableCell>
                        <StatusChip value={order.fulfillmentStatus} kind="fulfillment" />
                      </TableCell>
                      <TableCell>
                        <StatusChip value={order.paymentStatus} kind="payment" />
                      </TableCell>
                      <TableCell align="right">{order.items}</TableCell>
                      <TableCell align="right" sx={{ fontWeight: 600 }}>
                        {formatCurrency(order.total)}
                      </TableCell>
                    </TableRow>
                  ))}

                  {orders.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={7} align="center" sx={{ py: 4, opacity: 0.6 }}>
                        No orders found for this customer.
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          </Paper>
        </>
      )}
    </Box>
  );
}
