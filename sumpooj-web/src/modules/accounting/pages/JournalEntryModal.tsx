import React from 'react';
import { Box, Dialog, DialogTitle, DialogContent, Typography, Table, TableBody, TableCell, TableHead, TableRow } from '@mui/material';

export interface JournalEntryModalProps {
  open: boolean;
  onClose: () => void;
  entry: any;
}

const JournalEntryModal: React.FC<JournalEntryModalProps> = ({ open, onClose, entry }) => {
  if (!entry) return null;

  // API entries are flat (debit/credit/accountId) while local mock entries have `lines`.
  const lines = Array.isArray(entry.lines)
    ? entry.lines
    : [{ account: entry.accountName || entry.accountId || 'N/A', debit: entry.debit || 0, credit: entry.credit || 0 }];

  return (
    <Dialog open={open} onClose={onClose} fullWidth maxWidth="md">
      <DialogTitle>Journal Entry Details</DialogTitle>
      <DialogContent>
        <Box sx={{ mb: 2 }}>
          <Typography variant="subtitle1">Reference: {entry.reference}</Typography>
          <Typography variant="body2">Date: {entry.date}</Typography>
          <Typography variant="body2">Description: {entry.description}</Typography>
        </Box>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Account</TableCell>
              <TableCell>Debit</TableCell>
              <TableCell>Credit</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {lines.map((line: any, idx: number) => (
              <TableRow key={idx}>
                <TableCell>{line.account || line.accountId || 'N/A'}</TableCell>
                <TableCell>{line.debit}</TableCell>
                <TableCell>{line.credit}</TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </DialogContent>
    </Dialog>
  );
};

export default JournalEntryModal;
