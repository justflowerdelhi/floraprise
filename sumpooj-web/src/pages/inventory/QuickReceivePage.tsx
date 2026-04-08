/**
 * QuickReceivePage.tsx
 * Fast stock intake — bypasses full PO lifecycle.
 * Route: /inventory/quick-receive
 */
import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Paper,
  Button,
  IconButton,
  Stack,
  TextField,
  MenuItem,
  Divider,
  Tooltip,
  Alert,
  CircularProgress,
  Chip,
  Autocomplete,
  FormControlLabel,
  Checkbox,
  useTheme,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import AddIcon from '@mui/icons-material/Add';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import FlashOnIcon from '@mui/icons-material/FlashOn';
import WarningAmberIcon from '@mui/icons-material/WarningAmber';
import { getBatchesByProduct, quickReceive } from '../../api/inventory.api';
import { searchProducts } from '../../api/product.api';
import { getAllSuppliers } from '../../api/supplier.api';
import { getLocations } from '../../api/location.api';
import { showError, showSuccess } from '../../utils/toast';
import { formatCurrency, useCurrency } from '../../core/i18n';

// ─── Types ───────────────────────────────────────────────────

interface ItemRow {
  id: number;
  productId: string;
  productName: string;
  shelfLifeDays: number | null;
  quantity: number;
  costPerUnit: number;
  sellingPricePerUnit: number | null;
  unit: string;
  expiryDate: string;
  shelfLifeDaysOverride: number | null;
  storageLocation: string;
  mergeWithSameDayBatch: boolean;
  /** Colors available for this product (from tags / product.color) */
  availableColors: string[];
  /** Currently selected color for this batch */
  color: string;
}

interface ProductOption {
  id: string;
  name: string;
  sku?: string;
  color?: string;
  tags?: string[];
  categoryName?: string;
  shelfLifeDays?: number | null;
  costPrice?: number;
  retailPrice?: number;
  unitOfMeasure?: string;
}

// Known color names — used to distinguish color tags from keyword tags
const KNOWN_COLORS = new Set([
  'red', 'yellow', 'pink', 'white', 'orange', 'purple', 'blue', 'peach',
  'green', 'lavender', 'maroon', 'coral', 'cream', 'ivory', 'magenta', 'violet',
  'black', 'brown', 'gold', 'silver',
]);

/** Extract color options from a product: single color + color-like tags */
const getProductColors = (prod: ProductOption): string[] => {
  const colors = new Set<string>();
  if (prod.color) colors.add(prod.color);
  (prod.tags ?? []).forEach(t => {
    if (KNOWN_COLORS.has(t.toLowerCase())) colors.add(t);
  });
  return Array.from(colors);
};

// Swatch map for color dots
const COLOR_SWATCH: Record<string, string> = {
  Red: '#ef5350', Yellow: '#ffd54f', Pink: '#f48fb1', White: '#e0e0e0',
  Orange: '#ffa726', Purple: '#ab47bc', Blue: '#42a5f5', Peach: '#ffab91',
  Green: '#66bb6a', Lavender: '#ce93d8', Maroon: '#7b1fa2', Coral: '#ff7043',
  Cream: '#fff9c4', Ivory: '#fff8e1', Magenta: '#e91e63', Violet: '#7e57c2',
  Black: '#424242', Brown: '#795548', Gold: '#ffc107', Silver: '#bdbdbd',
};

let rowIdSeq = 0;
const newRow = (): ItemRow => ({
  id: ++rowIdSeq,
  productId: '',
  productName: '',
  shelfLifeDays: null,
  quantity: 1,
  costPerUnit: 0,
  sellingPricePerUnit: null,
  unit: 'each',
  expiryDate: '',
  shelfLifeDaysOverride: null,
  storageLocation: '',
  mergeWithSameDayBatch: false,
  availableColors: [],
  color: '',
});

const THREE_DAYS_MS = 3 * 24 * 60 * 60 * 1000;
const DEFAULT_MARGIN = 0.3;

// ─── Component ───────────────────────────────────────────────

const QuickReceivePage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const { currencySymbol } = useCurrency();

  const [supplierId, setSupplierId] = useState('');
  const [locationId, setLocationId] = useState('');
  const [rows, setRows] = useState<ItemRow[]>([newRow()]);
  const [loading, setLoading] = useState(false);

  const [products, setProducts] = useState<ProductOption[]>([]);
  const [suppliers, setSuppliers] = useState<{ id: string; name: string }[]>([]);
  const [locations, setLocations] = useState<{ id: string; name: string }[]>([]);

  // Load reference data
  useEffect(() => {
    Promise.all([
      searchProducts({ IsActive: true, PageSize: 500 }),
      getAllSuppliers(),
      getLocations(),
    ]).then(([prods, sups, locs]) => {
      const prodItems: ProductOption[] = (prods?.items ?? prods ?? []).map((p: any) => ({
        id: p.id,
        name: p.name,
        sku: p.sku ?? '',
        color: p.color ?? '',
        tags: Array.isArray(p.tags) ? p.tags : (typeof p.tags === 'string' && p.tags ? p.tags.split(',').map((t: string) => t.trim()) : []),
        categoryName: p.categoryName ?? p.category ?? '',
        shelfLifeDays: p.shelfLifeDays ?? null,
        costPrice: p.costPrice ?? 0,
        retailPrice: p.retailPrice ?? 0,
        unitOfMeasure: p.unitOfMeasure ?? 'each',
      }));
      setProducts(prodItems);
      const supplierItems = (Array.isArray(sups) ? sups : (sups as any)?.items ?? []) as any[];
      setSuppliers(supplierItems.map((s: any) => ({ id: s.id, name: s.name })));
      setLocations((Array.isArray(locs) ? locs : locs?.items ?? []).map((l: any) => ({ id: l.id, name: l.name })));
    }).catch(() => showError('Failed to load reference data'));
  }, []);

  const addRow = () => setRows(prev => [...prev, newRow()]);

  const removeRow = (id: number) => setRows(prev => prev.filter(r => r.id !== id));

  const updateRow = useCallback(<K extends keyof ItemRow>(id: number, key: K, value: ItemRow[K]) => {
    setRows(prev => prev.map(r => r.id === id ? { ...r, [key]: value } : r));
  }, []);

  const onProductChange = useCallback(async (rowId: number, productId: string) => {
    const prod = products.find(p => p.id === productId);

    let rememberedCost = prod?.costPrice ?? 0;
    try {
      const productBatches = await getBatchesByProduct(productId);
      const latest = (productBatches ?? [])
        .slice()
        .sort((a: any, b: any) => new Date(b.receivedDate).getTime() - new Date(a.receivedDate).getTime())[0];

      if (latest?.costPerUnit != null) {
        rememberedCost = Number(latest.costPerUnit);
      }
    } catch {
      // non-blocking fallback to product master cost
    }

    setRows(prev => prev.map(r =>
      r.id === rowId
        ? {
            ...r,
            productId,
            productName: prod?.name ?? '',
            shelfLifeDays: prod?.shelfLifeDays ?? null,
            costPerUnit: rememberedCost,
            sellingPricePerUnit: prod?.retailPrice ?? Number((rememberedCost * (1 + DEFAULT_MARGIN)).toFixed(2)),
            unit: prod?.unitOfMeasure ?? 'each',
            availableColors: prod ? getProductColors(prod) : [],
            color: prod ? (getProductColors(prod)[0] ?? '') : '',
          }
        : r,
    ));
  }, [products]);

  // Expiry warning — within 3 days of today
  const expiryWarning = (expiryDateStr: string): boolean => {
    if (!expiryDateStr) return false;
    const d = new Date(expiryDateStr).getTime();
    const now = Date.now();
    return d - now <= THREE_DAYS_MS && d >= now;
  };

  // Compute expiry preview from shelf life
  const computedExpiry = (row: ItemRow): string => {
    if (row.expiryDate) return row.expiryDate;
    const days = row.shelfLifeDaysOverride ?? row.shelfLifeDays;
    if (!days) return '';
    const d = new Date();
    d.setDate(d.getDate() + days);
    return d.toISOString().split('T')[0];
  };

  // Margin %
  const margin = (row: ItemRow): string => {
    if (!row.sellingPricePerUnit || !row.costPerUnit) return '—';
    const pct = ((row.sellingPricePerUnit - row.costPerUnit) / row.costPerUnit) * 100;
    return `${pct.toFixed(1)}%`;
  };

  const batchPreview = (row: ItemRow): string => {
    const prod = products.find(p => p.id === row.productId);
    const sku = (prod?.sku || 'NOSKU').replace(/\s+/g, '-').toUpperCase();
    const datePart = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    return `${sku}-${datePart}-###`;
  };

  const getRelatedSuggestions = (row: ItemRow): ProductOption[] => {
    if (!row.productId || !row.productName) return [];
    const root = row.productName.split(/\s+/)[0]?.toLowerCase();
    if (!root) return [];

    return products
      .filter(p => p.id !== row.productId && p.name.toLowerCase().includes(root))
      .slice(0, 3);
  };

  const daysLeft = (dateStr: string): number | null => {
    if (!dateStr) return null;
    const target = new Date(dateStr).getTime();
    if (Number.isNaN(target)) return null;
    return Math.ceil((target - Date.now()) / (24 * 60 * 60 * 1000));
  };

  const handleSubmit = async () => {
    if (!locationId) { showError('Please select a location.'); return; }
    if (rows.some(r => !r.productId)) { showError('Each row must have a product selected.'); return; }
    if (rows.some(r => r.quantity <= 0)) { showError('Quantity must be greater than 0.'); return; }

    setLoading(true);
    try {
      const result = await quickReceive({
        supplierId: supplierId || null,
        locationId,
        items: rows.map(r => ({
          productId: r.productId,
          quantity: r.quantity,
          costPerUnit: r.costPerUnit,
          sellingPricePerUnit: r.sellingPricePerUnit ?? null,
          unit: r.unit || null,
          expiryDate: r.expiryDate || null,
          shelfLifeDays: r.shelfLifeDaysOverride ?? null,
          storageLocation: [r.storageLocation, r.color ? `Color:${r.color}` : ''].filter(Boolean).join(' | ') || null,
          mergeWithSameDayBatch: r.mergeWithSameDayBatch,
        })),
      });

      showSuccess('Stock Received Successfully');
      navigate('/inventory');
    } catch (err: any) {
      showError(err?.response?.data?.message ?? 'Quick receive failed.');
    } finally {
      setLoading(false);
    }
  };

  const bg = dk ? '#0f0f0f' : '#f8f9fa';
  const cardBg = dk ? '#1a1a2e' : '#fff';

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: bg, pb: 8 }}>
      <Container maxWidth="lg" sx={{ pt: 3 }}>
        {/* Header */}
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 3 }}>
          <IconButton onClick={() => navigate(-1)}>
            <ArrowBackIcon />
          </IconButton>
          <FlashOnIcon sx={{ color: '#f59e0b', fontSize: 28 }} />
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              ⚡ Quick Receive
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Fast stock intake — optionally links to a supplier PO record
            </Typography>
          </Box>
        </Box>

        <Stack spacing={3}>
          {/* Header fields */}
          <Paper
            elevation={dk ? 0 : 1}
            sx={{ p: 3, bgcolor: cardBg, borderRadius: 2, border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none' }}
          >
            <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 2 }}>
              Receipt Details
            </Typography>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              <TextField
                select
                label="Supplier (optional)"
                value={supplierId}
                onChange={e => setSupplierId(e.target.value)}
                size="small"
                sx={{ minWidth: 240 }}
              >
                <MenuItem value="">— No supplier —</MenuItem>
                {suppliers.map(s => (
                  <MenuItem key={s.id} value={s.id}>{s.name}</MenuItem>
                ))}
              </TextField>

              <TextField
                select
                required
                label="Location"
                value={locationId}
                onChange={e => setLocationId(e.target.value)}
                size="small"
                sx={{ minWidth: 200 }}
              >
                <MenuItem value="" disabled>Select location</MenuItem>
                {locations.map(l => (
                  <MenuItem key={l.id} value={l.id}>{l.name}</MenuItem>
                ))}
              </TextField>
            </Box>
          </Paper>

          {/* Items */}
          <Paper
            elevation={dk ? 0 : 1}
            sx={{ p: 3, bgcolor: cardBg, borderRadius: 2, border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none' }}
          >
            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
              <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
                Items to Receive
              </Typography>
              <Button size="small" startIcon={<AddIcon />} onClick={addRow} sx={{ textTransform: 'none' }}>
                Add Row
              </Button>
            </Box>

            <Stack spacing={2} divider={<Divider />}>
              {rows.map((row, idx) => {
                const preview = computedExpiry(row);
                const warn = expiryWarning(row.expiryDate || preview);

                return (
                  <Box key={row.id}>
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
                      <Typography variant="caption" color="text.secondary" sx={{ minWidth: 20 }}>
                        #{idx + 1}
                      </Typography>
                      {rows.length > 1 && (
                        <Tooltip title="Remove row">
                          <IconButton size="small" color="error" onClick={() => removeRow(row.id)}>
                            <DeleteOutlineIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      )}
                    </Box>

                    {/* Row 1: Product + Qty + Cost + Sell */}
                    <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap', mb: 1.5 }}>
                      <Autocomplete
                        options={products}
                        value={products.find(p => p.id === row.productId) ?? null}
                        onChange={(_, value) => {
                          if (value?.id) {
                            onProductChange(row.id, value.id);
                          }
                        }}
                        size="small"
                        sx={{ minWidth: 260, flex: 2 }}
                        getOptionLabel={(option) => `${option.name} ${option.sku ? `(${option.sku})` : ''}`}
                        filterOptions={(options, state) => {
                          const q = state.inputValue.trim().toLowerCase();
                          if (!q) return options;
                          return options.filter(o =>
                            o.name.toLowerCase().includes(q)
                            || (o.sku ?? '').toLowerCase().includes(q)
                            || (o.color ?? '').toLowerCase().includes(q)
                            || (o.categoryName ?? '').toLowerCase().includes(q)
                          );
                        }}
                        renderInput={(params) => (
                          <TextField {...params} label="Product" required placeholder="Search name, SKU, color, category" />
                        )}
                      />

                      <TextField
                        label="Qty"
                        type="number"
                        size="small"
                        value={row.quantity}
                        onChange={e => updateRow(row.id, 'quantity', Number(e.target.value))}
                        slotProps={{ htmlInput: { min: 1 } }}
                        sx={{ width: 90 }}
                      />

                      <TextField
                        label={`Cost / Unit (${currencySymbol})`}
                        type="number"
                        size="small"
                        value={row.costPerUnit}
                        onChange={e => updateRow(row.id, 'costPerUnit', Number(e.target.value))}
                        slotProps={{ htmlInput: { min: 0, step: 0.01 } }}
                        sx={{ width: 140 }}
                      />

                      <TextField
                        label={`Sell Price (${currencySymbol})`}
                        type="number"
                        size="small"
                        value={row.sellingPricePerUnit ?? ''}
                        onChange={e => updateRow(row.id, 'sellingPricePerUnit', e.target.value !== '' ? Number(e.target.value) : null)}
                        slotProps={{ htmlInput: { min: 0, step: 0.01 } }}
                        sx={{ width: 140 }}
                        helperText={`Margin: ${margin(row)}`}
                      />

                      <TextField
                        label="Unit"
                        size="small"
                        value={row.unit}
                        onChange={e => updateRow(row.id, 'unit', e.target.value)}
                        sx={{ width: 100 }}
                      />
                    </Box>

                    {/* Row 2: Expiry / Shelf Life / Storage */}
                    <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap', alignItems: 'flex-start' }}>
                      <TextField
                        label="Expiry Date"
                        type="date"
                        size="small"
                        value={row.expiryDate}
                        onChange={e => updateRow(row.id, 'expiryDate', e.target.value)}
                        slotProps={{ inputLabel: { shrink: true } }}
                        sx={{ width: 170 }}
                      />

                      <TextField
                        label="Shelf Life (days)"
                        type="number"
                        size="small"
                        value={row.shelfLifeDaysOverride ?? row.shelfLifeDays ?? ''}
                        onChange={e => updateRow(row.id, 'shelfLifeDaysOverride', e.target.value !== '' ? Number(e.target.value) : null)}
                        slotProps={{ htmlInput: { min: 0 } }}
                        sx={{ width: 145 }}
                        helperText={preview ? `Expires: ${preview}` : 'From product master if blank'}
                      />

                      <TextField
                        label="Storage Location"
                        size="small"
                        value={row.storageLocation}
                        onChange={e => updateRow(row.id, 'storageLocation', e.target.value)}
                        sx={{ minWidth: 180 }}
                        placeholder="e.g. Cooler A"
                      />

                      <FormControlLabel
                        sx={{ m: 0, mt: 0.4 }}
                        control={
                          <Checkbox
                            checked={row.mergeWithSameDayBatch}
                            onChange={(_, checked) => updateRow(row.id, 'mergeWithSameDayBatch', checked)}
                          />
                        }
                        label="Merge with same-day batch"
                      />

                      {row.productId && (
                        <Chip
                          size="small"
                          variant="outlined"
                          sx={{ alignSelf: 'center', fontFamily: 'monospace' }}
                          label={`Batch Preview: ${batchPreview(row)}`}
                        />
                      )}

                      {(() => {
                        const d = daysLeft(row.expiryDate || preview);
                        if (d == null) return null;

                        const color = d > 5 ? 'success' : d >= 3 ? 'warning' : 'error';
                        return (
                          <Chip
                            size="small"
                            color={color}
                            variant="outlined"
                            label={`Expiry: ${d} day${d === 1 ? '' : 's'} left`}
                          />
                        );
                      })()}

                      {warn && (
                        <Alert severity="warning" icon={<WarningAmberIcon fontSize="small" />} sx={{ py: 0, px: 1, alignSelf: 'center' }}>
                          Expiry within 3 days!
                        </Alert>
                      )}
                    </Box>

                    {/* Color selector — shown only when product has color options */}
                    {row.availableColors.length > 0 && (
                      <Box sx={{ mt: 1, display: 'flex', gap: 1, flexWrap: 'wrap', alignItems: 'center' }}>
                        <Typography variant="caption" color="text.secondary" sx={{ alignSelf: 'center', fontWeight: 600 }}>
                          Color:
                        </Typography>
                        {row.availableColors.map(c => {
                          const selected = row.color === c;
                          const swatch = COLOR_SWATCH[c] ?? COLOR_SWATCH[c.charAt(0).toUpperCase() + c.slice(1).toLowerCase()] ?? '#90a4ae';
                          return (
                            <Chip
                              key={c}
                              size="small"
                              label={c}
                              clickable
                              onClick={() => updateRow(row.id, 'color', selected ? '' : c)}
                              variant={selected ? 'filled' : 'outlined'}
                              sx={{
                                borderColor: selected ? swatch : undefined,
                                bgcolor: selected ? swatch + '33' : undefined,
                                fontWeight: selected ? 700 : 400,
                                '&::before': {
                                  content: '""',
                                  display: 'inline-block',
                                  width: 10,
                                  height: 10,
                                  borderRadius: '50%',
                                  backgroundColor: swatch,
                                  marginRight: 0.5,
                                  border: '1px solid rgba(0,0,0,0.15)',
                                },
                              }}
                            />
                          );
                        })}
                      </Box>
                    )}

                    {getRelatedSuggestions(row).length > 0 && (
                      <Box sx={{ mt: 1, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                        <Typography variant="caption" color="text.secondary" sx={{ alignSelf: 'center' }}>
                          Suggestions:
                        </Typography>
                        {getRelatedSuggestions(row).map(s => (
                          <Chip
                            key={s.id}
                            size="small"
                            variant="outlined"
                            label={s.name}
                            onClick={() => onProductChange(row.id, s.id)}
                            clickable
                          />
                        ))}
                      </Box>
                    )}
                  </Box>
                );
              })}
            </Stack>
          </Paper>

          {/* Summary */}
          {rows.some(r => r.productId) && (
            <Paper
              elevation={dk ? 0 : 1}
              sx={{ p: 2, bgcolor: cardBg, borderRadius: 2, border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none' }}
            >
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                Summary
              </Typography>
              <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
                <Chip label={`${rows.filter(r => r.productId).length} products`} size="small" variant="outlined" />
                <Chip
                  label={`Total qty: ${rows.reduce((s, r) => s + (r.productId ? r.quantity : 0), 0)}`}
                  size="small"
                  variant="outlined"
                />
                <Chip
                  label={`Cost: ${formatCurrency(rows.reduce((s, r) => s + (r.productId ? r.quantity * r.costPerUnit : 0), 0))}`}
                  size="small"
                  color="primary"
                  variant="outlined"
                />
                {supplierId && (
                  <Chip label="PO will be created" size="small" color="success" variant="outlined" />
                )}
              </Box>
            </Paper>
          )}

          {/* Actions */}
          <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
            <Button variant="outlined" onClick={() => navigate(-1)} disabled={loading}>
              Cancel
            </Button>
            <Button
              variant="contained"
              onClick={handleSubmit}
              disabled={loading}
              startIcon={loading ? <CircularProgress size={16} /> : <FlashOnIcon />}
              sx={{
                background: 'linear-gradient(135deg, #f59e0b 0%, #ef4444 100%)',
                '&:hover': { background: 'linear-gradient(135deg, #d97706 0%, #dc2626 100%)' },
                fontWeight: 700,
              }}
            >
              {loading ? 'Receiving…' : '⚡ Confirm Quick Receive'}
            </Button>
          </Box>
        </Stack>
      </Container>
    </Box>
  );
};

export default QuickReceivePage;
