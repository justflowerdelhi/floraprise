import React, { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Button,
  Chip,
  CircularProgress,
  InputAdornment,
  alpha,
  useTheme,
} from '@mui/material';
import {
  Add as AddIcon,
  Search as SearchIcon,
} from '@mui/icons-material';
import { useToast } from '../../hooks/useToast';
import { useApiCall } from '../../hooks/useApiCall';
import {
  getAvailableFlowers,
  addItemToPhoneOrder,
  type AvailableFlowerResponse,
} from '../../modules/phone-orders/phoneOrders.api';

// ── Props ────────────────────────────────────────────────────────────────

interface CustomBouquetBuilderProps {
  orderId: string;
  onItemAdded?: () => void;
}

// ── Component ────────────────────────────────────────────────────────────

const CustomBouquetBuilder: React.FC<CustomBouquetBuilderProps> = ({ orderId, onItemAdded }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const toast = useToast();
  const { loading, execute } = useApiCall();

  const [flowers, setFlowers] = useState<AvailableFlowerResponse[]>([]);
  const [fetching, setFetching] = useState(true);
  const [search, setSearch] = useState('');
  const [quantities, setQuantities] = useState<Record<string, string>>({});

  // ── Fetch available flowers ──────────────────────────────────────────

  const loadFlowers = useCallback(async () => {
    setFetching(true);
    try {
      const data = await getAvailableFlowers();
      setFlowers(data);
    } catch {
      toast.error('Failed to load available flowers');
    } finally {
      setFetching(false);
    }
  }, [toast]);

  useEffect(() => {
    loadFlowers();
  }, [loadFlowers]);

  // ── Filtered list ────────────────────────────────────────────────────

  const filtered = flowers.filter((f) =>
    f.productName.toLowerCase().includes(search.toLowerCase()),
  );

  // ── Add item handler ─────────────────────────────────────────────────

  const handleAdd = async (flower: AvailableFlowerResponse) => {
    const qty = parseInt(quantities[flower.productId] || '1', 10);
    if (isNaN(qty) || qty <= 0) {
      toast.error('Quantity must be greater than zero');
      return;
    }
    if (qty > flower.availableUnits) {
      toast.error(`Only ${flower.availableUnits} units available for ${flower.productName}`);
      return;
    }

    await execute(
      () =>
        addItemToPhoneOrder(orderId, {
          productId: flower.productId,
          quantity: qty,
          unitPrice: flower.unitPrice,
        }),
      {
        successMessage: `Added ${qty}× ${flower.productName}`,
        errorMessage: `Failed to add ${flower.productName}`,
      },
    );

    // Clear quantity input for this product
    setQuantities((prev) => ({ ...prev, [flower.productId]: '' }));

    // Refresh flower list (availability may have changed) + notify parent
    await loadFlowers();
    onItemAdded?.();
  };

  // ── Render ───────────────────────────────────────────────────────────

  return (
    <Box>
      <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
        Custom Bouquet Builder
      </Typography>
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 2 }}>
        Select flowers and quantities to build a custom bouquet
      </Typography>

      {/* Search */}
      <TextField
        placeholder="Search flowers…"
        size="small"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        sx={{ mb: 2, width: { xs: '100%', sm: 300 } }}
        InputProps={{
          startAdornment: (
            <InputAdornment position="start">
              <SearchIcon fontSize="small" />
            </InputAdornment>
          ),
        }}
      />

      {/* Flower table */}
      {fetching ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : filtered.length === 0 ? (
        <Paper
          elevation={dk ? 0 : 1}
          sx={{
            p: 4, textAlign: 'center', borderRadius: 2,
            bgcolor: dk ? '#0f0f0f' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          }}
        >
          <Typography variant="body2" sx={{ color: 'text.secondary' }}>
            {search ? 'No flowers match your search' : 'No flowers available'}
          </Typography>
        </Paper>
      ) : (
        <TableContainer
          component={Paper}
          elevation={dk ? 0 : 1}
          sx={{
            bgcolor: dk ? '#0f0f0f' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            borderRadius: 2,
          }}
        >
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 700 }}>Flower</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>Available</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>Price / Unit</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>Qty</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>Action</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filtered.map((flower) => (
                <TableRow key={flower.productId}>
                  <TableCell>{flower.productName}</TableCell>
                  <TableCell align="right">
                    <Chip
                      label={flower.availableUnits}
                      size="small"
                      sx={{
                        bgcolor: alpha(
                          flower.availableUnits > 0 ? '#4caf50' : '#f44336',
                          dk ? 0.25 : 0.12,
                        ),
                        color: flower.availableUnits > 0 ? '#4caf50' : '#f44336',
                        fontWeight: 700,
                        fontSize: '0.7rem',
                      }}
                    />
                  </TableCell>
                  <TableCell align="right">${flower.unitPrice.toFixed(2)}</TableCell>
                  <TableCell align="center" sx={{ width: 90 }}>
                    <TextField
                      type="number"
                      size="small"
                      value={quantities[flower.productId] || ''}
                      onChange={(e) =>
                        setQuantities((prev) => ({ ...prev, [flower.productId]: e.target.value }))
                      }
                      placeholder="1"
                      inputProps={{ min: 1, max: flower.availableUnits, style: { textAlign: 'center' } }}
                      sx={{ width: 70 }}
                      disabled={flower.availableUnits === 0 || loading}
                    />
                  </TableCell>
                  <TableCell align="center">
                    <Button
                      size="small"
                      variant="outlined"
                      color="primary"
                      startIcon={loading ? <CircularProgress size={14} /> : <AddIcon />}
                      onClick={() => handleAdd(flower)}
                      disabled={flower.availableUnits === 0 || loading}
                      sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                    >
                      Add
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  );
};

export default CustomBouquetBuilder;
