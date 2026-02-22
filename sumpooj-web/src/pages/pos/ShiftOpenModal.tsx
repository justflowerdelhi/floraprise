/**
 * ShiftOpenModal.tsx — Blocks POS access until a shift is opened
 *
 * Full-screen overlay that requires the operator to enter an opening
 * cash-drawer amount before the POS becomes usable.
 */
import React, { useState, useCallback } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TextField,
  CircularProgress,
  Alert,
  InputAdornment,
  Typography,
  Box,
} from '@mui/material';
import {
  PointOfSale as POSIcon,
  LocationOn as LocationIcon,
} from '@mui/icons-material';
import { useShift } from './ShiftContext';

const ShiftOpenModal: React.FC = () => {
  const { activeShift, loading, error, openShift, locationId } = useShift();
  const [openingCash, setOpeningCash] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const handleOpen = useCallback(async () => {
    const amount = parseFloat(openingCash);
    if (isNaN(amount) || amount < 0) {
      setLocalError('Enter a valid cash amount (0 or more)');
      return;
    }

    try {
      setLocalError(null);
      setSubmitting(true);
      await openShift(amount);
    } catch {
      setLocalError('Failed to open shift. Please try again.');
    } finally {
      setSubmitting(false);
    }
  }, [openingCash, openShift]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Enter' && !submitting) {
        handleOpen();
      }
    },
    [handleOpen, submitting],
  );

  // Don't show if already open or still loading
  if (loading || activeShift) return null;

  // No location selected — show "select location" blocker
  if (!locationId) {
    return (
      <Dialog
        open
        maxWidth="xs"
        fullWidth
        disableEscapeKeyDown
        PaperProps={{ sx: { borderRadius: 3, overflow: 'hidden' } }}
        slotProps={{ backdrop: { sx: { backgroundColor: 'rgba(0,0,0,0.85)' } } }}
      >
        <Box
          sx={{
            background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
            px: 3, py: 2.5,
            display: 'flex', alignItems: 'center', gap: 1.5,
          }}
        >
          <LocationIcon sx={{ color: '#fb923c', fontSize: 28 }} />
          <DialogTitle sx={{ p: 0, color: 'white', fontWeight: 700, fontSize: '1.2rem' }}>
            Location Required
          </DialogTitle>
        </Box>
        <DialogContent sx={{ pt: 3, pb: 3 }}>
          <Alert severity="warning" sx={{ mb: 2 }}>
            Select a location to continue.
          </Alert>
          <Typography variant="body2" color="text.secondary">
            Use the location selector in the header to pick a specific store
            before opening the POS.
          </Typography>
        </DialogContent>
      </Dialog>
    );
  }

  return (
    <Dialog
      open
      maxWidth="xs"
      fullWidth
      disableEscapeKeyDown
      PaperProps={{
        sx: { borderRadius: 3, overflow: 'hidden' },
      }}
      slotProps={{
        backdrop: {
          sx: { backgroundColor: 'rgba(0,0,0,0.85)' },
        },
      }}
    >
      {/* Header */}
      <Box
        sx={{
          background: 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
          px: 3,
          py: 2.5,
          display: 'flex',
          alignItems: 'center',
          gap: 1.5,
        }}
      >
        <POSIcon sx={{ color: '#38bdf8', fontSize: 28 }} />
        <DialogTitle sx={{ p: 0, color: 'white', fontWeight: 700, fontSize: '1.2rem' }}>
          Open Cash Drawer
        </DialogTitle>
      </Box>

      <DialogContent sx={{ pt: 3, pb: 1 }}>
        <Typography variant="body2" color="text.secondary" sx={{ mb: 2.5 }}>
          Count the cash in the register and enter the total below to start your shift.
        </Typography>

        {(error || localError) && (
          <Alert severity="error" sx={{ mb: 2 }}>
            {localError || error}
          </Alert>
        )}

        <TextField
          autoFocus
          fullWidth
          label="Opening Cash"
          type="number"
          value={openingCash}
          onChange={(e) => {
            setOpeningCash(e.target.value);
            setLocalError(null);
          }}
          onKeyDown={handleKeyDown}
          slotProps={{
            input: {
              startAdornment: <InputAdornment position="start">$</InputAdornment>,
            },
          }}
          placeholder="0.00"
          disabled={submitting}
          sx={{ mt: 0.5 }}
        />
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button
          onClick={handleOpen}
          variant="contained"
          fullWidth
          size="large"
          disabled={submitting || !openingCash}
          sx={{
            py: 1.2,
            fontWeight: 600,
            fontSize: '0.95rem',
            borderRadius: 2,
          }}
        >
          {submitting ? (
            <CircularProgress size={22} color="inherit" />
          ) : (
            'Open Shift'
          )}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default ShiftOpenModal;
