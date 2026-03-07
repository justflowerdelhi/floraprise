import React, { useEffect, useState } from "react";
import {
  Box,
  Typography,
  Card,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody
} from "@mui/material";
import { getTrialBalance } from "../accounting.service";

export default function BalanceSheet() {

  const [assets, setAssets] = useState<any[]>([]);
  const [liabilities, setLiabilities] = useState<any[]>([]);
  const [equity, setEquity] = useState<any[]>([]);

  useEffect(() => {

    const rows = getTrialBalance();

    const a: any[] = [];
    const l: any[] = [];
    const e: any[] = [];

    rows.forEach((row: any) => {

      if (row.code.startsWith("1")) {
        a.push(row);
      }

      if (row.code.startsWith("2")) {
        l.push(row);
      }

      if (row.code.startsWith("3") || row.code.startsWith("4")) {
        e.push(row);
      }

    });

    setAssets(a);
    setLiabilities(l);
    setEquity(e);

  }, []);

  const renderRows = (rows: any[]) =>
    rows.map((r, i) => (
      <TableRow key={i}>
        <TableCell>{r.code}</TableCell>
        <TableCell>{r.name}</TableCell>
        <TableCell align="right">
          {r.code.startsWith("1")
            ? r.debit - r.credit
            : r.credit - r.debit}
        </TableCell>
      </TableRow>
    ));

  return (
    <Box p={3}>

      <Typography variant="h5" fontWeight={700} mb={3}>
        Balance Sheet
      </Typography>

      <Card sx={{ p: 2, mb: 3 }}>
        <Typography variant="h6">Assets</Typography>

        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Code</TableCell>
              <TableCell>Account</TableCell>
              <TableCell align="right">Amount</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {renderRows(assets)}
          </TableBody>
        </Table>
      </Card>

      <Card sx={{ p: 2, mb: 3 }}>
        <Typography variant="h6">Liabilities</Typography>

        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Code</TableCell>
              <TableCell>Account</TableCell>
              <TableCell align="right">Amount</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {renderRows(liabilities)}
          </TableBody>
        </Table>
      </Card>

      <Card sx={{ p: 2 }}>
        <Typography variant="h6">Equity</Typography>

        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Code</TableCell>
              <TableCell>Account</TableCell>
              <TableCell align="right">Amount</TableCell>
            </TableRow>
          </TableHead>

          <TableBody>
            {renderRows(equity)}
          </TableBody>
        </Table>
      </Card>

    </Box>
  );
}