import React, { useEffect, useState } from 'react';
import {
  Box,
  Button,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TextField,
  Typography,
  useTheme,
  alpha,
} from '@mui/material';
import { Add as AddIcon, LocalFlorist as FlowerIcon } from '@mui/icons-material';
import { useApiCall } from '../../hooks/useApiCall';
import {
  getAvailableFlowers,
  addItemToPhoneOrder,
  type AvailableFlowerResponse,
} from './phoneOrders.api';
import { formatCurrency } from '../../core/i18n';

// ── Props ────────────────────────────────────────────────────────────────

interface CustomBouquetBuilderProps {
  orderId: string;
  onItemAdded: () => void;
}

// ── Component ────────────────────────────────────────────────────────────

const CustomBouquetBuilder: React.FC<CustomBouquetBuilderProps> = ({
  orderId,
  onItemAdded,
}) => {
  const theme = useTheme();
  const { loading: fetching, execute: fetchExec } = useApiCall();
  const { loading: adding, execute: addExec } = useApiCall();

  const [flowers, setFlowers] = useState<AvailableFlowerResponse[]>([]);
  const [selected, setSelected] = useState<AvailableFlowerResponse | null>(null);
  const [quantity, setQuantity] = useState('1');

  // ── Load flowers ─────────────────────────────────────────────────────

  const loadFlowers = async () => {
    const data = await fetchExec(() => getAvailableFlowers(), {
      errorMessage: 'Failed to load available flowers',
    });
    if (data) setFlowers(data);
  };

  useEffect(() => {
    loadFlowers();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ── Quantity helpers ─────────────────────────────────────────────────

  const parsedQty = parseInt(quantity, 10);
  const validQty = !isNaN(parsedQty) && parsedQty >= 1;
  const exceedsStock = selected ? validQty && parsedQty > selected.availableUnits : false;

  // ── Handlers ─────────────────────────────────────────────────────────

  const handleFlowerClick = (flower: AvailableFlowerResponse) => {
    setSelected(flower);
    setQuantity('1');
  };

  const handleDialogClose = () => {
    if (adding) return;
    setSelected(null);
  };

  const handleAdd = async () => {
    if (!selected || !validQty || exceedsStock) return;

    const result = await addExec(
      () =>
        addItemToPhoneOrder(orderId, {
          productId: selected.productId,
          quantity: parsedQty,
          unitPrice: selected.unitPrice,
        }),
      {
        successMessage: `Added ${parsedQty} ${selected.consumptionUnit} of ${selected.productName}`,
        errorMessage: 'Failed to add item',
      },
    );

    if (result) {
      setSelected(null);
      onItemAdded();
    }
    // On failure: dialog stays open, error toast shown automatically by useApiCall
  };

  // ── Render ───────────────────────────────────────────────────────────

  return (
    <Box>
      <Typography variant="h6" sx={{ mb: 2, fontWeight: 700 }}>
        <FlowerIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
        Available Flowers
      </Typography>

      {fetching ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', py: 4 }}>
          <CircularProgress />
        </Box>
      ) : flowers.length === 0 ? (
        <Typography variant="body2" color="text.secondary" sx={{ py: 4, textAlign: 'center' }}>
          No flowers available in inventory.
        </Typography>
      ) : (
        <TableContainer component={Paper} variant="outlined">
          <Table size="small">
            <TableHead>
              <TableRow
                sx={{
                  bgcolor: alpha(theme.palette.primary.main, 0.06),
                }}
              >
                <TableCell sx={{ fontWeight: 700 }}>Flower</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>Available</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>Unit Price</TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>Action</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {flowers.map((f) => (
                <TableRow
                  key={f.productId}
                  hover
                  sx={{ cursor: 'pointer' }}
                  onClick={() => handleFlowerClick(f)}
                >
                  <TableCell>{f.productName}</TableCell>
                  <TableCell align="right">
                    {f.availableUnits} {f.consumptionUnit}
                  </TableCell>
                  <TableCell align="right">{formatCurrency(f.unitPrice)}</TableCell>
                  <TableCell align="center">
                    <Button
                      size="small"
                      variant="outlined"
                      startIcon={<AddIcon />}
                      onClick={(e) => {
                        e.stopPropagation();
                        handleFlowerClick(f);
                      }}
                      sx={{ textTransform: 'none' }}
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

      {/* ── Quantity dialog ─────────────────────────────────────────── */}

      <Dialog open={!!selected} onClose={handleDialogClose} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>
          Add {selected?.productName}
        </DialogTitle>

        <DialogContent sx={{ pt: '16px !important' }}>
          <TextField
            label={`Quantity (${selected?.consumptionUnit ?? 'units'})`}
            type="number"
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            size="small"
            fullWidth
            autoFocus
            inputProps={{ min: 1 }}
            error={exceedsStock || (quantity !== '' && !validQty)}
            helperText={
              exceedsStock
                ? `Only ${selected?.availableUnits} ${selected?.consumptionUnit} available`
                : quantity !== '' && !validQty
                  ? 'Enter a valid quantity (min 1)'
                  : `Available: ${selected?.availableUnits ?? 0} ${selected?.consumptionUnit ?? ''}`
            }
          />
        </DialogContent>

        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button
            onClick={handleDialogClose}
            disabled={adding}
            sx={{ textTransform: 'none' }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleAdd}
            disabled={adding || !validQty || exceedsStock}
            startIcon={adding ? <CircularProgress size={16} /> : <AddIcon />}
            sx={{ textTransform: 'none', fontWeight: 700 }}
          >
            Add to Order
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default CustomBouquetBuilder;
