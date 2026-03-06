import { Card, CardContent, Typography } from "@mui/material";

export default function ReorderAlertsCard() {
  return (
    <Card sx={{ height: "100%" }}>
      <CardContent>

        <Typography fontSize={14} fontWeight={700} color="#f9a825">
          Reorder Alerts
        </Typography>

        <Typography fontSize={28} fontWeight={700}>
          4
        </Typography>

        <Typography fontSize={12} color="text.secondary">
          Items below reorder level
        </Typography>

        <Typography fontSize={12}>
          Roses • Lilies • Wrapping Paper
        </Typography>

      </CardContent>
    </Card>
  );
}
