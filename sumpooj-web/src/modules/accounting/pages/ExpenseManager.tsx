import React, { useState, useEffect } from 'react';
import { Alert, Box, Button, Paper, Snackbar, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography, IconButton } from '@mui/material';
import { Edit, Block } from '@mui/icons-material';
import ExpenseForm from './ExpenseForm';
import { categoryIcons } from '../accounting.constants.tsx';
import { getExpenses, addExpense } from '../accounting.service';

const ExpenseManager: React.FC = () => {
  const [expenses, setExpenses] = useState<any[]>([]);

  useEffect(() => {
    getExpenses().then(data => setExpenses(Array.isArray(data) ? data : []));
  }, []);

  const [formOpen, setFormOpen] = useState(false);
  const [editData, setEditData] = useState<any>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleAdd = () => {
    setEditData(null);
    setFormOpen(true);
  };

  const handleEdit = (expense: any) => {
    setEditData(expense);
    setFormOpen(true);
  };

  const handleFormSubmit = async (data: any) => {
    try {
      if (editData) {
        // updateExpense(editData.id, data); // Function not implemented
      } else {
        await addExpense(data);
      }
      const expensesData = await getExpenses();
      setExpenses(Array.isArray(expensesData) ? expensesData : []);
      setFormOpen(false);
    } catch (err: any) {
      const msg = err?.response?.data?.message || err?.message || 'Failed to save expense. Please try again.';
      setErrorMsg(msg);
    }
  };

  const handleDisable = async (expense: any) => {
    // disableExpense(expense.id); // Function not implemented
    const expensesData = await getExpenses();
    setExpenses(Array.isArray(expensesData) ? expensesData : []);
  };

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Expense Manager</Typography>
      <Button variant="contained" sx={{ mb: 2 }} onClick={handleAdd}>+ Add Expense</Button>
      <TableContainer component={Paper} sx={{ borderRadius: 2 }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Date</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Vendor</TableCell>
              <TableCell>Amount</TableCell>
              <TableCell>Payment Method</TableCell>
              <TableCell>Location</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {expenses.map((exp: any) => (
              <TableRow key={exp.id}>
                <TableCell>{exp.expenseDate ? new Date(exp.expenseDate).toLocaleDateString() : ''}</TableCell>
                <TableCell>{categoryIcons[exp.category]} {exp.category}</TableCell>
                <TableCell>{exp.description || ''}</TableCell>
                <TableCell>{exp.amount}</TableCell>
                <TableCell>–</TableCell>
                <TableCell>–</TableCell>
                <TableCell>
                  <IconButton onClick={() => handleEdit(exp)}><Edit /></IconButton>
                  <IconButton onClick={() => handleDisable(exp)} disabled={!exp.isActive}><Block /></IconButton>
                </TableCell>
              </TableRow>
            ))}
            {expenses.length === 0 && (
              <TableRow>
                <TableCell colSpan={7} align="center">No expenses found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
      <ExpenseForm open={formOpen} onClose={() => setFormOpen(false)} onSubmit={handleFormSubmit} initialData={editData} />
      <Snackbar open={!!errorMsg} autoHideDuration={6000} onClose={() => setErrorMsg(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        <Alert severity="error" onClose={() => setErrorMsg(null)}>{errorMsg}</Alert>
      </Snackbar>
    </Box>
  );
};

export default ExpenseManager;
