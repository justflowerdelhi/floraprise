/**
 * RefundScreen.tsx — Full Refund Processing Screen
 * Florist ERP SaaS — Phase 1 Core Safe Version
 *
 * Features:
 * - Per-item quantity selection with max-refundable guard
 * - Restock toggle (auto OFF for perishable, ON for non-perishable)
 * - Refund method: original payment or store credit
 * - Auto-calculated totals capped at paid amount
 * - Reason field (required)
 * - Audit log creation on submit
 * - Updates order status to REFUNDED / PARTIALLY_REFUNDED
 */
import React, { useState, useMemo, useCallback, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box, Typography, Paper, Button, TextField, Divider,
  Table, TableBody, TableCell, TableContainer, TableHead, TableRow,
  Checkbox, Switch, FormControlLabel, RadioGroup, Radio,
  Alert, Chip, Dialog, DialogTitle, DialogContent, DialogActions,
  useTheme, alpha, Snackbar, IconButton, Tooltip,
} from '@mui/material';
import {
  ArrowBack as BackIcon,
  MoneyOff as RefundIcon,
  Inventory2 as RestockIcon,
  Warning as WarningIcon,
  CheckCircle as CheckIcon,
  Receipt as ReceiptIcon,
} from '@mui/icons-material';
import type { Order } from '../orders/OrderTypes';
import type { RefundItem, RefundMethod, RefundEntry } from './RefundTypes';
import {
  buildRefundableItems,
  calculateRefundTotal,
  deriveRefundOrderStatus,
  getTotalRefunded,
  nextRefundId,
  REFUND_METHOD_CONFIG,
  REFUND_STATUS_CONFIG,
} from './RefundTypes';
import { useOrders } from '../orders/OrderContext';
import { formatCurrency } from '../../core/i18n';
import type { AuditLog } from '../../core/audit/AuditTypes';
import { MOCK_AUDIT_LOGS } from '../../core/audit/AuditTypes';

const fmtCurrency = (v: number) => formatCurrency(v);

// ─── Helper: build isPerishable map from order items ────────

function buildPerishableMap(order: Order): Record<string, boolean> {
  const map: Record<string, boolean> = {};
  for (const item of order.items) {
    // If category contains "Fresh Flowers" or "Greens & Foliage" → perishable
    // Arrangements/Bouquets with batch allocations → perishable
    // Everything else → non-perishable
    const cat = item.category;
    const isPerishable =
      cat === 'Fresh Flowers' ||
      cat === 'Greens & Foliage' ||
      ((cat === 'Arrangements' || cat === 'Bouquets') && item.batchAllocations.length > 0);
    map[item.productId] = isPerishable;
  }
  return map;
}

// ─── Component ──────────────────────────────────────────────

const RefundScreen: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bg = dk ? '#0f0f0f' : '#f8f9fa';
  const navigate = useNavigate();
  const { orderId } = useParams<{ orderId: string }>();
  const { getOrder, updateOrder } = useOrders();

  // ─── Load Order ─────────────────────────────────────
  const order = orderId ? getOrder(orderId) : undefined;

  // ─── Refund State ───────────────────────────────────
  const previousRefunds = order?.refunds ?? [];
  const previouslyRefunded = getTotalRefunded(previousRefunds);
  const orderTotal = order?.totals.grandTotal ?? 0;
  // Use actual money collected (totalPaid), NOT order total — critical for PARTIALLY_PAID orders
  const totalPaid = order?.totalPaid ?? orderTotal;
  const maxRefundableAmount = Math.max(0, totalPaid - previouslyRefunded);
  const isPartiallyPaid = (order?.orderStatus === 'PARTIALLY_PAID') || (totalPaid < orderTotal);

  const perishableMap = useMemo(
    () => (order ? buildPerishableMap(order) : {}),
    [order],
  );

  const initialItems = useMemo(
    () =>
      order
        ? buildRefundableItems(
            order.items.map((i) => ({
              id: i.id,
              productId: i.productId,
              productName: i.productName,
              sku: i.sku,
              quantity: i.quantity,
              unitPrice: i.unitPrice,
              category: i.category,
            })),
            previousRefunds,
            perishableMap,
          )
        : [],
    [order, previousRefunds, perishableMap],
  );

  const [items, setItems] = useState<RefundItem[]>(initialItems);
  const [method, setMethod] = useState<RefundMethod>('ORIGINAL');
  const [reason, setReason] = useState('');
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [snackMsg, setSnackMsg] = useState('');
  const [snackSeverity, setSnackSeverity] = useState<'success' | 'error'>('success');
  const [useCustomAmount, setUseCustomAmount] = useState(false);
  const [customAmountStr, setCustomAmountStr] = useState('');

  // ─── Derived Values ─────────────────────────────────
  /** Raw sum of selected item × unitPrice (may exceed maxRefundable for partial orders) */
  const rawItemTotal = useMemo(
    () => items.reduce((sum: number, item: RefundItem) => sum + item.quantity * item.unitPrice, 0),
    [items],
  );

  /** Whether selected items total exceeds what can be refunded (informational, NOT a hard block) */
  const itemsExceedMax = rawItemTotal > maxRefundableAmount;

  /** Auto-capped amount = min(rawItemTotal, maxRefundable) */
  const autoCappedAmount = useMemo(
    () => calculateRefundTotal(items, maxRefundableAmount),
    [items, maxRefundableAmount],
  );

  /** Parsed custom amount (NaN-safe) */
  const parsedCustomAmount = parseFloat(customAmountStr) || 0;

  /** Final refund amount: custom amount if toggled and valid, otherwise auto-capped */
  const totalRefundAmount = useMemo(() => {
    if (useCustomAmount && parsedCustomAmount > 0) {
      return Math.min(parsedCustomAmount, maxRefundableAmount, rawItemTotal);
    }
    return autoCappedAmount;
  }, [useCustomAmount, parsedCustomAmount, maxRefundableAmount, rawItemTotal, autoCappedAmount]);

  const customAmountError = useMemo(() => {
    if (!useCustomAmount || customAmountStr === '') return '';
    if (parsedCustomAmount <= 0) return 'Enter a positive amount';
    if (parsedCustomAmount > maxRefundableAmount) return `Cannot exceed max refundable (${fmtCurrency(maxRefundableAmount)})`;
    if (parsedCustomAmount > rawItemTotal) return `Cannot exceed selected items total (${fmtCurrency(rawItemTotal)})`;
    return '';
  }, [useCustomAmount, customAmountStr, parsedCustomAmount, maxRefundableAmount, rawItemTotal]);

  // Reset custom amount when items change
  useEffect(() => {
    if (useCustomAmount && rawItemTotal > 0) {
      const cap = Math.min(rawItemTotal, maxRefundableAmount);
      setCustomAmountStr(cap.toFixed(2));
    }
  }, [rawItemTotal]); // eslint-disable-line react-hooks/exhaustive-deps

  const hasSelection = items.some((i) => i.quantity > 0);
  const isValid = hasSelection && reason.trim().length >= 3 && totalRefundAmount > 0 && !customAmountError;
  const restockItems = items.filter((i) => i.quantity > 0 && i.restock);

  // ─── Handlers ───────────────────────────────────────

  const handleQtyChange = useCallback((lineItemId: string, qty: number) => {
    setItems((prev) =>
      prev.map((item) => {
        if (item.lineItemId !== lineItemId) return item;
        const clamped = Math.max(0, Math.min(qty, item.maxRefundableQty));
        return {
          ...item,
          quantity: clamped,
          refundAmount: clamped * item.unitPrice,
        };
      }),
    );
  }, []);

  const handleSelectAll = useCallback((checked: boolean) => {
    setItems((prev) =>
      prev.map((item) => ({
        ...item,
        quantity: checked ? item.maxRefundableQty : 0,
        refundAmount: checked ? item.maxRefundableQty * item.unitPrice : 0,
      })),
    );
  }, []);

  const handleRestockToggle = useCallback((lineItemId: string) => {
    setItems((prev) =>
      prev.map((item) =>
        item.lineItemId === lineItemId ? { ...item, restock: !item.restock } : item,
      ),
    );
  }, []);

  const handleProcessRefund = useCallback(() => {
    if (!order || !isValid) return;

    const refundEntry: RefundEntry = {
      refundId: nextRefundId(),
      refundedAmount: totalRefundAmount,
      items: items.filter((i) => i.quantity > 0),
      method,
      reason: reason.trim(),
      createdAt: new Date().toISOString(),
      processedBy: 'user_001',       // TODO: from auth context
      processedByName: 'Admin User', // TODO: from auth context
      status: 'PROCESSED',
    };

    const newRefunds = [...previousRefunds, refundEntry];
    const newTotalRefunded = previouslyRefunded + totalRefundAmount;
    const newOrderStatus = deriveRefundOrderStatus(totalPaid, previouslyRefunded, totalRefundAmount);

    // Update order in context
    const updatedOrder: Order = {
      ...order,
      refunds: newRefunds,
      totalRefunded: newTotalRefunded,
      orderStatus: newOrderStatus,
      updatedAt: new Date().toISOString(),
    };
    updateOrder(updatedOrder);

    // Create audit log entry
    const auditEntry: AuditLog = {
      id: `audit_ref_${Date.now()}`,
      tenantId: 'tenant_001',
      locationId: order.locationId,
      entityType: 'ORDER',
      entityId: order.id,
      action: 'REFUND',
      changedBy: 'user_001',
      changedByName: 'Admin User',
      changeSummary: `Refund of ${fmtCurrency(totalRefundAmount)} processed — ${refundEntry.items.length} item(s), method: ${REFUND_METHOD_CONFIG[method].label}`,
      previousValue: {
        orderStatus: order.orderStatus,
        totalRefunded: previouslyRefunded,
      },
      newValue: {
        orderStatus: newOrderStatus,
        totalRefunded: newTotalRefunded,
        refundId: refundEntry.refundId,
      },
      metadata: {
        refundMethod: method,
        reason: reason.trim(),
        restockedItems: restockItems.map((i) => ({
          productId: i.productId,
          productName: i.productName,
          quantity: i.quantity,
        })),
      },
      createdAt: new Date().toISOString(),
    };
    MOCK_AUDIT_LOGS.unshift(auditEntry);

    // Log restock info (in production, this would update inventory)
    if (restockItems.length > 0) {
      console.log('📦 Inventory Restock (refund_restock):', restockItems.map((i) => ({
        productId: i.productId,
        productName: i.productName,
        quantity: i.quantity,
        type: 'refund_restock',
      })));
    }

    setConfirmOpen(false);
    setSnackSeverity('success');
    setSnackMsg(`Refund of ${fmtCurrency(totalRefundAmount)} processed for ${order.orderNumber}`);

    // Navigate back after short delay
    setTimeout(() => navigate('/order-list'), 1500);
  }, [order, isValid, items, method, reason, totalRefundAmount, previousRefunds, previouslyRefunded, totalPaid, restockItems, updateOrder, navigate]);

  // ─── Guard: Order not found ─────────────────────────
  if (!order) {
    return (
      <Box sx={{ p: 4, textAlign: 'center' }}>
        <Typography variant="h5" sx={{ mb: 2 }}>Order Not Found</Typography>
        <Typography color="text.secondary" sx={{ mb: 3 }}>
          The order "{orderId}" could not be found or is not eligible for refund.
        </Typography>
        <Button variant="outlined" startIcon={<BackIcon />} onClick={() => navigate('/order-list')}>
          Back to Orders
        </Button>
      </Box>
    );
  }

  // ─── Guard: Nothing left to refund ──────────────────
  if (maxRefundableAmount <= 0) {
    return (
      <Box sx={{ p: 4, textAlign: 'center' }}>
        <Typography variant="h5" sx={{ mb: 2 }}>Fully Refunded</Typography>
        <Typography color="text.secondary" sx={{ mb: 3 }}>
          Order {order.orderNumber} has already been fully refunded.
        </Typography>
        <Button variant="outlined" startIcon={<BackIcon />} onClick={() => navigate('/order-list')}>
          Back to Orders
        </Button>
      </Box>
    );
  }

  const allSelected = items.length > 0 && items.every((i) => i.quantity === i.maxRefundableQty);

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, bgcolor: bg, minHeight: '100vh' }}>
      {/* ─── Header ─────────────────────────────────────── */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <IconButton onClick={() => navigate('/order-list')} sx={{ color: dk ? '#fff' : undefined }}>
          <BackIcon />
        </IconButton>
        <Box sx={{ flex: 1 }}>
          <Typography variant="h5" sx={{ fontWeight: 800, display: 'flex', alignItems: 'center', gap: 1 }}>
            <RefundIcon sx={{ color: '#ff9800' }} />
            {isPartiallyPaid ? 'Refund Paid Amount' : 'Process Refund'}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Order {order.orderNumber} &bull; {order.customerName ?? 'Walk-in Customer'}
            {isPartiallyPaid
              ? <> &bull; Paid: {fmtCurrency(totalPaid)} of {fmtCurrency(orderTotal)}</>
              : <> &bull; {fmtCurrency(totalPaid)}</>}
          </Typography>
        </Box>
        {previouslyRefunded > 0 && (
          <Chip
            label={`Previously Refunded: ${fmtCurrency(previouslyRefunded)}`}
            color="info"
            variant="outlined"
            sx={{ fontWeight: 700 }}
          />
        )}
      </Box>

      {/* ─── Partially Paid Warning ─────────────────────── */}
      {isPartiallyPaid && (
        <Alert severity="warning" sx={{ mb: 2 }} icon={<WarningIcon />}>
          This order is <strong>partially paid</strong>. Only the collected amount ({fmtCurrency(totalPaid)}) can be refunded — not the full order total ({fmtCurrency(orderTotal)}).
        </Alert>
      )}

      {/* ─── Previous Refunds Warning ───────────────────── */}
      {previousRefunds.length > 0 && (
        <Alert severity="info" sx={{ mb: 2 }} icon={<ReceiptIcon />}>
          <strong>{previousRefunds.length} previous refund(s)</strong> totaling{' '}
          {fmtCurrency(previouslyRefunded)}. Remaining refundable: {fmtCurrency(maxRefundableAmount)}
        </Alert>
      )}

      <Box sx={{ display: 'flex', gap: 3, flexDirection: { xs: 'column', lg: 'row' } }}>
        {/* ─── Left: Item Selection ──────────────────────── */}
        <Paper
          elevation={dk ? 0 : 1}
          sx={{
            flex: 2,
            borderRadius: 2,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            overflow: 'hidden',
          }}
        >
          <Box sx={{ p: 2, borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#eee'}` }}>
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>Select Items to Refund</Typography>
          </Box>
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell sx={{ width: 48 }}>
                    <Checkbox
                      checked={allSelected}
                      indeterminate={items.some((i) => i.quantity > 0) && !allSelected}
                      onChange={(_, checked) => handleSelectAll(checked)}
                      size="small"
                    />
                  </TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'uppercase' }}>Product</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'uppercase' }} align="center">Ordered</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'uppercase' }} align="center">Refund Qty</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'uppercase' }} align="right">Unit Price</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'uppercase' }} align="right">Refund Amt</TableCell>
                  <TableCell sx={{ fontWeight: 700, fontSize: '0.72rem', textTransform: 'uppercase' }} align="center">Restock</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {items.map((item) => {
                  const selected = item.quantity > 0;
                  return (
                    <TableRow
                      key={item.lineItemId}
                      sx={{
                        bgcolor: selected
                          ? alpha(dk ? '#ff9800' : '#ff9800', dk ? 0.08 : 0.04)
                          : undefined,
                      }}
                    >
                      <TableCell>
                        <Checkbox
                          checked={selected}
                          onChange={(_, checked) =>
                            handleQtyChange(item.lineItemId, checked ? item.maxRefundableQty : 0)
                          }
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>{item.productName}</Typography>
                        <Typography variant="caption" color="text.secondary">{item.sku}</Typography>
                      </TableCell>
                      <TableCell align="center">
                        <Typography variant="body2">{item.maxRefundableQty}</Typography>
                      </TableCell>
                      <TableCell align="center" sx={{ width: 100 }}>
                        <TextField
                          type="number"
                          size="small"
                          value={item.quantity}
                          onChange={(e) => handleQtyChange(item.lineItemId, parseInt(e.target.value) || 0)}
                          slotProps={{
                            htmlInput: { min: 0, max: item.maxRefundableQty, style: { textAlign: 'center', width: 60 } },
                          }}
                          sx={{ width: 80 }}
                        />
                      </TableCell>
                      <TableCell align="right">
                        <Typography variant="body2">{fmtCurrency(item.unitPrice)}</Typography>
                      </TableCell>
                      <TableCell align="right">
                        <Typography variant="body2" sx={{ fontWeight: selected ? 700 : 400, color: selected ? '#ff9800' : undefined }}>
                          {selected ? fmtCurrency(item.refundAmount) : '—'}
                        </Typography>
                      </TableCell>
                      <TableCell align="center">
                        {item.isRestockable ? (
                          <Tooltip title={item.restock ? 'Will restock inventory' : 'Will NOT restock'}>
                            <Switch
                              checked={item.restock}
                              onChange={() => handleRestockToggle(item.lineItemId)}
                              size="small"
                              disabled={!selected}
                              color="success"
                            />
                          </Tooltip>
                        ) : (
                          <Tooltip title="Perishable — cannot restock">
                            <Typography variant="caption" color="text.disabled" sx={{ fontStyle: 'italic' }}>
                              Perishable
                            </Typography>
                          </Tooltip>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
                {items.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={7} align="center" sx={{ py: 4 }}>
                      <Typography color="text.disabled">No items available for refund</Typography>
                    </TableCell>
                  </TableRow>
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>

        {/* ─── Right: Refund Summary ─────────────────────── */}
        <Paper
          elevation={dk ? 0 : 1}
          sx={{
            flex: 1,
            borderRadius: 2,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            p: 3,
            alignSelf: 'flex-start',
            position: { lg: 'sticky' },
            top: { lg: 16 },
          }}
        >
          <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 2 }}>Refund Summary</Typography>

          {/* Order Totals */}
          <Box sx={{ mb: 2 }}>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="body2" color="text.secondary">Order Total</Typography>
              <Typography variant="body2" sx={{ fontWeight: 600 }}>{fmtCurrency(orderTotal)}</Typography>
            </Box>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="body2" color="text.secondary">Amount Paid</Typography>
              <Typography variant="body2" sx={{ fontWeight: 600, color: isPartiallyPaid ? '#ff9800' : undefined }}>
                {fmtCurrency(totalPaid)}
                {isPartiallyPaid && (
                  <Typography component="span" variant="caption" sx={{ ml: 0.5, color: 'text.disabled' }}>
                    (partial)
                  </Typography>
                )}
              </Typography>
            </Box>
            {previouslyRefunded > 0 && (
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                <Typography variant="body2" color="text.secondary">Previously Refunded</Typography>
                <Typography variant="body2" sx={{ fontWeight: 600, color: '#0288d1' }}>
                  −{fmtCurrency(previouslyRefunded)}
                </Typography>
              </Box>
            )}
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2" color="text.secondary">Max Refundable</Typography>
              <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(maxRefundableAmount)}</Typography>
            </Box>
          </Box>

          <Divider sx={{ my: 2 }} />

          {/* This Refund */}
          <Box
            sx={{
              p: 2, borderRadius: 2, mb: 2,
              bgcolor: totalRefundAmount > 0
                ? alpha('#ff9800', dk ? 0.15 : 0.08)
                : (dk ? 'rgba(255,255,255,0.03)' : '#f5f5f5'),
            }}
          >
            <Typography variant="overline" sx={{ fontSize: '0.68rem', color: 'text.secondary' }}>
              This Refund
            </Typography>
            <Typography variant="h4" sx={{ fontWeight: 800, color: totalRefundAmount > 0 ? '#ff9800' : 'text.disabled' }}>
              {fmtCurrency(totalRefundAmount)}
            </Typography>
            <Typography variant="caption" color="text.secondary">
              {items.filter((i) => i.quantity > 0).length} item(s) selected
            </Typography>
          </Box>

          {/* Items exceed max — info warning (not a hard block) */}
          {itemsExceedMax && (
            <Alert severity="warning" sx={{ mb: 2, fontSize: '0.78rem' }}>
              Selected items total ({fmtCurrency(rawItemTotal)}) exceeds the max refundable ({fmtCurrency(maxRefundableAmount)}).
              {' '}Refund will be capped at <strong>{fmtCurrency(autoCappedAmount)}</strong>.
              {isPartiallyPaid && ' This order is only partially paid.'}
            </Alert>
          )}

          {/* Custom Refund Amount */}
          {hasSelection && (
            <Box sx={{ mb: 2 }}>
              <FormControlLabel
                control={
                  <Checkbox
                    checked={useCustomAmount}
                    onChange={(_, checked) => {
                      setUseCustomAmount(checked);
                      if (checked) {
                        setCustomAmountStr(autoCappedAmount.toFixed(2));
                      }
                    }}
                    size="small"
                  />
                }
                label={
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    Enter custom refund amount
                  </Typography>
                }
              />
              {useCustomAmount && (
                <TextField
                  type="number"
                  size="small"
                  fullWidth
                  value={customAmountStr}
                  onChange={(e) => setCustomAmountStr(e.target.value)}
                  error={!!customAmountError}
                  helperText={customAmountError || `Max: ${fmtCurrency(Math.min(rawItemTotal, maxRefundableAmount))}`}
                  slotProps={{
                    htmlInput: { min: 0, max: Math.min(rawItemTotal, maxRefundableAmount), step: 0.01 },
                  }}
                  sx={{ mt: 1 }}
                />
              )}
            </Box>
          )}

          {/* Restock Summary */}
          {restockItems.length > 0 && (
            <Alert severity="success" icon={<RestockIcon fontSize="small" />} sx={{ mb: 2, fontSize: '0.78rem' }}>
              <strong>{restockItems.length} item(s)</strong> will be restocked to inventory
            </Alert>
          )}

          <Divider sx={{ my: 2 }} />

          {/* Refund Method */}
          <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>Refund Method</Typography>
          <RadioGroup value={method} onChange={(e) => setMethod(e.target.value as RefundMethod)}>
            {(Object.keys(REFUND_METHOD_CONFIG) as RefundMethod[]).map((m) => (
              <FormControlLabel
                key={m}
                value={m}
                control={<Radio size="small" />}
                label={
                  <Box>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>{REFUND_METHOD_CONFIG[m].label}</Typography>
                    <Typography variant="caption" color="text.secondary">
                      {REFUND_METHOD_CONFIG[m].description}
                    </Typography>
                  </Box>
                }
                sx={{ mb: 1, alignItems: 'flex-start', '& .MuiRadio-root': { mt: 0.5 } }}
              />
            ))}
          </RadioGroup>

          <Divider sx={{ my: 2 }} />

          {/* Reason */}
          <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
            Reason <Typography component="span" color="error">*</Typography>
          </Typography>
          <TextField
            multiline
            rows={3}
            fullWidth
            size="small"
            placeholder="Explain why the refund is being issued…"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            error={reason.length > 0 && reason.trim().length < 3}
            helperText={reason.length > 0 && reason.trim().length < 3 ? 'At least 3 characters' : ''}
            sx={{ mb: 2 }}
          />

          {/* Action Buttons */}
          <Button
            fullWidth
            variant="contained"
            color="warning"
            size="large"
            startIcon={<RefundIcon />}
            disabled={!isValid}
            onClick={() => setConfirmOpen(true)}
            sx={{ fontWeight: 700, textTransform: 'none', mb: 1, py: 1.2 }}
          >
            {isPartiallyPaid ? 'Refund Paid Amount' : 'Process Refund'} — {fmtCurrency(totalRefundAmount)}
          </Button>
          <Button
            fullWidth
            variant="outlined"
            color="inherit"
            onClick={() => navigate('/order-list')}
            sx={{ textTransform: 'none' }}
          >
            Cancel
          </Button>
        </Paper>
      </Box>

      {/* ─── Previous Refund History ─────────────────────── */}
      {previousRefunds.length > 0 && (
        <Paper
          elevation={dk ? 0 : 1}
          sx={{
            mt: 3, borderRadius: 2, p: 2,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
          }}
        >
          <Typography variant="subtitle1" sx={{ fontWeight: 700, mb: 1.5 }}>Refund History</Typography>
          {previousRefunds.map((r) => {
            const sCfg = REFUND_STATUS_CONFIG[r.status];
            return (
              <Box
                key={r.refundId}
                sx={{
                  display: 'flex', alignItems: 'center', gap: 2, py: 1,
                  borderBottom: `1px solid ${dk ? 'rgba(255,255,255,0.04)' : '#eee'}`,
                }}
              >
                <CheckIcon sx={{ color: sCfg.color, fontSize: 20 }} />
                <Box sx={{ flex: 1 }}>
                  <Typography variant="body2" sx={{ fontWeight: 600 }}>
                    {fmtCurrency(r.refundedAmount)} — {REFUND_METHOD_CONFIG[r.method].label}
                  </Typography>
                  <Typography variant="caption" color="text.secondary">
                    {r.items.length} item(s) &bull; {r.processedByName} &bull;{' '}
                    {new Date(r.createdAt).toLocaleString()}
                  </Typography>
                </Box>
                <Chip label={sCfg.label} size="small" sx={{ bgcolor: alpha(sCfg.color, 0.15), color: sCfg.color, fontWeight: 700 }} />
              </Box>
            );
          })}
        </Paper>
      )}

      {/* ─── Confirmation Dialog ─────────────────────────── */}
      <Dialog open={confirmOpen} onClose={() => setConfirmOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1, fontWeight: 700 }}>
          <WarningIcon color="warning" />
          Confirm Refund
        </DialogTitle>
        <DialogContent dividers>
          <Alert severity="warning" sx={{ mb: 2 }}>
            This action cannot be undone. The refund will be processed immediately.
          </Alert>
          <Box sx={{ mb: 2 }}>
            <Typography variant="body2" sx={{ mb: 1 }}>
              <strong>Order:</strong> {order.orderNumber}
            </Typography>
            <Typography variant="body2" sx={{ mb: 1 }}>
              <strong>Refund Amount:</strong>{' '}
              <Typography component="span" sx={{ fontWeight: 700, color: '#ff9800' }}>
                {fmtCurrency(totalRefundAmount)}
              </Typography>
            </Typography>
            <Typography variant="body2" sx={{ mb: 1 }}>
              <strong>Method:</strong> {REFUND_METHOD_CONFIG[method].label}
            </Typography>
            <Typography variant="body2" sx={{ mb: 1 }}>
              <strong>Reason:</strong> {reason}
            </Typography>
            <Typography variant="body2" sx={{ mb: 1 }}>
              <strong>Items:</strong>{' '}
              {items
                .filter((i) => i.quantity > 0)
                .map((i) => `${i.productName} ×${i.quantity}`)
                .join(', ')}
            </Typography>
            {restockItems.length > 0 && (
              <Typography variant="body2" sx={{ color: 'success.main' }}>
                <strong>Restocking:</strong>{' '}
                {restockItems.map((i) => `${i.productName} ×${i.quantity}`).join(', ')}
              </Typography>
            )}
          </Box>
          <Typography variant="body2" color="text.secondary">
            New order status will be:{' '}
            <Chip
              label={deriveRefundOrderStatus(totalPaid, previouslyRefunded, totalRefundAmount)}
              size="small"
              color={
                deriveRefundOrderStatus(totalPaid, previouslyRefunded, totalRefundAmount) === 'REFUNDED'
                  ? 'info'
                  : 'warning'
              }
              sx={{ fontWeight: 700 }}
            />
          </Typography>
        </DialogContent>
        <DialogActions sx={{ px: 3, py: 2 }}>
          <Button onClick={() => setConfirmOpen(false)} sx={{ textTransform: 'none' }}>Cancel</Button>
          <Button
            variant="contained"
            color="warning"
            startIcon={<RefundIcon />}
            onClick={handleProcessRefund}
            sx={{ fontWeight: 700, textTransform: 'none' }}
          >
            Confirm Refund
          </Button>
        </DialogActions>
      </Dialog>

      {/* ─── Snackbar ───────────────────────────────────── */}
      <Snackbar
        open={!!snackMsg}
        autoHideDuration={3000}
        onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity={snackSeverity} variant="filled" onClose={() => setSnackMsg('')}>{snackMsg}</Alert>
      </Snackbar>
    </Box>
  );
};

export default RefundScreen;
