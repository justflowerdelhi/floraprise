import React, { useState } from 'react';
import { Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl, InputLabel, MenuItem, Select, TextField, Typography } from '@mui/material';
import { categoryIcons, expenseCategories, paymentMethods, locations } from '../accounting.constants.tsx';

export interface ExpenseFormProps {
  open: boolean;
  onClose: () => void;
  onSubmit: (data: any) => void;
  initialData?: any;
}

const ExpenseForm: React.FC<ExpenseFormProps> = ({ open, onClose, onSubmit, initialData }) => {
  const [date, setDate] = useState(initialData?.date || '');
  const [category, setCategory] = useState(initialData?.category || 'Staff');
  const [vendor, setVendor] = useState(initialData?.vendor || '');
  const [amount, setAmount] = useState(initialData?.amount || '');
  const [paymentMethod, setPaymentMethod] = useState(initialData?.paymentMethod || 'Cash');
  const [location, setLocation] = useState(initialData?.location || 'Main');
  const [notes, setNotes] = useState(initialData?.notes || '');
  const [receipt, setReceipt] = useState(null);

  const handleSubmit = () => {
    onSubmit({ date, category, vendor, amount, paymentMethod, location, notes, receipt });
  };

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="sm">
      <DialogTitle>{initialData ? 'Edit Expense' : 'Add Expense'}</DialogTitle>
      <DialogContent>
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
          <TextField label="Date" type="date" value={date} onChange={e => setDate(e.target.value)} fullWidth InputLabelProps={{ shrink: true }} required />
          <FormControl fullWidth>
            <InputLabel>Category</InputLabel>
            <Select value={category} label="Category" onChange={e => setCategory(e.target.value)}>
              {expenseCategories.map(c => (
                <MenuItem key={c} value={c}>
                  {categoryIcons[c]} {c}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
          <TextField label="Vendor" value={vendor} onChange={e => setVendor(e.target.value)} fullWidth />
          <TextField label="Amount" type="number" value={amount} onChange={e => setAmount(e.target.value)} fullWidth required />
          <FormControl fullWidth>
            <InputLabel>Payment Method</InputLabel>
            <Select value={paymentMethod} label="Payment Method" onChange={e => setPaymentMethod(e.target.value)}>
              {paymentMethods.map(pm => (
                <MenuItem key={pm} value={pm}>{pm}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControl fullWidth>
            <InputLabel>Location</InputLabel>
            <Select value={location} label="Location" onChange={e => setLocation(e.target.value)}>
              {locations.map(l => (
                <MenuItem key={l} value={l}>{l}</MenuItem>
              ))}
            </Select>
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
