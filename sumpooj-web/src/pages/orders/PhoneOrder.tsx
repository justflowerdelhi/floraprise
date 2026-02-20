/**
 * PhoneOrder.tsx — Simplified Phone Order with Pickup/Delivery Flow
 *
 * REDESIGNED for minimal clicks and low-tech friendly UX:
 * - Pickup vs Delivery selector
 * - Smart address autocomplete
 * - Auto delivery zone detection
 * - Streamlined 3-click checkout
 * 
 * Frontend only • React + TypeScript + Material-UI
 */
import React, { useState, useMemo, useEffect, useCallback } from 'react';
import {
  Box, Typography, TextField, Button, Grid, Chip, Card, CardContent,
  InputAdornment, Snackbar, Alert, MenuItem, Divider, ToggleButton, ToggleButtonGroup,
  useTheme, alpha, Autocomplete,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material/styles';
import {
  Search as SearchIcon,
  Phone as PhoneIcon,
  Person as PersonIcon,
  CalendarToday as CalendarIcon,
  LocationOn as LocationIcon,
  Message as MessageIcon,
  Celebration as OccasionIcon,
  Payment as PayIcon,
  StoreMallDirectory as PickupIcon,
  LocalShipping as DeliveryIcon,
  AccessTime as TimeIcon,
} from '@mui/icons-material';
import type { ProductCategory } from './OrderTypes';
import { MOCK_PRODUCTS, PRODUCT_CATEGORIES } from './OrderMockData';
import { OCCASIONS, TIME_SLOTS } from './OrderTypes';
import type { TimeSlot } from './OrderTypes';
import type { OrderPaymentEntry, Order } from './OrderTypes';
import type { FulfillmentType, DeliveryAddress } from './DeliveryZoneTypes';
import { useCart } from '../cart/CartContext';
import CartTable from '../cart/CartTable';
import CartSummaryPanel from '../cart/CartSummaryPanel';
import { fmtCurrency } from '../cart/CartUtils';
import PaymentModal from '../payments/PaymentModal';
import SmartAddressInput from './SmartAddressInput';
import { MOCK_CUSTOMERS, type Customer } from '../crm/CRMTypes';
import { useOrders } from './OrderContext';
import { processOrderInventory, inferFulfillmentMode } from '../inventory/InventoryMovementService';

const PhoneOrder: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  const { state, addProduct, removeItem, updateQty, setDiscount, clearCart, setOrderSource } = useCart();
  const { addOrder } = useOrders();

  // ─── Fulfillment Type ───────────────────────────────────────
  const [fulfillmentType, setFulfillmentType] = useState<FulfillmentType>('DELIVERY');
  
  // ─── Common Fields ──────────────────────────────────────────
  const [customerName, setCustomerName]   = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [occasion, setOccasion]           = useState('');
  
  // ─── Pickup Fields ──────────────────────────────────────────
  const [pickupDate, setPickupDate]         = useState('');
  const [pickupTimeSlot, setPickupTimeSlot] = useState<TimeSlot>('11:00 AM - 1:00 PM');
  
  // ─── Delivery Fields ────────────────────────────────────────
  const [recipientName, setRecipientName]   = useState('');
  const [recipientPhone, setRecipientPhone] = useState('');
  const [deliveryAddress, setDeliveryAddress] = useState<Partial<DeliveryAddress> | null>(null);
  const [deliveryDate, setDeliveryDate]     = useState('');
  const [deliveryTimeSlot, setDeliveryTimeSlot] = useState<TimeSlot>('11:00 AM - 1:00 PM');
  const [cardMessage, setCardMessage]       = useState('');
  
  // ─── Product Search ─────────────────────────────────────────
  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<ProductCategory | ''>('');
  const [snackMsg, setSnackMsg] = useState('');
  const [payModalOpen, setPayModalOpen] = useState(false);
  const [paymentOrderId, setPaymentOrderId] = useState('');

  useEffect(() => { setOrderSource('PHONE'); }, [setOrderSource]);

  // Filtered customer suggestions based on name or phone input
  const customerSuggestions = useMemo(() => {
    const q = (customerName || customerPhone || '').toLowerCase().trim();
    if (!q) return MOCK_CUSTOMERS;
    return MOCK_CUSTOMERS.filter(
      (c) => c.name.toLowerCase().includes(q) || c.phone.replace(/\s/g, '').includes(q.replace(/\s/g, '')),
    );
  }, [customerName, customerPhone]);

  const filteredProducts = useMemo(() => {
    let list = MOCK_PRODUCTS;
    if (categoryFilter) list = list.filter((p) => p.category === categoryFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) => p.name.toLowerCase().includes(q) || p.sku.toLowerCase().includes(q),
      );
    }
    return list;
  }, [search, categoryFilter]);

  const fieldSx: SxProps<Theme> = dk
    ? {
        '& .MuiOutlinedInput-root': {
          color: '#e0e0e0',
          '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' },
          '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.3)' },
          '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
        },
        '& .MuiInputLabel-root': { color: 'rgba(255,255,255,0.5)' },
      }
    : {};

  // ─── Validation ─────────────────────────────────────────────
  const isPickupValid = 
    customerName.trim() && 
    customerPhone.trim() && 
    pickupDate;
  
  const isDeliveryValid = 
    recipientName.trim() && 
    recipientPhone.trim() && 
    deliveryAddress?.fullAddress &&  // Only require address, zone is optional
    deliveryDate;
  
  const isFormValid = fulfillmentType === 'PICKUP' ? isPickupValid : isDeliveryValid;
  const deliveryFee = fulfillmentType === 'DELIVERY'
    ? (deliveryAddress?.deliveryZone?.deliveryFee ?? 0)
    : 0;
  const grandTotalWithDelivery = state.totals.grandTotal + deliveryFee;

  const resetForm = useCallback(() => {
    clearCart();
    setCustomerName('');
    setCustomerPhone('');
    setSelectedCustomer(null);
    setRecipientName('');
    setRecipientPhone('');
    setPickupDate('');
    setDeliveryDate('');
    setDeliveryAddress(null);
    setCardMessage('');
    setOccasion('');
  }, [clearCart]);

  const handleSubmit = () => {
    if (!isFormValid || state.items.length === 0) return;
    
    const now = new Date().toISOString();
    const orderId = `phone_${Date.now()}`;
    // Phone draft orders with a future date → SCHEDULED (reserve inventory)
    const mode = inferFulfillmentMode({
      orderSource: 'PHONE',
      paymentStatus: 'UNPAID',
      deliveryDate: fulfillmentType === 'DELIVERY' ? deliveryDate : undefined,
      pickupDate: fulfillmentType === 'PICKUP' ? pickupDate : undefined,
    });
    const invResult = processOrderInventory(orderId, state.items, mode, 'loc_default');
    const newOrder: Order = {
      id: orderId,
      orderNumber: `ORD-${new Date().getFullYear()}-${String(Date.now()).slice(-4)}`,
      orderSource: 'PHONE',
      customerName,
      customerPhone,
      fulfillmentType,
      ...(fulfillmentType === 'PICKUP' && { pickupDate, pickupTimeSlot }),
      ...(fulfillmentType === 'DELIVERY' && {
        recipientName,
        recipientPhone,
        structuredDeliveryAddress: (deliveryAddress as DeliveryAddress) ?? undefined,
        deliveryDate,
        deliveryTimeSlot,
        cardMessage,
      }),
      occasion,
      fulfillmentStatus: 'DRAFT',
      paymentStatus: 'UNPAID',
      orderStatus: 'DRAFT',
      isPriceEditable: false,
      totalAmount: grandTotalWithDelivery,
      totalPaid: 0,
      balanceDue: grandTotalWithDelivery,
      items: state.items,
      totals: { ...state.totals, grandTotal: grandTotalWithDelivery },
      ...invResult,
      createdAt: now,
      updatedAt: now,
    };
    addOrder(newOrder);
    
    setSnackMsg(`Phone order created — ${fmtCurrency(grandTotalWithDelivery)}`);
    resetForm();
  };

  const handleOpenPay = useCallback(() => {
    if (!isFormValid || state.items.length === 0) return;
    setPaymentOrderId(`phone_${Date.now()}`);
    setPayModalOpen(true);
  }, [isFormValid, state.items.length]);

  const handleFullyPaid = useCallback((payments: OrderPaymentEntry[]) => {
    const now = new Date().toISOString();
    const deliveryFee = fulfillmentType === 'DELIVERY' ? (deliveryAddress?.deliveryZone?.deliveryFee ?? 0) : 0;
    // Phone paid order: check if it has a future date → SCHEDULED, else IMMEDIATE
    const mode = inferFulfillmentMode({
      orderSource: 'PHONE',
      paymentStatus: 'PAID',
      deliveryDate: fulfillmentType === 'DELIVERY' ? deliveryDate : undefined,
      pickupDate: fulfillmentType === 'PICKUP' ? pickupDate : undefined,
    });
    const invResult = processOrderInventory(paymentOrderId, state.items, mode, 'loc_default');
    const newOrder: Order = {
      id: paymentOrderId,
      orderNumber: `ORD-${new Date().getFullYear()}-${String(Date.now()).slice(-4)}`,
      orderSource: 'PHONE',
      customerName,
      customerPhone,
      fulfillmentType,
      ...(fulfillmentType === 'PICKUP' && { pickupDate, pickupTimeSlot }),
      ...(fulfillmentType === 'DELIVERY' && {
        recipientName,
        recipientPhone,
        structuredDeliveryAddress: (deliveryAddress as DeliveryAddress) ?? undefined,
        deliveryDate,
        deliveryTimeSlot,
        cardMessage,
      }),
      occasion,
      fulfillmentStatus: 'CONFIRMED',
      paymentStatus: 'PAID',
      orderStatus: 'PAID',
      isPriceEditable: false,
      totalAmount: grandTotalWithDelivery,
      totalPaid: grandTotalWithDelivery,
      balanceDue: 0,
      payments,
      items: state.items,
      totals: { ...state.totals, grandTotal: grandTotalWithDelivery },
      ...invResult,
      createdAt: now,
      updatedAt: now,
    };
    addOrder(newOrder);
    setPayModalOpen(false);
    setSnackMsg(`Phone order paid — ${fmtCurrency(grandTotalWithDelivery)}`);
    resetForm();
  }, [
    addOrder,
    paymentOrderId,
    fulfillmentType,
    customerName,
    customerPhone,
    pickupDate,
    pickupTimeSlot,
    recipientName,
    recipientPhone,
    deliveryAddress,
    deliveryDate,
    deliveryTimeSlot,
    cardMessage,
    occasion,
    state.items,
    state.totals,
    resetForm,
    grandTotalWithDelivery,
  ]);

  return (
    <Box sx={{ display: 'flex', height: '100vh', bgcolor: bgColor, overflow: 'hidden' }}>
      {/* ─── LEFT: Fulfillment Info + Products ────────────── */}
      <Box sx={{ width: 420, minWidth: 380, borderRight: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Form Section - Scrollable */}
        <Box sx={{ px: 2, pt: 2, pb: 1, overflow: 'auto', flexShrink: 0, maxHeight: '50vh' }}>
          <Typography variant="h6" sx={{ fontWeight: 800, mb: 2 }}>
            📞 Phone Order
          </Typography>

          {/* ─── FULFILLMENT TYPE SELECTOR ───────────── */}
          <Box sx={{ mb: 3 }}>
            <Typography variant="subtitle2" sx={{ mb: 1, fontWeight: 600 }}>
              Order Type
            </Typography>
            <ToggleButtonGroup
              value={fulfillmentType}
              exclusive
              onChange={(_, val) => val && setFulfillmentType(val)}
              fullWidth
              size="small"
              sx={{
                '& .MuiToggleButton-root': {
                  py: 1.5,
                  fontSize: '0.9rem',
                  fontWeight: 600,
                  border: dk ? '1px solid rgba(255,255,255,0.15)' : undefined,
                  '&.Mui-selected': {
                    bgcolor: dk ? alpha(theme.palette.primary.main, 0.2) : undefined,
                    color: theme.palette.primary.main,
                  },
                },
              }}
            >
              <ToggleButton value="PICKUP">
                <PickupIcon sx={{ mr: 1, fontSize: 20 }} />
                Pickup
              </ToggleButton>
              <ToggleButton value="DELIVERY">
                <DeliveryIcon sx={{ mr: 1, fontSize: 20 }} />
                Delivery
              </ToggleButton>
            </ToggleButtonGroup>
          </Box>

          {/* ─── PICKUP FLOW ──────────────────────────── */}
          {fulfillmentType === 'PICKUP' && (
            <Grid container spacing={2}>
              <Grid size={{ xs: 12 }}>
                <Autocomplete
                  freeSolo
                  size="small"
                  options={customerSuggestions}
                  getOptionLabel={(opt) => typeof opt === 'string' ? opt : opt.name}
                  value={selectedCustomer}
                  inputValue={customerName}
                  onInputChange={(_e, val) => setCustomerName(val)}
                  onChange={(_e, val) => {
                    if (val && typeof val !== 'string') {
                      setSelectedCustomer(val);
                      setCustomerName(val.name);
                      setCustomerPhone(val.phone);
                    } else {
                      setSelectedCustomer(null);
                      if (typeof val === 'string') setCustomerName(val);
                    }
                  }}
                  renderOption={(props, option) => (
                    <li {...props} key={option.id}>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>{option.name}</Typography>
                        <Typography variant="caption" color="text.secondary">{option.phone}{option.email ? ` \u00b7 ${option.email}` : ''}</Typography>
                      </Box>
                    </li>
                  )}
                  renderInput={(params) => (
                    <TextField
                      {...params}
                      required
                      label="Customer Name"
                      slotProps={{
                        input: {
                          ...params.InputProps,
                          startAdornment: (
                            <>
                              <InputAdornment position="start">
                                <PersonIcon sx={{ fontSize: 18 }} />
                              </InputAdornment>
                              {params.InputProps.startAdornment}
                            </>
                          ),
                        },
                      }}
                      sx={fieldSx}
                    />
                  )}
                />
              </Grid>
              <Grid size={{ xs: 12 }}>
                <Autocomplete
                  freeSolo
                  size="small"
                  options={customerSuggestions}
                  getOptionLabel={(opt) => typeof opt === 'string' ? opt : opt.phone}
                  value={selectedCustomer}
                  inputValue={customerPhone}
                  onInputChange={(_e, val) => setCustomerPhone(val)}
                  onChange={(_e, val) => {
                    if (val && typeof val !== 'string') {
                      setSelectedCustomer(val);
                      setCustomerName(val.name);
                      setCustomerPhone(val.phone);
                    } else {
                      setSelectedCustomer(null);
                      if (typeof val === 'string') setCustomerPhone(val);
                    }
                  }}
                  renderOption={(props, option) => (
                    <li {...props} key={option.id}>
                      <Box>
                        <Typography variant="body2" sx={{ fontWeight: 600 }}>{option.phone}</Typography>
                        <Typography variant="caption" color="text.secondary">{option.name}</Typography>
                      </Box>
                    </li>
                  )}
                  renderInput={(params) => (
                    <TextField
                      {...params}
                      required
                      label="Customer Phone"
                      slotProps={{
                        input: {
                          ...params.InputProps,
                          startAdornment: (
                            <>
                              <InputAdornment position="start">
                                <PhoneIcon sx={{ fontSize: 18 }} />
                              </InputAdornment>
                              {params.InputProps.startAdornment}
                            </>
                          ),
                        },
                      }}
                      sx={fieldSx}
                    />
                  )}
                />
              </Grid>
              <Grid size={{ xs: 7 }}>
                <TextField
                  required
                  size="small"
                  fullWidth
                  label="Pickup Date"
                  type="date"
                  value={pickupDate}
                  onChange={(e) => setPickupDate(e.target.value)}
                  slotProps={{
                    inputLabel: { shrink: true },
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <CalendarIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                />
              </Grid>
              <Grid size={{ xs: 5 }}>
                <TextField
                  select
                  size="small"
                  fullWidth
                  label="Time"
                  value={pickupTimeSlot}
                  onChange={(e) => setPickupTimeSlot(e.target.value as TimeSlot)}
                  slotProps={{
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <TimeIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                >
                  {TIME_SLOTS.map((slot) => (
                    <MenuItem key={slot} value={slot} sx={{ fontSize: '0.8rem' }}>
                      {slot}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>
              <Grid size={{ xs: 12 }}>
                <TextField
                  select
                  size="small"
                  fullWidth
                  label="Occasion (Optional)"
                  value={occasion}
                  onChange={(e) => setOccasion(e.target.value)}
                  slotProps={{
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <OccasionIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                >
                  <MenuItem value="">None</MenuItem>
                  {OCCASIONS.map((o) => (
                    <MenuItem key={o} value={o}>
                      {o}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>
            </Grid>
          )}

          {/* ─── DELIVERY FLOW ────────────────────────── */}
          {fulfillmentType === 'DELIVERY' && (
            <Grid container spacing={2}>
              <Grid size={{ xs: 12 }}>
                <TextField
                  required
                  size="small"
                  fullWidth
                  label="Recipient Name"
                  value={recipientName}
                  onChange={(e) => setRecipientName(e.target.value)}
                  slotProps={{
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <PersonIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                />
              </Grid>
              <Grid size={{ xs: 12 }}>
                <TextField
                  required
                  size="small"
                  fullWidth
                  label="Recipient Phone"
                  value={recipientPhone}
                  onChange={(e) => setRecipientPhone(e.target.value)}
                  slotProps={{
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <PhoneIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                />
              </Grid>
              <Grid size={{ xs: 12 }}>
                <SmartAddressInput
                  value={deliveryAddress}
                  onChange={setDeliveryAddress}
                  required
                />
              </Grid>
              <Grid size={{ xs: 7 }}>
                <TextField
                  required
                  size="small"
                  fullWidth
                  label="Delivery Date"
                  type="date"
                  value={deliveryDate}
                  onChange={(e) => setDeliveryDate(e.target.value)}
                  slotProps={{
                    inputLabel: { shrink: true },
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <CalendarIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                />
              </Grid>
              <Grid size={{ xs: 5 }}>
                <TextField
                  select
                  size="small"
                  fullWidth
                  label="Time"
                  value={deliveryTimeSlot}
                  onChange={(e) => setDeliveryTimeSlot(e.target.value as TimeSlot)}
                  slotProps={{
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <TimeIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                >
                  {TIME_SLOTS.map((slot) => (
                    <MenuItem key={slot} value={slot} sx={{ fontSize: '0.8rem' }}>
                      {slot}
                    </MenuItem>
                  ))}
                </TextField>
              </Grid>
              <Grid size={{ xs: 12 }}>
                <TextField
                  size="small"
                  fullWidth
                  label="Card Message (Optional)"
                  value={cardMessage}
                  onChange={(e) => setCardMessage(e.target.value)}
                  multiline
                  rows={2}
                  slotProps={{
                    input: {
                      startAdornment: (
                        <InputAdornment position="start">
                          <MessageIcon sx={{ fontSize: 18 }} />
                        </InputAdornment>
                      ),
                    },
                  }}
                  sx={fieldSx}
                />
              </Grid>
            </Grid>
          )}
        </Box>

        <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.06)' : undefined }} />

        {/* Product search */}
        <Box sx={{ px: 2, pt: 1.5, pb: 1, flexShrink: 0 }}>
          <TextField
            size="small"
            fullWidth
            placeholder="Search products..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon sx={{ fontSize: 18 }} />
                  </InputAdornment>
                ),
              },
            }}
            sx={{ mb: 1, ...fieldSx }}
          />
          <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 1 }}>
            <Chip
              label="All"
              size="small"
              onClick={() => setCategoryFilter('')}
              variant={categoryFilter === '' ? 'filled' : 'outlined'}
              color={categoryFilter === '' ? 'primary' : 'default'}
              sx={{ fontSize: '0.65rem' }}
            />
            {PRODUCT_CATEGORIES.map((c) => (
              <Chip
                key={c}
                label={c}
                size="small"
                onClick={() => setCategoryFilter(c === categoryFilter ? '' : c)}
                variant={categoryFilter === c ? 'filled' : 'outlined'}
                color={categoryFilter === c ? 'primary' : 'default'}
                sx={{ fontSize: '0.65rem' }}
              />
            ))}
          </Box>
        </Box>

        {/* Product list */}
        <Box sx={{ flex: 1, overflow: 'auto', px: 2, pb: 2, minHeight: 0 }}>
          {filteredProducts.map((p) => (
            <Card
              key={p.id}
              elevation={0}
              onClick={() => {
                addProduct(p);
                setSnackMsg(`Added ${p.name}`);
              }}
              sx={{
                mb: 0.5,
                cursor: 'pointer',
                py: 0.5,
                px: 1.5,
                bgcolor: dk ? '#1a1a2e' : '#fff',
                border: dk ? '1px solid rgba(255,255,255,0.04)' : '1px solid #f0f0f0',
                '&:hover': {
                  bgcolor: dk ? alpha('#fff', 0.05) : alpha('#000', 0.02),
                  borderColor: theme.palette.primary.main,
                },
              }}
            >
              <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Box>
                  <Typography variant="body2" sx={{ fontWeight: 600, fontSize: '0.82rem' }}>
                    {p.name}
                  </Typography>
                  <Typography
                    variant="caption"
                    sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}
                  >
                    {p.sku}
                  </Typography>
                </Box>
                <Typography
                  variant="body2"
                  sx={{ fontWeight: 700, color: dk ? theme.palette.warning.main : theme.palette.primary.main }}
                >
                  {fmtCurrency(p.sellingPrice)}
                </Typography>
              </Box>
            </Card>
          ))}
        </Box>
      </Box>

      {/* ─── CENTER: Cart ───────────────────────────────── */}
      <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <Box sx={{ p: 2, pb: 1 }}>
          <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
            Order Items ({state.totals.itemCount})
          </Typography>
        </Box>
        <Box sx={{ flex: 1, overflow: 'auto', px: 2 }}>
          <CartTable
            items={state.items}
            products={MOCK_PRODUCTS}
            isPriceEditable={state.isPriceEditable}
            onUpdateQty={updateQty}
            onRemove={removeItem}
            onSetDiscount={setDiscount}
            deliveryFee={deliveryFee}
          />
        </Box>
      </Box>

      {/* ─── RIGHT: Summary + Submit ────────────────────── */}
      <Box
        sx={{
          width: 280,
          minWidth: 260,
          borderLeft: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          display: 'flex',
          flexDirection: 'column',
          p: 2,
          gap: 2,
        }}
      >
        <CartSummaryPanel totals={state.totals} orderSource="PHONE" deliveryFee={deliveryFee} />

        {/* Validation warnings */}
        {state.items.length > 0 && !isFormValid && (
          <Card
            elevation={0}
            sx={{
              bgcolor: dk ? alpha(theme.palette.warning.dark, 0.1) : alpha(theme.palette.warning.light, 0.2),
              border: `1px solid ${alpha(theme.palette.warning.main, 0.3)}`,
              borderRadius: 1,
            }}
          >
            <CardContent sx={{ py: 1, '&:last-child': { pb: 1 } }}>
              <Typography variant="caption" sx={{ fontWeight: 600, color: theme.palette.warning.main }}>
                Required fields:
              </Typography>
              {fulfillmentType === 'PICKUP' ? (
                <>
                  {!customerName.trim() && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      • Customer name
                    </Typography>
                  )}
                  {!customerPhone.trim() && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      • Customer phone
                    </Typography>
                  )}
                  {!pickupDate && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      • Pickup date
                    </Typography>
                  )}
                </>
              ) : (
                <>
                  {!recipientName.trim() && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      • Recipient name
                    </Typography>
                  )}
                  {!recipientPhone.trim() && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      • Recipient phone
                    </Typography>
                  )}
                  {!deliveryAddress?.fullAddress && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      • Delivery address
                    </Typography>
                  )}
                  {!deliveryDate && (
                    <Typography variant="caption" display="block" color="text.secondary">
                      • Delivery date
                    </Typography>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        )}

        <Button
          variant="contained"
          size="large"
          fullWidth
          startIcon={<PayIcon />}
          disabled={!isFormValid || state.items.length === 0}
          onClick={handleOpenPay}
          color="warning"
          sx={{
            py: 1.5,
            fontWeight: 800,
            fontSize: '0.95rem',
          }}
        >
          Proceed to Payment
        </Button>
      </Box>

      <PaymentModal
        open={payModalOpen}
        onClose={() => setPayModalOpen(false)}
        orderId={paymentOrderId}
        orderSource={'PHONE'}
        grandTotal={grandTotalWithDelivery}
        onFullyPaid={handleFullyPaid}
      />

      <Snackbar
        open={!!snackMsg}
        autoHideDuration={2500}
        onClose={() => setSnackMsg('')}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="success" variant="filled" onClose={() => setSnackMsg('')}>
          {snackMsg}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default PhoneOrder;
