/**
 * Quick Add Supplier Modal
 * Fast supplier creation without leaving the product form
 */

import { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Stack,
  Box,
  Typography,
  IconButton,
  CircularProgress,
  Alert,
} from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import BusinessIcon from '@mui/icons-material/Business';
import type { Supplier } from '../types/product.types';
import { createSupplier } from '../api/product.api';

interface QuickAddSupplierModalProps {
  open: boolean;
  onClose: () => void;
  onSupplierCreated: (supplier: Supplier) => void;
  darkMode?: boolean;
}

const QuickAddSupplierModal = ({
  open,
  onClose,
  onSupplierCreated,
  darkMode = false,
}: QuickAddSupplierModalProps) => {
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [leadTime, setLeadTime] = useState<number | ''>('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const resetForm = () => {
    setName('');
    setCode('');
    setEmail('');
    setPhone('');
    setLeadTime('');
    setError(null);
  };

  const handleClose = () => {
    resetForm();
    onClose();
  };

  const handleSubmit = async () => {
    // Validate
    if (!name.trim()) {
      setError('Supplier name is required');
      return;
    }
    if (!code.trim()) {
      setError('Supplier code is required');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const response = await createSupplier({
        name: name.trim(),
        code: code.trim().toUpperCase(),
        email: email.trim() || undefined,
        phone: phone.trim() || undefined,
        leadTime: typeof leadTime === 'number' ? leadTime : undefined,
      });

      if (response.success && response.data) {
        onSupplierCreated(response.data);
        handleClose();
      } else {
        setError(response.error || 'Failed to create supplier');
      }
    } catch (err) {
      setError('An unexpected error occurred');
    } finally {
      setLoading(false);
    }
  };

  // Auto-generate code from name
  const handleNameChange = (value: string) => {
    setName(value);
    if (!code && value.length >= 3) {
      const autoCode = value
        .split(' ')
        .map((word) => word.charAt(0))
        .join('')
        .toUpperCase()
        .slice(0, 4);
      setCode(autoCode);
    }
  };

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          backgroundColor: darkMode ? 'grey.900' : 'white',
          borderRadius: 2,
        },
      }}
    >
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Box
              sx={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                width: 40,
                height: 40,
                borderRadius: 1.5,
                backgroundColor: darkMode
                  ? 'rgba(0, 188, 212, 0.2)'
                  : 'rgba(0, 188, 212, 0.1)',
              }}
            >
              <BusinessIcon sx={{ color: '#00bcd4' }} />
            </Box>
            <Box>
              <Typography variant="h6" sx={{ fontWeight: 600 }}>
                Quick Add Supplier
              </Typography>
              <Typography variant="caption" color="text.secondary">
                Create a new supplier without leaving the form
              </Typography>
            </Box>
          </Box>
          <IconButton onClick={handleClose} size="small">
            <CloseIcon />
          </IconButton>
        </Box>
      </DialogTitle>

      <DialogContent>
        <Stack spacing={2.5} sx={{ pt: 1 }}>
          {error && (
            <Alert severity="error" onClose={() => setError(null)}>
              {error}
            </Alert>
          )}

          {/* Name & Code */}
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
            <TextField
              label="Supplier Name"
              required
              fullWidth
              value={name}
              onChange={(e) => handleNameChange(e.target.value)}
              placeholder="e.g., Ecuador Rose Farms"
              autoFocus
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: darkMode ? 'grey.800' : 'white',
                },
              }}
            />
            <TextField
              label="Code"
              required
              value={code}
              onChange={(e) => setCode(e.target.value.toUpperCase())}
              placeholder="e.g., ERF"
              inputProps={{ maxLength: 6 }}
              sx={{
                width: { xs: '100%', sm: 120 },
                '& .MuiOutlinedInput-root': {
                  backgroundColor: darkMode ? 'grey.800' : 'white',
                },
              }}
            />
          </Stack>

          {/* Contact Info */}
          <Stack direction={{ xs: 'column', sm: 'row' }} spacing={2}>
            <TextField
              label="Email"
              type="email"
              fullWidth
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="supplier@example.com"
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: darkMode ? 'grey.800' : 'white',
                },
              }}
            />
            <TextField
              label="Phone"
              type="tel"
              fullWidth
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+1 (555) 123-4567"
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: darkMode ? 'grey.800' : 'white',
                },
              }}
            />
          </Stack>

          {/* Lead Time */}
          <TextField
            label="Default Lead Time"
            type="number"
            value={leadTime}
            onChange={(e) =>
              setLeadTime(e.target.value === '' ? '' : parseInt(e.target.value, 10))
            }
            placeholder="e.g., 5"
            InputProps={{
              endAdornment: <Typography color="text.secondary">days</Typography>,
            }}
            inputProps={{ min: 0, max: 365 }}
            sx={{
              width: { xs: '100%', sm: 200 },
              '& .MuiOutlinedInput-root': {
                backgroundColor: darkMode ? 'grey.800' : 'white',
              },
            }}
          />
        </Stack>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button onClick={handleClose} disabled={loading}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={loading || !name.trim() || !code.trim()}
          startIcon={loading ? <CircularProgress size={18} /> : undefined}
        >
          {loading ? 'Creating...' : 'Create Supplier'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default QuickAddSupplierModal;
