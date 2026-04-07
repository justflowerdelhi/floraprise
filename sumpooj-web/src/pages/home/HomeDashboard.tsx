import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";

import Box from "@mui/material/Box";
import Grid from "@mui/material/Grid";
import Paper from "@mui/material/Paper";
import Typography from "@mui/material/Typography";

/* Icons */
import PointOfSaleIcon from "@mui/icons-material/PointOfSale";
import ShoppingCartIcon from "@mui/icons-material/ShoppingCart";
import Inventory2Icon from "@mui/icons-material/Inventory2";
import PeopleIcon from "@mui/icons-material/People";
import PrecisionManufacturingIcon from "@mui/icons-material/PrecisionManufacturing";
import EventIcon from "@mui/icons-material/Event";
import PaymentsIcon from "@mui/icons-material/Payments";
import BarChartIcon from "@mui/icons-material/BarChart";
import SettingsIcon from "@mui/icons-material/Settings";

/* Panels */
import OperationsPanel from "../../components/dashboard/OperationsPanel";
import MorningSetupPanel from "../../components/dashboard/MorningSetupPanel";

import { getDailyFinancialSummary } from "../../modules/accounting/accounting.service";
import { formatCurrency } from "../../core/i18n";

const HomeDashboard = () => {

  const topStats = [
    { title: "Today Sales", value: formatCurrency(0), subtitle: "0 transactions" },
    { title: "Pending Orders", value: "0", subtitle: "Needs attention" },
    { title: "Low Stock Items", value: "0", subtitle: "Below threshold" },
    { title: "Active Shift", value: "No Shift", subtitle: "Tap POS to open" },
    { title: "Upcoming Events", value: "0", subtitle: "Next 7 days" }
  ];

  const [financial, setFinancial] = useState({ salesToday: 0, expensesToday: 0, profitToday: 0, cashInDrawer: 0 });

  useEffect(() => {
    getDailyFinancialSummary().then(data => setFinancial(data));
  }, []);

  const financeStats = [
    { title: "Revenue Today", value: formatCurrency(financial.salesToday) },
    { title: "Expenses Today", value: formatCurrency(financial.expensesToday) },
    { title: "Profit Today", value: formatCurrency(financial.profitToday) },
    { title: "Cash Balance", value: formatCurrency(financial.cashInDrawer) }
  ];

  return (
    <Box p={3}>

      {/* TOP STATS */}
      <Grid container spacing={2} mb={2}>
        {topStats.map((stat, index) => (
          <Grid size={{ xs: 12, md: 2 }} key={index}>
            <Paper sx={{ p:2, borderRadius:2 }}>
              <Typography fontSize={13} color="text.secondary">
                {stat.title}
              </Typography>
              <Typography fontWeight={700} fontSize={18}>
                {stat.value}
              </Typography>
              <Typography fontSize={12} color="text.secondary">
                {stat.subtitle}
              </Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>


      {/* FINANCE STATS */}
      <Grid container spacing={2} mb={3}>
        {financeStats.map((stat, index) => (
          <Grid size={{ xs: 12, md: 3 }} key={index}>
            <Paper sx={{ p:2, borderRadius:2 }}>
              <Typography fontSize={13} color="text.secondary">
                {stat.title}
              </Typography>
              <Typography fontWeight={700} fontSize={20}>
                {stat.value}
              </Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>


      {/* MORNING SETUP PANEL */}
      <MorningSetupPanel />


      {/* OPERATIONS */}
      <Typography
        variant="subtitle1"
        fontWeight={600}
        sx={{ mt: 3, mb: 2 }}
      >
        Operations
      </Typography>

      <OperationsPanel />


      {/* SYSTEM MODULES */}
      <Typography
        variant="subtitle1"
        fontWeight={600}
        sx={{ mt: 4, mb: 2 }}
      >
        System Modules
      </Typography>

      <Grid container spacing={2} justifyContent="flex-start" alignItems="stretch">
        {([
          { icon: <PointOfSaleIcon sx={{ fontSize:32, color:'#7b1fa2', mb:1 }} />, label: 'POS', desc: 'Point of Sale', to: '/pos' },
          { icon: <ShoppingCartIcon sx={{ fontSize:32, color:'#3949ab', mb:1 }} />, label: 'Orders', desc: 'Manage orders', to: '/orders' },
          { icon: <Inventory2Icon sx={{ fontSize:32, color:'#2e7d32', mb:1 }} />, label: 'Inventory', desc: 'Stock & batches', to: '/inventory' },
          { icon: <PeopleIcon sx={{ fontSize:32, color:'#0288d1', mb:1 }} />, label: 'CRM', desc: 'Customer intelligence', to: '/crm' },
          { icon: <PrecisionManufacturingIcon sx={{ fontSize:32, color:'#d81b60', mb:1 }} />, label: 'Production', desc: 'Floral recipes & build', to: '/production' },
          { icon: <EventIcon sx={{ fontSize:32, color:'#fb8c00', mb:1 }} />, label: 'Events', desc: 'Weddings & events', to: '/events' },
          { icon: <PaymentsIcon sx={{ fontSize:32, color:'#00897b', mb:1 }} />, label: 'Payments', desc: 'Day close & shifts', to: '/payments' },
          { icon: <BarChartIcon sx={{ fontSize:32, color:'#5e35b1', mb:1 }} />, label: 'Reports', desc: 'Profit & analytics', to: '/reports' },
          { icon: <SettingsIcon sx={{ fontSize:32, color:'#6d4c41', mb:1 }} />, label: 'Settings', desc: 'Store configuration', to: '/settings' }
        ]).map((mod, idx) => (
          <Grid size={{ xs: 12, sm: 6, md: 3, lg: 2 }} key={mod.label} sx={{ display: 'flex' }}>
            <Paper
              component={Link}
              to={mod.to}
              sx={{
                p: 3,
                textAlign: 'center',
                borderRadius: 2,
                minWidth: 140,
                flexGrow: 1,
                display: 'flex',
                flexDirection: 'column',
                justifyContent: 'center',
                height: '100%'
              }}
            >
              {mod.icon}
              <Typography fontWeight={600}>{mod.label}</Typography>
              <Typography variant="body2" color="text.secondary">
                {mod.desc}
              </Typography>
            </Paper>
          </Grid>
        ))}
      </Grid>

    </Box>
  );
};

export default HomeDashboard;