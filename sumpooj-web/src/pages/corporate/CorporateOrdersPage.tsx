import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Divider,
  Box,
  Button,
  IconButton,
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
  Alert,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import AddIcon from '@mui/icons-material/Add';
import { useSearchParams } from 'react-router-dom';
import { createCorporateOrder, searchCorporateClients, type CorporateClient, type CreateCorporateOrderRequest } from '../../api/corporate.api';
import { getLocations } from '../../api/location.api';
import { searchProducts } from '../../api/product.api';
import { useApiCall } from '../../hooks/useApiCall';

type ProductOption = {
  id: string;
  name: string;
  retailPrice: number;
};

type ItemRow = {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
};

const formatLocalDateTimeInput = () => {
  const now = new Date();
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}T${pad(now.getHours())}:${pad(now.getMinutes())}`;
};

export default function CorporateOrdersPage() {
  const { execute, loading } = useApiCall();
  const [searchParams] = useSearchParams();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const [clients, setClients] = useState<CorporateClient[]>([]);
  const [products, setProducts] = useState<ProductOption[]>([]);
  const [locations, setLocations] = useState<Array<{ id: string; name: string }>>([]);

  const [creditWarn, setCreditWarn] = useState<string | null>(null);

  const [form, setForm] = useState({
    clientId: searchParams.get('clientId') ?? '',
    orderType: 'DELIVERY' as 'DELIVERY' | 'PICKUP',
    deliveryDate: formatLocalDateTimeInput(),
    timeSlot: '10:00-13:00',
    deliveryAddress: '',
    deliveryPincode: '',
    recipientName: '',
    recipientPhone: '',
    message: '',
    locationId: '',
    items: [{ productId: '', productName: '', quantity: 1, unitPrice: 0 }] as ItemRow[],
  });

  const loadLookups = useCallback(async () => {
    const [clientsRes, productsRes, locationsRes] = await Promise.all([
      execute(() => searchCorporateClients({ page: 1, pageSize: 200 }), { errorMessage: 'Failed to load corporate clients' }),
      execute(() => searchProducts({ IsActive: true, PageSize: 300 }), { errorMessage: 'Failed to load products' }),
      execute(() => getLocations(), { errorMessage: 'Failed to load locations' }),
    ]);

    if (clientsRes) setClients(clientsRes.items ?? []);

    const rawProducts = (productsRes?.items ?? productsRes ?? []) as any[];
    setProducts(
      rawProducts.map((p) => ({
        id: String(p.id),
        name: String(p.name ?? p.productName ?? 'Product'),
        retailPrice: Number(p.retailPrice ?? p.sellingPrice ?? p.price ?? 0),
      }))
    );

    const rawLocations = (locationsRes ?? []) as any[];
    setLocations(rawLocations.map((l) => ({ id: String(l.id), name: String(l.name ?? 'Location') })));
  }, [execute]);

  useEffect(() => {
    loadLookups();
  }, [loadLookups]);

  const total = useMemo(
    () => form.items.reduce((sum, it) => sum + (it.quantity * it.unitPrice), 0),
    [form.items]
  );

  const updateItem = (index: number, patch: Partial<ItemRow>) => {
    setForm((prev) => {
      const items = [...prev.items];
      items[index] = { ...items[index], ...patch };
      return { ...prev, items };
    });
  };

  const addItem = () => {
    setForm((prev) => ({ ...prev, items: [...prev.items, { productId: '', productName: '', quantity: 1, unitPrice: 0 }] }));
  };

  const removeItem = (index: number) => {
    setForm((prev) => ({ ...prev, items: prev.items.filter((_, i) => i !== index) }));
  };

  const submit = async () => {
    setCreditWarn(null);

    if (!form.clientId || form.items.length === 0 || form.items.some((i) => !i.productId || i.quantity <= 0)) {
      return;
    }

    const payload: CreateCorporateOrderRequest = {
      clientId: form.clientId,
      orderType: form.orderType,
      deliveryDate: new Date(form.deliveryDate).toISOString(),
      timeSlot: form.orderType === 'DELIVERY' ? form.timeSlot : undefined,
      deliveryAddress: form.orderType === 'DELIVERY' ? form.deliveryAddress : undefined,
      deliveryPincode: form.orderType === 'DELIVERY' ? form.deliveryPincode : undefined,
      recipientName: form.recipientName || undefined,
      recipientPhone: form.recipientPhone || undefined,
      message: form.message || undefined,
      locationId: form.locationId || undefined,
      items: form.items.map((i) => ({
        productId: i.productId,
        productName: i.productName,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
      })),
    };

    const created = await execute(
      () => createCorporateOrder(payload),
      { successMessage: 'Corporate order created', errorMessage: 'Failed to create corporate order' }
    );

    if (created?.creditLimitExceeded) {
      setCreditWarn('Credit limit exceeded for this client. Order is created but requires financial attention.');
    }

    if (created) {
      setForm((prev) => ({
        ...prev,
        recipientName: '',
        recipientPhone: '',
        message: '',
        items: [{ productId: '', productName: '', quantity: 1, unitPrice: 0 }],
      }));
    }
  };

  return (
    <Paper sx={{ p: { xs: 1.25, sm: 2 } }}>
      <Typography variant={isMobile ? 'h6' : 'h5'} fontWeight={700} mb={0.5}>Corporate Orders</Typography>
      <Typography variant="body2" color="text.secondary" mb={2}>
        Create B2B credit orders (outside POS) with delivery integration.
      </Typography>

      {creditWarn && <Alert severity="warning" sx={{ mb: 2 }}>{creditWarn}</Alert>}

      <Stack spacing={2}>
        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <TextField
            select
            label="Corporate Client"
            value={form.clientId}
            onChange={(e) => setForm((prev) => ({ ...prev, clientId: e.target.value }))}
            fullWidth
          >
            {clients.map((c) => (
              <MenuItem key={c.id} value={c.id}>{c.name}</MenuItem>
            ))}
          </TextField>

          <TextField
            select
            label="Order Type"
            value={form.orderType}
            onChange={(e) => setForm((prev) => ({ ...prev, orderType: e.target.value as 'DELIVERY' | 'PICKUP' }))}
            sx={{ minWidth: 170 }}
          >
            <MenuItem value="DELIVERY">Delivery</MenuItem>
            <MenuItem value="PICKUP">Pickup</MenuItem>
          </TextField>

          <TextField
            select
            label="Location"
            value={form.locationId}
            onChange={(e) => setForm((prev) => ({ ...prev, locationId: e.target.value }))}
            sx={{ minWidth: 210 }}
          >
            {locations.map((l) => (
              <MenuItem key={l.id} value={l.id}>{l.name}</MenuItem>
            ))}
          </TextField>
        </Stack>

        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <TextField
            label="Delivery Date & Time"
            type="datetime-local"
            value={form.deliveryDate}
            onChange={(e) => setForm((prev) => ({ ...prev, deliveryDate: e.target.value }))}
            InputLabelProps={{ shrink: true }}
            fullWidth
          />
          <TextField
            label="Time Slot"
            value={form.timeSlot}
            onChange={(e) => setForm((prev) => ({ ...prev, timeSlot: e.target.value }))}
            fullWidth
          />
        </Stack>

        {form.orderType === 'DELIVERY' && (
          <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
            <TextField
              label="Delivery Address"
              value={form.deliveryAddress}
              onChange={(e) => setForm((prev) => ({ ...prev, deliveryAddress: e.target.value }))}
              fullWidth
            />
            <TextField
              label="Pincode"
              value={form.deliveryPincode}
              onChange={(e) => setForm((prev) => ({ ...prev, deliveryPincode: e.target.value }))}
              sx={{ minWidth: 180 }}
            />
          </Stack>
        )}

        <Stack direction={{ xs: 'column', md: 'row' }} spacing={2}>
          <TextField
            label="Recipient Name"
            value={form.recipientName}
            onChange={(e) => setForm((prev) => ({ ...prev, recipientName: e.target.value }))}
            fullWidth
          />
          <TextField
            label="Recipient Phone"
            value={form.recipientPhone}
            onChange={(e) => setForm((prev) => ({ ...prev, recipientPhone: e.target.value }))}
            fullWidth
          />
        </Stack>

        <TextField
          label="Message"
          value={form.message}
          onChange={(e) => setForm((prev) => ({ ...prev, message: e.target.value }))}
          multiline
          minRows={2}
        />

        <Box>
          <Stack direction="row" justifyContent="space-between" mb={1}>
            <Typography variant="subtitle1" fontWeight={600}>Order Items</Typography>
            <Button startIcon={<AddIcon />} onClick={addItem}>Add Item</Button>
          </Stack>

          {isMobile ? (
            <Stack spacing={1}>
              {form.items.map((item, idx) => (
                <Paper key={idx} variant="outlined" sx={{ p: 1 }}>
                  <Stack spacing={1}>
                    <TextField
                      select
                      size="small"
                      label="Product"
                      value={item.productId}
                      onChange={(e) => {
                        const selected = products.find((p) => p.id === e.target.value);
                        updateItem(idx, {
                          productId: e.target.value,
                          productName: selected?.name ?? '',
                          unitPrice: selected?.retailPrice ?? 0,
                        });
                      }}
                      fullWidth
                    >
                      {products.map((p) => (
                        <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>
                      ))}
                    </TextField>

                    <Stack direction="row" spacing={1}>
                      <TextField
                        size="small"
                        type="number"
                        label="Qty"
                        value={item.quantity}
                        onChange={(e) => updateItem(idx, { quantity: Math.max(1, Number(e.target.value || 1)) })}
                        fullWidth
                      />
                      <TextField
                        size="small"
                        type="number"
                        label="Unit Price"
                        value={item.unitPrice}
                        onChange={(e) => updateItem(idx, { unitPrice: Math.max(0, Number(e.target.value || 0)) })}
                        fullWidth
                      />
                    </Stack>

                    <Divider />

                    <Stack direction="row" justifyContent="space-between" alignItems="center">
                      <Typography variant="body2" fontWeight={600}>
                        Line Total: {(item.quantity * item.unitPrice).toFixed(2)}
                      </Typography>
                      <IconButton color="error" onClick={() => removeItem(idx)} disabled={form.items.length === 1}>
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </Stack>
                  </Stack>
                </Paper>
              ))}
            </Stack>
          ) : (
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Product</TableCell>
                  <TableCell align="right">Qty</TableCell>
                  <TableCell align="right">Unit Price</TableCell>
                  <TableCell align="right">Line Total</TableCell>
                  <TableCell align="center"></TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {form.items.map((item, idx) => (
                  <TableRow key={idx}>
                    <TableCell>
                      <TextField
                        select
                        size="small"
                        value={item.productId}
                        onChange={(e) => {
                          const selected = products.find((p) => p.id === e.target.value);
                          updateItem(idx, {
                            productId: e.target.value,
                            productName: selected?.name ?? '',
                            unitPrice: selected?.retailPrice ?? 0,
                          });
                        }}
                        fullWidth
                      >
                        {products.map((p) => (
                          <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>
                        ))}
                      </TextField>
                    </TableCell>
                    <TableCell align="right">
                      <TextField
                        size="small"
                        type="number"
                        value={item.quantity}
                        onChange={(e) => updateItem(idx, { quantity: Math.max(1, Number(e.target.value || 1)) })}
                        sx={{ width: 90 }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <TextField
                        size="small"
                        type="number"
                        value={item.unitPrice}
                        onChange={(e) => updateItem(idx, { unitPrice: Math.max(0, Number(e.target.value || 0)) })}
                        sx={{ width: 120 }}
                      />
                    </TableCell>
                    <TableCell align="right">{(item.quantity * item.unitPrice).toFixed(2)}</TableCell>
                    <TableCell align="center">
                      <IconButton color="error" onClick={() => removeItem(idx)} disabled={form.items.length === 1}>
                        <DeleteIcon fontSize="small" />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </Box>

        <Stack direction={{ xs: 'column', sm: 'row' }} justifyContent="space-between" alignItems={{ xs: 'stretch', sm: 'center' }} spacing={1.25}>
          <Typography variant="h6">Total: {total.toFixed(2)}</Typography>
          <Button variant="contained" onClick={submit} disabled={loading} fullWidth={isMobile}>Create Corporate Order</Button>
        </Stack>
      </Stack>
    </Paper>
  );
}
