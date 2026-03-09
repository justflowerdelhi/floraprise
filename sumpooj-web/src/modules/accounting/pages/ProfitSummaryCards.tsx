import React from 'react';
import { Box, Grid, Paper, Typography } from '@mui/material';

export interface ProfitSummaryCardProps {
  title: string;
  value: string | number;
  color?: string;
}

const ProfitSummaryCards: React.FC<{ cards: ProfitSummaryCardProps[] }> = ({ cards }) => (
  <Grid container spacing={2}>
    {cards.map((card, idx) => (
      <Grid size={{ xs: 12, sm: 6, md: 4, lg: 2 }} key={idx}>
        <Paper sx={{ p: 2, bgcolor: card.color || 'background.paper', minHeight: 100, display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', borderRadius: 2 }}>
          <Typography variant="subtitle2" color="text.secondary" sx={{ mb: 1 }}>{card.title}</Typography>
          <Typography variant="h5" fontWeight={700}>{card.value}</Typography>
        </Paper>
      </Grid>
    ))}
  </Grid>
);

export default ProfitSummaryCards;
