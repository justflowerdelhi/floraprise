/**
 * RetailDeliveryFilterBar.tsx — Status and Date Filter Bar for Retail Deliveries
 */

import React from 'react';
import {
  Box,
  Paper,
  Tabs,
  Tab,
  Badge,
  ToggleButtonGroup,
  ToggleButton,
  TextField,
  InputAdornment,
  IconButton,
  Tooltip,
  Typography,
  useTheme,
  alpha,
} from '@mui/material';
import {
  Search as SearchIcon,
  Clear as ClearIcon,
  Refresh as RefreshIcon,
  Schedule as ScheduledIcon,
  LocalShipping as TruckIcon,
  CheckCircle as DeliveredIcon,
  ViewList as AllIcon,
} from '@mui/icons-material';
import type { DeliveryFilterStatus, DeliveryDateFilter } from './retailDelivery.types';

interface RetailDeliveryFilterBarProps {
  statusFilter: DeliveryFilterStatus;
  onStatusFilterChange: (status: DeliveryFilterStatus) => void;
  dateFilter: DeliveryDateFilter;
  onDateFilterChange: (date: DeliveryDateFilter) => void;
  searchQuery: string;
  onSearchQueryChange: (query: string) => void;
  counts: {
    all: number;
    scheduled: number;
    outForDelivery: number;
    delivered: number;
  };
  onRefresh: () => void;
  loading?: boolean;
}

export const RetailDeliveryFilterBar: React.FC<RetailDeliveryFilterBarProps> = ({
  statusFilter,
  onStatusFilterChange,
  dateFilter,
  onDateFilterChange,
  searchQuery,
  onSearchQueryChange,
  counts,
  onRefresh,
  loading = false,
}) => {
  const theme = useTheme();

  return (
    <Paper
      elevation={0}
      sx={{
        p: 2,
        mb: 3,
        borderRadius: 2,
        border: `1px solid ${theme.palette.divider}`,
        bgcolor: 'background.paper',
        display: 'flex',
        flexDirection: 'column',
        gap: 2,
      }}
    >
      {/* Top Row: Date filter + Search input + Refresh */}
      <Box
        sx={{
          display: 'flex',
          flexWrap: 'wrap',
          alignItems: 'center',
          justifyContent: 'space-between',
          gap: 2,
        }}
      >
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, flexWrap: 'wrap' }}>
          <Typography variant="body2" sx={{ fontWeight: 600, color: 'text.secondary' }}>
            Schedule:
          </Typography>
          <ToggleButtonGroup
            size="small"
            value={dateFilter}
            exclusive
            onChange={(_, val) => {
              if (val) onDateFilterChange(val);
            }}
            sx={{
              '& .MuiToggleButton-root': {
                px: 2,
                py: 0.5,
                fontWeight: 600,
                textTransform: 'none',
                borderRadius: 1.5,
              },
            }}
          >
            <ToggleButton value="TODAY">Today</ToggleButton>
            <ToggleButton value="TOMORROW">Tomorrow</ToggleButton>
            <ToggleButton value="ALL_ACTIVE">All Active</ToggleButton>
          </ToggleButtonGroup>
        </Box>

        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, flex: 1, minWidth: 260, maxWidth: 460 }}>
          <TextField
            fullWidth
            size="small"
            placeholder="Search recipient, phone, order #, or address..."
            value={searchQuery}
            onChange={(e) => onSearchQueryChange(e.target.value)}
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon fontSize="small" color="action" />
                  </InputAdornment>
                ),
                endAdornment: searchQuery ? (
                  <InputAdornment position="end">
                    <IconButton size="small" onClick={() => onSearchQueryChange('')} edge="end">
                      <ClearIcon fontSize="small" />
                    </IconButton>
                  </InputAdornment>
                ) : null,
              },
            }}
          />

          <Tooltip title="Refresh Deliveries">
            <span>
              <IconButton
                size="small"
                onClick={onRefresh}
                disabled={loading}
                sx={{
                  border: `1px solid ${theme.palette.divider}`,
                  p: 0.8,
                  borderRadius: 1.5,
                }}
              >
                <RefreshIcon fontSize="small" />
              </IconButton>
            </span>
          </Tooltip>
        </Box>
      </Box>

      {/* Bottom Row: Status Tabs with count badges */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs
          value={statusFilter}
          onChange={(_, val) => onStatusFilterChange(val)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{
            minHeight: 44,
            '& .MuiTab-root': {
              minHeight: 44,
              py: 0.5,
              px: 2,
              textTransform: 'none',
              fontWeight: 600,
              fontSize: '0.9rem',
            },
          }}
        >
          <Tab
            value="ALL"
            icon={<AllIcon fontSize="small" />}
            iconPosition="start"
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>All Orders</span>
                <Badge badgeContent={counts.all} color="default" max={999} />
              </Box>
            }
          />
          <Tab
            value="SCHEDULED"
            icon={<ScheduledIcon fontSize="small" sx={{ color: '#2196f3' }} />}
            iconPosition="start"
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>Pending Dispatch</span>
                <Badge
                  badgeContent={counts.scheduled}
                  color="primary"
                  max={999}
                  sx={{
                    '& .MuiBadge-badge': { bgcolor: '#2196f3' },
                  }}
                />
              </Box>
            }
          />
          <Tab
            value="OUT_FOR_DELIVERY"
            icon={<TruckIcon fontSize="small" sx={{ color: '#ff9800' }} />}
            iconPosition="start"
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>Out for Delivery</span>
                <Badge
                  badgeContent={counts.outForDelivery}
                  max={999}
                  sx={{
                    '& .MuiBadge-badge': { bgcolor: '#ff9800', color: '#fff' },
                  }}
                />
              </Box>
            }
          />
          <Tab
            value="DELIVERED"
            icon={<DeliveredIcon fontSize="small" sx={{ color: '#4caf50' }} />}
            iconPosition="start"
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <span>Delivered</span>
                <Badge
                  badgeContent={counts.delivered}
                  max={999}
                  sx={{
                    '& .MuiBadge-badge': { bgcolor: '#4caf50', color: '#fff' },
                  }}
                />
              </Box>
            }
          />
        </Tabs>
      </Box>
    </Paper>
  );
};
