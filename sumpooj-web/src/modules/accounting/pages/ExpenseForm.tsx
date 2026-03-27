import React, { useState, useEffect } from 'react';
import {
  Box, Button, Dialog, DialogActions, DialogContent, DialogTitle,
  FormControl, FormHelperText, InputLabel, MenuItem, Select, TextField, Typography
} from '@mui/material';
import { categoryIcons, expenseCategories, paymentMethods } from '../accounting.constants.tsx';
import { useAuth } from '../../../auth/AuthContext';
import { getLocations } from '../../../api/location.api';

export interface ExpenseFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (data: any) => void;
  initialData?: any;
}

interface FormErrors {
  date?: string;
  amount?: string;
  location?: string;
}

const ExpenseForm: React.FC<ExpenseFormProps> = ({ open, onClose, onSubmit, initialData }) => {
  const { user } = useAuth();

  const [date, setDate] = useState('');
  const [category, setCategory] = useState('Staff');
  const [vendor, setVendor] = useState('');
  const [amount, setAmount] = useState('');
  const [paymentMethod, setPaymentMethod] = useState('Cash');
  const [location, setLocation] = useState('');
  const [notes, setNotes] = useState('');
  const [receipt, setReceipt] = useState<File | null>(null);
  const [errors, setErrors] = useState<FormErrors>({});
  const [availableLocations, setAvailableLocations] = useState<{ id: string; name: string }[]>([]);

  // Reset form and load real locations every time the dialog opens
  useEffect(() => {
    if (!open) return;

    setDate(initialData?.date || '');
    setCategory(initialData?.category || 'Staff');
    setVendor(initialData?.vendor || '');
    setAmount(initialData?.amount || '');
    setPaymentMethod(initialData?.paymentMethod || 'Cash');
    setNotes(initialData?.notes || '');
    setReceipt(null);
    setErrors({});

    getLocations()
      .then((locs: any[]) => {
        const locList = Array.isArray(locs) ? locs : [];
        const assignedIds = user?.assignedLocationIds;
        const filtered = assignedIds?.length
          ? locList.filter((l: any) => assignedIds.includes(l.id))
          : locList;
        const mapped = filtered.map((l: any) => ({ id: l.id, name: l.name }));
        setAvailableLocations(mapped);

        if (initialData?.location) {
          setLocation(initialData.location);
        } else {
          // Pre-select the user's primary location
          const primary = locList.find((l: any) => l.id === user?.primaryLocationId);
          setLocation(primary?.name ?? (mapped[0]?.name ?? ''));
        }
      })
      .catch(() => {
        // Fallback to static list if API is unavailable
        const fallback = [
          { id: 'Main', name: 'Main' },
          { id: 'Branch1', name: 'Branch1' },
          { id: 'Branch2', name: 'Branch2' },
        ];
        setAvailableLocations(fallback);
        setLocation(initialData?.location || 'Main');
      });
  }, [open]); // eslint-disable-line react-hooks/exhaustive-deps

  const validate = (): boolean => {
    const newErrors: FormErrors = {};
    if (!date) newErrors.date = 'Date is required';
    if (!amount || Number(amount) <= 0) newErrors.amount = 'Amount must be greater than 0';
    if (!location) newErrors.location = 'Location is required';
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = () => {
    if (!validate()) return;
    onSubmit({ date, category, vendor, amount: Number(amount), paymentMethod, location, notes, receipt });
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>{initialData ? 'Edit Expense' : 'Add Expense'}</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          <TextField
            label="Date" type="date" value={date}
            onChange={e => { setDate(e.target.value); setErrors(p => ({ ...p, date: undefined })); }}
            fullWidth InputLabelProps={{ shrink: true }} required
            error={!!errors.date} helperText={errors.date}
          />
          <FormControl fullWidth>
            <InputLabel>Category</InputLabel>
            <Select value={category} label="Category" onChange={e => setCategory(e.target.value)}>
              {expenseCategories.map(c => (
                <MenuItem key={c} value={c}>{categoryIcons[c]} {c}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField label="Vendor" value={vendor} onChange={e => setVendor(e.target.value)} fullWidth />
          <TextField
            label="Amount" type="number" value={amount}
            onChange={e => { setAmount(e.target.value); setErrors(p => ({ ...p, amount: undefined })); }}
            fullWidth required
            error={!!errors.amount} helperText={errors.amount}
            inputProps={{ min: 0 }}
          />
          <FormControl fullWidth>
            <InputLabel>Payment Method</InputLabel>
            <Select value={paymentMethod} label="Payment Method" onChange={e => setPaymentMethod(e.target.value)}>
              {paymentMethods.map(pm => (
                <MenuItem key={pm} value={pm}>{pm}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControl fullWidth error={!!errors.location}>
            <InputLabel>Location</InputLabel>
            <Select
              value={location} label="Location"
              onChange={e => { setLocation(e.target.value); setErrors(p => ({ ...p, location: undefined })); }}
            >
              {availableLocations.map(l => (
                <MenuItem key={l.id} value={l.name}>{l.name}</MenuItem>
              ))}
            </Select>
            {errors.location && <FormHelperText>{errors.location}</FormHelperText>}
          </FormControl>
          <TextField label="Notes" value={notes} onChange={e => setNotes(e.target.value)} fullWidth multiline minRows={2} />
          <Box>
            <Typography sx={{ mb: 1 }}>Receipt Upload</Typography>
            <input type="file" accept="image/*,application/pdf" onChange={e => setReceipt(e.target.files?.[0] || null)} />
          </Box>
        </Box>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button variant="contained" onClick={handleSubmit}>{initialData ? 'Save' : 'Add'}</Button>
      </DialogActions>
    </Dialog>
  );
};

export default ExpenseForm;
