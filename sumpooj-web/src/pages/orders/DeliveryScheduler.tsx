/**
 * DeliveryScheduler.tsx — Delivery management grouped by date/time-slot
 *
 * Shows all scheduled deliveries with driver assignment,
 * status updates, and timeline grouping.
 */
import React, { useState, useMemo } from 'react';
import {
  Box, Typography, Paper, Chip, Select, MenuItem, FormControl,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Tabs, Tab, Badge, useTheme, alpha,
} from '@mui/material';
import type { SelectChangeEvent } from '@mui/material/Select';
import {
  LocalShipping as TruckIcon,
  Schedule as ClockIcon,
  Place as PinIcon,
} from '@mui/icons-material';
import type { DeliveryEntry, FulfillmentStatus } from './OrderTypes';
import { FULFILLMENT_STATUS_CONFIG, TIME_SLOTS, DRIVERS } from './OrderTypes';
import { MOCK_DELIVERIES } from './OrderMockData';

const fmtDate = (iso: string) =>
  new Date(iso).toLocaleDateString('en-IN', { weekday: 'short', day: '2-digit', month: 'short' });

const DeliveryScheduler: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bg = dk ? '#0f0f0f' : '#f8f9fa';

  const [deliveries, setDeliveries] = useState<DeliveryEntry[]>([...MOCK_DELIVERIES]);
  const [tabIdx, setTabIdx] = useState(0);

  /* unique sorted dates */
  const dates = useMemo(() => {
    const set = new Set(deliveries.map((d) => d.deliveryDate));
    return [...set].sort();
  }, [deliveries]);

  const activeDate = dates[tabIdx] ?? dates[0] ?? '';

  /* rows for current date, grouped by time slot */
  const rows = useMemo(() => {
    const subset = deliveries.filter((d) => d.deliveryDate === activeDate);
    return TIME_SLOTS.map((ts) => ({
      slot: ts,
      entries: subset.filter((d) => d.timeSlot === ts),
    }));
  }, [deliveries, activeDate]);

  const handleDriverChange = (orderId: string, e: SelectChangeEvent) => {
    setDeliveries((prev) => prev.map((d) => (d.orderId === orderId ? { ...d, assignedDriver: e.target.value } : d)));
  };

  const handleStatusChange = (orderId: string, e: SelectChangeEvent) => {
    const val = e.target.value as FulfillmentStatus;
    setDeliveries((prev) => prev.map((d) => (d.orderId === orderId ? { ...d, fulfillmentStatus: val } : d)));
  };

  const headerSx = {
    fontWeight: 700, fontSize: '0.7rem', textTransform: 'uppercase' as const,
    letterSpacing: 0.5, whiteSpace: 'nowrap' as const,
    color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
    bgcolor: dk ? '#1a1a2e' : '#f5f5f5',
    borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.08)' : '#ddd'}`,
  };

  /* summary counters */
  const todayDeliveries = deliveries.filter((d) => d.deliveryDate === activeDate);
  const statusCounts = todayDeliveries.reduce<Record<string, number>>((acc, d) => {
    acc[d.fulfillmentStatus] = (acc[d.fulfillmentStatus] || 0) + 1;
    return acc;
  }, {});

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <TruckIcon sx={{ fontSize: 32, color: dk ? '#fdd835' : '#1976d2' }} />
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 800 }}>Delivery Scheduler</Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            Manage deliveries, assign drivers, and track fulfillment
          </Typography>
        </Box>
      </Box>

      {/* Date Tabs */}
      <Paper
        elevation={dk ? 0 : 1}
        sx={{
          mb: 2,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          borderRadius: 2,
        }}
      >
        <Tabs
          value={tabIdx}
          onChange={(_, v) => setTabIdx(v)}
          variant="scrollable"
          scrollButtons="auto"
          sx={{ '& .MuiTab-root': { fontWeight: 700, textTransform: 'none' } }}
        >
          {dates.map((d) => {
            const count = deliveries.filter((e) => e.deliveryDate === d).length;
            return (
              <Tab
                key={d}
                label={
                  <Badge badgeContent={count} color="primary" sx={{ '& .MuiBadge-badge': { fontWeight: 700 } }}>
                    <Box sx={{ pr: 1.5 }}>{fmtDate(d)}</Box>
                  </Badge>
                }
              />
            );
          })}
        </Tabs>
      </Paper>

      {/* Status Chips */}
      <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
        {Object.entries(statusCounts).map(([s, c]) => {
          const cfg = FULFILLMENT_STATUS_CONFIG[s as FulfillmentStatus];
          return cfg ? (
            <Chip
              key={s}
              label={`${cfg.label}: ${c}`}
              size="small"
              sx={{
                bgcolor: alpha(cfg.color, dk ? 0.25 : 0.12),
                color: cfg.color,
                fontWeight: 700,
                fontSize: '0.74rem',
              }}
            />
          ) : null;
        })}
      </Box>

      {/* Time Slot Sections */}
      {rows.map(({ slot, entries }) => (
        <Paper
          key={slot}
          elevation={dk ? 0 : 1}
          sx={{
            mb: 2,
            bgcolor: dk ? '#0f0f0f' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            borderRadius: 2,
            overflow: 'hidden',
          }}
        >
          {/* Slot header */}
          <Box
            sx={{
              px: 2, py: 1.2,
              bgcolor: dk ? '#1a1a2e' : '#f5f5f5',
              display: 'flex', alignItems: 'center', gap: 1,
              borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.05)' : '#eee'}`,
            }}
          >
            <ClockIcon sx={{ fontSize: 18, color: dk ? '#fdd835' : '#1976d2' }} />
            <Typography variant="subtitle2" sx={{ fontWeight: 700 }}>{slot}</Typography>
            <Chip label={`${entries.length}`} size="small" color="primary" sx={{ fontWeight: 700, height: 20, fontSize: '0.72rem' }} />
          </Box>

          {entries.length === 0 ? (
            <Box sx={{ p: 2 }}>
              <Typography variant="body2" color="text.disabled">No deliveries in this slot</Typography>
            </Box>
          ) : (
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell sx={headerSx}>Order</TableCell>
                    <TableCell sx={headerSx}>Recipient</TableCell>
                    <TableCell sx={headerSx}>Address</TableCell>
                    <TableCell sx={headerSx}>Driver</TableCell>
                    <TableCell sx={headerSx}>Status</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {entries.map((e) => {
                    const cfg = FULFILLMENT_STATUS_CONFIG[e.fulfillmentStatus];
                    return (
                      <TableRow key={e.orderId} hover sx={{ '&:hover': { bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02) } }}>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: 'monospace', fontSize: '0.82rem' }}>
                            {e.orderNumber}
                          </Typography>
                          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
                            {e.orderSource}
                          </Typography>
                        </TableCell>
                        <TableCell>
                          <Typography variant="body2" sx={{ fontWeight: 600 }}>{e.recipientName}</Typography>
                        </TableCell>
                        <TableCell>
                          <Box sx={{ display: 'flex', alignItems: 'flex-start', gap: 0.5 }}>
                            <PinIcon sx={{ fontSize: 14, mt: 0.3, color: dk ? 'rgba(255,255,255,0.3)' : 'text.disabled' }} />
                            <Typography variant="body2" sx={{ maxWidth: 220, fontSize: '0.82rem' }}>{e.address}</Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <FormControl size="small" sx={{ minWidth: 120 }}>
                            <Select
                              value={e.assignedDriver}
                              onChange={(ev) => handleDriverChange(e.orderId, ev)}
                              sx={{
                                fontSize: '0.78rem',
                                ...(dk ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
                              }}
                            >
                              {DRIVERS.map((d) => (
                                <MenuItem key={d} value={d} sx={{ fontSize: '0.82rem' }}>{d}</MenuItem>
                              ))}
                            </Select>
                          </FormControl>
                        </TableCell>
                        <TableCell>
                          <Chip
                            label={cfg.label}
                            size="small"
                            sx={{
                              bgcolor: alpha(cfg.color, dk ? 0.25 : 0.12),
                              color: cfg.color,
                              fontWeight: 700,
                              fontSize: '0.7rem',
                            }}
                          />
                          <FormControl size="small" sx={{ minWidth: 125, ml: 1 }}>
                            <Select
                              value={e.fulfillmentStatus}
                              onChange={(ev) => handleStatusChange(e.orderId, ev)}
                              sx={{
                                fontSize: '0.72rem',
                                ...(dk ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
                              }}
                            >
                              {(Object.keys(FULFILLMENT_STATUS_CONFIG) as FulfillmentStatus[]).map((fs) => (
                                <MenuItem key={fs} value={fs} sx={{ fontSize: '0.78rem' }}>
                                  {FULFILLMENT_STATUS_CONFIG[fs].label}
                                </MenuItem>
                              ))}
                            </Select>
                          </FormControl>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </Paper>
      ))}
    </Box>
  );
};

export default DeliveryScheduler;
