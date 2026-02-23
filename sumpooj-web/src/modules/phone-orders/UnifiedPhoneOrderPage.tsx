import React, { useState, useMemo } from 'react';
import {
  Box,
  Button,
  Chip,
  CircularProgress,
  Container,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  Divider,
  FormControl,
  FormControlLabel,
  FormLabel,
  Grid,
  InputAdornment,
  InputLabel,
  MenuItem,
  Paper,
  Radio,
  RadioGroup,
  Select,
  TextField,
  Typography,
} from '@mui/material';
import {
  Save as SaveIcon,
  CheckCircle as ConfirmIcon,
  PlayArrow as PlayIcon,
  LocalShipping as DeliveryIcon,
  Receipt as ReceiptIcon,
} from '@mui/icons-material';
import { useToast } from '../../hooks/useToast';
import {
  createPhoneOrder,
  addItemToPhoneOrder,
  confirmPhoneLocalOrder,
  startProductionForPhoneLocalOrder,
  getPhoneOrder,
  createPayment,
  scheduleDelivery,
} from './phoneOrders.api';
import type { PhoneOrderResponse } from './phoneOrders.api';
import VendorAssignmentModal from './VendorAssignmentModal';
import InvoiceDialog from './InvoiceDialog';

// ── Constants ────────────────────────────────────────────────────────────────

type OrderType = 'Pickup' | 'LocalDelivery' | 'OutstationDelivery';
type PaymentMode = 'Cash' | 'UPI' | 'Card' | 'BankTransfer';

const TIME_SLOT_OPTIONS = [
  '10:00 AM – 12:00 PM',
  '12:00 PM – 2:00 PM',
  '2:00 PM – 4:00 PM',
  '4:00 PM – 6:00 PM',
  'Custom',
];

const PAYMENT_MODES: { value: PaymentMode; label: string }[] = [
  { value: 'Cash', label: 'Cash' },
  { value: 'UPI', label: 'UPI' },
  { value: 'Card', label: 'Card' },
  { value: 'BankTransfer', label: 'Bank Transfer' },
];

// ── Status badge color mapping ───────────────────────────────────────────

const getStatusChipColor = (status: string): 'warning' | 'info' | 'primary' | 'success' | 'error' | 'default' => {
  switch (status) {
    case 'Draft':
      return 'warning'; // Yellow
    case 'Confirmed':
      return 'info'; // Blue
    case 'InProduction':
      return 'primary'; // Orange (primary can be themed, using 'primary')
    case 'Delivered':
      return 'success'; // Green
    case 'Cancelled':
      return 'error'; // Red
    default:
      return 'default';
  }
};
// ── Payment status chip helper ───────────────────────────────────────────
const getPaymentStatusChip = (
  paid: number,
  balance: number
): { label: string; color: 'success' | 'warning' | 'error' } => {
  if (balance === 0 && paid > 0) {
    return { label: 'Paid', color: 'success' };
  } else if (paid > 0 && balance > 0) {
    return { label: 'Partially Paid', color: 'warning' };
  } else {
    return { label: 'Unpaid', color: 'error' };
  }
};

// ── Section wrapper component (defined outside to prevent re-renders) ───────
const Section: React.FC<{ title: string; children: React.ReactNode }> = ({ title, children }) => (
  <Box sx={{ mb: 4 }}>
    <Typography variant="subtitle1" sx={{ fontWeight: 600, mb: 2, color: 'primary.main' }}>
      {title}
    </Typography>
    {children}
  </Box>
);

// ── Component ────────────────────────────────────────────────────────────────

const UnifiedPhoneOrderPage: React.FC = () => {
  const toast = useToast();

  // ── Saving / Confirming state ─────────────────────────────────────────────
  const [saving, setSaving] = useState(false);
  const [confirming, setConfirming] = useState(false);
  const [vendorModalOpen, setVendorModalOpen] = useState(false);

  // ── Backend order state ───────────────────────────────────────────────
  const [order, setOrder] = useState<PhoneOrderResponse | null>(null);
  const savedOrderId = order?.id ?? null;

  // ── Production state ───────────────────────────────────────────────────
  const [startingProduction, setStartingProduction] = useState(false);

  // ── 1️⃣ Order Type ─────────────────────────────────────────────────────────
  const [orderType, setOrderType] = useState<OrderType>('LocalDelivery');

  // ── 2️⃣ Customer Information ───────────────────────────────────────────────
  const [customerName, setCustomerName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');

  // ── 3️⃣ Delivery Details ───────────────────────────────────────────────────
  const [deliveryDate, setDeliveryDate] = useState('');
  const [deliveryTime, setDeliveryTime] = useState('');
  const [customTime, setCustomTime] = useState('');
  const [city, setCity] = useState('');
  const [deliveryAddress, setDeliveryAddress] = useState('');
  const [cardMessage, setCardMessage] = useState('');
  const [senderName, setSenderName] = useState('');

  // ── 4️⃣ Product Summary ────────────────────────────────────────────────────
  const [productDescription, setProductDescription] = useState('');
  const [amount, setAmount] = useState<number | ''>('');
  const [deliveryCharge, setDeliveryCharge] = useState<number | ''>('');
  const [discount, setDiscount] = useState<number | ''>('');

  // ── 5️⃣ Payment Details ────────────────────────────────────────────────────
  const [advancePaid, setAdvancePaid] = useState<number>(0);
  const [paymentMode, setPaymentMode] = useState<PaymentMode>('Cash');
  const [confirmingWithPayment, setConfirmingWithPayment] = useState(false);  const [pendingPaymentAfterVendorConfirm, setPendingPaymentAfterVendorConfirm] = useState(false);
  const [recordedPayment, setRecordedPayment] = useState<{ amount: number; mode: PaymentMode } | null>(null);

  // ── Invoice dialog state ─────────────────────────────────────────────────
  const [invoiceDialogOpen, setInvoiceDialogOpen] = useState(false);

  // ── Schedule Delivery dialog state ───────────────────────────────────────
  const [scheduleDeliveryDialogOpen, setScheduleDeliveryDialogOpen] = useState(false);
  const [scheduleDeliveryDate, setScheduleDeliveryDate] = useState('');
  const [scheduleDeliveryTimeSlot, setScheduleDeliveryTimeSlot] = useState('');
  const [scheduleDeliveryAddress, setScheduleDeliveryAddress] = useState('');
  const [schedulingDelivery, setSchedulingDelivery] = useState(false);

  // ── Computed total ─────────────────────────────────────────────────────────
  const total = useMemo(() => {
    const amtVal = typeof amount === 'number' ? amount : 0;
    const dcVal = typeof deliveryCharge === 'number' ? deliveryCharge : 0;
    const discVal = typeof discount === 'number' ? discount : 0;
    return amtVal + dcVal - discVal;
  }, [amount, deliveryCharge, discount]);

  // ── Computed balance ───────────────────────────────────────────────────────
  const balanceAmount = useMemo(() => {
    return Math.max(0, total - advancePaid);
  }, [total, advancePaid]);

  // ── Field behavior flags ───────────────────────────────────────────────────
  const isLocked = !!(order && order.status !== 'Draft');
  const isCityDisabled = isLocked || orderType === 'Pickup';
  const isAddressDisabled = isLocked || orderType === 'Pickup' || orderType === 'OutstationDelivery';

  // ── Validation ─────────────────────────────────────────────────────────────
  const validateDraft = (): string[] => {
    const errors: string[] = [];
    if (!customerName.trim()) errors.push('Customer Name is required');
    if (!phoneNumber.trim()) errors.push('Phone Number is required');
    if (!deliveryDate) errors.push('Delivery Date is required');
    if (!productDescription.trim()) errors.push('Product Description is required');
    if (amount === '' || amount <= 0) errors.push('Amount is required and must be greater than 0');
    return errors;
  };

  // ── Refetch order from backend ──────────────────────────────────────
  const refetchOrder = async (orderId: string) => {
    try {
      const fetchedOrder = await getPhoneOrder(orderId);
      setOrder(fetchedOrder);
    } catch (err) {
      console.error('Failed to refetch order:', err);
    }
  };

  // ── Handlers ───────────────────────────────────────────────────────────────
  const handleSaveDraft = async () => {
    // Validate required fields
    const validationErrors = validateDraft();
    if (validationErrors.length > 0) {
      toast.error(validationErrors.join('\n'));
      return;
    }

    setSaving(true);
    try {
      // Map order type to API format
      const apiOrderType: 'PhoneLocal' | 'PhoneOutstation' =
        orderType === 'OutstationDelivery' ? 'PhoneOutstation' : 'PhoneLocal';

      // Create the phone order
      const createdOrder = await createPhoneOrder({
        customerId: undefined, // null for now
        customerName: customerName.trim(),
        phoneNumber: phoneNumber.trim(),
        orderType: apiOrderType,
        deliveryDate,
        deliveryCity: city.trim() || 'N/A',
        timeSlot: deliveryTime === 'Custom' ? customTime.trim() : deliveryTime || undefined,
        occasion: cardMessage.trim() || undefined,
        budget: typeof amount === 'number' ? amount : undefined,
        specialInstructions: productDescription.trim() || undefined,
      });

      // Add item to the order
      await addItemToPhoneOrder(createdOrder.id, {
        productId: `manual-item-${Date.now()}`,
        quantity: 1,
        unitPrice: typeof amount === 'number' ? amount : 0,
      });

      // Store order and show success toast
      setOrder(createdOrder);
      toast.success('Draft saved successfully');
    } catch (err) {
      console.error('Failed to save draft:', err);
      toast.error('Failed to save draft');
    } finally {
      setSaving(false);
    }
  };

  const handleConfirmOrder = async () => {
    // Validate required fields
    const validationErrors = validateDraft();
    if (validationErrors.length > 0) {
      toast.error(validationErrors.join('\n'));
      return;
    }

    setConfirming(true);
    try {
      let orderId = savedOrderId;

      // If no order exists yet, create one first
      if (!orderId) {
        const apiOrderType: 'PhoneLocal' | 'PhoneOutstation' =
          orderType === 'OutstationDelivery' ? 'PhoneOutstation' : 'PhoneLocal';

        const createdOrder = await createPhoneOrder({
          customerId: undefined,
          customerName: customerName.trim(),
          phoneNumber: phoneNumber.trim(),
          orderType: apiOrderType,
          deliveryDate,
          deliveryCity: city.trim() || 'N/A',
          timeSlot: deliveryTime === 'Custom' ? customTime.trim() : deliveryTime || undefined,
          occasion: cardMessage.trim() || undefined,
          budget: typeof amount === 'number' ? amount : undefined,
          specialInstructions: productDescription.trim() || undefined,
        });

        await addItemToPhoneOrder(createdOrder.id, {
          productId: `manual-item-${Date.now()}`,
          quantity: 1,
          unitPrice: typeof amount === 'number' ? amount : 0,
        });

        orderId = createdOrder.id;
        setOrder(createdOrder);
      }

      // Confirm based on order type
      if (orderType === 'OutstationDelivery') {
        // Open vendor modal - confirmation will happen in modal callback
        setConfirming(false);
        setVendorModalOpen(true);
      } else {
        // Local or Pickup - confirm directly
        await confirmPhoneLocalOrder(orderId);
        toast.success('Order confirmed');
        await refetchOrder(orderId);
      }
    } catch (err) {
      console.error('Failed to confirm order:', err);
      toast.error('Failed to confirm order');
    } finally {
      setConfirming(false);
    }
  };

  const handleVendorConfirmSuccess = async () => {
    // Check if we need to create payment after vendor confirms (for Confirm & Pay flow)
    if (pendingPaymentAfterVendorConfirm && savedOrderId) {
      try {
        await createPayment({
          orderId: savedOrderId,
          amount: advancePaid,
          paymentMode,
        });
        setRecordedPayment({ amount: advancePaid, mode: paymentMode });
        toast.success('Order confirmed and payment recorded');
      } catch (err) {
        console.error('Failed to create payment:', err);
        toast.error('Order confirmed but payment failed');
      }
      setPendingPaymentAfterVendorConfirm(false);
    } else {
      toast.success('Order confirmed');
    }
    if (savedOrderId) {
      await refetchOrder(savedOrderId);
    }
  };

  const handleStartProduction = async () => {
    if (!savedOrderId) return;
    setStartingProduction(true);
    try {
      await startProductionForPhoneLocalOrder(savedOrderId);
      toast.success('Production started');
      await refetchOrder(savedOrderId);
    } catch (err) {
      console.error('Failed to start production:', err);
      toast.error('Failed to start production');
    } finally {
      setStartingProduction(false);
    }
  };

  // ── Schedule Delivery Handlers ─────────────────────────────────────────────
  const openScheduleDeliveryDialog = () => {
    // Pre-fill from order data
    setScheduleDeliveryDate(deliveryDate || '');
    setScheduleDeliveryTimeSlot(deliveryTime || '');
    setScheduleDeliveryAddress(deliveryAddress || '');
    setScheduleDeliveryDialogOpen(true);
  };

  const handleScheduleDeliverySubmit = async () => {
    if (!savedOrderId) return;

    // Validate
    if (!scheduleDeliveryDate) {
      toast.error('Delivery date is required');
      return;
    }
    if (!scheduleDeliveryTimeSlot) {
      toast.error('Time slot is required');
      return;
    }
    if (!scheduleDeliveryAddress.trim()) {
      toast.error('Delivery address is required');
      return;
    }

    setSchedulingDelivery(true);
    try {
      await scheduleDelivery(savedOrderId, {
        deliveryDate: scheduleDeliveryDate,
        timeSlot: scheduleDeliveryTimeSlot,
        address: scheduleDeliveryAddress.trim(),
      });
      toast.success('Delivery Scheduled');
      setScheduleDeliveryDialogOpen(false);
      await refetchOrder(savedOrderId);
    } catch (err) {
      console.error('Failed to schedule delivery:', err);
      toast.error('Failed to schedule delivery');
    } finally {
      setSchedulingDelivery(false);
    }
  };

  const handleConfirmAndPay = async () => {
    // Validate required fields
    const validationErrors = validateDraft();
    if (validationErrors.length > 0) {
      toast.error(validationErrors.join('\n'));
      return;
    }

    if (advancePaid <= 0) {
      toast.error('Advance amount must be greater than 0');
      return;
    }

    setConfirmingWithPayment(true);
    try {
      let orderId = savedOrderId;

      // If no order exists yet, create one first
      if (!orderId) {
        const apiOrderType: 'PhoneLocal' | 'PhoneOutstation' =
          orderType === 'OutstationDelivery' ? 'PhoneOutstation' : 'PhoneLocal';

        const createdOrder = await createPhoneOrder({
          customerId: undefined,
          customerName: customerName.trim(),
          phoneNumber: phoneNumber.trim(),
          orderType: apiOrderType,
          deliveryDate,
          deliveryCity: city.trim() || 'N/A',
          timeSlot: deliveryTime === 'Custom' ? customTime.trim() : deliveryTime || undefined,
          occasion: cardMessage.trim() || undefined,
          budget: typeof amount === 'number' ? amount : undefined,
          specialInstructions: productDescription.trim() || undefined,
        });

        await addItemToPhoneOrder(createdOrder.id, {
          productId: `manual-item-${Date.now()}`,
          quantity: 1,
          unitPrice: typeof amount === 'number' ? amount : 0,
        });

        orderId = createdOrder.id;
        setOrder(createdOrder);
      }

      // Confirm based on order type
      if (orderType === 'OutstationDelivery') {
        // Set flag to collect payment after vendor confirms
        setPendingPaymentAfterVendorConfirm(true);
        setConfirmingWithPayment(false);
        setVendorModalOpen(true);
        // Payment will be handled in handleVendorConfirmSuccess
      } else {
        // Local or Pickup - confirm directly
        await confirmPhoneLocalOrder(orderId);

        // Create payment record
        await createPayment({
          orderId,
          amount: advancePaid,
          paymentMode,
        });

        // Track recorded payment for summary display
        setRecordedPayment({ amount: advancePaid, mode: paymentMode });

        toast.success('Order confirmed & payment collected');
        await refetchOrder(orderId);
      }
    } catch (err) {
      console.error('Failed to confirm order with payment:', err);
      toast.error('Failed to confirm order');
    } finally {
      setConfirmingWithPayment(false);
    }
  };

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <Container maxWidth="md" sx={{ py: 4 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, mb: 3 }}>
        <Typography variant="h5" sx={{ fontWeight: 700 }}>
          Phone Order
        </Typography>
        {order && (
          <>
            <Chip
              label={order.status}
              color={getStatusChipColor(order.status)}
              size="small"
              sx={{ fontWeight: 600 }}
            />
            {(() => {
              const paid = recordedPayment?.amount ?? 0;
              const balance = total - paid;
              const paymentChip = getPaymentStatusChip(paid, balance);
              return (
                <Chip
                  label={paymentChip.label}
                  color={paymentChip.color}
                  size="small"
                  variant="outlined"
                  sx={{ fontWeight: 600 }}
                />
              );
            })()}
            {order.status !== 'Draft' && (
              <Button
                size="small"
                variant="outlined"
                startIcon={<ReceiptIcon />}
                onClick={() => setInvoiceDialogOpen(true)}
              >
                View Invoice
              </Button>
            )}
          </>
        )}
      </Box>

      <Paper elevation={2} sx={{ p: 3 }}>
        {/* ═══════════════════════════════════════════════════════════════════
            1️⃣ ORDER TYPE SECTION
        ═══════════════════════════════════════════════════════════════════ */}
        <Section title="1. Order Type">
          <FormControl component="fieldset" disabled={isLocked}>
            <FormLabel component="legend" sx={{ mb: 1 }}>
              Select order type
            </FormLabel>
            <RadioGroup
              row
              value={orderType}
              onChange={(e) => setOrderType(e.target.value as OrderType)}
            >
              <FormControlLabel value="Pickup" control={<Radio />} label="Pickup" disabled={isLocked} />
              <FormControlLabel value="LocalDelivery" control={<Radio />} label="Local Delivery" disabled={isLocked} />
              <FormControlLabel value="OutstationDelivery" control={<Radio />} label="Outstation Delivery" disabled={isLocked} />
            </RadioGroup>
          </FormControl>
        </Section>

        <Divider sx={{ mb: 3 }} />

        {/* ═══════════════════════════════════════════════════════════════════
            2️⃣ CUSTOMER INFORMATION SECTION
        ═══════════════════════════════════════════════════════════════════ */}
        <Section title="2. Customer Information">
          <Grid container spacing={2}>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Customer Name"
                value={customerName}
                onChange={(e) => setCustomerName(e.target.value)}
                fullWidth
                required
                size="small"
                disabled={isLocked}
              />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Phone Number"
                value={phoneNumber}
                onChange={(e) => setPhoneNumber(e.target.value)}
                fullWidth
                required
                size="small"
                disabled={isLocked}
              />
            </Grid>
          </Grid>
        </Section>

        <Divider sx={{ mb: 3 }} />

        {/* ═══════════════════════════════════════════════════════════════════
            3️⃣ DELIVERY DETAILS SECTION
        ═══════════════════════════════════════════════════════════════════ */}
        <Section title="3. Delivery Details">
          <Grid container spacing={2}>
            {/* Delivery Date */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Delivery Date"
                type="date"
                value={deliveryDate}
                onChange={(e) => setDeliveryDate(e.target.value)}
                fullWidth
                required
                size="small"
                slotProps={{ inputLabel: { shrink: true } }}
                disabled={isLocked}
              />
            </Grid>

            {/* Delivery Time */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <FormControl fullWidth size="small" disabled={isLocked}>
                <InputLabel id="delivery-time-label">Delivery Time</InputLabel>
                <Select
                  labelId="delivery-time-label"
                  value={deliveryTime}
                  label="Delivery Time"
                  onChange={(e) => setDeliveryTime(e.target.value)}
                >
                  {TIME_SLOT_OPTIONS.map((slot) => (
                    <MenuItem key={slot} value={slot}>
                      {slot}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Custom Time (shown when Custom selected) */}
            {deliveryTime === 'Custom' && (
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  label="Custom Time"
                  value={customTime}
                  onChange={(e) => setCustomTime(e.target.value)}
                  placeholder="e.g., 9:00 AM - 11:00 AM"
                  fullWidth
                  size="small"
                  disabled={isLocked}
                />
              </Grid>
            )}

            {/* City */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="City"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                fullWidth
                size="small"
                disabled={isCityDisabled}
              />
            </Grid>

            {/* Delivery Address */}
            <Grid size={{ xs: 12 }}>
              <TextField
                label="Delivery Address"
                value={deliveryAddress}
                onChange={(e) => setDeliveryAddress(e.target.value)}
                fullWidth
                size="small"
                multiline
                rows={2}
                disabled={isAddressDisabled}
              />
            </Grid>

            {/* Card Message */}
            <Grid size={{ xs: 12 }}>
              <TextField
                label="Card Message"
                value={cardMessage}
                onChange={(e) => setCardMessage(e.target.value)}
                fullWidth
                size="small"
                multiline
                rows={2}
                disabled={isLocked}
              />
            </Grid>

            {/* Sender Name */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Sender Name"
                value={senderName}
                onChange={(e) => setSenderName(e.target.value)}
                fullWidth
                size="small"
                disabled={isLocked}
              />
            </Grid>
          </Grid>
        </Section>

        <Divider sx={{ mb: 3 }} />

        {/* ═══════════════════════════════════════════════════════════════════
            4️⃣ PRODUCT SUMMARY SECTION
        ═══════════════════════════════════════════════════════════════════ */}
        <Section title="4. Product Summary">
          <Grid container spacing={2}>
            {/* Product Description */}
            <Grid size={{ xs: 12 }}>
              <TextField
                label="Product Description"
                value={productDescription}
                onChange={(e) => setProductDescription(e.target.value)}
                fullWidth
                required
                size="small"
                multiline
                rows={3}
                disabled={isLocked}
              />
            </Grid>

            {/* Amount */}
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <TextField
                label="Amount"
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value === '' ? '' : Number(e.target.value))}
                fullWidth
                required
                size="small"
                slotProps={{
                  input: {
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
                disabled={isLocked}
              />
            </Grid>

            {/* Delivery Charge */}
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <TextField
                label="Delivery Charge"
                type="number"
                value={deliveryCharge}
                onChange={(e) => setDeliveryCharge(e.target.value === '' ? '' : Number(e.target.value))}
                fullWidth
                size="small"
                slotProps={{
                  input: {
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
                disabled={isLocked}
              />
            </Grid>

            {/* Discount */}
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <TextField
                label="Discount"
                type="number"
                value={discount}
                onChange={(e) => setDiscount(e.target.value === '' ? '' : Number(e.target.value))}
                fullWidth
                size="small"
                slotProps={{
                  input: {
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
                disabled={isLocked}
              />
            </Grid>

            {/* Total (read-only) */}
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <TextField
                label="Total"
                value={total.toFixed(2)}
                fullWidth
                size="small"
                slotProps={{
                  input: {
                    readOnly: true,
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
                sx={{
                  '& .MuiInputBase-input': {
                    fontWeight: 700,
                    color: 'success.main',
                  },
                }}
              />
            </Grid>
          </Grid>
        </Section>

        <Divider sx={{ mb: 3 }} />

        {/* ═══════════════════════════════════════════════════════════════════
            5️⃣ PAYMENT DETAILS SECTION
        ═══════════════════════════════════════════════════════════════════ */}
        <Section title="5. Payment Details">
          <Grid container spacing={2}>
            {/* Advance Paid */}
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <TextField
                label="Advance Paid"
                type="number"
                value={advancePaid}
                onChange={(e) => setAdvancePaid(e.target.value === '' ? 0 : Number(e.target.value))}
                fullWidth
                size="small"
                slotProps={{
                  input: {
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
                disabled={isLocked}
              />
            </Grid>

            {/* Payment Mode */}
            <Grid size={{ xs: 12, sm: 6, md: 3 }}>
              <FormControl fullWidth size="small" disabled={isLocked}>
                <InputLabel id="payment-mode-label">Payment Mode</InputLabel>
                <Select
                  labelId="payment-mode-label"
                  value={paymentMode}
                  label="Payment Mode"
                  onChange={(e) => setPaymentMode(e.target.value as PaymentMode)}
                >
                  {PAYMENT_MODES.map((mode) => (
                    <MenuItem key={mode.value} value={mode.value}>
                      {mode.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Order Total (read-only) */}
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField
                label="Order Total"
                value={total.toFixed(2)}
                fullWidth
                size="small"
                slotProps={{
                  input: {
                    readOnly: true,
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
              />
            </Grid>

            {/* Advance Paid Display (read-only) */}
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField
                label="Advance Paid"
                value={advancePaid.toFixed(2)}
                fullWidth
                size="small"
                slotProps={{
                  input: {
                    readOnly: true,
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
              />
            </Grid>

            {/* Balance Amount (read-only) */}
            <Grid size={{ xs: 12, sm: 6, md: 2 }}>
              <TextField
                label="Balance"
                value={balanceAmount.toFixed(2)}
                fullWidth
                size="small"
                slotProps={{
                  input: {
                    readOnly: true,
                    startAdornment: <InputAdornment position="start">₹</InputAdornment>,
                  },
                }}
                sx={{
                  '& .MuiInputBase-input': {
                    fontWeight: 700,
                    color: balanceAmount > 0 ? 'error.main' : 'success.main',
                  },
                }}
              />
            </Grid>
          </Grid>
        </Section>

        <Divider sx={{ mb: 3 }} />

        {/* ═══════════════════════════════════════════════════════════════════
            6️⃣ ACTION BUTTONS SECTION
        ═══════════════════════════════════════════════════════════════════ */}
        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end', flexWrap: 'wrap' }}>
          <Button
            variant="outlined"
            startIcon={saving ? <CircularProgress size={16} /> : <SaveIcon />}
            onClick={handleSaveDraft}
            disabled={saving || isLocked}
          >
            {saving ? 'Saving...' : 'Save Draft'}
          </Button>
          <Button
            variant="outlined"
            color="primary"
            startIcon={confirming ? <CircularProgress size={16} /> : <ConfirmIcon />}
            onClick={handleConfirmOrder}
            disabled={confirming || confirmingWithPayment || isLocked}
          >
            {isLocked ? 'Confirmed' : confirming ? 'Confirming...' : 'Confirm (Unpaid)'}
          </Button>
          <Button
            variant="contained"
            color="success"
            startIcon={confirmingWithPayment ? <CircularProgress size={16} color="inherit" /> : <ConfirmIcon />}
            onClick={handleConfirmAndPay}
            disabled={confirming || confirmingWithPayment || isLocked}
          >
            {confirmingWithPayment ? 'Processing...' : 'Confirm & Collect Payment'}
          </Button>
        </Box>

        {/* ═══════════════════════════════════════════════════════════════════
            STATUS-BASED ACTION PANELS
        ═══════════════════════════════════════════════════════════════════ */}
        {order?.status === 'Confirmed' && (
          <>
            <Divider sx={{ my: 3 }} />
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}>
              <ConfirmIcon color="success" />
              <Typography variant="h6" sx={{ fontWeight: 600, color: 'success.main' }}>
                Order Confirmed
              </Typography>
            </Box>

            {/* Payment Summary */}
            {recordedPayment && (
              <Section title="Payment Summary">
                <Box
                  sx={{
                    p: 2,
                    bgcolor: 'success.lighter',
                    borderRadius: 2,
                    border: '1px solid',
                    borderColor: 'success.light',
                  }}
                >
                  <Grid container spacing={2}>
                    <Grid size={4}>
                      <Typography variant="body2" color="text.secondary">
                        Order Total
                      </Typography>
                      <Typography variant="h6" sx={{ fontWeight: 600 }}>
                        ₹{total.toLocaleString()}
                      </Typography>
                    </Grid>
                    <Grid size={4}>
                      <Typography variant="body2" color="text.secondary">
                        Paid ({recordedPayment.mode})
                      </Typography>
                      <Typography variant="h6" sx={{ fontWeight: 600, color: 'success.main' }}>
                        ₹{recordedPayment.amount.toLocaleString()}
                      </Typography>
                    </Grid>
                    <Grid size={4}>
                      <Typography variant="body2" color="text.secondary">
                        Balance Due
                      </Typography>
                      <Typography
                        variant="h6"
                        sx={{
                          fontWeight: 600,
                          color:
                            total - recordedPayment.amount > 0
                              ? 'warning.main'
                              : 'success.main',
                        }}
                      >
                        ₹{(total - recordedPayment.amount).toLocaleString()}
                      </Typography>
                    </Grid>
                  </Grid>
                </Box>
              </Section>
            )}

            <Section title="Next Actions">
              {/* Pickup or Local Delivery: Show Start Production */}
              {(orderType === 'Pickup' || orderType === 'LocalDelivery') && (
                <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <Button
                    variant="contained"
                    color="primary"
                    startIcon={
                      startingProduction ? (
                        <CircularProgress size={16} color="inherit" />
                      ) : (
                        <PlayIcon />
                      )
                    }
                    onClick={handleStartProduction}
                    disabled={startingProduction}
                    sx={{ alignSelf: 'flex-start' }}
                  >
                    {startingProduction ? 'Starting...' : '▶ Start Production'}
                  </Button>

                  {/* Local Delivery: Also show Schedule Delivery */}
                  {orderType === 'LocalDelivery' && (
                    <Button
                      variant="outlined"
                      startIcon={schedulingDelivery ? <CircularProgress size={16} /> : <DeliveryIcon />}
                      onClick={openScheduleDeliveryDialog}
                      disabled={schedulingDelivery}
                      sx={{ alignSelf: 'flex-start' }}
                    >
                      {schedulingDelivery ? 'Scheduling...' : '🚚 Schedule Delivery'}
                    </Button>
                  )}
                </Box>
              )}

              {/* Outstation Delivery: Show forwarded text */}
              {orderType === 'OutstationDelivery' && (
                <Typography variant="body1" sx={{ color: 'text.secondary', fontStyle: 'italic' }}>
                  Forwarded to vendor
                </Typography>
              )}
            </Section>
          </>
        )}

        {order?.status === 'InProduction' && (
          <>
            <Divider sx={{ my: 3 }} />
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}>
              <PlayIcon color="primary" />
              <Typography variant="h6" sx={{ fontWeight: 600, color: 'primary.main' }}>
                Production Started
              </Typography>
            </Box>

            <Typography variant="body1" sx={{ color: 'text.secondary' }}>
              This order is currently in production.
            </Typography>

            {/* Local Delivery: Show Schedule Delivery */}
            {orderType === 'LocalDelivery' && (
              <Box sx={{ mt: 2 }}>
                <Button
                  variant="outlined"
                  startIcon={schedulingDelivery ? <CircularProgress size={16} /> : <DeliveryIcon />}
                  onClick={openScheduleDeliveryDialog}
                  disabled={schedulingDelivery}
                  sx={{ alignSelf: 'flex-start' }}
                >
                  {schedulingDelivery ? 'Scheduling...' : '🚚 Schedule Delivery'}
                </Button>
              </Box>
            )}
          </>
        )}

        {order && order.status !== 'Draft' && order.status !== 'Confirmed' && order.status !== 'InProduction' && (
          <>
            <Divider sx={{ my: 3 }} />
            <Typography variant="body1" sx={{ color: 'text.secondary' }}>
              Order Status: {order.status}
            </Typography>
          </>
        )}
      </Paper>

      {/* Vendor Assignment Modal for Outstation orders */}
      {savedOrderId && (
        <VendorAssignmentModal
          open={vendorModalOpen}
          onClose={() => setVendorModalOpen(false)}
          orderId={savedOrderId}
          onSuccess={handleVendorConfirmSuccess}
        />
      )}

      {/* Invoice Dialog */}
      {savedOrderId && (
        <InvoiceDialog
          open={invoiceDialogOpen}
          orderId={savedOrderId}
          onClose={() => setInvoiceDialogOpen(false)}
        />
      )}

      {/* Schedule Delivery Dialog */}
      <Dialog
        open={scheduleDeliveryDialogOpen}
        onClose={() => !schedulingDelivery && setScheduleDeliveryDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Schedule Delivery</DialogTitle>
        <DialogContent>
          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2, mt: 1 }}>
            <TextField
              label="Delivery Date"
              type="date"
              value={scheduleDeliveryDate}
              onChange={(e) => setScheduleDeliveryDate(e.target.value)}
              slotProps={{ inputLabel: { shrink: true } }}
              fullWidth
              required
              disabled={schedulingDelivery}
            />
            <FormControl fullWidth required disabled={schedulingDelivery}>
              <InputLabel>Time Slot</InputLabel>
              <Select
                value={scheduleDeliveryTimeSlot}
                label="Time Slot"
                onChange={(e) => setScheduleDeliveryTimeSlot(e.target.value)}
              >
                {TIME_SLOT_OPTIONS.map((slot) => (
                  <MenuItem key={slot} value={slot}>
                    {slot}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
            <TextField
              label="Delivery Address"
              value={scheduleDeliveryAddress}
              onChange={(e) => setScheduleDeliveryAddress(e.target.value)}
              multiline
              rows={3}
              fullWidth
              required
              disabled={schedulingDelivery}
              placeholder="Enter full delivery address"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setScheduleDeliveryDialogOpen(false)}
            disabled={schedulingDelivery}
          >
            Cancel
          </Button>
          <Button
            variant="contained"
            onClick={handleScheduleDeliverySubmit}
            disabled={schedulingDelivery}
            startIcon={schedulingDelivery ? <CircularProgress size={16} /> : <DeliveryIcon />}
          >
            {schedulingDelivery ? 'Scheduling...' : 'Schedule Delivery'}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default UnifiedPhoneOrderPage;
