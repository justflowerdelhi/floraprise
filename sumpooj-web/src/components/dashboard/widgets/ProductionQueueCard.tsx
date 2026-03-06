import { Card, CardContent, Typography } from "@mui/material";

export default function ProductionQueueCard() {
  return (
    <Card sx={{ height: "100%" }}>
      <CardContent>

        <Typography fontSize={14} fontWeight={700} color="#f57c00">
          Production Queue
        </Typography>

        <Typography fontSize={28} fontWeight={700}>
          6
        </Typography>

        <Typography fontSize={12} color="text.secondary">
          Orders waiting design
        </Typography>

        <Typography fontSize={12}>
          #1042 Birthday Bouquet
        </Typography>

      </CardContent>
    </Card>
  );
}
