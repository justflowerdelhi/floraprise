/**
 * ExternalOrdersInbox.tsx — FTD + BloomNation external order management
 *
 * Columns: External Order ID, Platform, Sender, Delivery, Recipient, Gross, Commission, Net Payout, Status
 * Actions: Accept, Reject, Assign Designer, Update Fulfillment Status
 */
import React, { useState } from 'react';
import {
  Box, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Paper, Chip, Button, IconButton, Tooltip, Select, MenuItem, FormControl, InputLabel,
  Dialog, DialogTitle, DialogContent, DialogActions, Snackbar, Alert, ToggleButton,
  ToggleButtonGroup, useTheme, alpha,
} from '@mui/material';
import type { SelectChangeEvent } from '@mui/material/Select';
import {
  CheckCircle as AcceptIcon,
  Cancel as RejectIcon,
  Brush as DesignerIcon,
  Visibility as ViewIcon,
  LocalFlorist as FloristIcon,
  Storefront as BloomIcon,
  LocalShipping as FTDIcon,
} from '@mui/icons-material';
import type { ExternalOrder, ExternalOrderStatus, FulfillmentStatus } from './OrderTypes';
import { FULFILLMENT_STATUS_CONFIG, DESIGNERS, ORDER_SOURCE_CONFIG } from './OrderTypes';
import { MOCK_EXTERNAL_ORDERS } from './OrderMockData';

const fmtCurrency = (v: number) =>
  new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR', maximumFractionDigits: 0 }).format(v);
const fmtDate = (iso: string) =>
  new Date(iso).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' });

const STATUS_COLORS: Record<ExternalOrderStatus, 'warning' | 'success' | 'error'> = {
  PENDING: 'warning', ACCEPTED: 'success', REJECTED: 'error',
};

const PLATFORM_COLORS: Record<string, string> = {
  FTD: ORDER_SOURCE_CONFIG.FTD.color,
  BLOOMNATION: ORDER_SOURCE_CONFIG.BLOOMNATION.color,
};

type PlatformFilter = 'ALL' | 'FTD' | 'BLOOMNATION';

const ExternalOrdersInbox: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  const [orders, setOrders] = useState<ExternalOrder[]>([...MOCK_EXTERNAL_ORDERS]);
  const [snackMsg, setSnackMsg] = useState('');
  const [detailOrder, setDetailOrder] = useState<ExternalOrder | null>(null);
  const [designerDialogId, setDesignerDialogId] = useState<string | null>(null);
  const [selectedDesigner, setSelectedDesigner] = useState('');
  const [fulfilMap, setFulfilMap] = useState<Record<string, FulfillmentStatus>>({});
  const [platformFilter, setPlatformFilter] = useState<PlatformFilter>('ALL');

  const filteredOrders = platformFilter === 'ALL'
    ? orders
    : orders.filter((o) => o.platform === platformFilter);

  const updateStatus = (id: string, status: ExternalOrderStatus) => {
    setOrders((prev) => prev.map((o) => (o.id === id ? { ...o, status } : o)));
    setSnackMsg(`Order ${status.toLowerCase()}`);
  };

  const handleDesignerAssign = () => {
    if (designerDialogId && selectedDesigner) {
      setSnackMsg(`${selectedDesigner} assigned to ${designerDialogId}`);
    }
    setDesignerDialogId(null);
    setSelectedDesigner('');
  };

  const handleFulfilChange = (id: string, e: SelectChangeEvent) => {
    const val = e.target.value as FulfillmentStatus;
    setFulfilMap((prev) => ({ ...prev, [id]: val }));
    setSnackMsg(`Status updated to ${FULFILLMENT_STATUS_CONFIG[val].label}`);
  };

  const headerSx = {
    fontWeight: 700, fontSize: '0.7rem', textTransform: 'uppercase' as const,
    letterSpacing: 0.5, whiteSpace: 'nowrap' as const,
    color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
    bgcolor: dk ? '#1a1a2e' : '#f5f5f5',
    borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.08)' : '#ddd'}`,
  };

  // Aggregates
  const nonRejected = filteredOrders.filter((o) => o.status !== 'REJECTED');
  const totalGross = nonRejected.reduce((s, o) => s + o.grossAmount, 0);
  const totalCommission = nonRejected.reduce((s, o) => s + o.commission, 0);
  const totalNet = nonRejected.reduce((s, o) => s + o.netPayout, 0);

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bgColor, minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3, flexWrap: 'wrap' }}>
        <FloristIcon sx={{ fontSize: 32, color: '#ff9800' }} />
        <Box sx={{ flex: 1 }}>
          <Typography variant="h4" sx={{ fontWeight: 800 }}>External Orders Inbox</Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
            Accept, reject, and manage orders from FTD &amp; BloomNation
          </Typography>
        </Box>
        {/* Platform Filter */}
        <ToggleButtonGroup
          size="small"
          exclusive
          value={platformFilter}
          onChange={(_, v) => { if (v) setPlatformFilter(v as PlatformFilter); }}
          sx={{ '& .MuiToggleButton-root': { textTransform: 'none', fontWeight: 600 } }}
        >
          <ToggleButton value="ALL">All</ToggleButton>
          <ToggleButton value="FTD">
            <FTDIcon sx={{ fontSize: 16, mr: 0.5 }} /> FTD
          </ToggleButton>
          <ToggleButton value="BLOOMNATION">
            <BloomIcon sx={{ fontSize: 16, mr: 0.5 }} /> BloomNation
          </ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {/* Stats */}
      <Box sx={{ display: 'flex', gap: 2, mb: 3, flexWrap: 'wrap' }}>
        {(['PENDING', 'ACCEPTED', 'REJECTED'] as ExternalOrderStatus[]).map((s) => {
          const count = filteredOrders.filter((o) => o.status === s).length;
          return (
            <Chip
              key={s}
              label={`${s}: ${count}`}
              color={STATUS_COLORS[s]}
              variant={dk ? 'outlined' : 'filled'}
              sx={{ fontWeight: 700 }}
            />
          );
        })}
        <Box sx={{ ml: 'auto', display: 'flex', gap: 1 }}>
          <Chip label={`Gross: ${fmtCurrency(totalGross)}`} variant="outlined" sx={{ fontWeight: 700 }} />
          <Chip
            label={`Commission: ${fmtCurrency(totalCommission)}`}
            variant="outlined"
            sx={{ fontWeight: 700, borderColor: theme.palette.error.main, color: theme.palette.error.main }}
          />
          <Chip
            label={`Net: ${fmtCurrency(totalNet)}`}
            variant="outlined"
            sx={{ fontWeight: 700, borderColor: '#fdd835', color: '#fdd835' }}
          />
        </Box>
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
              <TableCell sx={headerSx}>External ID</TableCell>
              <TableCell sx={headerSx}>Platform</TableCell>
              <TableCell sx={headerSx}>Sender</TableCell>
              <TableCell sx={headerSx}>Delivery</TableCell>
              <TableCell sx={headerSx}>Recipient</TableCell>
              <TableCell sx={headerSx} align="right">Gross</TableCell>
              <TableCell sx={headerSx} align="right">Commission</TableCell>
              <TableCell sx={headerSx} align="right">Net Payout</TableCell>
              <TableCell sx={headerSx}>Status</TableCell>
              <TableCell sx={headerSx}>Fulfillment</TableCell>
              <TableCell sx={headerSx} align="center">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredOrders.map((o) => {
              const pColor = PLATFORM_COLORS[o.platform] ?? '#ff9800';
              return (
                <TableRow
                  key={o.id}
                  hover
                  sx={{ '&:hover': { bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02) } }}
                >
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: 'monospace', fontSize: '0.82rem' }}>
                      {o.externalOrderId}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={o.platform === 'BLOOMNATION' ? 'BloomNation' : o.platform}
                      size="small"
                      sx={{ bgcolor: pColor, color: '#fff', fontWeight: 700, fontSize: '0.7rem' }}
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>{o.senderName}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">{fmtDate(o.deliveryDate)}</Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>{o.recipientName}</Typography>
                    <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
                      {o.recipientPhone}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(o.grossAmount)}</Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body2" sx={{ color: theme.palette.error.main, fontWeight: 600 }}>
                      -{fmtCurrency(o.commission)}
                    </Typography>
                  </TableCell>
                  <TableCell align="right">
                    <Typography variant="body2" sx={{ fontWeight: 700, color: '#fdd835' }}>
                      {fmtCurrency(o.netPayout)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Chip
                      label={o.status}
                      color={STATUS_COLORS[o.status]}
                      size="small"
                      variant={dk ? 'outlined' : 'filled'}
                      sx={{ fontWeight: 700, fontSize: '0.7rem' }}
                    />
                  </TableCell>
                  <TableCell>
                    {o.status === 'ACCEPTED' ? (
                      <FormControl size="small" sx={{ minWidth: 130 }}>
                        <Select
                          value={fulfilMap[o.id] || 'CONFIRMED'}
                          onChange={(e) => handleFulfilChange(o.id, e)}
                          sx={{
                            fontSize: '0.78rem',
                            ...(dk ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } } : {}),
                          }}
                        >
                          {(Object.keys(FULFILLMENT_STATUS_CONFIG) as FulfillmentStatus[]).map((fs) => (
                            <MenuItem key={fs} value={fs} sx={{ fontSize: '0.82rem' }}>
                              {FULFILLMENT_STATUS_CONFIG[fs].label}
                            </MenuItem>
                          ))}
                        </Select>
                      </FormControl>
                    ) : (
                      <Typography variant="caption" color="text.disabled">—</Typography>
                    )}
                  </TableCell>
                  <TableCell align="center">
                    <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                      <Tooltip title="View Details" arrow>
                        <IconButton size="small" onClick={() => setDetailOrder(o)}>
                          <ViewIcon sx={{ fontSize: 18 }} />
                        </IconButton>
                      </Tooltip>
                      {o.status === 'PENDING' && (
                        <>
                          <Tooltip title="Accept" arrow>
                            <IconButton size="small" color="success" onClick={() => updateStatus(o.id, 'ACCEPTED')}>
                              <AcceptIcon sx={{ fontSize: 18 }} />
                            </IconButton>
                          </Tooltip>
                          <Tooltip title="Reject" arrow>
                            <IconButton size="small" color="error" onClick={() => updateStatus(o.id, 'REJECTED')}>
                              <RejectIcon sx={{ fontSize: 18 }} />
                            </IconButton>
                          </Tooltip>
                        </>
                      )}
                      {o.status === 'ACCEPTED' && (
                        <Tooltip title="Assign Designer" arrow>
                          <IconButton size="small" color="secondary" onClick={() => setDesignerDialogId(o.id)}>
                            <DesignerIcon sx={{ fontSize: 18 }} />
                          </IconButton>
                        </Tooltip>
                      )}
                    </Box>
                  </TableCell>
                </TableRow>
              );
            })}
          </TableBody>
        </Table>
      </TableContainer>

      {/* ─── Detail Dialog ──────────────────────────────── */}
      <Dialog open={!!detailOrder} onClose={() => setDetailOrder(null)} maxWidth="sm" fullWidth>
        {detailOrder && (
          <>
            <DialogTitle sx={{ fontWeight: 700 }}>
              Order {detailOrder.externalOrderId}
              <Chip
                label={detailOrder.platform === 'BLOOMNATION' ? 'BloomNation' : detailOrder.platform}
                size="small"
                sx={{ ml: 1, bgcolor: PLATFORM_COLORS[detailOrder.platform] ?? '#ff9800', color: '#fff', fontWeight: 700 }}
              />
            </DialogTitle>
            <DialogContent dividers>
              <Box sx={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 2, mb: 2 }}>
                <Box>
                  <Typography variant="caption" color="text.secondary">Sender</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>{detailOrder.senderName}</Typography>
                </Box>
                <Box>
                  <Typography variant="caption" color="text.secondary">Recipient</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>{detailOrder.recipientName}</Typography>
                </Box>
                <Box>
                  <Typography variant="caption" color="text.secondary">Phone</Typography>
                  <Typography variant="body2">{detailOrder.recipientPhone}</Typography>
                </Box>
                <Box>
                  <Typography variant="caption" color="text.secondary">Delivery Date</Typography>
                  <Typography variant="body2">{fmtDate(detailOrder.deliveryDate)}</Typography>
                </Box>
              </Box>

              <Box sx={{ mb: 2 }}>
                <Typography variant="caption" color="text.secondary">Delivery Address</Typography>
                <Typography variant="body2">{detailOrder.deliveryAddress}</Typography>
              </Box>

              {detailOrder.deliveryInstructions && (
                <Box sx={{ mb: 2 }}>
                  <Typography variant="caption" color="text.secondary">Delivery Instructions</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {detailOrder.deliveryInstructions}
                  </Typography>
                </Box>
              )}

              <Box sx={{ mb: 2 }}>
                <Typography variant="caption" color="text.secondary">Card Message</Typography>
                <Typography variant="body2" sx={{ fontStyle: 'italic' }}>"{detailOrder.cardMessage}"</Typography>
              </Box>

              {/* Commission Breakdown */}
              <Box
                sx={{
                  mb: 2, p: 1.5, borderRadius: 1,
                  bgcolor: dk ? alpha('#fdd835', 0.06) : alpha('#fdd835', 0.1),
                  border: `1px solid ${dk ? alpha('#fdd835', 0.15) : alpha('#fdd835', 0.3)}`,
                }}
              >
                <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                  Commission Breakdown
                </Typography>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.3 }}>
                  <Typography variant="body2" color="text.secondary">Gross Revenue</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(detailOrder.grossAmount)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.3 }}>
                  <Typography variant="body2" color="text.secondary">
                    {detailOrder.platform === 'BLOOMNATION' ? 'BloomNation' : detailOrder.platform} Commission
                  </Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600, color: theme.palette.error.main }}>
                    -{fmtCurrency(detailOrder.commission)}
                  </Typography>
                </Box>
                {detailOrder.fees > 0 && (
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.3 }}>
                    <Typography variant="body2" color="text.secondary">Platform Fees</Typography>
                    <Typography variant="body2" sx={{ fontWeight: 600, color: theme.palette.error.main }}>
                      -{fmtCurrency(detailOrder.fees)}
                    </Typography>
                  </Box>
                )}
                <Box sx={{ display: 'flex', justifyContent: 'space-between', py: 0.3, pt: 0.8, borderTop: '1px solid', borderColor: dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)' }}>
                  <Typography variant="body2" sx={{ fontWeight: 800 }}>Net Payout</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 800, color: '#fdd835' }}>
                    {fmtCurrency(detailOrder.netPayout)}
                  </Typography>
                </Box>
              </Box>

              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>Items</Typography>
              {detailOrder.items.map((item, i) => (
                <Box key={i} sx={{ display: 'flex', justifyContent: 'space-between', py: 0.5 }}>
                  <Typography variant="body2">{item.quantity}× {item.productName}</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>{fmtCurrency(item.unitPrice)}</Typography>
                </Box>
              ))}
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setDetailOrder(null)}>Close</Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* ─── Assign Designer Dialog ─────────────────────── */}
      <Dialog open={!!designerDialogId} onClose={() => setDesignerDialogId(null)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>Assign Designer</DialogTitle>
        <DialogContent>
          <FormControl fullWidth size="small" sx={{ mt: 1 }}>
            <InputLabel>Designer</InputLabel>
            <Select value={selectedDesigner} label="Designer" onChange={(e) => setSelectedDesigner(e.target.value)}>
              {DESIGNERS.map((d) => <MenuItem key={d} value={d}>{d}</MenuItem>)}
            </Select>
          </FormControl>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDesignerDialogId(null)}>Cancel</Button>
          <Button variant="contained" onClick={handleDesignerAssign} disabled={!selectedDesigner}>Assign</Button>
        </DialogActions>
      </Dialog>

      <Snackbar open={!!snackMsg} autoHideDuration={2500} onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}>
        <Alert severity="success" variant="filled" onClose={() => setSnackMsg('')}>{snackMsg}</Alert>
      </Snackbar>
    </Box>
  );
};

export default ExternalOrdersInbox;
