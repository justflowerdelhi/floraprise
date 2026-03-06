import { Grid, Typography } from "@mui/material";
import ProductionQueueCard from "./widgets/ProductionQueueCard";
import DeliveryTimelineCard from "./widgets/DeliveryTimelineCard";
import FlowerRiskCard from "./widgets/FlowerRiskCard";
import ReorderAlertsCard from "./widgets/ReorderAlertsCard";
import OperationalIntelligenceCard from "./widgets/OperationalIntelligenceCard";
import ComingSoonCard from "./widgets/ComingSoonCard";

export default function OperationsPanel() {
  return (
    <>
      <Grid container spacing={2}>
        <Grid item xs={12} md={2}>
          <ProductionQueueCard />
        </Grid>
        <Grid item xs={12} md={2}>
          <DeliveryTimelineCard />
        </Grid>
        <Grid item xs={12} md={2}>
          <FlowerRiskCard />
        </Grid>
        <Grid item xs={12} md={2}>
          <ReorderAlertsCard />
        </Grid>
        <Grid item xs={12} md={2}>
          <OperationalIntelligenceCard />
        </Grid>
        <Grid item xs={12} md={2}>
          <ComingSoonCard />
        </Grid>
      </Grid>
    </>
  );
}
