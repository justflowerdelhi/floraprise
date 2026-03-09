import React, { useState } from 'react';
import { Box, Button, Dialog, DialogActions, DialogContent, DialogTitle, FormControl, InputLabel, MenuItem, Select, TextField, Typography } from '@mui/material';
import { expenseCategories, paymentMethods } from '../accounting.constants.tsx';
import { addExpense } from '../accounting.service';
import { useToast } from '../../../hooks/useToast';

const QuickExpenseWidget: React.FC<{ onExpenseSaved?: () => void }> = ({ onExpenseSaved }) => {
  const [open, setOpen] = useState(false);
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState(expenseCategories[0]);
  const [paymentMethod, setPaymentMethod] = useState(paymentMethods[0]);
  const [note, setNote] = useState('');
  const toast = useToast();

  const handleSave = () => {
    addExpense({ amount, category, paymentMethod, note });
    setOpen(false);
    toast.success('Expense recorded successfully');
    if (onExpenseSaved) onExpenseSaved();
    setAmount('');
    setCategory(expenseCategories[0]);
    setPaymentMethod(paymentMethods[0]);
    setNote('');
  };

  return (
    <Box>
      <Button variant="contained" sx={{ fontSize: 18, py: 1.5, px: 3, borderRadius: 2 }} onClick={() => setOpen(true)}>
        Quick Expense
      </Button>
      <Dialog open={open} onClose={() => setOpen(false)} fullWidth maxWidth="xs">
        <DialogTitle>Quick Expense</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              label="Amount"
              type="number"
              value={amount}
              onChange={e => setAmount(e.target.value)}
              fullWidth
              inputProps={{ style: { fontSize: 32, textAlign: 'center', padding: 12 } }}
              required
            />
            <FormControl fullWidth>
              <InputLabel>Category</InputLabel>
              <Select value={category} label="Category" onChange={e => setCategory(e.target.value)}>
                {expenseCategories.map(c => (
                  <MenuItem key={c} value={c}>{c}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <FormControl fullWidth>
              <InputLabel>Payment Method</InputLabel>
              <Select value={paymentMethod} label="Payment Method" onChange={e => setPaymentMethod(e.target.value)}>
                {paymentMethods.map(pm => (
                  <MenuItem key={pm} value={pm}>{pm}</MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField label="Note (optional)" value={note} onChange={e => setNote(e.target.value)} fullWidth multiline minRows={2} />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleSave}>Save</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default QuickExpenseWidget;
