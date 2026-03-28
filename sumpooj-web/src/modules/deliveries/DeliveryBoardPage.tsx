import React, { useState, useEffect, useCallback } from 'react';
import {
  Alert,
  Box,
  Button,
  Card,
  CardContent,
  Chip,
  CircularProgress,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  FormControl,
  Grid,
  IconButton,
  InputLabel,
  MenuItem,
  Select,
  Tooltip,
  Typography,
  useTheme,
  alpha,
} from '@mui/material';
import {
  LocalShipping as TruckIcon,
  CheckCircle as DeliveredIcon,
  Schedule as ScheduledIcon,
  AccessTime as TimeIcon,
  Place as PlaceIcon,
  PersonAdd as AssignIcon,
} from '@mui/icons-material';
import { useToast } from '../../hooks/useToast';
import {
  getDeliveries,
  markOutForDelivery,
  markDelivered,
  assignDeliveryPerson,
  getDeliveryStaff,
  type DeliveryListItem,
  type StaffOption,
} from './delivery.api';

// ── Column config ────────────────────────────────────────────────────────

type StatusColumn = 'Scheduled' | 'OutForDelivery' | 'Delivered';

const COLUMNS: { key: StatusColumn; label: string; color: string; icon: React.ReactNode }[] = [
  { key: 'Scheduled', label: 'Scheduled', color: '#2196f3', icon: <ScheduledIcon /> },
  { key: 'OutForDelivery', label: 'Out for Delivery', color: '#ff9800', icon: <TruckIcon /> },
  { key: 'Delivered', label: 'Delivered', color: '#4caf50', icon: <DeliveredIcon /> },
];

// ── Helpers ──────────────────────────────────────────────────────────────

const shortenAddress = (address: string, maxLen = 40) =>
  address.length > maxLen ? address.slice(0, maxLen) + '…' : address;

const formatLocalDate = (date = new Date()) => {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
};

// ── Component ────────────────────────────────────────────────────────────

const DeliveryBoardPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const toast = useToast();

  const [deliveries, setDeliveries] = useState<DeliveryListItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [actionId, setActionId] = useState<string | null>(null);

  // Assign dialog state
  const [assignDialogOpen, setAssignDialogOpen] = useState(false);
  const [assignDeliveryId, setAssignDeliveryId] = useState<string | null>(null);
  const [selectedStaffId, setSelectedStaffId] = useState('');
  const [staffList, setStaffList] = useState<StaffOption[]>([]);
  const [loadingStaff, setLoadingStaff] = useState(false);
  const [assigning, setAssigning] = useState(false);

  // ── Fetch ────────────────────────────────────────────────────────────
  const fetchDeliveries = useCallback(async () => {
    setLoading(true);
    try {
      const data = await getDeliveries(formatLocalDate());
      setDeliveries(data);
    } catch (err) {
      console.error('Failed to load deliveries:', err);
      toast.error('Failed to load deliveries');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchDeliveries();
  }, [fetchDeliveries]);

  // ── Group by status ──────────────────────────────────────────────────
  const grouped: Record<StatusColumn, DeliveryListItem[]> = {
    Scheduled: deliveries.filter((d) => d.status === 'Scheduled'),
    OutForDelivery: deliveries.filter((d) => d.status === 'OutForDelivery'),
    Delivered: deliveries.filter((d) => d.status === 'Delivered'),
  };

  // ── Actions ──────────────────────────────────────────────────────────
  const handleOutForDelivery = async (id: string) => {
    setActionId(id);
    try {
      await markOutForDelivery(id);
      toast.success('Marked out for delivery');
      await fetchDeliveries();
    } catch {
      toast.error('Failed to update status');
    } finally {
      setActionId(null);
    }
  };

  const handleMarkDelivered = async (id: string) => {
    setActionId(id);
    try {
      await markDelivered(id);
      toast.success('Marked as delivered');
      await fetchDeliveries();
    } catch {
      toast.error('Failed to update status');
    } finally {
      setActionId(null);
    }
  };

  // ── Assign dialog ────────────────────────────────────────────────────
  const openAssignDialog = async (deliveryId: string) => {
    setAssignDeliveryId(deliveryId);
    setSelectedStaffId('');
    setAssignDialogOpen(true);
    setLoadingStaff(true);
    try {
      const staff = await getDeliveryStaff();
      setStaffList(staff);
    } catch {
      toast.error('Failed to load staff');
    } finally {
      setLoadingStaff(false);
    }
  };

  const handleAssignConfirm = async () => {
    if (!assignDeliveryId || !selectedStaffId) return;
    setAssigning(true);
    try {
      await assignDeliveryPerson(assignDeliveryId, selectedStaffId);
      toast.success('Delivery person assigned');
      setAssignDialogOpen(false);
      await fetchDeliveries();
    } catch {
      toast.error('Failed to assign delivery person');
    } finally {
      setAssigning(false);
    }
  };

  // ── Render ───────────────────────────────────────────────────────────
  if (loading) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', py: 10 }}>
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          Delivery Board
        </Typography>
        <Typography variant="body2" color="text.secondary">
          Today's deliveries &middot; {deliveries.length} total
        </Typography>
      </Box>

      {/* Unassigned warning */}
      {(() => {
        const unassignedCount = deliveries.filter((d) => !d.deliveryPersonName && d.status !== 'Delivered' && d.status !== 'Cancelled').length;
        return unassignedCount > 0 ? (
          <Alert severity="warning" sx={{ mb: 2 }}>
            {unassignedCount} {unassignedCount === 1 ? 'delivery is' : 'deliveries are'} unassigned
          </Alert>
        ) : null;
      })()}

      {/* Board columns */}
      <Grid container spacing={2.5}>
        {COLUMNS.map((col) => {
          const items = grouped[col.key];
          return (
            <Grid size={{ xs: 12, md: 4 }} key={col.key}>
              {/* Column header */}
              <Box
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 1,
                  mb: 2,
                  px: 1.5,
                  py: 1,
                  borderRadius: 2,
                  bgcolor: alpha(col.color, dk ? 0.15 : 0.08),
                }}
              >
                <Box sx={{ color: col.color, display: 'flex' }}>{col.icon}</Box>
                <Typography variant="subtitle1" sx={{ fontWeight: 700, flex: 1 }}>
                  {col.label}
                </Typography>
                <Chip
                  label={items.length}
                  size="small"
                  sx={{
                    fontWeight: 700,
                    bgcolor: alpha(col.color, dk ? 0.3 : 0.15),
                    color: col.color,
                  }}
                />
              </Box>

              {/* Cards */}
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5, minHeight: 120 }}>
                {items.length === 0 && (
                  <Typography
                    variant="body2"
                    sx={{ textAlign: 'center', py: 4, color: 'text.disabled' }}
                  >
                    No deliveries
                  </Typography>
                )}

                {items.map((d) => (
                  <Card
                    key={d.deliveryId}
                    variant="outlined"
                    sx={{
                      borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
                      borderRadius: 2,
                      bgcolor: dk ? alpha(theme.palette.grey[800], 0.5) : '#fff',
                    }}
                  >
                    <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
                      {/* Order number & customer */}
                      <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>
                        {d.orderNumber}
                      </Typography>
                      <Typography variant="body2" sx={{ mb: 1 }}>
                        {d.customerName}
                      </Typography>

                      {/* Time slot */}
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
                        <TimeIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
                        <Typography variant="caption" color="text.secondary">
                          {d.timeSlot}
                        </Typography>
                      </Box>

                      {/* Address */}
                      <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 0.5, mb: d.postalCode ? 0.5 : 1 }}>
                        <PlaceIcon sx={{ fontSize: 14, color: 'text.secondary', mt: 0.2 }} />
                        <Typography variant="caption" color="text.secondary">
                          {shortenAddress(d.address)}
                        </Typography>
                      </Box>

                      {/* Postal code */}
                      {d.postalCode && (
                        <Typography variant="caption" sx={{ color: 'text.secondary', pl: 2.5, display: 'block', mb: 1 }}>
                          PIN: {d.postalCode}
                        </Typography>
                      )}

                      {/* Assigned person chip + assign button */}
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 1.5 }}>
                        {d.deliveryPersonName ? (
                          <Chip
                            label={`Assigned: ${d.deliveryPersonName}`}
                            size="small"
                            color="success"
                            variant="outlined"
                            sx={{ fontSize: 11, height: 22, flex: 1, justifyContent: 'flex-start' }}
                          />
                        ) : (
                          <Chip
                            label="Unassigned"
                            size="small"
                            color="warning"
                            variant="outlined"
                            sx={{ fontSize: 11, height: 22, flex: 1, justifyContent: 'flex-start' }}
                          />
                        )}
                        {col.key !== 'Delivered' && (
                          <Tooltip title="Assign delivery person">
                            <IconButton
                              size="small"
                              onClick={() => openAssignDialog(d.deliveryId)}
                              sx={{ p: 0.5 }}
                            >
                              <AssignIcon sx={{ fontSize: 16 }} />
                            </IconButton>
                          </Tooltip>
                        )}
                      </Box>

                      {/* Action buttons */}
                      {col.key === 'Scheduled' && (
                        <Button
                          size="small"
                          variant="contained"
                          fullWidth
                          startIcon={
                            actionId === d.deliveryId ? (
                              <CircularProgress size={14} color="inherit" />
                            ) : (
                              <TruckIcon sx={{ fontSize: 16 }} />
                            )
                          }
                          disabled={actionId === d.deliveryId}
                          onClick={() => handleOutForDelivery(d.deliveryId)}
                          sx={{
                            textTransform: 'none',
                            fontWeight: 600,
                            bgcolor: '#ff9800',
                            '&:hover': { bgcolor: '#f57c00' },
                          }}
                        >
                          Out for Delivery
                        </Button>
                      )}

                      {col.key === 'OutForDelivery' && (
                        <Button
                          size="small"
                          variant="contained"
                          fullWidth
                          startIcon={
                            actionId === d.deliveryId ? (
                              <CircularProgress size={14} color="inherit" />
                            ) : (
                              <DeliveredIcon sx={{ fontSize: 16 }} />
                            )
                          }
                          disabled={actionId === d.deliveryId}
                          onClick={() => handleMarkDelivered(d.deliveryId)}
                          sx={{
                            textTransform: 'none',
                            fontWeight: 600,
                            bgcolor: '#4caf50',
                            '&:hover': { bgcolor: '#388e3c' },
                          }}
                        >
                          Mark Delivered
                        </Button>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </Box>
            </Grid>
          );
        })}
      </Grid>

      {/* Assign Delivery Person Dialog */}
      <Dialog
        open={assignDialogOpen}
        onClose={() => setAssignDialogOpen(false)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>Assign Delivery Person</DialogTitle>
        <DialogContent>
          {loadingStaff ? (
            <Box sx={{ display: 'flex', justifyContent: 'center', py: 3 }}>
              <CircularProgress size={28} />
            </Box>
          ) : (
            <FormControl fullWidth sx={{ mt: 1 }}>
              <InputLabel>Select Staff</InputLabel>
              <Select
                value={selectedStaffId}
                label="Select Staff"
                onChange={(e) => setSelectedStaffId(e.target.value)}
              >
                {staffList.map((s) => (
                  <MenuItem key={s.id} value={s.id}>
                    {s.name}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAssignDialogOpen(false)}>Cancel</Button>
          <Button
            variant="contained"
            disabled={!selectedStaffId || assigning}
            onClick={handleAssignConfirm}
            startIcon={assigning ? <CircularProgress size={14} color="inherit" /> : undefined}
          >
            Assign
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default DeliveryBoardPage;
