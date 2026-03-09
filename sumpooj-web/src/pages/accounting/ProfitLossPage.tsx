import React, { useEffect, useState } from "react";
import {
  Box, Button, Card, CardContent, Typography, TextField, MenuItem,
  Table, TableHead, TableBody, TableRow, TableCell, CircularProgress,
  FormControl, InputLabel, Select,
} from "@mui/material";
import api from "../../api/axios";

interface RevenueBreakdown {
  Account: string;
  Amount: number;
}
interface ExpenseBreakdown {
  Account: string;
  Amount: number;
}
interface ProfitLossData {
  RevenueBreakdown: RevenueBreakdown[];
  COGSTotal: number;
  ExpenseBreakdown: ExpenseBreakdown[];
  GrossProfit: number;
  NetProfit: number;
}

const ProfitLossPage: React.FC = () => {
  const [data, setData] = useState<ProfitLossData | null>(null);
  const [startDate, setStartDate] = useState<string>("");
  const [endDate, setEndDate] = useState<string>("");
  const [locationId, setLocationId] = useState<string>("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (startDate && endDate) fetchData();
    // eslint-disable-next-line
  }, [startDate, endDate, locationId]);

  const fetchData = async () => {
    setLoading(true);
    try {
      const params: any = { startDate, endDate };
      if (locationId) params.locationId = locationId;
      const res = await api.get("/accounting/profit-loss", { params });
      setData(res.data);
    } catch {
      setData(null);
    }
    setLoading(false);
  };

  const exportCSV = () => {
    if (!data) return;
    let csv = "Section,Account,Amount\n";
    data.RevenueBreakdown.forEach((r: RevenueBreakdown) => csv += `Revenue,${r.Account},${r.Amount}\n`);
    csv += `COGS,,${data.COGSTotal}\n`;
    data.ExpenseBreakdown.forEach((e: ExpenseBreakdown) => csv += `Expense,${e.Account},${e.Amount}\n`);
    csv += `Gross Profit,,${data.GrossProfit}\n`;
    csv += `Net Profit,,${data.NetProfit}\n`;
    const blob = new Blob([csv], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "profit_loss_report.csv";
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const exportPDF = () => {
    window.print();
  };

  const rows = data ? [
    ...data.RevenueBreakdown.map((r: RevenueBreakdown) => ({ section: "Revenue", account: r.Account, amount: r.Amount })),
    { section: "COGS", account: "", amount: data.COGSTotal },
    ...data.ExpenseBreakdown.map((e: ExpenseBreakdown) => ({ section: "Expense", account: e.Account, amount: e.Amount })),
    { section: "Gross Profit", account: "", amount: data.GrossProfit },
    { section: "Net Profit", account: "", amount: data.NetProfit },
  ] : [];

  return (
    <Box p={3}>
      <Typography variant="h5" mb={2}>Profit &amp; Loss Report</Typography>
      <Box sx={{ display: "flex", gap: 2, mb: 2, flexWrap: "wrap" }}>
        <TextField
          label="Start Date"
          type="date"
          value={startDate}
          onChange={(e) => setStartDate(e.target.value)}
          InputLabelProps={{ shrink: true }}
          size="small"
        />
        <TextField
          label="End Date"
          type="date"
          value={endDate}
          onChange={(e) => setEndDate(e.target.value)}
          InputLabelProps={{ shrink: true }}
          size="small"
        />
        <FormControl size="small" sx={{ minWidth: 200 }}>
          <InputLabel>Location</InputLabel>
          <Select
            value={locationId}
            label="Location"
            onChange={(e) => setLocationId(e.target.value)}
          >
            <MenuItem value="">All</MenuItem>
          </Select>
        </FormControl>
        <Button variant="outlined" onClick={exportCSV}>Export CSV</Button>
        <Button variant="outlined" onClick={exportPDF}>Export PDF</Button>
      </Box>
      {data && (
        <Box sx={{ display: "flex", gap: 2, mb: 2, flexWrap: "wrap" }}>
          <Card sx={{ flex: 1, minWidth: 140 }}><CardContent><Typography variant="caption">Revenue</Typography><Typography variant="h6">{data.RevenueBreakdown.reduce((sum: number, r: RevenueBreakdown) => sum + r.Amount, 0)}</Typography></CardContent></Card>
          <Card sx={{ flex: 1, minWidth: 140 }}><CardContent><Typography variant="caption">COGS</Typography><Typography variant="h6">{data.COGSTotal}</Typography></CardContent></Card>
          <Card sx={{ flex: 1, minWidth: 140 }}><CardContent><Typography variant="caption">Gross Profit</Typography><Typography variant="h6">{data.GrossProfit}</Typography></CardContent></Card>
          <Card sx={{ flex: 1, minWidth: 140 }}><CardContent><Typography variant="caption">Expenses</Typography><Typography variant="h6">{data.ExpenseBreakdown.reduce((sum: number, e: ExpenseBreakdown) => sum + e.Amount, 0)}</Typography></CardContent></Card>
          <Card sx={{ flex: 1, minWidth: 140 }}><CardContent><Typography variant="caption">Net Profit</Typography><Typography variant="h6">{data.NetProfit}</Typography></CardContent></Card>
        </Box>
      )}
      {loading && <CircularProgress sx={{ display: "block", mx: "auto", my: 4 }} />}
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Section</TableCell>
            <TableCell>Account</TableCell>
            <TableCell align="right">Amount</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {rows.map((row, idx: number) => (
            <TableRow key={idx}>
              <TableCell>{row.section}</TableCell>
              <TableCell>{row.account}</TableCell>
              <TableCell align="right">{row.amount}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
};

export default ProfitLossPage;
