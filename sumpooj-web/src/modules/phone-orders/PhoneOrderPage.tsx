import React, { useCallback, useEffect, useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Chip,
  Button,
  CircularProgress,
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
  type PhoneOrderResponse,
} from './phoneOrders.api';

// ── Status badge config ──────────────────────────────────────────────────

const STATUS_CONFIG: Record<string, { label: string; color: string }> = {
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

  const [order, setOrder] = useState<PhoneOrderResponse | null>(null);
  const [fetching, setFetching] = useState(true);
  const [vendorModalOpen, setVendorModalOpen] = useState(false);

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

  // ── Loading ──────────────────────────────────────────────────────────

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

  // ── Render ───────────────────────────────────────────────────────────

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      {/* ── Header ──────────────────────────────────────────────────── */}
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

      {/* ── Delivery summary ────────────────────────────────────────── */}
      <Paper
        elevation={dk ? 0 : 1}
        sx={{
          p: 2, mb: 3, borderRadius: 2,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
        }}
      >
        <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>Delivery Details</Typography>
        <Box sx={{ display: 'flex', gap: 4, flexWrap: 'wrap' }}>
          <Box>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>Delivery Date</Typography>
            <Typography variant="body2" sx={{ fontWeight: 600 }}>
              {order.deliveryDate ? new Date(order.deliveryDate).toLocaleDateString() : '—'}
            </Typography>
          </Box>
          <Box>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>City</Typography>
            <Typography variant="body2" sx={{ fontWeight: 600 }}>{order.deliveryCity || '—'}</Typography>
          </Box>
          {order.occasion && (
            <Box>
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>Occasion</Typography>
              <Typography variant="body2" sx={{ fontWeight: 600 }}>{order.occasion}</Typography>
            </Box>
          )}
          {order.budget != null && (
            <Box>
              <Typography variant="caption" sx={{ color: 'text.secondary' }}>Budget</Typography>
              <Typography variant="body2" sx={{ fontWeight: 600 }}>${order.budget.toFixed(2)}</Typography>
            </Box>
          )}
        </Box>
      </Paper>

      {/* ── Action buttons ──────────────────────────────────────────── */}
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

      {/* ── Order items (placeholder) ───────────────────────────────── */}
      <Paper
        elevation={dk ? 0 : 1}
        sx={{
          p: 3, borderRadius: 2,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
        }}
      >
        <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>Order Items</Typography>
        {order.items.length === 0 ? (
          <Typography variant="body2" sx={{ color: 'text.secondary', py: 2, textAlign: 'center' }}>
            No items added yet
          </Typography>
        ) : (
          <Box component="ul" sx={{ pl: 2, m: 0 }}>
            {order.items.map((item) => (
              <Typography component="li" variant="body2" key={item.id} sx={{ mb: 0.5 }}>
                {item.productName} — {item.quantity} × ${item.unitPrice.toFixed(2)} = ${item.totalPrice.toFixed(2)}
              </Typography>
            ))}
          </Box>
        )}
      </Paper>
    </Box>
  );
};

export default PhoneOrderPage;
