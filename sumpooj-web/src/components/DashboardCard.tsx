import React from "react";
import { Grid, Typography, Paper, Box } from "@mui/material";

interface DashboardCardProps {
  title: string;
  children: React.ReactNode;
  color?: string;
  icon?: React.ReactNode;
}

const colorMap: Record<string, string> = {
  info: '#1976d2', // Blue - Information
  warning: '#d32f2f', // Red - Warning
  logistics: '#7b1fa2', // Purple - Logistics
  work: '#f57c00', // Orange - Work
  inventory: '#fbc02d', // Amber - Inventory
};

const DashboardCard = ({ title, children, color = 'info', icon }: DashboardCardProps) => {
  const barColor = colorMap[color] || colorMap.info;
  return (
    <Paper
      sx={{
        height: '100%',
        p: 2.5,
        borderRadius: 2,
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'space-between'
      }}
    >
      <Box
        sx={{
          height: 4,
          background: barColor,
          borderRadius: "4px 4px 0 0",
          mb: 1,
        }}
      />
      <Box display="flex" alignItems="center" gap={1} mb={1}>
        {icon && React.cloneElement(icon as React.ReactElement<any>, { sx: { fontSize: 18, color: barColor } })}
        <Typography variant="subtitle2" fontWeight={700} sx={{ color: barColor }}>
          {title}
        </Typography>
      </Box>
      <Box sx={{ flexGrow: 1 }}>
        {children}
      </Box>
    </Paper>
  );
};

export default DashboardCard;
