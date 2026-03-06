import { Box, Paper, Typography, Grid, Button } from "@mui/material";
import WbSunnyIcon from "@mui/icons-material/WbSunny";
import PrecisionManufacturingIcon from "@mui/icons-material/PrecisionManufacturing";
import LocalShippingIcon from "@mui/icons-material/LocalShipping";
import LocalFloristIcon from "@mui/icons-material/LocalFlorist";
import InventoryIcon from "@mui/icons-material/Inventory";
import { useNavigate } from "react-router-dom";

const MorningSetupPanel = () => {
  const navigate = useNavigate();

  const data = {
    productionQueue: 6,
    deliveriesToday: 3,
    flowersExpiring: 28,
    reorderAlerts: 4
  };

  return (
    <Paper
      sx={{
        p: 3,
        mb: 3,
        background: "#FFF8E1",
        borderRadius: 3
      }}
    >
      <Box display="flex" alignItems="center" gap={1} mb={2}>
        <WbSunnyIcon color="warning" />
        <Typography variant="h6" fontWeight={700}>
          Good Morning
        </Typography>
      </Box>

      <Typography color="text.secondary" mb={2}>
        Here's what needs attention today
      </Typography>

      <Grid container spacing={2}>

        <Grid item xs={6} md={3}>
          <Box display="flex" alignItems="center" gap={1}>
            <PrecisionManufacturingIcon color="primary" />
            <Typography>
              {data.productionQueue} Orders waiting production
            </Typography>
          </Box>
        </Grid>

        <Grid item xs={6} md={3}>
          <Box display="flex" alignItems="center" gap={1}>
            <LocalShippingIcon color="success" />
            <Typography>
              {data.deliveriesToday} Deliveries scheduled
            </Typography>
          </Box>
        </Grid>

        <Grid item xs={6} md={3}>
          <Box display="flex" alignItems="center" gap={1}>
            <LocalFloristIcon color="error" />
            <Typography>
              {data.flowersExpiring} Flowers expiring
            </Typography>
          </Box>
        </Grid>

        <Grid item xs={6} md={3}>
          <Box display="flex" alignItems="center" gap={1}>
            <InventoryIcon color="warning" />
            <Typography>
              {data.reorderAlerts} Items need reorder
            </Typography>
          </Box>
        </Grid>

      </Grid>

      <Box mt={3} display="flex" gap={2}>

        <Button
          variant="contained"
          onClick={() => navigate("/production/produce")}
        >
          Start Production
        </Button>

        <Button
          variant="outlined"
          onClick={() => navigate("/deliveries")}
        >
          View Deliveries
        </Button>

      </Box>
    </Paper>
  );
};

export default MorningSetupPanel;
