import { Card, CardContent, Typography, Box } from "@mui/material";

export default function DeliveryTimelineCard() {
  return (
    <Card sx={{ height: "100%" }}>
      <CardContent>

        <Typography fontSize={14} fontWeight={700} color="#8e24aa">
          Delivery Timeline
        </Typography>

        <Box mt={1}>

          <Box display="flex" justifyContent="space-between">
            <Typography fontSize={15} fontWeight={600}>
              10:30 AM
            </Typography>
            <Typography fontSize={13} color="text.secondary">
              Birthday Bouquet
            </Typography>
          </Box>

          <Box display="flex" justifyContent="space-between">
            <Typography fontSize={15} fontWeight={600}>
              11:15 AM
            </Typography>
            <Typography fontSize={13} color="text.secondary">
              Sympathy Arrangement
            </Typography>
          </Box>

          <Box display="flex" justifyContent="space-between">
            <Typography fontSize={15} fontWeight={600}>
              1:30 PM
            </Typography>
            <Typography fontSize={13} color="text.secondary">
              Anniversary Roses
            </Typography>
          </Box>

        </Box>

      </CardContent>
    </Card>
  );
}
