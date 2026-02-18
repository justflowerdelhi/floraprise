/**
 * Quick Add Supplier Modal
 * Keyboard-friendly modal for adding a new supplier inline
 */

import { useState } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Grid,
  IconButton,
  Typography,
  CircularProgress,
  Box,
  MenuItem,
  alpha,
  useTheme,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material';
import CloseIcon from '@mui/icons-material/Close';
import PersonAddIcon from '@mui/icons-material/PersonAdd';
import type { Supplier } from '../types/purchase.types';
import { PAYMENT_TERMS } from '../types/purchase.types';

interface QuickAddSupplierModalProps {
  open: boolean;
  onClose: () => void;
  onAdd: (supplier: Supplier) => void;
  darkMode?: boolean;
}

const QuickAddSupplierModal = ({
  open,
  onClose,
  onAdd,
  darkMode = false,
}: QuickAddSupplierModalProps) => {
  const theme = useTheme();
  const [loading, setLoading] = useState(false);
  const [form, setForm] = useState({
    name: '',
    contactPerson: '',
    email: '',
    phone: '',
    address: '',
    defaultPaymentTerms: 'net_30',
  });
  const [errors, setErrors] = useState<Record<string, string>>({});

  const fieldSx: SxProps<Theme> = darkMode
    ? {
        '& .MuiOutlinedInput-root': {
          backgroundColor: 'grey.900',
          color: 'grey.100',
          '& fieldset': { borderColor: 'grey.700' },
          '&:hover fieldset': { borderColor: 'grey.500' },
          '&.Mui-focused fieldset': { borderColor: 'primary.main' },
        },
        '& .MuiInputLabel-root': { color: 'grey.400' },
        '& .MuiInputLabel-root.Mui-focused': { color: 'primary.light' },
        '& .MuiInputBase-input': { color: 'grey.100' },
      }
    : {};

  const validate = () => {
    const e: Record<string, string> = {};
    if (!form.name.trim()) e.name = 'Supplier name is required';
    if (form.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email))
      e.email = 'Invalid email';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const handleSubmit = async () => {
    if (!validate()) return;
    setLoading(true);
    // Simulate API
    await new Promise((r) => setTimeout(r, 600));
    const newSupplier: Supplier = {
      id: `sup_${Date.now().toString().slice(-6)}`,
      ...form,
    };
    onAdd(newSupplier);
    setLoading(false);
    setForm({
      name: '',
      contactPerson: '',
      email: '',
      phone: '',
      address: '',
      defaultPaymentTerms: 'net_30',
    });
    setErrors({});
  };

  const handleChange = (field: string) => (e: React.ChangeEvent<HTMLInputElement>) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }));
    if (errors[field]) setErrors((prev) => ({ ...prev, [field]: '' }));
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          backgroundColor: darkMode
            ? alpha(theme.palette.grey[900], 0.98)
            : 'white',
          borderRadius: 2,
        },
      }}
    >
      <DialogTitle
        sx={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          pb: 1,
          color: darkMode ? 'grey.100' : 'grey.900',
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <PersonAddIcon color="primary" />
          <Typography variant="h6" fontWeight={600}>
            Quick Add Supplier
          </Typography>
        </Box>
        <IconButton onClick={onClose} size="small">
          <CloseIcon sx={{ color: darkMode ? 'grey.400' : 'grey.600' }} />
        </IconButton>
      </DialogTitle>

      <DialogContent dividers sx={{ borderColor: darkMode ? 'grey.800' : 'grey.200' }}>
        <Grid container spacing={2} sx={{ mt: 0.5 }}>
          <Grid size={{ xs: 12 }}>
            <TextField
              label="Supplier Name *"
              fullWidth
              value={form.name}
              onChange={handleChange('name')}
              error={!!errors.name}
              helperText={errors.name}
              autoFocus
              sx={fieldSx}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Contact Person"
              fullWidth
              value={form.contactPerson}
              onChange={handleChange('contactPerson')}
              sx={fieldSx}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Phone"
              fullWidth
              value={form.phone}
              onChange={handleChange('phone')}
              sx={fieldSx}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Email"
              fullWidth
              value={form.email}
              onChange={handleChange('email')}
              error={!!errors.email}
              helperText={errors.email}
              sx={fieldSx}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Payment Terms"
              select
              fullWidth
              value={form.defaultPaymentTerms}
              onChange={handleChange('defaultPaymentTerms')}
              sx={fieldSx}
            >
              {PAYMENT_TERMS.map((pt) => (
                <MenuItem key={pt.value} value={pt.value}>
                  {pt.label}
                </MenuItem>
              ))}
            </TextField>
          </Grid>
          <Grid size={{ xs: 12 }}>
            <TextField
              label="Address"
              fullWidth
              multiline
              rows={2}
              value={form.address}
              onChange={handleChange('address')}
              sx={fieldSx}
            />
          </Grid>
        </Grid>
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={onClose} color="inherit" tabIndex={-1}>
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSubmit}
          disabled={loading}
          startIcon={loading ? <CircularProgress size={18} /> : <PersonAddIcon />}
        >
          {loading ? 'Adding…' : 'Add Supplier'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

export default QuickAddSupplierModal;
