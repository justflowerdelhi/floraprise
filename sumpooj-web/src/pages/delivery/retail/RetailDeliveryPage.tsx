/**
 * RetailDeliveryPage.tsx — Floraprise ERP Retail Delivery Hub
 *
 * Streamlined, florist-centric delivery operations screen:
 * - Direct driver dispatch & status transitions
 * - Thermal packing slip and gift card printing
 * - One-click WhatsApp & Maps navigation
 * - Filter by date & delivery status
 * - View continuity with Professional Delivery Control Center
 */

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  CircularProgress,
  Snackbar,
  Alert,
  Paper,
  Chip,
  Tooltip,
  useTheme,
  alpha,
} from '@mui/material';
import {
  LocalShipping as DeliveryIcon,
  Dashboard as ErpIcon,
  CheckCircle as CheckCircleIcon,
  Schedule as ScheduleIcon,
} from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { useOperationalView } from '../../../core/tenant';
import {
  fetchRetailDeliveries,
  fetchRetailDeliveryDrivers,
  assignDeliveryDriver,
  markDeliveryOutForDelivery,
  markDeliveryDelivered,
} from './retailDelivery.api';
import type {
  RetailDeliveryItem,
  RetailDeliveryDriver,
  DeliveryFilterStatus,
  DeliveryDateFilter,
} from './retailDelivery.types';
import { RetailDeliveryFilterBar } from './RetailDeliveryFilterBar';
import { RetailDeliveryCard } from './RetailDeliveryCard';
import { RetailDeliverySlipModal } from './RetailDeliverySlipModal';

export const RetailDeliveryPage: React.FC = () => {
  const theme = useTheme();
  const navigate = useNavigate();
  const { setView } = useOperationalView();

  // Data state
  const [deliveries, setDeliveries] = useState<RetailDeliveryItem[]>([]);
  const [drivers, setDrivers] = useState<RetailDeliveryDriver[]>([]);
  const [loading, setLoading] = useState(true);

  // Filter state
  const [statusFilter, setStatusFilter] = useState<DeliveryFilterStatus>('ALL');
  const [dateFilter, setDateFilter] = useState<DeliveryDateFilter>('TODAY');
  const [searchQuery, setSearchQuery] = useState('');

  // Slip modal state
  const [slipModalOpen, setSlipModalOpen] = useState(false);
  const [selectedSlipDelivery, setSelectedSlipDelivery] = useState<RetailDeliveryItem | null>(null);

  // Notifications
  const [snackbar, setSnackbar] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'info' | 'warning' | 'error';
  }>({
    open: false,
    message: '',
    severity: 'info',
  });

  const showNotification = (
    message: string,
    severity: 'success' | 'info' | 'warning' | 'error' = 'info'
  ) => {
    setSnackbar({ open: true, message, severity });
  };

  // Load Drivers
  const loadDrivers = useCallback(async () => {
    try {
      const driverList = await fetchRetailDeliveryDrivers();
      setDrivers(driverList);
    } catch (err: any) {
      console.error('Failed to load delivery drivers:', err);
    }
  }, []);

  // Compute query date string based on date filter
  const targetDateString = useMemo(() => {
    const today = new Date();
    if (dateFilter === 'TODAY') {
      return today.toISOString().split('T')[0];
    }
    if (dateFilter === 'TOMORROW') {
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);
      return tomorrow.toISOString().split('T')[0];
    }
    return undefined; // ALL_ACTIVE
  }, [dateFilter]);

  // Load Deliveries
  const loadDeliveries = useCallback(async () => {
    setLoading(true);
    try {
      const list = await fetchRetailDeliveries({
        date: targetDateString,
      });
      setDeliveries(list);
    } catch (err: any) {
      showNotification(
        err.response?.data?.message || err.message || 'Failed to load deliveries',
        'error'
      );
    } finally {
      setLoading(false);
    }
  }, [targetDateString]);

  useEffect(() => {
    loadDrivers();
  }, [loadDrivers]);

  useEffect(() => {
    loadDeliveries();
  }, [loadDeliveries]);

  // Filter & Search computation
  const filteredDeliveries = useMemo(() => {
    return deliveries.filter((item) => {
      // Status filter
      if (statusFilter === 'SCHEDULED' && item.status !== 'Scheduled') return false;
      if (statusFilter === 'OUT_FOR_DELIVERY' && item.status !== 'OutForDelivery') return false;
      if (statusFilter === 'DELIVERED' && item.status !== 'Delivered') return false;

      // Search query filter
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase().trim();
        const matchName = item.recipientName.toLowerCase().includes(query);
        const matchCustomer = item.customerName.toLowerCase().includes(query);
        const matchPhone = (item.recipientPhone || item.phone || '').includes(query);
        const matchOrder = item.orderNumber.toLowerCase().includes(query);
        const matchAddress = item.address.toLowerCase().includes(query);
        if (!matchName && !matchCustomer && !matchPhone && !matchOrder && !matchAddress) {
          return false;
        }
      }

      return true;
    });
  }, [deliveries, statusFilter, searchQuery]);

  // Counts for tabs & badges
  const counts = useMemo(() => {
    let scheduled = 0;
    let outForDelivery = 0;
    let delivered = 0;

    deliveries.forEach((d) => {
      if (d.status === 'Scheduled') scheduled++;
      else if (d.status === 'OutForDelivery') outForDelivery++;
      else if (d.status === 'Delivered') delivered++;
    });

    return {
      all: deliveries.length,
      scheduled,
      outForDelivery,
      delivered,
    };
  }, [deliveries]);

  // Driver Assignment Handler
  const handleAssignDriver = async (deliveryId: string, staffId: string) => {
    try {
      const result = await assignDeliveryDriver(deliveryId, staffId);
      showNotification(
        result.driverName ? `Driver ${result.driverName} assigned` : 'Driver assigned successfully',
        'success'
      );
      await loadDeliveries();
    } catch (err: any) {
      showNotification(
        err.response?.data?.message || err.message || 'Failed to assign driver',
        'error'
      );
    }
  };

  // Dispatch Out Handler
  const handleDispatchOut = async (deliveryId: string) => {
    try {
      await markDeliveryOutForDelivery(deliveryId);
      showNotification('Delivery dispatched out for delivery', 'success');
      await loadDeliveries();
    } catch (err: any) {
      showNotification(
        err.response?.data?.message || err.message || 'Failed to dispatch delivery',
        'error'
      );
    }
  };

  // Mark Delivered Handler
  const handleMarkDelivered = async (deliveryId: string) => {
    try {
      await markDeliveryDelivered(deliveryId);
      showNotification('Delivery marked as completed and inventory settled', 'success');
      await loadDeliveries();
    } catch (err: any) {
      showNotification(
        err.response?.data?.message || err.message || 'Failed to complete delivery',
        'error'
      );
    }
  };

  // Slip print handler
  const handlePrintSlip = (delivery: RetailDeliveryItem) => {
    setSelectedSlipDelivery(delivery);
    setSlipModalOpen(true);
  };

  const handleSwitchToProfessional = () => {
    setView('PROFESSIONAL');
    navigate('/delivery/control-center');
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1400, margin: '0 auto' }}>
      {/* Page Header */}
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          mb: 3,
          flexWrap: 'wrap',
          gap: 2,
        }}
      >
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <DeliveryIcon color="primary" sx={{ fontSize: 32 }} />
            <Typography variant="h5" sx={{ fontWeight: 800 }}>
              Retail Delivery Hub
            </Typography>
            <Chip
              label="Retail View"
              color="primary"
              variant="outlined"
              size="small"
              sx={{ fontWeight: 700 }}
            />
          </Box>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            Manage daily florist dispatches, driver routes, gift messages, and proof of delivery.
          </Typography>
        </Box>

        {/* Action button to switch to Professional Control Center */}
        <Tooltip title="Switch to Enterprise Delivery Operations Control Center">
          <Button
            variant="outlined"
            color="inherit"
            startIcon={<ErpIcon />}
            onClick={handleSwitchToProfessional}
            sx={{ fontWeight: 600, textTransform: 'none' }}
          >
            Switch to ERP View
          </Button>
        </Tooltip>
      </Box>

      {/* Filter Bar */}
      <RetailDeliveryFilterBar
        statusFilter={statusFilter}
        onStatusFilterChange={setStatusFilter}
        dateFilter={dateFilter}
        onDateFilterChange={setDateFilter}
        searchQuery={searchQuery}
        onSearchQueryChange={setSearchQuery}
        counts={counts}
        onRefresh={loadDeliveries}
        loading={loading}
      />

      {/* Delivery Cards Grid */}
      {loading ? (
        <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', py: 10 }}>
          <CircularProgress />
        </Box>
      ) : filteredDeliveries.length === 0 ? (
        <Paper
          elevation={0}
          sx={{
            py: 8,
            px: 3,
            textAlign: 'center',
            borderRadius: 2,
            border: `1px dashed ${theme.palette.divider}`,
            bgcolor: 'background.paper',
          }}
        >
          <DeliveryIcon sx={{ fontSize: 48, color: 'text.disabled', mb: 1.5 }} />
          <Typography variant="h6" sx={{ fontWeight: 700, color: 'text.secondary' }}>
            No deliveries found
          </Typography>
          <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.5 }}>
            {searchQuery
              ? `No deliveries matching "${searchQuery}"`
              : `No ${statusFilter.toLowerCase().replace('_', ' ')} deliveries scheduled for this period.`}
          </Typography>
        </Paper>
      ) : (
        <Grid container spacing={2.5}>
          {filteredDeliveries.map((delivery) => (
            <Grid key={delivery.deliveryId} size={{ xs: 12, sm: 6, md: 4 }}>
              <RetailDeliveryCard
                delivery={delivery}
                drivers={drivers}
                onAssignDriver={handleAssignDriver}
                onDispatchOut={handleDispatchOut}
                onMarkDelivered={handleMarkDelivered}
                onPrintSlip={handlePrintSlip}
                loading={loading}
              />
            </Grid>
          ))}
        </Grid>
      )}

      {/* Printable Delivery & Gift Slip Modal */}
      <RetailDeliverySlipModal
        open={slipModalOpen}
        onClose={() => setSlipModalOpen(false)}
        delivery={selectedSlipDelivery}
      />

      {/* Notification Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert
          severity={snackbar.severity}
          onClose={() => setSnackbar((s) => ({ ...s, open: false }))}
          sx={{ fontWeight: 600 }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default RetailDeliveryPage;
