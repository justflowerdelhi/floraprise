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
  Grid,
  Alert,
} from '@mui/material';
import type { SelectChangeEvent } from '@mui/material/Select';
import {
  Search as SearchIcon,
  Add as AddIcon,
  Refresh as RefreshIcon,
  CallReceived as ReceiveIcon,
  Visibility as ViewIcon,
  Send as SubmitIcon,
  Cancel as CancelIcon,
  LocalShipping as SupplierIcon,
  FlashOn as FlashOnIcon,
} from '@mui/icons-material';
import { searchPurchases, receivePurchaseOrder, submitPurchaseOrder, cancelPurchaseOrder, getPurchaseById } from '../../api/purchase.api';
import type { ReceivePurchaseOrderRequest, ReceiveItemRequest } from '../../api/purchase.api';
import api from '../../api/axios';
import { showError, showSuccess } from '../../utils/toast';
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
  const [loading, setLoading] = useState(false);
  const [receiveItems, setReceiveItems] = useState<ReceiveItemRequest[]>([]);
  const [actualDate, setActualDate] = useState(new Date().toISOString().split('T')[0]);
  const [invoiceNumber, setInvoiceNumber] = useState('');

  const buildAutoBatchNumber = (item: any, idx: number): string => {
    const dateCode = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const productCode = (item?.sku || item?.productName || `ITEM${idx + 1}`)
      .toString()
      .toUpperCase()
      .replace(/[^A-Z0-9]/g, '')
      .slice(0, 6);

    return `B-${dateCode}-${productCode}-${String(idx + 1).padStart(2, '0')}`;
  };

  const rowValidationErrors = useMemo(() => {
    return (purchase?.items ?? []).map((item: any, idx: number) => {
      const receive = receiveItems[idx];
      const errors: string[] = [];
      const qty = Number(receive?.receivedQuantity ?? 0);
      const cost = Number(receive?.actualCostPerUnit ?? 0);
      const batch = (receive?.batchNumber ?? '').toString().trim();
      const expiry = (receive?.expiryDate ?? '').toString().trim();

      if (!qty || qty <= 0) errors.push('Quantity must be greater than 0.');
      if (!cost || cost <= 0) errors.push('Actual cost must be greater than 0.');
      if (!batch) errors.push('Batch number is required.');
      if (item?.isPerishable && !expiry) errors.push('Expiry date is required for perishable items.');

      return errors;
    });
  }, [purchase, receiveItems]);

  const isReceiveFormValid = useMemo(
    () => rowValidationErrors.every((errs) => errs.length === 0),
    [rowValidationErrors]
  );

  const validationMessage = useMemo(() => {
    if (isReceiveFormValid) return '';
    const firstInvalidIndex = rowValidationErrors.findIndex((errs) => errs.length > 0);
    if (firstInvalidIndex < 0) return '';
    return `Item ${firstInvalidIndex + 1}: ${rowValidationErrors[firstInvalidIndex][0]}`;
  }, [isReceiveFormValid, rowValidationErrors]);

  useEffect(() => {
    if (purchase?.items) {
      setReceiveItems(
        purchase.items.map((item: any, idx: number) => ({
          productId: item.productId,
          receivedQuantity: item.quantity ?? item.orderedQuantity ?? 0,
          actualCostPerUnit: item.expectedPrice ?? item.unitPrice ?? item.costPerUnit ?? 0,
          batchNumber: item.batchNumber ?? buildAutoBatchNumber(item, idx),
          expiryDate: item.expiryDate ?? null,
          storageLocation: item.storageLocation ?? null,
        }))
      );
      setInvoiceNumber(purchase.invoiceNumber ?? '');
    }
  }, [purchase]);

  const handleQuantityChange = (index: number, qty: number) => {
    setReceiveItems(prev => prev.map((item, i) => i === index ? { ...item, receivedQuantity: qty } : item));
  };

  const handleItemFieldChange = <K extends keyof ReceiveItemRequest>(index: number, key: K, value: ReceiveItemRequest[K]) => {
    setReceiveItems((prev) => prev.map((item, i) => (i === index ? { ...item, [key]: value } : item)));
  };

  const handleReceive = async () => {
    if (!purchase) return;
    if (!isReceiveFormValid) {
      showError(validationMessage || 'Please fill all required receive fields.');
      return;
    }

    setLoading(true);
    try {
      const req: ReceivePurchaseOrderRequest = {
        actualDeliveryDate: actualDate,
        invoiceNumber: invoiceNumber || null,
        items: receiveItems,
      };
      await receivePurchaseOrder(purchase.id, req);
      showSuccess('Stock Received Successfully');
      onReceived();
      onClose();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? 'Failed to receive purchase order.');
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
          <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap' }}>
            <TextField
              label="Actual Delivery Date"
              type="date"
              size="small"
              value={actualDate}
              onChange={(e) => setActualDate(e.target.value)}
              slotProps={{ inputLabel: { shrink: true } }}
              sx={{ minWidth: 200 }}
            />
            <TextField
              label="Invoice Number"
              size="small"
              value={invoiceNumber}
              onChange={(e) => setInvoiceNumber(e.target.value)}
              sx={{ minWidth: 220 }}
            />
          </Box>
        </Box>

        <Typography variant="subtitle2" sx={{ mb: 1.5, fontWeight: 700 }}>
          Items to Receive
        </Typography>

        {!isReceiveFormValid && (
          <Alert severity="warning" sx={{ mb: 1.5 }}>
            {validationMessage}
          </Alert>
        )}

        <TableContainer component={Paper} variant="outlined" sx={{ bgcolor: dk ? '#1a1a2e' : '#fafafa' }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }}>Product</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Ordered Qty</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Receive Qty</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Actual Cost</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }}>Batch</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }}>Expiry</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }}>Storage</TableCell>
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
                    <Box sx={{ mt: 0.5, display: 'flex', gap: 0.5, flexWrap: 'wrap' }}>
                      {(receiveItems[idx]?.receivedQuantity ?? 0) !== (item.quantity ?? item.orderedQuantity ?? 0) && (
                        <Chip size="small" color="warning" label="Qty mismatch" />
                      )}
                      {Number(receiveItems[idx]?.actualCostPerUnit ?? 0) !== Number(item.expectedPrice ?? item.unitPrice ?? item.costPerUnit ?? 0) && (
                        <Chip size="small" color="warning" label="Cost mismatch" />
                      )}
                      {(item.isQuantityMismatch || item.isPriceMismatch) && (
                        <Chip size="small" color="error" label="Mismatch recorded" />
                      )}
                    </Box>
                    {rowValidationErrors[idx]?.length > 0 && (
                      <Typography variant="caption" color="error" sx={{ display: 'block', mt: 0.5 }}>
                        {rowValidationErrors[idx][0]}
                      </Typography>
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
                  <TableCell align="right" sx={{ width: 130 }}>
                    <TextField
                      type="number"
                      size="small"
                      value={receiveItems[idx]?.actualCostPerUnit ?? 0}
                      onChange={(e) => handleItemFieldChange(idx, 'actualCostPerUnit', Number(e.target.value))}
                      slotProps={{ htmlInput: { min: 0, step: 0.01 } }}
                      sx={{ width: 110 }}
                    />
                  </TableCell>
                  <TableCell sx={{ minWidth: 160 }}>
                    <TextField
                      size="small"
                      placeholder="Batch Number"
                      value={receiveItems[idx]?.batchNumber ?? ''}
                      onChange={(e) => handleItemFieldChange(idx, 'batchNumber', e.target.value || null)}
                    />
                  </TableCell>
                  <TableCell sx={{ minWidth: 160 }}>
                    <TextField
                      size="small"
                      type="date"
                      slotProps={{ inputLabel: { shrink: true } }}
                      value={receiveItems[idx]?.expiryDate ?? ''}
                      onChange={(e) => handleItemFieldChange(idx, 'expiryDate', e.target.value || null)}
                    />
                  </TableCell>
                  <TableCell sx={{ minWidth: 180 }}>
                    <TextField
                      size="small"
                      placeholder="Storage Location"
                      value={receiveItems[idx]?.storageLocation ?? ''}
                      onChange={(e) => handleItemFieldChange(idx, 'storageLocation', e.target.value || null)}
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
          disabled={loading || !isReceiveFormValid}
          startIcon={loading ? <CircularProgress size={16} /> : <ReceiveIcon />}
        >
          {loading ? 'Receiving…' : 'Confirm Receive'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};

interface ViewDetailsDialogProps {
  open: boolean;
  purchase: any;
  pdfUrl?: string | null;
  onDownloadPdf: () => void;
  onClose: () => void;
}

const ViewDetailsDialog: React.FC<ViewDetailsDialogProps> = ({ open, purchase, pdfUrl, onDownloadPdf, onClose }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  if (!purchase) return null;

  const poNumber = purchase.orderNumber ?? purchase.poNumber ?? purchase.purchaseOrderNumber ?? purchase.id;
  const orderDate = purchase.orderDate ?? purchase.purchaseDate;
  const expectedDate = purchase.expectedDeliveryDate;
  const status = (purchase.status ?? '').toString();
  const isDraft = ['Draft', 'DRAFT'].includes(status);

  return (
    <Dialog open={open} onClose={onClose} maxWidth="lg" fullWidth>
      <DialogTitle sx={{ fontWeight: 700 }}>
        PO Details — {poNumber}
      </DialogTitle>
      <DialogContent>
        <Grid container spacing={1.5} sx={{ mt: 0.25, mb: 2 }}>
          <Grid size={{ xs: 12, md: 4 }}>
            <Typography variant="caption" color="text.secondary">Supplier</Typography>
            <Typography variant="body2" sx={{ fontWeight: 700 }}>{purchase.supplierName ?? '—'}</Typography>
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <Typography variant="caption" color="text.secondary">Order Date</Typography>
            <Typography variant="body2" sx={{ fontWeight: 700 }}>
              {orderDate ? new Date(orderDate).toLocaleDateString('en-IN') : '—'}
            </Typography>
          </Grid>
          <Grid size={{ xs: 12, md: 4 }}>
            <Typography variant="caption" color="text.secondary">Expected Delivery</Typography>
            <Typography variant="body2" sx={{ fontWeight: 700 }}>
              {expectedDate ? new Date(expectedDate).toLocaleDateString('en-IN') : '—'}
            </Typography>
          </Grid>
        </Grid>

        <TableContainer component={Paper} variant="outlined" sx={{ bgcolor: dk ? '#1a1a2e' : '#fafafa' }}>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }}>Product</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Ordered Qty</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Received Qty</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Qty Diff</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Ordered Price</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="right">Actual Price</TableCell>
                <TableCell sx={{ fontWeight: 700, fontSize: '0.75rem' }} align="center">Price Diff</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {(purchase.items ?? []).map((item: any, idx: number) => {
                const orderedQty = Number(item.quantity ?? 0);
                const receivedQty = Number(item.receivedQuantity ?? 0);
                const qtyDiff = receivedQty - orderedQty;
                const hasQtyDiff = item.isQuantityMismatch || qtyDiff !== 0;
                const orderedPrice = Number(item.expectedPrice ?? item.unitPrice ?? item.costPerUnit ?? 0);
                const actualPrice = Number(item.actualPrice ?? (receivedQty > 0 ? (item.actualTotalPrice ?? item.totalPrice ?? 0) / receivedQty : orderedPrice));
                const priceDiff = actualPrice - orderedPrice;
                const hasPriceDiff = !!item.isPriceMismatch || Math.abs(priceDiff) > 0.0001;

                return (
                  <TableRow
                    key={item.id ?? item.productId ?? idx}
                    sx={{
                      bgcolor: hasQtyDiff || hasPriceDiff
                        ? alpha(theme.palette.warning.main, dk ? 0.15 : 0.08)
                        : 'inherit',
                    }}
                  >
                    <TableCell>
                      <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {item.productName ?? 'Product'}
                      </Typography>
                      {item.sku && (
                        <Typography variant="caption" color="text.secondary">{item.sku}</Typography>
                      )}
                    </TableCell>
                    <TableCell align="right">{orderedQty}</TableCell>
                    <TableCell align="right">
                      <Typography
                        variant="body2"
                        sx={{ color: hasQtyDiff ? 'warning.main' : 'text.primary', fontWeight: hasQtyDiff ? 700 : 500 }}
                      >
                        {receivedQty}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      {hasQtyDiff ? (
                        <Chip
                          size="small"
                          color="warning"
                          label={`${qtyDiff > 0 ? '+' : ''}${qtyDiff}`}
                        />
                      ) : (
                        <Typography variant="body2" color="text.secondary">0</Typography>
                      )}
                    </TableCell>
                    <TableCell align="right">{formatCurrency(orderedPrice)}</TableCell>
                    <TableCell align="right">
                      <Typography
                        variant="body2"
                        sx={{ color: hasPriceDiff ? 'warning.main' : 'text.primary', fontWeight: hasPriceDiff ? 700 : 500 }}
                      >
                        {formatCurrency(actualPrice)}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      {hasPriceDiff ? (
                        <Chip size="small" color="error" label={`${priceDiff > 0 ? '+' : ''}${formatCurrency(priceDiff)}`} />
                      ) : (
                        <Chip size="small" color="success" variant="outlined" label="OK" />
                      )}
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2 }}>
        {isDraft ? (
          <Tooltip title="Submit PO first, then PDF is available">
            <span>
              <Button variant="outlined" disabled>
                Download PO PDF
              </Button>
            </span>
          </Tooltip>
        ) : (
          <Button
            variant="contained"
            onClick={onDownloadPdf}
            disabled={!pdfUrl}
          >
            Download PO PDF
          </Button>
        )}
        <Button onClick={onClose}>Close</Button>
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

  const [purchases, setPurchases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [pdfUrlsById, setPdfUrlsById] = useState<Record<string, string>>({});

  // Receive dialog
  const [receiveDialogOpen, setReceiveDialogOpen] = useState(false);
  const [selectedPurchaseForReceive, setSelectedPurchaseForReceive] = useState<any>(null);

  // View details dialog
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [selectedPurchaseForView, setSelectedPurchaseForView] = useState<any>(null);

  const resolvePdfUrl = (pdfPathOrUrl: string | null | undefined): string | null => {
    if (!pdfPathOrUrl) return null;

    if (/^https?:\/\//i.test(pdfPathOrUrl)) {
      return pdfPathOrUrl;
    }

    const apiBase = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.trim() || '';
    if (!apiBase) return pdfPathOrUrl;

    // Endpoints use /api; static files are hosted at server root.
    const serverOrigin = apiBase.replace(/\/api\/?$/i, '');
    const normalizedPath = pdfPathOrUrl.startsWith('/') ? pdfPathOrUrl : `/${pdfPathOrUrl}`;
    return `${serverOrigin}${normalizedPath}`;
  };

  const loadPurchases = useCallback(async () => {
    setLoading(true);
    try {
      const result = await searchPurchases({ PageSize: 200 });
      const items = result?.items ?? (Array.isArray(result) ? result : []);
      setPurchases(items);
    } catch (err) {
      console.error('Failed to load purchases:', err);
      showError('Failed to load purchase orders.');
    } finally {
      setLoading(false);
    }
  }, []);

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
      const result = await submitPurchaseOrder(id);
      if (result?.pdfUrl) {
        const resolved = resolvePdfUrl(result.pdfUrl);
        if (resolved) {
          setPdfUrlsById((prev) => ({ ...prev, [id]: resolved }));
          await openPdfByPurchaseId(id);
        }
      }
      showSuccess('Purchase Order Submitted Successfully');
      loadPurchases();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? 'Failed to submit.');
    }
  };

  const handleCancel = async (id: string) => {
    try {
      await cancelPurchaseOrder(id);
      showSuccess('Purchase Order Cancelled Successfully');
      loadPurchases();
    } catch (err: any) {
      showError(err?.response?.data?.message ?? 'Failed to cancel.');
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

  const handleOpenView = async (purchase: any) => {
    try {
      const full = await getPurchaseById(purchase.id);
      setSelectedPurchaseForView(full);
    } catch {
      setSelectedPurchaseForView(purchase);
    }
    setViewDialogOpen(true);
  };

  const getPdfUrlForPurchase = (purchase: any): string | null => {
    if (!purchase) return null;

    const cached = pdfUrlsById[purchase.id];
    if (cached) return cached;

    const orderNumber = purchase.orderNumber ?? purchase.poNumber ?? purchase.purchaseOrderNumber;
    if (!orderNumber) return null;

    return resolvePdfUrl(`/files/PO-${orderNumber}.pdf`);
  };

  const handleDownloadFromView = () => {
    if (!selectedPurchaseForView?.id) {
      showError('PO PDF is not available for this order yet.');
      return;
    }

    void openPdfByPurchaseId(selectedPurchaseForView.id);
  };

  const handleDownloadFromRow = (purchase: any) => {
    if (!purchase?.id) {
      showError('PO PDF is not available for this order yet.');
      return;
    }

    void openPdfByPurchaseId(purchase.id);
  };

  const openPdfByPurchaseId = async (purchaseId: string) => {
    try {
      const response = await api.get(`/purchases/${purchaseId}/pdf`, {
        responseType: 'blob',
        headers: { Accept: 'application/pdf' },
      });

      const blob = response.data instanceof Blob
        ? response.data
        : new Blob([response.data], { type: 'application/pdf' });

      if (!blob || blob.size === 0) {
        showError('Generated PO PDF is empty.');
        return;
      }

      const blobUrl = window.URL.createObjectURL(blob);
      window.open(blobUrl, '_blank', 'noopener,noreferrer');
      window.setTimeout(() => window.URL.revokeObjectURL(blobUrl), 60_000);
    } catch {
      showError('Failed to load PO PDF. Please try again.');
    }
  };

  const getStatusConfig = (status: string) =>
    STATUS_CONFIG[status] ?? { label: status, color: '#9e9e9e' };

  const canSubmit = (status: string) => ['Draft', 'DRAFT'].includes(status);
  const canReceive = (status: string) => ['Approved', 'APPROVED', 'Submitted', 'SUBMITTED', 'PartiallyReceived', 'PARTIALLY_RECEIVED'].includes(status);
  const isDraft = (status: string) => ['Draft', 'DRAFT'].includes(status);
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
          <Button
            variant="contained"
            startIcon={<FlashOnIcon />}
            onClick={() => navigate('/inventory/quick-receive')}
            sx={{ fontWeight: 700, textTransform: 'none' }}
          >
            ⚡ Receive Stock
          </Button>
          <Tooltip title="Refresh">
            <IconButton onClick={loadPurchases} disabled={loading}>
              <RefreshIcon />
            </IconButton>
          </Tooltip>
          <Button
            variant="outlined"
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
              <TableCell sx={{ ...headerSx, minWidth: 300 }} align="center">Actions</TableCell>
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
                    <TableCell align="center" sx={{ minWidth: 300 }}>
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center', flexWrap: 'nowrap', alignItems: 'center' }}>
                        <Button
                          size="small"
                          variant="outlined"
                          startIcon={<ViewIcon />}
                          onClick={() => handleOpenView(p)}
                          sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                        >
                          View
                        </Button>
                        {canReceive(status) && (
                          <Button
                            size="small"
                            variant="contained"
                            color="success"
                            startIcon={<FlashOnIcon />}
                            onClick={() => handleOpenReceive(p)}
                            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                          >
                            ⚡ Receive Stock
                          </Button>
                        )}
                        {isDraft(status) && (
                          <Tooltip title="Submit the purchase order before receiving stock">
                            <span>
                              <Button
                                size="small"
                                variant="contained"
                                color="success"
                                startIcon={<ReceiveIcon />}
                                disabled
                                sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                              >
                                Receive Locked
                              </Button>
                            </span>
                          </Tooltip>
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
                        {!isDraft(status) && !!getPdfUrlForPurchase(p) && (
                          <Button
                            size="small"
                            variant="text"
                            onClick={() => handleDownloadFromRow(p)}
                            sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'none', minHeight: 32 }}
                          >
                            Download PO PDF
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
        onReceived={() => {
          loadPurchases();
          navigate('/inventory');
        }}
      />

      <ViewDetailsDialog
        open={viewDialogOpen}
        purchase={selectedPurchaseForView}
        pdfUrl={getPdfUrlForPurchase(selectedPurchaseForView)}
        onDownloadPdf={handleDownloadFromView}
        onClose={() => {
          setViewDialogOpen(false);
          setSelectedPurchaseForView(null);
        }}
      />
    </Box>
  );
};

export default PurchaseListPage;
