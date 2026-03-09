import React, { useEffect, useState } from "react";
import {
  Box,
  Typography,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  Paper
} from "@mui/material";
import { getTrialBalance } from "../accounting.service";

const TrialBalance = () => {

  const [rows, setRows] = useState<any[]>([]);

  useEffect(() => {
    getTrialBalance().then(data => setRows(Array.isArray(data) ? data : []));
  }, []);

  // Add total calculations
  const totalDebit = rows.reduce((sum, r) => sum + Number(r.debit || 0), 0);
  const totalCredit = rows.reduce((sum, r) => sum + Number(r.credit || 0), 0);

  return (
    <Box p={3}>
      <Typography variant="h5" fontWeight={700} mb={2}>
        Trial Balance
      </Typography>

      {totalDebit !== totalCredit && (
        <Typography color="error">
          Trial Balance is not balanced!
        </Typography>
      )}

      <Paper>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Account Code</TableCell>
              <TableCell>Account Name</TableCell>
              <TableCell align="right">Debit</TableCell>
              <TableCell align="right">Credit</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {rows.map((row) => (
              <TableRow key={row.accountId}>
                <TableCell>{row.code}</TableCell>
                <TableCell>{row.name}</TableCell>
                <TableCell align="right">{Number(row.debit).toLocaleString()}</TableCell>
                <TableCell align="right">{Number(row.credit).toLocaleString()}</TableCell>
              </TableRow>
            ))}

            <TableRow sx={{ fontWeight: "bold", background: "#fafafa" }}>
              <TableCell></TableCell>
              <TableCell><b>Total</b></TableCell>
              <TableCell align="right"><b>{totalDebit.toLocaleString()}</b></TableCell>
              <TableCell align="right"><b>{totalCredit.toLocaleString()}</b></TableCell>
            </TableRow>
          </TableBody>
        </Table>
      </Paper>
    </Box>
  );
};

export default TrialBalance;
