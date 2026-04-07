import React from "react";
import { Grid, TextField, InputAdornment } from "@mui/material";
import { getCurrencySymbol } from "../../../core/i18n";

interface Props {
  productDescription: string;
  setProductDescription: (v: string) => void;
  amount: number | "";
  setAmount: (v: number | "") => void;
  isLocked: boolean;
}

export default function ProductSection({
  productDescription,
  setProductDescription,
  amount,
  setAmount,
  isLocked,
}: Props) {
  const currencySymbol = getCurrencySymbol();

  return (
    <Grid container spacing={2}>
      <Grid size={{ xs: 12, md: 8 }}>
        <TextField
          label="Product Description"
          value={productDescription}
          onChange={(e) => setProductDescription(e.target.value)}
          multiline
          rows={3}
          fullWidth
          size="small"
          disabled={isLocked}
        />
      </Grid>

      <Grid size={{ xs: 12, md: 4 }}>
        <TextField
          label="Amount"
          type="number"
          value={amount}
          onChange={(e) =>
            setAmount(e.target.value === "" ? "" : Number(e.target.value))
          }
          fullWidth
          size="small"
          InputProps={{
            startAdornment: (
              <InputAdornment position="start">{currencySymbol}</InputAdornment>
            ),
          }}
        />
      </Grid>
    </Grid>
  );
}

