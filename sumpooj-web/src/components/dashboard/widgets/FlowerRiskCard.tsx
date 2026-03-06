import { Card, CardContent, Typography } from "@mui/material";

export default function FlowerRiskCard() {
  return (
    <Card sx={{ height: "100%" }}>
      <CardContent>

        <Typography fontSize={14} fontWeight={700} color="#e53935">
          Flower Risk
        </Typography>

        <Typography fontSize={28} fontWeight={700}>
          18
        </Typography>

        <Typography fontSize={12} color="text.secondary">
          Roses expiring tomorrow
        </Typography>

        <Typography fontSize={12} color="#e53935">
          Estimated loss ₹950
        </Typography>

        <Typography fontSize={12}>
          Sell today: Roses • Gerberas • Lilies
        </Typography>

      </CardContent>
    </Card>
  );
}
