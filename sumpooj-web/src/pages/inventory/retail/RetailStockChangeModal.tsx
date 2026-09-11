/**
 * RetailStockChangeModal.tsx — Floraprise ERP Retail View Stock Change Modal
 *
 * Dedicated florist-friendly stock operation dialog:
 * - 4 standard operations: + Stock In (purchase), - Stock Out (sale), Wastage, Adjustment
 * - Live balance preview calculation
 * - Authoritative Post-Transaction Stock Refresh
 * - Strict Batch Handling for TrackBatch = true:
 *     * Mandatory batch selection on deductions (Stock Out, Wastage, Decrease Adjustment)
 *     * Seamless addition to existing batch OR creating a new batch on Stock In
 *     * Zero batch ledger bypass — keeps ProductStock and BatchStock in 100% parity
 * - Negative balance protection (blocks submission if stock would drop below zero)
 * - Preset florist wastage reason chips
 */

import React, { useState, useEffect } from 'react';
import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Box,
  Typography,
  Button,
  TextField,
  InputAdornment,
  Chip,
  Tabs,
  Tab,
  Alert,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  RadioGroup,
  FormControlLabel,
  Radio,
  useTheme,
  alpha,
  Divider,
} from '@mui/material';
import {
  Add as AddIcon,
  Remove as RemoveIcon,
  DeleteOutline as WastageIcon,
  Tune as AdjustIcon,
  Layers as BatchIcon,
  ArrowForward as ArrowForwardIcon,
} from '@mui/icons-material';
import {
  applyStockChange,
  createAdjustment,
  createBatch,
  getBatchesByProduct,
  type InventoryStockChangeRequest,
  type CreateAdjustmentRequest,
  type CreateBatchRequest,
} from '../../../api/inventory.api';
import type { RetailStockItem } from './RetailStockCard';

export type StockOperationType = 'purchase' | 'sale' | 'wastage' | 'adjustment';

interface RetailStockChangeModalProps {
  open: boolean;
  item: RetailStockItem | null;
  initialOperation?: StockOperationType;
  currencySymbol: string;
  onClose: () => void;
  onSuccess: () => void;
}

const WASTAGE_REASON_PRESETS = [
  'Wilted flowers',
  'Damaged in transit',
  'Broken stem',
  'Expired / Old stock',
  'Pest / Mold damage',
  'Display decay',
];

interface ProductBatchOption {
  id: string;
  batchNumber: string;
  quantityRemaining: number;
  costPerUnit: number;
  expiryDate?: string | null;
}

export const RetailStockChangeModal: React.FC<RetailStockChangeModalProps> = ({
  open,
  item,
  initialOperation = 'purchase',
  currencySymbol,
  onClose,
  onSuccess,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // Modal State
  const [operation, setOperation] = useState<StockOperationType>(initialOperation);
  const [quantity, setQuantity] = useState<string>('1');
  const [adjustmentDirection, setAdjustmentDirection] = useState<'increase' | 'decrease'>('increase');
  const [reason, setReason] = useState<string>('');
  const [notes, setNotes] = useState<string>('');
  const [supplier, setSupplier] = useState<string>('');
  const [costPerUnit, setCostPerUnit] = useState<string>('');

  // Batch Management State (for TrackBatch = true)
  const [batches, setBatches] = useState<ProductBatchOption[]>([]);
  const [selectedBatchId, setSelectedBatchId] = useState<string>('');
  const [batchActionType, setBatchActionType] = useState<'existing' | 'new'>('existing');
  const [newBatchNumber, setNewBatchNumber] = useState<string>('');
  const [newBatchExpiry, setNewBatchExpiry] = useState<string>('');
  const [loadingBatches, setLoadingBatches] = useState(false);

  // Submission State
  const [submitting, setSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Sync initial operation and product fields when modal opens
  useEffect(() => {
    if (open && item) {
      setOperation(initialOperation);
      setQuantity('1');
      setAdjustmentDirection('increase');
      setReason(initialOperation === 'wastage' ? 'Wilted flowers' : '');
      setNotes('');
      setSupplier('');
      setCostPerUnit(item.costPrice > 0 ? item.costPrice.toString() : '');
      setSelectedBatchId('');
      setBatchActionType('existing');
      setNewBatchNumber('');
      setNewBatchExpiry('');
      setErrorMessage(null);

      // Load batches if product has TrackBatch = true
      if (item.trackBatch) {
        setLoadingBatches(true);
        getBatchesByProduct(item.id)
          .then((res) => {
            const raw = Array.isArray(res) ? res : res?.items ?? [];
            const mapped: ProductBatchOption[] = raw
              .map((b: any) => ({
                id: b.id,
                batchNumber: b.batchCode || b.batchNumber || 'Batch',
                quantityRemaining: b.quantityRemaining ?? b.stemsInStock ?? 0,
                costPerUnit: b.costPerUnit ?? 0,
                expiryDate: b.expiryDate,
              }))
              .filter((b: ProductBatchOption) => b.quantityRemaining > 0 || initialOperation === 'purchase');

            setBatches(mapped);
            if (mapped.length > 0) {
              setSelectedBatchId(mapped[0].id);
              setBatchActionType('existing');
            } else {
              setBatchActionType('new');
              const d = new Date();
              setNewBatchNumber(`B-${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}-01`);
            }
          })
          .catch((err) => {
            console.error('Failed to load batches for product:', err);
            setBatches([]);
            setBatchActionType('new');
          })
          .finally(() => {
            setLoadingBatches(false);
          });
      } else {
        setBatches([]);
      }
    }
  }, [open, item, initialOperation]);

  if (!item) return null;

  // Determine if this is a stock deduction
  const isDeduction =
    operation === 'sale' ||
    operation === 'wastage' ||
    (operation === 'adjustment' && adjustmentDirection === 'decrease');

  // Calculate quantity delta and projected new stock
  const numericQty = parseFloat(quantity) || 0;
  let stockDelta = 0;

  if (operation === 'purchase') {
    stockDelta = numericQty;
  } else if (operation === 'sale' || operation === 'wastage') {
    stockDelta = -numericQty;
  } else if (operation === 'adjustment') {
    stockDelta = adjustmentDirection === 'increase' ? numericQty : -numericQty;
  }

  const projectedStock = item.stockQuantity + stockDelta;
  const isNegative = projectedStock < 0;

  // Selected batch reference
  const selectedBatch = batches.find((b) => b.id === selectedBatchId);
  const batchExceeded =
    item.trackBatch &&
    isDeduction &&
    selectedBatch &&
    numericQty > selectedBatch.quantityRemaining;

  // Validation
  const isValidQty = numericQty > 0 && Number.isInteger(numericQty);

  // For TrackBatch = true:
  // - On deductions, a valid batch with sufficient quantity MUST be selected.
  // - On Stock In / Increase, either an existing batch or new batch number is required.
  const isBatchValid =
    !item.trackBatch ||
    (isDeduction
      ? Boolean(selectedBatchId && selectedBatch && !batchExceeded)
      : batchActionType === 'existing'
      ? Boolean(selectedBatchId)
      : Boolean(newBatchNumber.trim()));

  const canSubmit =
    item.trackInventory &&
    isValidQty &&
    !isNegative &&
    isBatchValid &&
    !submitting &&
    (operation !== 'wastage' || reason.trim().length > 0);

  // Handle Submission
  const handleSubmit = async () => {
    if (!canSubmit) return;
    setSubmitting(true);
    setErrorMessage(null);

    try {
      if (item.trackBatch) {
        // Authoritative Batch Execution
        if (operation === 'purchase' && batchActionType === 'new') {
          // Creating a new batch for incoming stock
          const createBatchPayload: CreateBatchRequest = {
            productId: item.id,
            batchNumber: newBatchNumber.trim(),
            quantity: numericQty,
            costPerUnit: parseFloat(costPerUnit) || item.costPrice || 0,
            sellingPricePerUnit: item.retailPrice || null,
            receivedDate: new Date().toISOString(),
            expiryDate: newBatchExpiry ? new Date(newBatchExpiry).toISOString() : null,
            storageLocation: 'Retail Store',
          };
          await createBatch(createBatchPayload);
        } else {
          // Adjusting against an existing batch
          let adjType = 'Correction';
          if (operation === 'purchase') adjType = 'Found';
          else if (operation === 'sale') adjType = 'Other';
          else if (operation === 'wastage') {
            if (reason.toLowerCase().includes('expired')) adjType = 'Expired';
            else if (reason.toLowerCase().includes('damag')) adjType = 'Damaged';
            else adjType = 'Spoiled';
          } else if (operation === 'adjustment') {
            adjType = 'Correction';
          }

          const adjPayload: CreateAdjustmentRequest = {
            productId: item.id,
            batchId: selectedBatchId || null,
            adjustmentType: adjType,
            quantity: numericQty,
            costPerUnit: parseFloat(costPerUnit) || item.costPrice || 0,
            reason: reason.trim() || (operation === 'adjustment' ? adjustmentDirection : operation),
            adjustmentDate: new Date().toISOString(),
            notes: notes.trim() || undefined,
          };
          await createAdjustment(adjPayload);
        }
      } else {
        // Standard high-level stock change endpoint for non-batch products
        const payload: InventoryStockChangeRequest = {
          productId: item.id,
          operation,
          quantity: numericQty,
          increase: operation === 'adjustment' ? adjustmentDirection === 'increase' : undefined,
          costPerUnit: parseFloat(costPerUnit) || undefined,
          supplier: supplier.trim() || undefined,
          reason: reason.trim() || undefined,
          notes: notes.trim() || undefined,
        };
        await applyStockChange(payload);
      }

      // Trigger authoritative post-transaction refresh from backend
      onSuccess();
      onClose();
    } catch (err: any) {
      console.error('Failed to apply stock change:', err);
      const msg =
        err?.response?.data?.message ||
        err?.message ||
        'Failed to record stock change. Please verify your connection.';
      setErrorMessage(msg);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Dialog
      open={open}
      onClose={!submitting ? onClose : undefined}
      maxWidth="sm"
      fullWidth
      PaperProps={{
        sx: {
          borderRadius: 3.5,
          p: 1,
          bgcolor: dk ? '#1E1E1E' : '#FFFFFF',
        },
      }}
    >
      <DialogTitle sx={{ pb: 1 }}>
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <Box>
            <Typography variant="h6" fontWeight={800}>
              Stock Operation
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {item.name} &bull; <span style={{ fontFamily: 'monospace' }}>SKU: {item.sku}</span>
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
            {item.trackBatch && (
              <Chip
                icon={<BatchIcon sx={{ fontSize: '13px !important' }} />}
                label="Batch Tracked"
                size="small"
                color="primary"
                variant="outlined"
                sx={{ fontWeight: 600 }}
              />
            )}
            <Chip
              label={item.category}
              size="small"
              sx={{ fontWeight: 600, bgcolor: dk ? 'rgba(255,255,255,0.08)' : '#F0F4F8' }}
            />
          </Box>
        </Box>
      </DialogTitle>

      <DialogContent sx={{ pt: 1 }}>
        {/* Untracked Warning */}
        {!item.trackInventory && (
          <Alert severity="warning" sx={{ mb: 2, borderRadius: 2 }}>
            <strong>Inventory Tracking Disabled:</strong> Stock changes cannot be applied to this
            product because inventory tracking is turned off.
          </Alert>
        )}

        {errorMessage && (
          <Alert severity="error" sx={{ mb: 2, borderRadius: 2 }}>
            {errorMessage}
          </Alert>
        )}

        {/* Operation Selector Tabs */}
        <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 2.5 }}>
          <Tabs
            value={operation}
            onChange={(_, val) => {
              setOperation(val);
              if (val === 'wastage' && !reason) {
                setReason('Wilted flowers');
              }
            }}
            variant="fullWidth"
            textColor="primary"
            indicatorColor="primary"
          >
            <Tab
              value="purchase"
              icon={<AddIcon sx={{ fontSize: 18 }} />}
              iconPosition="start"
              label="Stock In"
              disabled={submitting}
              sx={{ fontWeight: 700, minHeight: 48 }}
            />
            <Tab
              value="sale"
              icon={<RemoveIcon sx={{ fontSize: 18 }} />}
              iconPosition="start"
              label="Stock Out"
              disabled={submitting}
              sx={{ fontWeight: 700, minHeight: 48 }}
            />
            <Tab
              value="wastage"
              icon={<WastageIcon sx={{ fontSize: 18 }} />}
              iconPosition="start"
              label="Wastage"
              disabled={submitting}
              sx={{ fontWeight: 700, minHeight: 48 }}
            />
            <Tab
              value="adjustment"
              icon={<AdjustIcon sx={{ fontSize: 18 }} />}
              iconPosition="start"
              label="Adjust"
              disabled={submitting}
              sx={{ fontWeight: 700, minHeight: 48 }}
            />
          </Tabs>
        </Box>

        {/* Projected Estimate Preview Box */}
        <Box
          sx={{
            p: 2,
            mb: 3,
            borderRadius: 2.5,
            bgcolor: isNegative
              ? dk
                ? alpha(theme.palette.error.main, 0.15)
                : '#FFEBEE'
              : dk
              ? 'rgba(255,255,255,0.04)'
              : '#F8FAFC',
            border: '1px solid',
            borderColor: isNegative
              ? theme.palette.error.main
              : dk
              ? 'rgba(255,255,255,0.08)'
              : 'rgba(0,0,0,0.08)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-around',
          }}
        >
          {/* Current Stock */}
          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="caption" color="text.secondary" fontWeight={600}>
              CURRENT STOCK
            </Typography>
            <Typography variant="h5" fontWeight={800}>
              {item.stockQuantity}{' '}
              <Typography component="span" variant="body2" color="text.secondary">
                {item.unitOfMeasure}
              </Typography>
            </Typography>
          </Box>

          <ArrowForwardIcon sx={{ color: 'text.secondary', opacity: 0.5 }} />

          {/* Operation Delta */}
          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="caption" color="text.secondary" fontWeight={600}>
              CHANGE
            </Typography>
            <Typography
              variant="h5"
              fontWeight={800}
              sx={{
                color:
                  stockDelta > 0
                    ? theme.palette.success.main
                    : stockDelta < 0
                    ? theme.palette.error.main
                    : 'text.primary',
              }}
            >
              {stockDelta > 0 ? `+${stockDelta}` : stockDelta}{' '}
              <Typography component="span" variant="body2" color="inherit">
                {item.unitOfMeasure}
              </Typography>
            </Typography>
          </Box>

          <ArrowForwardIcon sx={{ color: 'text.secondary', opacity: 0.5 }} />

          {/* Projected New Stock Preview */}
          <Box sx={{ textAlign: 'center' }}>
            <Typography variant="caption" color="text.secondary" fontWeight={600}>
              PROJECTED PREVIEW
            </Typography>
            <Typography
              variant="h5"
              fontWeight={800}
              sx={{
                color: isNegative
                  ? theme.palette.error.main
                  : projectedStock <= item.minimumStockLevel
                  ? theme.palette.warning.main
                  : theme.palette.success.main,
              }}
            >
              {projectedStock}{' '}
              <Typography component="span" variant="body2" color="inherit">
                {item.unitOfMeasure}
              </Typography>
            </Typography>
          </Box>
        </Box>

        {isNegative && (
          <Alert severity="error" sx={{ mb: 2.5, borderRadius: 2 }}>
            Stock cannot go negative. The current stock is {item.stockQuantity} {item.unitOfMeasure}.
          </Alert>
        )}

        {/* Batch Exceeded Error */}
        {batchExceeded && (
          <Alert severity="error" sx={{ mb: 2.5, borderRadius: 2 }}>
            Quantity ({numericQty}) exceeds the selected batch balance ({selectedBatch?.quantityRemaining} {item.unitOfMeasure}).
          </Alert>
        )}

        {/* Form Controls */}
        <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
          {/* Adjustment Direction (only for adjustment) */}
          {operation === 'adjustment' && (
            <FormControl component="fieldset">
              <Typography variant="caption" color="text.secondary" fontWeight={600} sx={{ mb: 0.5 }}>
                ADJUSTMENT DIRECTION
              </Typography>
              <RadioGroup
                row
                value={adjustmentDirection}
                onChange={(e) => setAdjustmentDirection(e.target.value as 'increase' | 'decrease')}
              >
                <FormControlLabel
                  value="increase"
                  control={<Radio size="small" color="success" />}
                  label={<Typography variant="body2" fontWeight={600}>Increase (+ Found stock)</Typography>}
                />
                <FormControlLabel
                  value="decrease"
                  control={<Radio size="small" color="error" />}
                  label={<Typography variant="body2" fontWeight={600}>Decrease (- Correction)</Typography>}
                />
              </RadioGroup>
            </FormControl>
          )}

          {/* Batch Handling for TrackBatch = true */}
          {item.trackBatch && (
            <Box
              sx={{
                p: 2,
                borderRadius: 2.5,
                bgcolor: dk ? alpha(theme.palette.primary.main, 0.08) : '#F0F7FF',
                border: '1px solid',
                borderColor: dk ? alpha(theme.palette.primary.main, 0.25) : '#C2E0FF',
              }}
            >
              <Typography variant="caption" fontWeight={700} color="primary" sx={{ display: 'block', mb: 1 }}>
                BATCH ALLOCATION (REQUIRED FOR BATCH-TRACKED PRODUCTS)
              </Typography>

              {/* Deduction must select an existing batch */}
              {isDeduction ? (
                batches.length === 0 ? (
                  <Alert severity="warning" sx={{ borderRadius: 1.5 }}>
                    No active batches exist for this product. Cannot deduct stock without a valid batch.
                  </Alert>
                ) : (
                  <FormControl fullWidth size="small" required>
                    <InputLabel id="deduct-batch-select-label">Select Active Batch *</InputLabel>
                    <Select
                      labelId="deduct-batch-select-label"
                      value={selectedBatchId}
                      label="Select Active Batch *"
                      onChange={(e) => setSelectedBatchId(e.target.value)}
                    >
                      {batches.map((b) => (
                        <MenuItem key={b.id} value={b.id}>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between', width: '100%' }}>
                            <span>
                              <strong>{b.batchNumber}</strong>
                              {b.expiryDate && (
                                <span style={{ fontSize: '0.8rem', opacity: 0.7, marginLeft: 8 }}>
                                  (Exp: {new Date(b.expiryDate).toLocaleDateString()})
                                </span>
                              )}
                            </span>
                            <Typography variant="body2" color="text.secondary" fontWeight={600}>
                              {b.quantityRemaining} {item.unitOfMeasure} available
                            </Typography>
                          </Box>
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                )
              ) : (
                /* Addition allows adding to existing batch or creating new batch */
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                  <RadioGroup
                    row
                    value={batchActionType}
                    onChange={(e) => setBatchActionType(e.target.value as 'existing' | 'new')}
                  >
                    {batches.length > 0 && (
                      <FormControlLabel
                        value="existing"
                        control={<Radio size="small" />}
                        label={<Typography variant="body2" fontWeight={600}>Add to Existing Batch</Typography>}
                      />
                    )}
                    <FormControlLabel
                      value="new"
                      control={<Radio size="small" />}
                      label={<Typography variant="body2" fontWeight={600}>Create New Batch</Typography>}
                    />
                  </RadioGroup>

                  {batchActionType === 'existing' && batches.length > 0 ? (
                    <FormControl fullWidth size="small" required>
                      <InputLabel id="in-batch-select-label">Select Batch *</InputLabel>
                      <Select
                        labelId="in-batch-select-label"
                        value={selectedBatchId}
                        label="Select Batch *"
                        onChange={(e) => setSelectedBatchId(e.target.value)}
                      >
                        {batches.map((b) => (
                          <MenuItem key={b.id} value={b.id}>
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', width: '100%' }}>
                              <span><strong>{b.batchNumber}</strong></span>
                              <Typography variant="body2" color="text.secondary">
                                {b.quantityRemaining} {item.unitOfMeasure} current
                              </Typography>
                            </Box>
                          </MenuItem>
                        ))}
                      </Select>
                    </FormControl>
                  ) : (
                    <Box sx={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 1.5 }}>
                      <TextField
                        label="Batch Code *"
                        value={newBatchNumber}
                        onChange={(e) => setNewBatchNumber(e.target.value)}
                        size="small"
                        required
                        placeholder="e.g. B-20260911-01"
                      />
                      <TextField
                        label="Expiry Date"
                        type="date"
                        value={newBatchExpiry}
                        onChange={(e) => setNewBatchExpiry(e.target.value)}
                        size="small"
                        InputLabelProps={{ shrink: true }}
                      />
                    </Box>
                  )}
                </Box>
              )}
            </Box>
          )}

          {/* Quantity Input */}
          <TextField
            label="Quantity"
            type="number"
            value={quantity}
            onChange={(e) => setQuantity(e.target.value)}
            fullWidth
            required
            disabled={submitting || !item.trackInventory}
            slotProps={{
              input: {
                endAdornment: (
                  <InputAdornment position="end">{item.unitOfMeasure}</InputAdornment>
                ),
              },
              htmlInput: { min: 1, step: 1 },
            }}
            helperText={!isValidQty ? 'Please enter a positive whole number' : ''}
            error={!isValidQty && quantity.trim().length > 0}
          />

          {/* Wastage Preset Reason Chips */}
          {operation === 'wastage' && (
            <Box>
              <Typography variant="caption" color="text.secondary" fontWeight={600} sx={{ mb: 1, display: 'block' }}>
                REASON FOR WASTAGE *
              </Typography>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 1.5 }}>
                {WASTAGE_REASON_PRESETS.map((preset) => (
                  <Chip
                    key={preset}
                    label={preset}
                    size="small"
                    clickable
                    color={reason === preset ? 'error' : 'default'}
                    variant={reason === preset ? 'filled' : 'outlined'}
                    onClick={() => setReason(preset)}
                    sx={{ fontWeight: 600, borderRadius: 1.5 }}
                  />
                ))}
              </Box>
              <TextField
                label="Specific Reason / Damage Details"
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                fullWidth
                size="small"
                required
                disabled={submitting}
              />
            </Box>
          )}

          {/* Stock In: Supplier & Cost Details */}
          {operation === 'purchase' && (
            <Box sx={{ display: 'grid', gridTemplateColumns: '1.2fr 1fr', gap: 1.5 }}>
              <TextField
                label="Supplier (Optional)"
                value={supplier}
                onChange={(e) => setSupplier(e.target.value)}
                size="small"
                placeholder="e.g. FloraWholesale Ltd"
                disabled={submitting}
              />
              <TextField
                label="Unit Cost"
                type="number"
                value={costPerUnit}
                onChange={(e) => setCostPerUnit(e.target.value)}
                size="small"
                disabled={submitting}
                slotProps={{
                  input: {
                    startAdornment: (
                      <InputAdornment position="start">{currencySymbol}</InputAdornment>
                    ),
                  },
                  htmlInput: { min: 0, step: 0.01 },
                }}
              />
            </Box>
          )}

          {/* Additional Notes */}
          <TextField
            label="Notes / Comments (Optional)"
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            fullWidth
            multiline
            rows={2}
            size="small"
            placeholder="Add any internal comments or reference details..."
            disabled={submitting}
          />
        </Box>
      </DialogContent>

      <DialogActions sx={{ px: 3, pb: 2, pt: 1 }}>
        <Button onClick={onClose} disabled={submitting} sx={{ fontWeight: 600 }}>
          Cancel
        </Button>
        <Button
          variant="contained"
          color={
            operation === 'purchase'
              ? 'success'
              : operation === 'sale'
              ? 'info'
              : operation === 'wastage'
              ? 'error'
              : 'primary'
          }
          disabled={!canSubmit}
          onClick={handleSubmit}
          startIcon={submitting ? <CircularProgress size={18} color="inherit" /> : null}
          sx={{
            fontWeight: 700,
            borderRadius: 2,
            px: 3,
            minWidth: 140,
          }}
        >
          {submitting
            ? 'Recording...'
            : operation === 'purchase'
            ? '+ Record Stock In'
            : operation === 'sale'
            ? '- Record Stock Out'
            : operation === 'wastage'
            ? 'Record Wastage'
            : 'Apply Adjustment'}
        </Button>
      </DialogActions>
    </Dialog>
  );
};
