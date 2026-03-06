import { Card, CardContent, Typography, Box } from "@mui/material";

export default function OperationalIntelligenceCard() {
  return (
    <Card sx={{ height: "100%" }}>
      <CardContent>

        <Typography fontSize={14} fontWeight={700} color="#1976d2">
          Operational Intelligence
        </Typography>

        <Box display="flex" gap={3} mt={1}>

          <Box textAlign="center">
            <Typography fontSize={20} fontWeight={700}>6</Typography>
            <Typography fontSize={11}>Production</Typography>
          </Box>

          <Box textAlign="center">
            <Typography fontSize={20} fontWeight={700}>3</Typography>
            <Typography fontSize={11}>Drivers Out</Typography>
          </Box>

          <Box textAlign="center">
            <Typography fontSize={20} fontWeight={700}>28</Typography>
            <Typography fontSize={11}>Expiring Flowers</Typography>
          </Box>

        </Box>

      </CardContent>
    </Card>
  );
}
