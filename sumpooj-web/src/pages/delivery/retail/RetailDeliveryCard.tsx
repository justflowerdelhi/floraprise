/**
 * RetailDeliveryCard.tsx — Card component for individual Retail Delivery item
 */

import React, { useState } from 'react';
import {
  Card,
  CardContent,
  CardActions,
  Box,
  Typography,
  Chip,
  Button,
  IconButton,
  Tooltip,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Divider,
  useTheme,
  alpha,
  CircularProgress,
} from '@mui/material';
import {
  LocalShipping as TruckIcon,
  CheckCircle as DeliveredIcon,
  Schedule as ScheduledIcon,
  Phone as PhoneIcon,
  WhatsApp as WhatsAppIcon,
  Map as MapIcon,
  CardGiftcard as GiftIcon,
  Print as PrintIcon,
  Person as PersonIcon,
  PriorityHigh as PriorityIcon,
} from '@mui/icons-material';
import type {
  RetailDeliveryItem,
  RetailDeliveryDriver,
} from './retailDelivery.types';
import {
  generateWhatsAppLink,
  generateGoogleMapsLink,
} from './retailDelivery.types';

interface RetailDeliveryCardProps {
  delivery: RetailDeliveryItem;
  drivers: RetailDeliveryDriver[];
  onAssignDriver: (deliveryId: string, driverId: string) => Promise<void>;
  onDispatchOut: (deliveryId: string) => Promise<void>;
  onMarkDelivered: (deliveryId: string) => Promise<void>;
  onPrintSlip: (delivery: RetailDeliveryItem) => void;
  loading?: boolean;
}

export const RetailDeliveryCard: React.FC<RetailDeliveryCardProps> = ({
  delivery,
  drivers,
  onAssignDriver,
  onDispatchOut,
  onMarkDelivered,
  onPrintSlip,
  loading = false,
}) => {
  const theme = useTheme();
  const [assigning, setAssigning] = useState(false);
  const [actionInProgress, setActionInProgress] = useState(false);

  const isExpress = delivery.deliveryPriority.toLowerCase() === 'express';
  const isPaid = delivery.paymentStatus.toLowerCase() === 'paid';
  const hasDriver = Boolean(delivery.deliveryPersonId);
  const isScheduled = delivery.status === 'Scheduled';
  const isOutForDelivery = delivery.status === 'OutForDelivery';
  const isDelivered = delivery.status === 'Delivered';

  const waLink = generateWhatsAppLink(
    delivery.recipientPhone || delivery.phone,
    delivery.recipientName,
    delivery.orderNumber
  );

  const mapsLink = generateGoogleMapsLink(delivery.address, delivery.postalCode);

  const handleDriverChange = async (e: any) => {
    const driverId = e.target.value as string;
    if (!driverId || driverId === delivery.deliveryPersonId) return;

    try {
      setAssigning(true);
      await onAssignDriver(delivery.deliveryId, driverId);
    } finally {
      setAssigning(false);
    }
  };

  const handleDispatch = async () => {
    try {
      setActionInProgress(true);
      await onDispatchOut(delivery.deliveryId);
    } finally {
      setActionInProgress(false);
    }
  };

  const handleDelivered = async () => {
    try {
      setActionInProgress(true);
      await onMarkDelivered(delivery.deliveryId);
    } finally {
      setActionInProgress(false);
    }
  };

  // Status color & chip
  const getStatusChip = () => {
    if (isDelivered) {
      return (
        <Chip
          size="small"
          icon={<DeliveredIcon fontSize="small" />}
          label="Delivered"
          sx={{ bgcolor: alpha(theme.palette.success.main, 0.1), color: 'success.main', fontWeight: 700 }}
        />
      );
    }
    if (isOutForDelivery) {
      return (
        <Chip
          size="small"
          icon={<TruckIcon fontSize="small" />}
          label="In Transit"
          sx={{ bgcolor: alpha(theme.palette.warning.main, 0.15), color: 'warning.dark', fontWeight: 700 }}
        />
      );
    }
    return (
      <Chip
        size="small"
        icon={<ScheduledIcon fontSize="small" />}
        label="Pending Dispatch"
        sx={{ bgcolor: alpha(theme.palette.info.main, 0.1), color: 'info.main', fontWeight: 700 }}
      />
    );
  };

  return (
    <Card
      elevation={0}
      sx={{
        borderRadius: 2,
        border: `1px solid ${
          isExpress ? theme.palette.error.light : theme.palette.divider
        }`,
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        transition: 'all 0.2s ease-in-out',
        '&:hover': {
          boxShadow: '0 4px 16px rgba(0,0,0,0.08)',
          borderColor: isExpress ? theme.palette.error.main : theme.palette.primary.main,
        },
      }}
    >
      {/* Card Header: Order #, Priority, Slot, Status */}
      <Box
        sx={{
          p: 1.5,
          pb: 1,
          bgcolor: isExpress ? alpha(theme.palette.error.main, 0.04) : 'background.default',
          borderBottom: `1px solid ${theme.palette.divider}`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          flexWrap: 'wrap',
          gap: 1,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Typography variant="subtitle2" sx={{ fontWeight: 800, letterSpacing: 0.5 }}>
            #{delivery.orderNumber}
          </Typography>
          {isExpress && (
            <Chip
              size="small"
              icon={<PriorityIcon fontSize="inherit" />}
              label="EXPRESS"
              color="error"
              sx={{ fontWeight: 800, height: 20, fontSize: '0.65rem' }}
            />
          )}
          <Chip
            size="small"
            label={delivery.timeSlot}
            variant="outlined"
            sx={{ fontWeight: 600, height: 20, fontSize: '0.7rem' }}
          />
        </Box>

        {getStatusChip()}
      </Box>

      <CardContent sx={{ p: 2, flex: 1, display: 'flex', flexDirection: 'column', gap: 1.5 }}>
        {/* Recipient & Contact Details */}
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <Box>
            <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600, textTransform: 'uppercase' }}>
              Deliver To:
            </Typography>
            <Typography variant="body1" sx={{ fontWeight: 700 }}>
              {delivery.recipientName}
            </Typography>
            {(delivery.recipientPhone || delivery.phone) && (
              <Typography variant="body2" sx={{ color: 'text.secondary', mt: 0.2 }}>
                {delivery.recipientPhone || delivery.phone}
              </Typography>
            )}
          </Box>

          {/* Quick Contact Actions: WhatsApp & Call */}
          <Box sx={{ display: 'flex', gap: 0.5 }}>
            {(delivery.recipientPhone || delivery.phone) && (
              <Tooltip title="Call Recipient">
                <IconButton
                  size="small"
                  component="a"
                  href={`tel:${delivery.recipientPhone || delivery.phone}`}
                  sx={{ border: `1px solid ${theme.palette.divider}`, p: 0.7 }}
                >
                  <PhoneIcon fontSize="small" color="action" />
                </IconButton>
              </Tooltip>
            )}

            {waLink && (
              <Tooltip title="Message on WhatsApp">
                <IconButton
                  size="small"
                  component="a"
                  href={waLink}
                  target="_blank"
                  rel="noopener noreferrer"
                  sx={{
                    border: '1px solid #25D366',
                    p: 0.7,
                    bgcolor: alpha('#25D366', 0.1),
                    color: '#25D366',
                    '&:hover': { bgcolor: alpha('#25D366', 0.2) },
                  }}
                >
                  <WhatsAppIcon fontSize="small" />
                </IconButton>
              </Tooltip>
            )}
          </Box>
        </Box>

        {/* Address with Google Maps quick link */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'flex-start',
            gap: 1,
            p: 1,
            borderRadius: 1.5,
            bgcolor: alpha(theme.palette.action.hover, 0.5),
          }}
        >
          <Box sx={{ flex: 1 }}>
            <Typography variant="body2" sx={{ color: 'text.primary', fontSize: '0.85rem' }}>
              {delivery.address}
            </Typography>
            {delivery.postalCode && (
              <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 600 }}>
                PIN: {delivery.postalCode}
              </Typography>
            )}
          </Box>
          <Tooltip title="Open in Google Maps">
            <IconButton
              size="small"
              component="a"
              href={mapsLink}
              target="_blank"
              rel="noopener noreferrer"
              sx={{ color: 'primary.main', p: 0.5 }}
            >
              <MapIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        </Box>

        {/* Card Message (Florist highlight) */}
        {delivery.cardMessage && (
          <Box
            sx={{
              p: 1.2,
              borderRadius: 1.5,
              border: `1px dashed ${theme.palette.warning.main}`,
              bgcolor: alpha(theme.palette.warning.light, 0.1),
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.7, mb: 0.3 }}>
              <GiftIcon sx={{ fontSize: 16, color: 'warning.dark' }} />
              <Typography variant="caption" sx={{ fontWeight: 700, color: 'warning.dark' }}>
                GIFT MESSAGE:
              </Typography>
            </Box>
            <Typography
              variant="body2"
              sx={{
                fontStyle: 'italic',
                color: 'text.primary',
                fontSize: '0.82rem',
                pl: 1,
                borderLeft: `2px solid ${theme.palette.warning.main}`,
              }}
            >
              "{delivery.cardMessage}"
            </Typography>
          </Box>
        )}

        {/* Items Summary */}
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', pt: 0.5 }}>
          <Typography variant="body2" sx={{ color: 'text.secondary', fontSize: '0.8rem', fontWeight: 600 }}>
            {delivery.itemCount} item{delivery.itemCount !== 1 ? 's' : ''}:
          </Typography>
          <Typography
            variant="body2"
            sx={{
              fontWeight: 500,
              fontSize: '0.8rem',
              maxWidth: '70%',
              textAlign: 'right',
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
            title={delivery.itemsSummary}
          >
            {delivery.itemsSummary || 'Standard Bouquet'}
          </Typography>
        </Box>

        {/* Total & Payment Status */}
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            pt: 1,
            borderTop: `1px solid ${theme.palette.divider}`,
          }}
        >
          <Box>
            <Typography variant="caption" sx={{ color: 'text.secondary' }}>
              Total:
            </Typography>
            <Typography variant="subtitle1" sx={{ fontWeight: 800, color: 'text.primary' }}>
              ₹{delivery.totalAmount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
            </Typography>
          </Box>

          <Chip
            size="small"
            label={isPaid ? 'PAID' : `COD: ₹${delivery.totalAmount.toFixed(0)}`}
            color={isPaid ? 'success' : 'warning'}
            variant={isPaid ? 'filled' : 'outlined'}
            sx={{ fontWeight: 700, fontSize: '0.75rem' }}
          />
        </Box>

        {/* Driver Assignment Dropdown */}
        <Box sx={{ mt: 1 }}>
          <FormControl fullWidth size="small">
            <InputLabel id={`driver-select-label-${delivery.deliveryId}`}>Assigned Driver</InputLabel>
            <Select
              labelId={`driver-select-label-${delivery.deliveryId}`}
              label="Assigned Driver"
              value={delivery.deliveryPersonId || ''}
              onChange={handleDriverChange}
              disabled={isDelivered || assigning || loading}
              renderValue={(selected) => {
                if (!selected) return <em>Unassigned</em>;
                const d = drivers.find((x) => x.id === selected);
                return d ? d.name : delivery.deliveryPersonName || 'Assigned Driver';
              }}
            >
              <MenuItem value="" disabled>
                <em>Select a Delivery Driver</em>
              </MenuItem>
              {drivers.map((d) => (
                <MenuItem key={d.id} value={d.id}>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, width: '100%', justifyContent: 'space-between' }}>
                    <span>{d.name}</span>
                    {d.isDeliveryRole && (
                      <Chip label="Driver" size="small" sx={{ height: 18, fontSize: '0.65rem' }} />
                    )}
                  </Box>
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Box>
      </CardContent>

      <Divider />

      {/* Card Actions: Slip print + Dispatch Out / Mark Delivered */}
      <CardActions sx={{ p: 1.5, display: 'flex', justifyContent: 'space-between', gap: 1 }}>
        <Tooltip title="Print Delivery & Card Slip">
          <Button
            size="small"
            variant="outlined"
            color="inherit"
            startIcon={<PrintIcon />}
            onClick={() => onPrintSlip(delivery)}
            sx={{ fontWeight: 600, textTransform: 'none' }}
          >
            Slip
          </Button>
        </Tooltip>

        <Box sx={{ display: 'flex', gap: 1 }}>
          {isScheduled && (
            <Tooltip title={!hasDriver ? 'Assign a driver first before dispatching' : 'Dispatch out for delivery'}>
              <span>
                <Button
                  size="small"
                  variant="contained"
                  color="warning"
                  startIcon={actionInProgress ? <CircularProgress size={16} color="inherit" /> : <TruckIcon />}
                  disabled={!hasDriver || actionInProgress || loading}
                  onClick={handleDispatch}
                  sx={{ fontWeight: 700, textTransform: 'none' }}
                >
                  Dispatch Out
                </Button>
              </span>
            </Tooltip>
          )}

          {isOutForDelivery && (
            <Button
              size="small"
              variant="contained"
              color="success"
              startIcon={actionInProgress ? <CircularProgress size={16} color="inherit" /> : <DeliveredIcon />}
              disabled={actionInProgress || loading}
              onClick={handleDelivered}
              sx={{ fontWeight: 700, textTransform: 'none' }}
            >
              Mark Delivered
            </Button>
          )}

          {isDelivered && (
            <Button
              size="small"
              variant="text"
              color="success"
              disabled
              startIcon={<DeliveredIcon />}
              sx={{ fontWeight: 700, textTransform: 'none' }}
            >
              Delivered
            </Button>
          )}
        </Box>
      </CardActions>
    </Card>
  );
};
