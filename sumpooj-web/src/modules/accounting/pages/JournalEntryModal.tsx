import React from 'react';
import { Box, Dialog, DialogTitle, DialogContent, Typography, Table, TableBody, TableCell, TableHead, TableRow } from '@mui/material';

export interface JournalEntryModalProps {
  open: boolean;
  onClose: () => void;
  entry: any;
}

const JournalEntryModal: React.FC<JournalEntryModalProps> = ({ open, onClose, entry }) => {
  if (!entry) return null;
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
            {entry.lines.map((line: any, idx: number) => (
              <TableRow key={idx}>
                <TableCell>{line.account}</TableCell>
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
