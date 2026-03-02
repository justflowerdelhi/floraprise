/**
 * PurchaseListPage.tsx — Purchase Orders List
 *
 * Shows all purchase orders with status, supplier, totals.
 * Provides actions: View, Receive, Submit, Approve, Cancel.
 */
import { useState, useEffect, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box, Typography, Paper, Chip, TextField, FormControl, InputLabel, Select, MenuItem,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  InputAdornment, useTheme, alpha, Button, CircularProgress,
  Dialog, DialogTitle, DialogContent, DialogActions, IconButton, Tooltip,
  Snackbar, Alert, Grid,
} from '@mui/material';
import type { SelectChangeEvent } from '@mui/material/Select';
import {
  Search as SearchIcon,
  Add as AddIcon,
  Refresh as RefreshIcon,
  Visibility as ViewIcon,
  CallReceived as ReceiveIcon,
  Send as SubmitIcon,
  CheckCircle as ApproveIcon,
  Cancel as CancelIcon,
  LocalShipping as SupplierIcon,
} from '@mui/icons-material';
import { searchPurchases, receivePurchaseOrder, submitPurchaseOrder, approvePurchaseOrder, cancelPurchaseOrder, getPurchaseById } from '../../api/purchase.api';
import type { ReceivePurchaseOrderRequest, ReceiveItemRequest } from '../../api/purchase.api';
import { useToast } from '../../hooks/useToast';
import { formatCurrency } from '../../core/i18n';

// ─── Status Config ──────────────────────────────────────────

type PurchaseStatus = 'Draft' | 'Submitted' | 'Approved' | 'Received' | 'PartiallyReceived' | 'Cancelled';

const STATUS_CONFIG: Record<string, { label: string; color: string }> = {
  Draft: { label: 'Draft', color: '#9e9e9e' },
  Submitted: { label: 'Submitted', color: '#2196f3' },
  Approved: { label: 'Approved', color: '#ff9800' },
  Received: { label: 'Received', color: '#4caf50' },
  PartiallyReceived: { label: 'Partially Received', color: '#00bcd4' },
  Cancelled: { label: 'Cancelled', color: '#f44336' },
  // handle backend PascalCase or UPPER_CASE
  DRAFT: { label: 'Draft', color: '#9e9e9e' },
  SUBMITTED: { label: 'Submitted', color: '#2196f3' },
  APPROVED: { label: 'Approved', color: '#ff9800' },
  RECEIVED: { label: 'Received', color: '#4caf50' },
  PARTIALLY_RECEIVED: { label: 'Partially Received', color: '#00bcd4' },
  CANCELLED: { label: 'Cancelled', color: '#f44336' },
};

// ─── Receive Dialog ─────────────────────────────────────────

interface ReceiveDialogProps {
  open: boolean;
  purchase: any;
  onClose: () => void;
  onReceived: () => void;
}

const ReceiveDialog: React.FC<ReceiveDialogProps> = ({ open, purchase, onClose, onReceived }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const toast = useToast();
  const [loading, setLoading] = useState(false);
  const [receiveItems, setReceiveItems] = useState<ReceiveItemRequest[]>([]);
  const [actualDate, setActualDate] = useState(new Date().toISOString().split('T')[0]);

  useEffect(() => {
    if (purchase?.items) {
      setReceiveItems(
        purchase.items.map((item: any) => ({
          productId: item.productId,
          receivedQuantity: item.quantity ?? item.orderedQuantity ?? 0,
          batchNumber: item.batchNumber ?? null,
          expiryDate: item.expiryDate ?? null,
          storageLocation: item.storageLocation ?? null,
        }))
      );
    }
  }, [purchase]);

  const handleQuantityChange = (index: number, qty: number) => {
    setReceiveItems(prev => prev.map((item, i) => i === index ? { ...item, receivedQuantity: qty } : item));
  };

  const handleReceive = async () => {
    if (!purchase) return;
    setLoading(true);
    try {
      const req: ReceivePurchaseOrderRequest = {
        actualDeliveryDate: actualDate,
        items: receiveItems,
      };
      await receivePurchaseOrder(purchase.id, req);
      toast.success('Purchase order received successfully!');
      onReceived();
      onClose();
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Failed to receive purchase order.');
    } finally {
      setLoading(false);
    }
  };

  if (!purchase) return null;

  return (
    <Dialog open={open} onClose={onClose} maxWidth="md" fullWidth>
      <DialogTitle sx={{ fontWeight: 700 }}>
        Receive Purchase Order — {purchase.poNumber ?? purchase.purchaseOrderNumber ?? purchase.id}
      </DialogTitle>
      <DialogContent>
        <Box sx={{ mb: 2, mt: 1 }}>
          <TextField
            label="Actual Delivery Date"
            type="date"
            size="small"
            value={actualDate}
            onChange={(e) => setActualDate(e.target.value)}
            slotProps={{ inputLabel: { shrink: true } }}
            sx={{ minWidth: 200 }}
          />
        </Box>

        <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 700 }}>
          Items to Receive
        </Typography>

        <TableContainer component={Paper} variant="outlined" sx={{ bgcolor: dk ? '#1a1a2e' : '#fafafa' }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }}>Product</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Ordered Qty</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Receive Qty</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(purchase.items ?? []).map((item: any, idx: number) => (
                <TableRow key={item.productId ?? idx}>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                      {item.productName ?? item.name ?? 'Product'}
                    </Typography>
                    {item.sku && (
                      <Typography variant="caption" color="text.secondary">{item.sku}</Typography>
                    )}
                  </TableCell>
                  <TableCell align="right">
                    {item.quantity ?? item.orderedQuantity ?? 0}
                  </TableCell>
                  <TableCell align="right" sx={{ width: 120 }}>
                    <TextField
                      type="number"
                      size="small"
                      value={receiveItems[idx]?.receivedQuantity ?? 0}
                      onChange={(e) => handleQuantityChange(idx, Number(e.target.value))}
                      slotProps={{ htmlInput: { min: 0, max: item.quantity ?? item.orderedQuantity ?? 9999 } }}
                      sx={{ width: 100 }}
                    />
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        <Button onClick={onClose} disabled={loading}>Cancel</Button>
        <Button
          variant="contained"
          color="success"
          onClick={handleReceive}
          disabled={loading}
          startIcon={loading ? <CircularProgress size={16} /> : <ReceiveIcon />}
        >
          {loading ? 'Receiving…' : 'Confirm Receive'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

// ─── Main Component ─────────────────────────────────────────

const PurchaseListPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bg = dk ? '#0f0f0f' : '#f8f9fa';
  const navigate = useNavigate();
  const toast = useToast();

  const [purchases, setPurchases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [snackMsg, setSnackMsg] = useState('');

  // Receive dialog
  const [receiveDialogOpen, setReceiveDialogOpen] = useState(false);
  const [selectedPurchaseForReceive, setSelectedPurchaseForReceive] = useState<any>(null);

  const loadPurchases = useCallback(async () => {
    setLoading(true);
    try {
      const result = await searchPurchases({ PageSize: 200 });
      const items = result?.items ?? (Array.isArray(result) ? result : []);
      setPurchases(items);
    } catch (err) {
      console.error('Failed to load purchases:', err);
      toast.error('Failed to load purchase orders.');
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    loadPurchases();
  }, [loadPurchases]);

  const filtered = useMemo(() => {
    let list = purchases;
    if (statusFilter !== 'ALL') {
      list = list.filter((p) => (p.status ?? '').toLowerCase() === statusFilter.toLowerCase());
    }
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) =>
          (p.poNumber ?? p.purchaseOrderNumber ?? p.id ?? '').toLowerCase().includes(q) ||
          (p.supplierName ?? '').toLowerCase().includes(q) ||
          (p.invoiceNumber ?? '').toLowerCase().includes(q)
      );
    }
    return list;
  }, [purchases, search, statusFilter]);

  const handleSubmit = async (id: string) => {
    try {
      await submitPurchaseOrder(id);
      toast.success('Purchase order submitted!');
      loadPurchases();
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Failed to submit.');
    }
  };

  const handleApprove = async (id: string) => {
    try {
      await approvePurchaseOrder(id);
      toast.success('Purchase order approved!');
      loadPurchases();
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Failed to approve.');
    }
  };

  const handleCancel = async (id: string) => {
    try {
      await cancelPurchaseOrder(id);
      toast.success('Purchase order cancelled.');
      loadPurchases();
    } catch (err: any) {
      toast.error(err?.response?.data?.message ?? 'Failed to cancel.');
    }
  };

  const handleOpenReceive = async (purchase: any) => {
    try {
      // Fetch full purchase details for items
      const full = await getPurchaseById(purchase.id);
      setSelectedPurchaseForReceive(full);
    } catch {
      // If detail fetch fails, use list data
      setSelectedPurchaseForReceive(purchase);
    }
    setReceiveDialogOpen(true);
  };

  const getStatusConfig = (status: string) =>
    STATUS_CONFIG[status] ?? { label: status, color: '#9e9e9e' };

  const canSubmit = (status: string) => ['Draft', 'DRAFT'].includes(status);
  const canApprove = (status: string) => ['Submitted', 'SUBMITTED'].includes(status);
  const canReceive = (status: string) => ['Approved', 'APPROVED', 'Submitted', 'SUBMITTED', 'PartiallyReceived', 'PARTIALLY_RECEIVED'].includes(status);
  const canCancel = (status: string) => ['Draft', 'DRAFT', 'Submitted', 'SUBMITTED'].includes(status);

  const headerSx = {
    fontWeight: 700, fontSize: '0.7rem', textTransform: 'uppercase' as const,
    letterSpacing: 0.5, whiteSpace: 'nowrap' as const,
    color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
    bgcolor: dk ? '#1a1a2e' : '#f5f5f5',
    borderBottom: `2px solid ${dk ? 'rgba(255,255,255,0.08)' : '#ddd'}`,
  };

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      {/* Title Row */}
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 0.5 }}>
        <Box>
          <Typography variant="h4" sx={{ fontWeight: 800 }}>Purchase Orders</Typography>
          <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary', mb: 2 }}>
            Manage and receive purchase orders from suppliers
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Tooltip title="Refresh">
            <IconButton onClick={loadPurchases} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => navigate('/purchases/new')}
            sx={{ fontWeight: 700, textTransform: 'none' }}
          >
            New Purchase
          </Button>
        </Box>
      </Box>

      {/* Filters */}
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
          placeholder="Search by PO #, Supplier, Invoice…"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          slotProps={{ input: { startAdornment: <InputAdornment position="start"><SearchIcon sx={{ fontSize: 18 }} /></InputAdornment> } }}
          sx={{ minWidth: 260, flex: 1 }}
        />
        <FormControl size="small" sx={{ minWidth: 170 }}>
          <InputLabel>Status</InputLabel>
          <Select value={statusFilter} label="Status" onChange={(e: SelectChangeEvent) => setStatusFilter(e.target.value)}>
            <MenuItem value="ALL">All Statuses</MenuItem>
            <MenuItem value="Draft">Draft</MenuItem>
            <MenuItem value="Submitted">Submitted</MenuItem>
            <MenuItem value="Approved">Approved</MenuItem>
            <MenuItem value="Received">Received</MenuItem>
            <MenuItem value="PartiallyReceived">Partially Received</MenuItem>
            <MenuItem value="Cancelled">Cancelled</MenuItem>
          </Select>
        </FormControl>
      </Paper>

      {/* Stats */}
      <Box sx={{ display: 'flex', gap: 1, mb: 2, flexWrap: 'wrap' }}>
        <Chip label={`Total: ${filtered.length}`} variant="outlined" sx={{ fontWeight: 700 }} />
        {['Approved', 'Submitted'].map((status) => {
          const count = filtered.filter((p) => (p.status ?? '').toLowerCase() === status.toLowerCase()).length;
          if (!count) return null;
          const cfg = getStatusConfig(status);
          return (
            <Chip
              key={status}
              label={`${cfg.label}: ${count}`}
              size="small"
              sx={{
                bgcolor: alpha(cfg.color, dk ? 0.25 : 0.12),
                color: cfg.color,
                fontWeight: 700,
                fontSize: '0.74rem',
              }}
            />
          );
        })}
        <Chip
          label={`Value: ${formatCurrency(filtered.reduce((s, p) => s + (p.grandTotal ?? p.totalAmount ?? 0), 0))}`}
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
              <TableCell sx={headerSx}>PO #</TableCell>
              <TableCell sx={headerSx}>Supplier</TableCell>
              <TableCell sx={headerSx}>Invoice #</TableCell>
              <TableCell sx={headerSx}>Purchase Date</TableCell>
              <TableCell sx={headerSx}>Expected Delivery</TableCell>
              <TableCell sx={headerSx}>Status</TableCell>
              <TableCell sx={headerSx} align="right">Items</TableCell>
              <TableCell sx={headerSx} align="right">Total</TableCell>
              <TableCell sx={headerSx} align="center">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {loading ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 8 }}>
                  <CircularProgress size={36} sx={{ mb: 2 }} />
                  <Typography color="text.secondary" display="block">Loading purchase orders…</Typography>
                </TableCell>
              </TableRow>
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={9} align="center" sx={{ py: 6 }}>
                  <Typography color="text.disabled" sx={{ mb: 1 }}>No purchase orders found</Typography>
                  <Button
                    variant="outlined"
                    startIcon={<AddIcon />}
                    onClick={() => navigate('/purchases/new')}
                    sx={{ textTransform: 'none' }}
                  >
                    Create First Purchase
                  </Button>
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((p) => {
                const status = p.status ?? 'Draft';
                const sCfg = getStatusConfig(status);
                const poNum = p.poNumber ?? p.purchaseOrderNumber ?? p.id;
                const fmtDate = (d?: string) => d ? new Date(d).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—';
                return (
                  <TableRow
                    key={p.id}
                    hover
                    sx={{ '&:hover': { bgcolor: dk ? alpha('#fff', 0.03) : alpha('#000', 0.02) } }}
                  >
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 700, fontFamily: 'monospace', fontSize: '0.82rem' }}>
                        {poNum}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                        <SupplierIcon sx={{ fontSize: 16, color: 'text.secondary' }} />
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>
                          {p.supplierName ?? '—'}
                        </Typography>
                      </Box>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">{p.invoiceNumber ?? '—'}</Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>{fmtDate(p.purchaseDate ?? p.orderDate)}</Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ fontSize: '0.82rem' }}>{fmtDate(p.expectedDeliveryDate)}</Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={sCfg.label}
                        size="small"
                        sx={{
                          bgcolor: alpha(sCfg.color, dk ? 0.25 : 0.12),
                          color: sCfg.color,
                          fontWeight: 700,
                          fontSize: '0.7rem',
                        }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2">{p.itemCount ?? p.items?.length ?? 0}</Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" sx={{ fontWeight: 700 }}>
                        {formatCurrency(p.grandTotal ?? p.totalAmount ?? 0)}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center', flexWrap: 'wrap' }}>
                        {canReceive(status) && (
                          <Button
                            size="small"
                            variant="contained"
                            color="success"
                            startIcon={<ReceiveIcon />}
                            onClick={() => handleOpenReceive(p)}
                            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                          >
                            Receive
                          </Button>
                        )}
                        {canSubmit(status) && (
                          <Button
                            size="small"
                            variant="outlined"
                            color="primary"
                            startIcon={<SubmitIcon />}
                            onClick={() => handleSubmit(p.id)}
                            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                          >
                            Submit
                          </Button>
                        )}
                        {canApprove(status) && (
                          <Button
                            size="small"
                            variant="outlined"
                            color="warning"
                            startIcon={<ApproveIcon />}
                            onClick={() => handleApprove(p.id)}
                            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                          >
                            Approve
                          </Button>
                        )}
                        {canCancel(status) && (
                          <Tooltip title="Cancel PO">
                            <IconButton
                              size="small"
                              color="error"
                              onClick={() => handleCancel(p.id)}
                            >
                              <CancelIcon fontSize="small" />
                            </IconButton>
                          </Tooltip>
                        )}
                      </Box>
                    </TableCell>
                  </TableRow>
                );
              })
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Receive Dialog */}
      <ReceiveDialog
        open={receiveDialogOpen}
        purchase={selectedPurchaseForReceive}
        onClose={() => {
          setReceiveDialogOpen(false);
          setSelectedPurchaseForReceive(null);
        }}
        onReceived={loadPurchases}
      />

      {/* Snackbar */}
      <Snackbar
        open={!!snackMsg}
        autoHideDuration={3000}
        onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" variant="filled" onClose={() => setSnackMsg('')}>{snackMsg}</Alert>
      </Snackbar>
    </Box>
  );
};

export default PurchaseListPage;
