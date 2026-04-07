/**
 * DirectAddStockPage.tsx
 * Ultra-fast stock entry without supplier/PO.
 * Route: /inventory/direct-add
 */
import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Container,
  Typography,
  Paper,
  Stack,
  TextField,
  MenuItem,
  Button,
  IconButton,
  Alert,
  CircularProgress,
  FormControlLabel,
  Checkbox,
  useTheme,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import AddCircleOutlineIcon from '@mui/icons-material/AddCircleOutline';
import { directAddStock, getBatchesByProduct } from '../../api/inventory.api';
import { searchProducts } from '../../api/product.api';
import { getLocations } from '../../api/location.api';
import { useToast } from '../../hooks/useToast';
import { useCurrency } from '../../core/i18n';

interface ProductOption {
  id: string;
  name: string;
  shelfLifeDays?: number | null;
  costPrice?: number;
}

const DirectAddStockPage: React.FC = () => {
  const { currencySymbol } = useCurrency();
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const navigate = useNavigate();
  const toast = useToast();

  const [productId, setProductId] = useState('');
  const [quantity, setQuantity] = useState(1);
  const [costPerUnit, setCostPerUnit] = useState(0);
  const [locationId, setLocationId] = useState('');
  const [expiryDate, setExpiryDate] = useState('');
  const [storageLocation, setStorageLocation] = useState('');
  const [mergeWithSameDayBatch, setMergeWithSameDayBatch] = useState(false);

  const [products, setProducts] = useState<ProductOption[]>([]);
  const [locations, setLocations] = useState<{ id: string; name: string }[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    Promise.all([
      searchProducts({ IsActive: true, PageSize: 500 }),
      getLocations(),
    ]).then(([prods, locs]) => {
      setProducts((prods?.items ?? prods ?? []).map((p: any) => ({
        id: p.id,
        name: p.name,
        shelfLifeDays: p.shelfLifeDays ?? null,
        costPrice: p.costPrice ?? 0,
      })));
      setLocations((Array.isArray(locs) ? locs : locs?.items ?? []).map((l: any) => ({ id: l.id, name: l.name })));
    }).catch(() => toast.error('Failed to load products/locations'));
  }, [toast]);

  const selectedProduct = products.find(p => p.id === productId);

  const inferredExpiry = !expiryDate && selectedProduct?.shelfLifeDays
    ? (() => {
        const d = new Date();
        d.setDate(d.getDate() + selectedProduct.shelfLifeDays!);
        return d.toISOString().split('T')[0];
      })()
    : '';

  const isExpirySoon = (() => {
    const x = expiryDate || inferredExpiry;
    if (!x) return false;
    const diff = new Date(x).getTime() - Date.now();
    return diff >= 0 && diff <= 3 * 24 * 60 * 60 * 1000;
  })();

  const handleProductChange = async (id: string) => {
    setProductId(id);
    const p = products.find(x => x.id === id);
    let rememberedCost = p?.costPrice ?? 0;

    try {
      const productBatches = await getBatchesByProduct(id);
      const latest = (productBatches ?? [])
        .slice()
        .sort((a: any, b: any) => new Date(b.receivedDate).getTime() - new Date(a.receivedDate).getTime())[0];
      if (latest?.costPerUnit != null) {
        rememberedCost = Number(latest.costPerUnit);
      }
    } catch {
      // non-blocking fallback to product master
    }

    if (p) {
      setCostPerUnit(rememberedCost);
    }
  };

  const handleSubmit = async () => {
    if (!productId) { toast.error('Select a product'); return; }
    if (!locationId) { toast.error('Select a location'); return; }
    if (quantity <= 0) { toast.error('Quantity must be greater than zero'); return; }

    setLoading(true);
    try {
      const res = await directAddStock({
        productId,
        quantity,
        costPerUnit,
        locationId,
        expiryDate: expiryDate || null,
        storageLocation: storageLocation || null,
        mergeWithSameDayBatch,
      });

      toast.success(`Stock added. Batch: ${res.batchNumber}`);
      navigate('/inventory');
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Direct add failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box sx={{ minHeight: '100vh', bgcolor: dk ? '#0f0f0f' : '#f8f9fa', pb: 8 }}>
      <Container maxWidth="sm" sx={{ pt: 3 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, mb: 3 }}>
          <IconButton onClick={() => navigate(-1)}>
            <ArrowBackIcon />
          </IconButton>
          <AddCircleOutlineIcon sx={{ color: '#10b981', fontSize: 28 }} />
          <Box>
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              ➕ Add Stock
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Simple direct stock entry (no supplier, no PO)
            </Typography>
          </Box>
        </Box>

        <Paper sx={{ p: 3, borderRadius: 2, border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none', bgcolor: dk ? '#1a1a2e' : '#fff' }}>
          <Stack spacing={2}>
            <TextField
              select
              required
              label="Product"
              value={productId}
              onChange={e => handleProductChange(e.target.value)}
              size="small"
            >
              <MenuItem value="" disabled>Select product</MenuItem>
              {products.map(p => (
                <MenuItem key={p.id} value={p.id}>{p.name}</MenuItem>
              ))}
            </TextField>

            <TextField
              label="Quantity"
              type="number"
              size="small"
              value={quantity}
              onChange={e => setQuantity(Number(e.target.value))}
              slotProps={{ htmlInput: { min: 1 } }}
            />

            <TextField
              label={`Cost per Unit (${currencySymbol})`}
              type="number"
              size="small"
              value={costPerUnit}
              onChange={e => setCostPerUnit(Number(e.target.value))}
              slotProps={{ htmlInput: { min: 0, step: 0.01 } }}
            />

            <TextField
              select
              required
              label="Location"
              value={locationId}
              onChange={e => setLocationId(e.target.value)}
              size="small"
            >
              <MenuItem value="" disabled>Select location</MenuItem>
              {locations.map(l => (
                <MenuItem key={l.id} value={l.id}>{l.name}</MenuItem>
              ))}
            </TextField>

            <TextField
              type="date"
              label="Expiry Date (optional)"
              size="small"
              value={expiryDate}
              onChange={e => setExpiryDate(e.target.value)}
              slotProps={{ inputLabel: { shrink: true } }}
              helperText={!expiryDate && inferredExpiry ? `Auto from shelf-life: ${inferredExpiry}` : undefined}
            />

            <TextField
              label="Storage Location (optional)"
              size="small"
              value={storageLocation}
              onChange={e => setStorageLocation(e.target.value)}
              placeholder="e.g. Rack B / Cooler 2"
            />

            <FormControlLabel
              control={
                <Checkbox
                  checked={mergeWithSameDayBatch}
                  onChange={(_, checked) => setMergeWithSameDayBatch(checked)}
                />
              }
              label="Merge with same-day batch if available"
            />

            {isExpirySoon && (
              <Alert severity="warning">
                This stock is expiring within 3 days.
              </Alert>
            )}

            <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 1.5, pt: 1 }}>
              <Button variant="outlined" onClick={() => navigate(-1)} disabled={loading}>Cancel</Button>
              <Button
                variant="contained"
                onClick={handleSubmit}
                disabled={loading}
                startIcon={loading ? <CircularProgress size={16} /> : <AddCircleOutlineIcon />}
                sx={{
                  background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                  '&:hover': { background: 'linear-gradient(135deg, #059669 0%, #047857 100%)' },
                  fontWeight: 700,
                }}
              >
                {loading ? 'Adding…' : 'Add Stock'}
              </Button>
            </Box>
          </Stack>
        </Paper>
      </Container>
    </Box>
  );
};

export default DirectAddStockPage;
