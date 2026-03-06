import React, { useState } from 'react';
import { Box, Button, Paper, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Typography, Chip, IconButton } from '@mui/material';
import { Edit, Block } from '@mui/icons-material';
import AccountForm from './AccountForm';
import { AccountTypeIcons } from '../accounting.constants.tsx';
import { getAccounts, addAccount, updateAccount, disableAccount } from '../accounting.service';

const ChartOfAccounts: React.FC = () => {
  const [accounts, setAccounts] = useState(getAccounts());
  const [formOpen, setFormOpen] = useState(false);
  const [editData, setEditData] = useState<any>(null);

  const handleAdd = () => {
    setEditData(null);
    setFormOpen(true);
  };

  const handleEdit = (account: any) => {
    setEditData(account);
    setFormOpen(true);
  };

  const handleFormSubmit = (data: any) => {
    if (editData) {
      updateAccount(editData.id, data);
    } else {
      addAccount(data);
    }
    setAccounts(getAccounts());
    setFormOpen(false);
  };

  const handleDisable = (account: any) => {
    disableAccount(account.id);
    setAccounts(getAccounts());
  };

  return (
    <Box sx={{ p: { xs: 1, sm: 2, md: 3 }, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h5" fontWeight={700} sx={{ mb: 2 }}>Chart of Accounts</Typography>
      <Button variant="contained" sx={{ mb: 2 }} onClick={handleAdd}>+ Add Account</Button>
      <TableContainer component={Paper} sx={{ borderRadius: 2 }}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Code</TableCell>
              <TableCell>Account Name</TableCell>
              <TableCell>Account Type</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {accounts.map((acc: any) => (
              <TableRow key={acc.id}>
                <TableCell>{acc.code}</TableCell>
                <TableCell>{acc.name}</TableCell>
                <TableCell>
                  {AccountTypeIcons[acc.accountType]} {acc.accountType}
                </TableCell>
                <TableCell>
                  <Chip label={acc.isActive ? 'Active' : 'Disabled'} color={acc.isActive ? 'success' : 'default'} size="small" />
                </TableCell>
                <TableCell>
                  <IconButton onClick={() => handleEdit(acc)}><Edit /></IconButton>
                  <IconButton onClick={() => handleDisable(acc)} disabled={!acc.isActive}><Block /></IconButton>
                </TableCell>
              </TableRow>
            ))}
            {accounts.length === 0 && (
              <TableRow>
                <TableCell colSpan={5} align="center">No accounts found</TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>
      <AccountForm open={formOpen} onClose={() => setFormOpen(false)} onSubmit={handleFormSubmit} initialData={editData} />
    </Box>
  );
};

export default ChartOfAccounts;
