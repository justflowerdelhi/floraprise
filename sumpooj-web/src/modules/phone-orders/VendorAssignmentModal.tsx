import React, { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  MenuItem,
  Box,
  Typography,
  CircularProgress,
  useTheme,
} from '@mui/material';
import { CheckCircle as ConfirmIcon } from '@mui/icons-material';
import { useApiCall } from '../../hooks/useApiCall';
import { confirmPhoneOutstationOrder } from './phoneOrders.api';
import { formatCurrency } from '../../core/i18n';

// ── Mock vendor list (replace with API fetch later) ──────────────────────

const MOCK_VENDORS = [
  { id: 'v-001', name: 'BloomCraft Florals' },
  { id: 'v-002', name: 'PetalPush Partners' },
  { id: 'v-003', name: 'RoseRoute Deliveries' },
  { id: 'v-004', name: 'FloraLink Express' },
  { id: 'v-005', name: 'GardenGate Wholesale' },
];

// ── Props ────────────────────────────────────────────────────────────────

interface VendorAssignmentModalProps {
  open: boolean;
  onClose: () => void;
  orderId: string;
  onSuccess: () => void;
}

// ── Component ────────────────────────────────────────────────────────────

const VendorAssignmentModal: React.FC<VendorAssignmentModalProps> = ({
  open,
  onClose,
  orderId,
  onSuccess,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { loading, execute } = useApiCall();

  const [vendorId, setVendorId] = useState('');
  const [vendorCost, setVendorCost] = useState('');
  const [deliveryCharge, setDeliveryCharge] = useState('');

  const cost = parseFloat(vendorCost) || 0;
  const delivery = parseFloat(deliveryCharge) || 0;
  const totalPayable = cost + delivery;
  const isValid = vendorId.trim().length > 0;

  const handleConfirm = async () => {
    await execute(
      () =>
        confirmPhoneOutstationOrder({
          salesOrderId: orderId,
          vendorId,
          vendorCost: cost,
          deliveryCharge: delivery,
        }),
      {
        successMessage: 'Outstation order confirmed & vendor assigned',
        errorMessage: 'Failed to confirm outstation order',
      },
    );

    // Reset & notify parent
    setVendorId('');
    setVendorCost('');
    setDeliveryCharge('');
    onClose();
    onSuccess();
  };

  const handleClose = () => {
    if (loading) return;
    onClose();
  };

  return (
    <Dialog open={open} onClose={handleClose} maxWidth="sm" fullWidth>
      <DialogTitle sx={{ fontWeight: 700 }}>Assign Vendor</DialogTitle>

      <DialogContent
        sx={{ display: 'flex', flexDirection: 'column', gap: 2.5, pt: '16px !important' }}
      >
        <TextField
          select
          label="Vendor"
          value={vendorId}
          onChange={(e) => setVendorId(e.target.value)}
          size="small"
          fullWidth
          required
          error={vendorId === '' ? false : !isValid}
        >
          <MenuItem value="" disabled>
            Select a vendor…
          </MenuItem>
          {MOCK_VENDORS.map((v) => (
            <MenuItem key={v.id} value={v.id}>
              {v.name}
            </MenuItem>
          ))}
        </TextField>

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

        <Box
          sx={{
            p: 1.5,
            borderRadius: 1,
            bgcolor: dk ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.03)',
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
          }}
        >
          <Typography variant="body2" sx={{ fontWeight: 600 }}>
            Total Vendor Payable
          </Typography>
          <Typography variant="body1" sx={{ fontWeight: 700 }}>
            {formatCurrency(totalPayable)}
          </Typography>
        </Box>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button
          onClick={handleClose}
          disabled={loading}
          sx={{ textTransform: 'none' }}
        >
          Cancel
        </Button>
        <Button
          variant="contained"
          color="success"
          onClick={handleConfirm}
          disabled={loading || !isValid}
          startIcon={loading ? <CircularProgress size={16} /> : <ConfirmIcon />}
          sx={{ textTransform: 'none', fontWeight: 700 }}
        >
          Confirm &amp; Assign
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default VendorAssignmentModal;
