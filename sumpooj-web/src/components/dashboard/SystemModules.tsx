import React from "react";
import { Typography, Grid, Paper } from "@mui/material";

export default function SystemModules() {
  return (
    <>
      <Typography
        variant="subtitle1"
        fontWeight={600}
        sx={{ mt: 4, mb: 2 }}
      >
        System Modules
      </Typography>

      <Grid container spacing={2}>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>POS</Typography>
            <Typography variant="body2" color="text.secondary">
              Point of Sale
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>Orders</Typography>
            <Typography variant="body2" color="text.secondary">
              Manage orders
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>Inventory</Typography>
            <Typography variant="body2" color="text.secondary">
              Stock & batches
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>CRM</Typography>
            <Typography variant="body2" color="text.secondary">
              Customer intelligence
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>Production</Typography>
            <Typography variant="body2" color="text.secondary">
              Floral recipes & build
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>Events</Typography>
            <Typography variant="body2" color="text.secondary">
              Weddings & events
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>Payments</Typography>
            <Typography variant="body2" color="text.secondary">
              Day close & shifts
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>Reports</Typography>
            <Typography variant="body2" color="text.secondary">
              Profit & analytics
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p:3, textAlign:"center", borderRadius:2 }}>
            <Typography fontWeight={600}>Settings</Typography>
            <Typography variant="body2" color="text.secondary">
              Store configuration
            </Typography>
          </Paper>
        </Grid>
      </Grid>
    </>
  );
}
