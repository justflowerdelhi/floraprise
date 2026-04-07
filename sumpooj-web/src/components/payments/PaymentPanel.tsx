import React, { useState } from "react";
import { Box, Button, Grid, TextField, Typography, MenuItem } from "@mui/material";
import { formatCurrency } from "../../core/i18n";

type Payment = {
  mode: "Cash" | "Card" | "UPI";
  amount: number;
};

interface Props {
  total: number;
  onCheckout?: (payments: Payment[]) => void;
}

export default function PaymentPanel({ total, onCheckout }: Props) {
  const [payments, setPayments] = useState<Payment[]>([]);
  const [mode, setMode] = useState<"Cash" | "Card" | "UPI">("Cash");

  function addPayment(amount: number) {
    setPayments([...payments, { mode, amount }]);
  }

  function addSplit() {
    setPayments([...payments, { mode: "Cash", amount: 0 }]);
  }

  function updatePayment(index: number, field: string, value: any) {
    const updated = [...payments];
    updated[index] = { ...updated[index], [field]: value };
    setPayments(updated);
  }

  const paid = payments.reduce((sum, p) => sum + Number(p.amount || 0), 0);
  const balance = total - paid;

  function handleCheckout() {
    if (onCheckout) {
      onCheckout(payments);
    }
  }

  return (
    <Box sx={{ p: 2 }}>
      <Typography variant="h6">Order Summary</Typography>
      <Box sx={{ mt: 2 }}>
        <Typography>Subtotal: {formatCurrency(total)}</Typography>
        <Typography fontWeight="bold">Total: {formatCurrency(total)}</Typography>
      </Box>
      <Box sx={{ mt: 2 }}>
        <Grid container spacing={1}>
          <Grid size={4}>
            <Button
              fullWidth
              variant="outlined"
              onClick={() => addPayment(balance)}
            >
              Cash
            </Button>
          </Grid>
          <Grid size={4}>
            <Button
              fullWidth
              variant="outlined"
              onClick={() => {
                setMode("Card");
                addPayment(balance);
              }}
            >
              Card
            </Button>
          </Grid>
          <Grid size={4}>
            <Button
              fullWidth
              variant="outlined"
              onClick={addSplit}
            >
              Split
            </Button>
          </Grid>
        </Grid>
      </Box>
      {payments.length > 0 && (
        <Box sx={{ mt: 2 }}>
          {payments.map((p, i) => (
            <Grid container spacing={1} key={i} sx={{ mb: 1 }}>
              <Grid size={6}>
                <TextField
                  select
                  fullWidth
                  size="small"
                  value={p.mode}
                  onChange={(e) =>
                    updatePayment(i, "mode", e.target.value)
                  }
                >
                  <MenuItem value="Cash">Cash</MenuItem>
                  <MenuItem value="Card">Card</MenuItem>
                  <MenuItem value="UPI">UPI</MenuItem>
                </TextField>
              </Grid>
              <Grid size={6}>
                <TextField
                  fullWidth
                  size="small"
                  type="number"
                  value={p.amount}
                  onChange={(e) =>
                    updatePayment(i, "amount", Number(e.target.value))
                  }
                />
              </Grid>
            </Grid>
          ))}
        </Box>
      )}
      <Box sx={{ mt: 2 }}>
        <Typography>Total Paid: {formatCurrency(paid)}</Typography>
        <Typography color={balance > 0 ? "error" : "success.main"}>
          Balance: {formatCurrency(balance)}
        </Typography>
      </Box>
      <Button
        fullWidth
        variant="contained"
        sx={{ mt: 2 }}
        disabled={balance > 0}
        onClick={handleCheckout}
      >
        Checkout {formatCurrency(total)}
      </Button>
    </Box>
  );
}
