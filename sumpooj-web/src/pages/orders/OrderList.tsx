/**
 * OrderList.tsx — Unified order list with source badges, search & status filters
 * Supports: WALK_IN, PHONE, WEBSITE, FTD, BLOOMNATION
 */
import React, { useState, useMemo } from 'react';
import {
  Box, Typography, Paper, Chip, TextField, FormControl, InputLabel, Select, MenuItem,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  InputAdornment, useTheme, alpha, Button,
} from '@mui/material';
import type { SelectChangeEvent } from '@mui/material/Select';
import {
  Search as SearchIcon,
  Storefront as WalkInIcon,
  Phone as PhoneIcon,
  Public as WebIcon,
  LocalShipping as FTDIcon,
  LocalFlorist as BloomIcon,
  AddTask as AddTaskIcon,
} from '@mui/icons-material';
import type { Order, OrderSource, FulfillmentStatus, OrderPaymentStatus, OrderType } from './OrderTypes';
import { ORDER_SOURCE_CONFIG, FULFILLMENT_STATUS_CONFIG, PAYMENT_STATUS_CONFIG } from './OrderTypes';
import { MOCK_ORDERS } from './OrderMockData';
import { useTenant } from '../../core/tenant/TenantContext';
import { PermissionGate } from '../../core/rbac/RBACContext';
import CreateTaskDialog from '../tasks/CreateTaskDialog';

const fmtCurrency = (v: number) =>
  new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(v);
const fmtDateTime = (iso: string) =>
  new Date(iso).toLocaleString('en-IN', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' });

const SOURCE_ICONS: Record<OrderSource, React.ReactElement> = {
  WALK_IN: <WalkInIcon sx={{ fontSize: 16 }} />,
  PHONE: <PhoneIcon sx={{ fontSize: 16 }} />,
  WEBSITE: <WebIcon sx={{ fontSize: 16 }} />,
  FTD: <FTDIcon sx={{ fontSize: 16 }} />,
  BLOOMNATION: <BloomIcon sx={{ fontSize: 16 }} />,
};

const ORDER_TYPE_CONFIG: Record<OrderType, { label: string; color: string }> = {
  LOCAL: { label: 'Local', color: '#4caf50' },
  OUTGOING_NETWORK: { label: 'Outgoing Network', color: '#ff9800' },
  INCOMING_NETWORK: { label: 'Incoming Network', color: '#2196f3' },
};

const OrderList: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bg = dk ? '#0f0f0f' : '#f8f9fa';
  const { hasFeature } = useTenant();
  const wireEnabled = hasFeature('WIRE_MANAGEMENT');

  const [search, setSearch] = useState('');
  const [sourceFilter, setSourceFilter] = useState<OrderSource | 'ALL'>('ALL');
  const [statusFilter, setStatusFilter] = useState<FulfillmentStatus | 'ALL'>('ALL');
  const [payStatus, setPayStatus] = useState<OrderPaymentStatus | 'ALL'>('ALL');
  const [orderTypeFilter, setOrderTypeFilter] = useState<OrderType | 'ALL'>('ALL');
  const [taskDialogOpen, setTaskDialogOpen] = useState(false);

  const filtered = useMemo(() => {
    let list: Order[] = [...MOCK_ORDERS];
    if (sourceFilter !== 'ALL') list = list.filter((o) => o.orderSource === sourceFilter);
    if (statusFilter !== 'ALL') list = list.filter((o) => o.fulfillmentStatus === statusFilter);
    if (payStatus !== 'ALL') list = list.filter((o) => o.paymentStatus === payStatus);
    if (wireEnabled && orderTypeFilter !== 'ALL') {
      list = list.filter((o) => (o.orderType ?? 'LOCAL') === orderTypeFilter);
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (o) =>
          o.id.toLowerCase().includes(q) ||
          (o.customerName ?? '').toLowerCase().includes(q) ||
          (o.customerPhone ?? '').includes(q),
      );
    }
    return list;
  }, [search, sourceFilter, statusFilter, payStatus, orderTypeFilter, wireEnabled]);

  const headerSx = {
    fontWeight: 700, fontSize: '0.7rem', textTransform: 'uppercase' as const,
    letterSpacing: 0.5, whiteSpace: 'nowrap' as const,
    color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
    bgcolor: dk ? '#1a1a2e' : '#f5f5f5',
    borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.08)' : '#ddd'}`,
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      {/* Title */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 0.5 }}>
        <Typography variant="h4" sx={{ fontWeight: 800 }}>All Orders</Typography>
        <PermissionGate permission="tasks:manage">
          <Button
            variant="outlined"
            size="small"
            startIcon={<AddTaskIcon />}
            onClick={() => setTaskDialogOpen(true)}
            sx={{ fontWeight: 600, textTransform: 'none' }}
          >
            Create Task
          </Button>
        </PermissionGate>
      </Box>
      <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 3 }}>
        Unified view of every order across all channels
      </Typography>

      {/* Filters Row */}
      <Paper
        elevation={dk ? 0 : 1}
        sx={{
          p: 2, mb: 2, borderRadius: 2,
          bgcolor: dk ? '#1a1a2e' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center',
        }}
      >
        <TextField
          size="small"
          placeholder="Search by Order ID, Name, Phone…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          slotProps={{ input: { startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
          sx={{ minWidth: 260, flex: 1 }}
        />
        <FormControl size="small" sx={{ minWidth: 130 }}>
          <InputLabel>Source</InputLabel>
          <Select value={sourceFilter} label="Source" onChange={(e: SelectChangeEvent) => setSourceFilter(e.target.value as OrderSource | 'ALL')}>
            <MenuItem value="ALL">All Sources</MenuItem>
            {(Object.keys(ORDER_SOURCE_CONFIG) as OrderSource[]).map((s) => (
              <MenuItem key={s} value={s}>{ORDER_SOURCE_CONFIG[s].label}</MenuItem>
            ))}
          </Select>
        </FormControl>
        <FormControl size="small" sx={{ minWidth: 150 }}>
          <InputLabel>Fulfillment</InputLabel>
          <Select value={statusFilter} label="Fulfillment" onChange={(e: SelectChangeEvent) => setStatusFilter(e.target.value as FulfillmentStatus | 'ALL')}>
            <MenuItem value="ALL">All Statuses</MenuItem>
            {(Object.keys(FULFILLMENT_STATUS_CONFIG) as FulfillmentStatus[]).map((fs) => (
              <MenuItem key={fs} value={fs}>{FULFILLMENT_STATUS_CONFIG[fs].label}</MenuItem>
            ))}
          </Select>
        </FormControl>
        <FormControl size="small" sx={{ minWidth: 130 }}>
          <InputLabel>Payment</InputLabel>
          <Select value={payStatus} label="Payment" onChange={(e: SelectChangeEvent) => setPayStatus(e.target.value as OrderPaymentStatus | 'ALL')}>
            <MenuItem value="ALL">All</MenuItem>
            {(Object.keys(PAYMENT_STATUS_CONFIG) as OrderPaymentStatus[]).map((ps) => (
              <MenuItem key={ps} value={ps}>{PAYMENT_STATUS_CONFIG[ps].label}</MenuItem>
            ))}
          </Select>
        </FormControl>
        {wireEnabled && (
          <FormControl size="small" sx={{ minWidth: 160 }}>
            <InputLabel>Order Type</InputLabel>
            <Select
              value={orderTypeFilter}
              label="Order Type"
              onChange={(e: SelectChangeEvent) => setOrderTypeFilter(e.target.value as OrderType | 'ALL')}
            >
              <MenuItem value="ALL">All Types</MenuItem>
              {(Object.keys(ORDER_TYPE_CONFIG) as OrderType[]).map((ot) => (
                <MenuItem key={ot} value={ot}>{ORDER_TYPE_CONFIG[ot].label}</MenuItem>
              ))}
            </Select>
          </FormControl>
        )}
      </Paper>

      {/* Stats bar */}
      <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
        <Chip label={`Total: ${filtered.length}`} variant="outlined" sx={{ fontWeight: 700 }} />
        {(Object.keys(ORDER_SOURCE_CONFIG) as OrderSource[]).map((s) => {
          const count = filtered.filter((o) => o.orderSource === s).length;
          if (!count) return null;
          const cfg = ORDER_SOURCE_CONFIG[s];
          return (
            <Chip
              key={s}
              icon={SOURCE_ICONS[s]}
              label={`${cfg.label}: ${count}`}
              size="small"
              sx={{
                bgcolor: alpha(cfg.color, dk ? 0.25 : 0.12),
                color: cfg.color,
                fontWeight: 700,
                fontSize: '0.74rem',
                '& .MuiChip-icon': { color: cfg.color },
              }}
            />
          );
        })}
        <Chip
          label={`Revenue: ${fmtCurrency(filtered.reduce((s, o) => s + o.totals.grandTotal, 0))}`}
          variant="outlined"
          sx={{ fontWeight: 700, ml: 'auto' }}
        />
      </Box>

      {/* Table */}
      <TableContainer
        component={Paper}
        elevation={dk ? 0 : 1}
        sx={{
          bgcolor: dk ? '#0f0f0f' : '#fff',
          border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          borderRadius: 2,
        }}
      >
        <Table size="small">
          <TableHead>
            <TableRow>
              <TableCell sx={headerSx}>Order #</TableCell>
              <TableCell sx={headerSx}>Source</TableCell>
              {wireEnabled && <TableCell sx={headerSx}>Order Type</TableCell>}
              <TableCell sx={headerSx}>Customer</TableCell>
              <TableCell sx={headerSx}>Created</TableCell>
              <TableCell sx={headerSx} align="right">Total</TableCell>
              <TableCell sx={headerSx} align="right">Net Payout</TableCell>
              <TableCell sx={headerSx}>Fulfillment</TableCell>
              <TableCell sx={headerSx}>Payment</TableCell>
              <TableCell sx={headerSx} align="right">Items</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={wireEnabled ? 10 : 9} align="center" sx={{ py: 6 }}>
                  <Typography color="text.disabled">No orders match the current filters</Typography>
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((o) => {
                const srcCfg = ORDER_SOURCE_CONFIG[o.orderSource];
                const fCfg = FULFILLMENT_STATUS_CONFIG[o.fulfillmentStatus];
                const pCfg = PAYMENT_STATUS_CONFIG[o.paymentStatus];
                const hasCommission = o.netPayout != null;
                const orderType = o.orderType ?? 'LOCAL';
                const typeCfg = ORDER_TYPE_CONFIG[orderType];
                return (
                  <TableRow key={o.id} hover sx={{ '&:hover': { bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02) } }}>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: 'monospace', fontSize: '0.82rem' }}>
                        {o.orderNumber}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        icon={SOURCE_ICONS[o.orderSource]}
                        label={srcCfg.label}
                        size="small"
                        sx={{
                          bgcolor: alpha(srcCfg.color, dk ? 0.25 : 0.12),
                          color: srcCfg.color,
                          fontWeight: 700,
                          fontSize: '0.7rem',
                          '& .MuiChip-icon': { color: srcCfg.color },
                        }}
                      />
                    </TableCell>
                    {wireEnabled && (
                      <TableCell>
                        <Chip
                          label={typeCfg.label}
                          size="small"
                          sx={{
                            bgcolor: alpha(typeCfg.color, dk ? 0.25 : 0.12),
                            color: typeCfg.color,
                            fontWeight: 700,
                            fontSize: '0.7rem',
                          }}
                        />
                      </TableCell>
                    )}
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>{o.customerName}</Typography>
                      {o.recipientName && o.recipientName !== o.customerName && (
                        <Typography variant="caption" sx={{ display: 'block', color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
                          → {o.recipientName}
                        </Typography>
                      )}
                      <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
                        {o.customerPhone}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>{fmtDateTime(o.createdAt)}</Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(o.totals.grandTotal)}</Typography>
                    </TableCell>
                    <TableCell align="right">
                      {hasCommission ? (
                        <Typography variant="body2" sx={{ fontWeight: 700, color: '#fdd835' }}>
                          {fmtCurrency(o.netPayout!)}
                        </Typography>
                      ) : (
                        <Typography variant="caption" color="text.disabled">—</Typography>
                      )}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={fCfg.label}
                        size="small"
                        sx={{
                          bgcolor: alpha(fCfg.color, dk ? 0.25 : 0.12),
                          color: fCfg.color,
                          fontWeight: 700,
                          fontSize: '0.7rem',
                        }}
                      />
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={pCfg.label}
                        size="small"
                        sx={{
                          bgcolor: alpha(pCfg.color, dk ? 0.25 : 0.12),
                          color: pCfg.color,
                          fontWeight: 700,
                          fontSize: '0.7rem',
                        }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2">{o.items.length}</Typography>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Create Task Dialog */}
      <CreateTaskDialog
        open={taskDialogOpen}
        onClose={() => setTaskDialogOpen(false)}
        defaults={{ relatedEntityType: 'ORDER' }}
      />
    </Box>
  );
};

export default OrderList;
