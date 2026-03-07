import React, { useEffect, useState } from "react";
import { Box, Typography, Card } from "@mui/material";
import { getProfitLossData } from "../accounting.service";

export default function ProfitLoss() {

  const [data, setData] = useState<any>(null);

  useEffect(() => {
    setData(getProfitLossData());
  }, []);

  if (!data) return null;

  return (
    <Box p={3}>
      <Typography variant="h5" mb={3}>
        Profit & Loss
      </Typography>

      <Card sx={{ p: 2, mb: 2 }}>
        Revenue: {data?.revenue || 0}
      </Card>

      <Card sx={{ p: 2, mb: 2 }}>
        COGS: {data?.cogs || 0}
      </Card>

      <Card sx={{ p: 2, mb: 2 }}>
        Gross Profit: {data?.grossProfit || 0}
      </Card>

      <Card sx={{ p: 2, mb: 2 }}>
        Expenses: {data?.expenses || 0}
      </Card>

      <Card sx={{ p: 2, mb: 2 }}>
        Net Profit: {data?.netProfit || 0}
      </Card>

      <Card sx={{ p: 2 }}>
        Profit Margin: {data?.margin || 0}%
      </Card>

    </Box>
  );
}
