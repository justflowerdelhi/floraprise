import { Paper, Typography, Divider, Button } from "@mui/material";

interface Props {
  amount: number | "";
  onSubmit: () => void;
}

export default function OrderSummaryPanel({ amount, onSubmit }: Props) {

  const total = amount || 0;

  return (
    <Paper sx={{ p: 3, position: "sticky", top: 20 }}>

      <Typography variant="h6" sx={{ mb: 2 }}>
        Order Summary
      </Typography>

      <Divider sx={{ mb: 2 }} />

      <Typography>
        Product Total: ₹{total}
      </Typography>

      <Typography sx={{ fontWeight: 600, mt: 1 }}>
        Order Total: ₹{total}
      </Typography>

      <Divider sx={{ my: 2 }} />

      <Button
        variant="contained"
        fullWidth
        color="success"
        onClick={onSubmit}
      >
        Confirm Order
      </Button>

    </Paper>
  );
}
