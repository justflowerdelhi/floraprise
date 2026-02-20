/**
 * QuickCreateCustomerModal.tsx — Fast inline customer creation for POS
 *
 * Features:
 * - Minimal required fields (Name, Phone)
 * - Optional collapsed section (Email, Address, Notes, Birthday)
 * - Smart prefill from search query
 * - Loading state during save
 * - Duplicate prevention
 * - Auto-select after save
 */
import React, { useState, useRef, useEffect } from 'react';
import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Box, TextField, Button, Collapse, Typography,
  CircularProgress, Alert, IconButton, useTheme, alpha,
} from '@mui/material';
import {
  ExpandMore as ExpandIcon,
  ExpandLess as CollapseIcon,
  Phone as PhoneIcon,
  Person as PersonIcon,
  Close as CloseIcon,
} from '@mui/icons-material';
import type { SelectedCustomer } from './CustomerSearchBar';

interface QuickCreateCustomerModalProps {
  open: boolean;
  onClose: () => void;
  onCreated: (customer: SelectedCustomer) => void;
  prefillPhone?: string;
}

export default function QuickCreateCustomerModal({
  open,
  onClose,
  onCreated,
  prefillPhone = '',
}: QuickCreateCustomerModalProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const nameRef = useRef<HTMLInputElement>(null);

  // Form state
  const [name, setName] = useState('');
  const [phone, setPhone] = useState(prefillPhone);
  const [email, setEmail] = useState('');
  const [address, setAddress] = useState('');
  const [notes, setNotes] = useState('');
  const [birthday, setBirthday] = useState('');

  const [showOptional, setShowOptional] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  // Reset form when modal opens
  useEffect(() => {
    if (open) {
      setName('');
      setPhone(prefillPhone);
      setEmail('');
      setAddress('');
      setNotes('');
      setBirthday('');
      setShowOptional(false);
      setError('');
      // Focus name field after modal animation
      setTimeout(() => nameRef.current?.focus(), 100);
    }
  }, [open, prefillPhone]);

  // Validation
  const isValid = name.trim().length >= 2 && phone.trim().length >= 10;

  const handleSave = async () => {
    if (!isValid) return;

    setError('');
    setSaving(true);

    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 400));

      // Check for duplicate (mock)
      const normalizedPhone = phone.replace(/\D/g, '');
      if (normalizedPhone === '9876543210') {
        setError('A customer with this phone number already exists.');
        setSaving(false);
        return;
      }

      // Create customer (mock response)
      const newCustomer: SelectedCustomer = {
        id: `cust_${Date.now()}`,
        name: name.trim(),
        phone: normalizedPhone,
        email: email.trim() || undefined,
      };

      onCreated(newCustomer);
      onClose();
    } catch {
      setError('Failed to create customer. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && isValid && !saving) {
      e.preventDefault();
      handleSave();
    }
  };

  const inputSx = {
    '& .MuiOutlinedInput-root': {
      minHeight: 48,
      ...(dk && { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } }),
    },
  };

  return (
    <Dialog
      open={open}
      onClose={saving ? undefined : onClose}
      maxWidth="xs"
      fullWidth
      PaperProps={{
        sx: {
          bgcolor: dk ? '#1a1a2e' : '#fff',
          borderRadius: 3,
        },
      }}
    >
      <DialogTitle sx={{ pb: 1, display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <Typography variant="h6" sx={{ fontWeight: 800 }}>
          Quick Add Customer
        </Typography>
        <IconButton
          size="small"
          onClick={onClose}
          disabled={saving}
          sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}
        >
          <CloseIcon />
        </IconButton>
      </DialogTitle>

      <DialogContent>
        {error && (
          <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>
            {error}
          </Alert>
        )}

        {/* Required Fields */}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          <TextField
            inputRef={nameRef}
            label="Customer Name"
            placeholder="Enter full name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            onKeyDown={handleKeyDown}
            required
            fullWidth
            disabled={saving}
            slotProps={{
              input: {
                startAdornment: (
                  <PersonIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                ),
              },
            }}
            sx={inputSx}
            error={name.length > 0 && name.length < 2}
            helperText={name.length > 0 && name.length < 2 ? 'Name must be at least 2 characters' : ''}
          />

          <TextField
            label="Phone Number"
            placeholder="Enter phone number"
            value={phone}
            onChange={(e) => setPhone(e.target.value.replace(/[^\d+\-\s()]/g, ''))}
            onKeyDown={handleKeyDown}
            required
            fullWidth
            disabled={saving}
            slotProps={{
              input: {
                startAdornment: (
                  <PhoneIcon sx={{ mr: 1, color: 'text.secondary', fontSize: 20 }} />
                ),
              },
            }}
            sx={inputSx}
            error={phone.length > 0 && phone.replace(/\D/g, '').length < 10}
            helperText={phone.length > 0 && phone.replace(/\D/g, '').length < 10 ? 'Enter at least 10 digits' : ''}
          />
        </Box>

        {/* Optional Fields Toggle */}
        <Box sx={{ mt: 2 }}>
          <Button
            size="small"
            onClick={() => setShowOptional(!showOptional)}
            endIcon={showOptional ? <CollapseIcon /> : <ExpandIcon />}
            sx={{
              color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
              textTransform: 'none',
              fontWeight: 500,
              '&:hover': { bgcolor: 'transparent', textDecoration: 'underline' },
            }}
          >
            {showOptional ? 'Hide' : 'Show'} optional details
          </Button>
        </Box>

        {/* Optional Fields */}
        <Collapse in={showOptional}>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 2 }}>
            <TextField
              label="Email (Optional)"
              placeholder="customer@email.com"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              onKeyDown={handleKeyDown}
              fullWidth
              disabled={saving}
              sx={inputSx}
            />

            <TextField
              label="Address (Optional)"
              placeholder="Delivery address"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              onKeyDown={handleKeyDown}
              fullWidth
              multiline
              rows={2}
              disabled={saving}
              sx={inputSx}
            />

            <TextField
              label="Birthday (Optional)"
              type="date"
              value={birthday}
              onChange={(e) => setBirthday(e.target.value)}
              fullWidth
              disabled={saving}
              slotProps={{
                inputLabel: { shrink: true },
              }}
              sx={inputSx}
            />

            <TextField
              label="Notes (Optional)"
              placeholder="Any special preferences or notes"
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              fullWidth
              multiline
              rows={2}
              disabled={saving}
              sx={inputSx}
            />
          </Box>
        </Collapse>
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2, gap: 1 }}>
        <Button
          onClick={onClose}
          disabled={saving}
          sx={{ fontWeight: 600, minHeight: 44, minWidth: 80 }}
        >
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleSave}
          disabled={!isValid || saving}
          sx={{
            fontWeight: 700,
            minHeight: 44,
            minWidth: 140,
            bgcolor: '#4caf50',
            '&:hover': { bgcolor: '#43a047' },
            transition: 'all 0.15s',
          }}
        >
          {saving ? (
            <CircularProgress size={22} color="inherit" />
          ) : (
            'Save & Select'
          )}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
