
import { Grid, TextField, MenuItem } from "@mui/material";

interface Props {
  advancePaid: number | "";
  setAdvancePaid: (v: number | "") => void;
  paymentMode: string;
  setPaymentMode: (v: string) => void;
  total: number;
}

const PAYMENT_MODES = [
  { value: "Cash", label: "Cash" },
  { value: "Card", label: "Card" },
  { value: "UPI", label: "UPI" },
];

export default function PaymentSection({
  advancePaid,
  setAdvancePaid,
  paymentMode,
  setPaymentMode,
  total,
}: Props) {

  const balance = total - (advancePaid || 0);

  return (
    <Grid container spacing={2} sx={{ mt: 2 }}>

      <Grid xs={12} md={3}>
        <TextField
          label="Advance Paid"
          type="number"
          value={advancePaid}
          onChange={(e) =>
            setAdvancePaid(e.target.value === "" ? "" : Number(e.target.value))
          }
          fullWidth
          size="small"
        />
      </Grid>

      <Grid xs={12} md={3}>
        <TextField
          select
          label="Payment Mode"
          value={paymentMode}
          onChange={(e) => setPaymentMode(e.target.value)}
          fullWidth
          size="small"
        >
          {PAYMENT_MODES.map((mode) => (
            <MenuItem key={mode.value} value={mode.value}>
              {mode.label}
            </MenuItem>
          ))}
        </TextField>
      </Grid>

      <Grid xs={12} md={3}>
        <TextField
          label="Order Total"
          value={total}
          fullWidth
          size="small"
          InputProps={{ readOnly: true }}
        />
      </Grid>

      <Grid xs={12} md={3}>
        <TextField
          label="Balance"
          value={balance}
          fullWidth
          size="small"
          InputProps={{ readOnly: true }}
        />
      </Grid>

    </Grid>
  );
}