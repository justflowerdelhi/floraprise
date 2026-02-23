import React, { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Chip,
  Button,
  CircularProgress,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Divider,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  alpha,
  useTheme,
} from '@mui/material';
import {
  CheckCircle as ConfirmIcon,
  Cancel as CancelIcon,
  Build as ProductionIcon,
  Refresh as RefreshIcon,
} from '@mui/icons-material';
import { useParams } from 'react-router-dom';
import { useToast } from '../../hooks/useToast';
import { useApiCall } from '../../hooks/useApiCall';
import {
  getPhoneOrder,
  confirmPhoneLocalOrder,
  confirmPhoneOutstationOrder,
  cancelPhoneLocalOrder,
  startProductionForPhoneLocalOrder,
} from '../../api/phoneOrders.api';

// ── Types ────────────────────────────────────────────────────────────────

type SalesOrderStatus = 'Draft' | 'Confirmed' | 'InProduction' | 'SentToVendor' | 'Delivered' | 'Cancelled';
type OrderType = 'PhoneLocal' | 'PhoneOutstation';

interface SalesOrderItem {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  totalPrice: number;
}

interface SalesOrder {
  id: string;
  companyId: string;
  customerId: string;
  orderNumber: string;
  orderType: OrderType;
  status: SalesOrderStatus;
  items: SalesOrderItem[];
  createdAtUtc: string;
  updatedAtUtc?: string;
}

// ── Status badge config ──────────────────────────────────────────────────

const STATUS_CONFIG: Record<SalesOrderStatus, { label: string; color: string }> = {
  Draft: { label: 'Draft', color: '#2196f3' },
  Confirmed: { label: 'Confirmed', color: '#ff9800' },
  InProduction: { label: 'In Production', color: '#9c27b0' },
  SentToVendor: { label: 'Sent to Vendor', color: '#00bcd4' },
  Delivered: { label: 'Delivered', color: '#4caf50' },
  Cancelled: { label: 'Cancelled', color: '#9e9e9e' },
};

// ── Component ────────────────────────────────────────────────────────────

const PhoneOrderPage: React.FC = () => {
  const { orderId } = useParams<{ orderId: string }>();
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bg = dk ? '#0f0f0f' : '#f8f9fa';
  const toast = useToast();
  const { loading, execute } = useApiCall();

  const [order, setOrder] = useState<SalesOrder | null>(null);
  const [fetching, setFetching] = useState(true);

  // Vendor assignment modal state
  const [vendorModalOpen, setVendorModalOpen] = useState(false);
  const [vendorId, setVendorId] = useState('');
  const [vendorCost, setVendorCost] = useState('');
  const [deliveryCharge, setDeliveryCharge] = useState('');

  // ── Fetch order ──────────────────────────────────────────────────────

  const loadOrder = useCallback(async () => {
    if (!orderId) return;
    setFetching(true);
    try {
      const data = await getPhoneOrder(orderId);
      setOrder(data);
    } catch {
      toast.error('Failed to load order');
    } finally {
      setFetching(false);
    }
  }, [orderId, toast]);

  useEffect(() => {
    loadOrder();
  }, [loadOrder]);

  // ── Actions ──────────────────────────────────────────────────────────

  const handleConfirm = async () => {
    if (!order) return;

    if (order.orderType === 'PhoneOutstation') {
      setVendorModalOpen(true);
      return;
    }

    await execute(
      () => confirmPhoneLocalOrder(order.id),
      { successMessage: 'Order confirmed', errorMessage: 'Failed to confirm order' },
    );
    await loadOrder();
  };

  const handleVendorConfirm = async () => {
    if (!order) return;
    if (!vendorId.trim()) {
      toast.error('Vendor ID is required');
      return;
    }

    const cost = parseFloat(vendorCost) || 0;
    const delivery = parseFloat(deliveryCharge) || 0;

    await execute(
      () => confirmPhoneOutstationOrder({
        salesOrderId: order.id,
        vendorId: vendorId.trim(),
        vendorCost: cost,
        deliveryCharge: delivery,
      }),
      { successMessage: 'Outstation order confirmed', errorMessage: 'Failed to confirm outstation order' },
    );

    setVendorModalOpen(false);
    setVendorId('');
    setVendorCost('');
    setDeliveryCharge('');
    await loadOrder();
  };

  const handleStartProduction = async () => {
    if (!order) return;
    await execute(
      () => startProductionForPhoneLocalOrder(order.id),
      { successMessage: 'Production started', errorMessage: 'Failed to start production' },
    );
    await loadOrder();
  };

  const handleCancel = async () => {
    if (!order) return;
    await execute(
      () => cancelPhoneLocalOrder(order.id),
      { successMessage: 'Order cancelled', errorMessage: 'Failed to cancel order' },
    );
    await loadOrder();
  };

  // ── Loading state ────────────────────────────────────────────────────

  if (fetching) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
        <CircularProgress />
      </Box>
    );
  }

  if (!order) {
    return (
      <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
        <Typography variant="h5" sx={{ fontWeight: 700 }}>Order not found</Typography>
      </Box>
    );
  }

  // ── Derived state ────────────────────────────────────────────────────

  const statusCfg = STATUS_CONFIG[order.status] ?? { label: order.status, color: '#757575' };
  const isLocal = order.orderType === 'PhoneLocal';
  const isDraft = order.status === 'Draft';
  const isConfirmed = order.status === 'Confirmed';
  const isDelivered = order.status === 'Delivered';
  const isCancelled = order.status === 'Cancelled';

  const showConfirm = isDraft;
  const showStartProduction = isConfirmed && isLocal;
  const showCancel = !isDelivered && !isCancelled;

  const subtotal = order.items.reduce((sum, i) => sum + i.totalPrice, 0);

  // ── Render ───────────────────────────────────────────────────────────

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 1, flexWrap: 'wrap' }}>
        <Typography variant="h4" sx={{ fontWeight: 800 }}>
          {order.orderNumber}
        </Typography>
        <Chip
          label={statusCfg.label}
          size="small"
          sx={{
            bgcolor: alpha(statusCfg.color, dk ? 0.25 : 0.12),
            color: statusCfg.color,
            fontWeight: 700,
            fontSize: '0.7rem',
          }}
        />
        <Chip
          label={isLocal ? 'Phone Local' : 'Phone Outstation'}
          size="small"
          variant="outlined"
          sx={{ fontWeight: 600, fontSize: '0.7rem' }}
        />
      </Box>
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}>
        Created {new Date(order.createdAtUtc).toLocaleString()}
      </Typography>

      {/* Action buttons */}
      <Paper
        elevation={dk ? 0 : 1}
        sx={{
          p: 2, mb: 3, borderRadius: 2,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          display: 'flex', gap: 1, flexWrap: 'wrap', alignItems: 'center',
        }}
      >
        <Button
          size="small"
          variant="outlined"
          startIcon={<RefreshIcon />}
          onClick={loadOrder}
          disabled={loading}
          sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 36 }}
        >
          Refresh
        </Button>

        {showConfirm && (
          <Button
            size="small"
            variant="outlined"
            color="success"
            startIcon={loading ? <CircularProgress size={16} /> : <ConfirmIcon />}
            onClick={handleConfirm}
            disabled={loading}
            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 36 }}
          >
            Confirm Order
          </Button>
        )}

        {showStartProduction && (
          <Button
            size="small"
            variant="outlined"
            color="info"
            startIcon={loading ? <CircularProgress size={16} /> : <ProductionIcon />}
            onClick={handleStartProduction}
            disabled={loading}
            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 36 }}
          >
            Start Production
          </Button>
        )}

        {showCancel && (
          <Button
            size="small"
            variant="outlined"
            color="error"
            startIcon={loading ? <CircularProgress size={16} /> : <CancelIcon />}
            onClick={handleCancel}
            disabled={loading}
            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 36 }}
          >
            Cancel Order
          </Button>
        )}
      </Paper>

      {/* Vendor Assignment Modal */}
      <Dialog
        open={vendorModalOpen}
        onClose={() => !loading && setVendorModalOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle sx={{ fontWeight: 700 }}>Assign Vendor</DialogTitle>
        <DialogContent sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: '16px !important' }}>
          <TextField
            label="Vendor ID"
            value={vendorId}
            onChange={(e) => setVendorId(e.target.value)}
            required
            size="small"
            fullWidth
          />
          <TextField
            label="Vendor Cost"
            type="number"
            value={vendorCost}
            onChange={(e) => setVendorCost(e.target.value)}
            size="small"
            fullWidth
            inputProps={{ min: 0, step: '0.01' }}
          />
          <TextField
            label="Delivery Charge"
            type="number"
            value={deliveryCharge}
            onChange={(e) => setDeliveryCharge(e.target.value)}
            size="small"
            fullWidth
            inputProps={{ min: 0, step: '0.01' }}
          />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button
            onClick={() => setVendorModalOpen(false)}
            disabled={loading}
            sx={{ textTransform: 'none' }}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            color="success"
            onClick={handleVendorConfirm}
            disabled={loading || !vendorId.trim()}
            startIcon={loading ? <CircularProgress size={16} /> : <ConfirmIcon />}
            sx={{ textTransform: 'none', fontWeight: 700 }}
          >
            Confirm &amp; Assign
          </Button>
        </DialogActions>
      </Dialog>

      {/* Order items */}
      <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
        Order Items
      </Typography>

      <TableContainer
        component={Paper}
        elevation={dk ? 0 : 1}
        sx={{
          bgcolor: dk ? '#0f0f0f' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          borderRadius: 2, mb: 3,
        }}
      >
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell sx={{ fontWeight: 700 }}>Product</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>Qty</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>Unit Price</TableCell>
              <TableCell align="right" sx={{ fontWeight: 700 }}>Total</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {order.items.length === 0 ? (
              <TableRow>
                <TableCell colSpan={4} align="center" sx={{ py: 4, color: 'text.secondary' }}>
                  No items added yet
                </TableCell>
              </TableRow>
            ) : (
              order.items.map((item) => (
                <TableRow key={item.id}>
                  <TableCell>{item.productName}</TableCell>
                  <TableCell align="right">{item.quantity}</TableCell>
                  <TableCell align="right">${item.unitPrice.toFixed(2)}</TableCell>
                  <TableCell align="right">${item.totalPrice.toFixed(2)}</TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Subtotal */}
      {order.items.length > 0 && (
        <Paper
          elevation={dk ? 0 : 1}
          sx={{
            p: 2, borderRadius: 2,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            display: 'flex', justifyContent: 'flex-end', gap: 2,
          }}
        >
          <Divider />
          <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
            Subtotal: ${subtotal.toFixed(2)}
          </Typography>
        </Paper>
      )}
    </Box>
  );
};

export default PhoneOrderPage;
