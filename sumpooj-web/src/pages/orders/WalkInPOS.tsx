/**
 * WalkInPOS.tsx — Point of Sale for walk-in customers
 *
 * Layout: Left (product search + categories) | Center (cart) | Right (summary + pay)
 * Features: barcode input, category filter, FIFO auto-batch, hold/resume, terminal payment
 */
import React, { useState, useMemo, useRef, useEffect, useCallback } from 'react';
import {
  Box, Typography, TextField, InputAdornment, Button, Chip,
  Card, CardContent, Grid, IconButton, Snackbar, Alert,
  Dialog, DialogTitle, DialogContent, DialogActions,
  useTheme, Divider, FormControl, InputLabel, Select, MenuItem,
  Autocomplete, CircularProgress,
} from '@mui/material';
import {
  Search as SearchIcon,
  QrCodeScanner as BarcodeIcon,
  PauseCircle as HoldIcon,
  PlayCircle as ResumeIcon,
  Payment as PayIcon,
  ShoppingCart as CartIcon,
  Person as PersonIcon,
  Phone as PhoneIcon,
} from '@mui/icons-material';
import { CardGiftcard as GiftCardIcon } from '@mui/icons-material';
import type { Product, ProductCategory, OrderType, OrderPaymentEntry, Order } from './OrderTypes';
import { PRODUCT_CATEGORIES } from './OrderMockData';
import { processOrderInventory, inferFulfillmentMode } from '../inventory/InventoryMovementService';
import { useCart } from '../cart/CartContext';
import CartTable from '../cart/CartTable';
import CartSummaryPanel from '../cart/CartSummaryPanel';
import { fmtCurrency } from '../cart/CartUtils';
import PaymentModal from '../payments/PaymentModal';
import { useTenant } from '../../core/tenant/TenantContext';
import { type Customer } from '../crm/CRMTypes';
import { useOrders } from './OrderContext';
import { searchProducts } from '../../api/product.api';
import { searchCustomers } from '../../api/customer.api';
import { getAllSuppliers } from '../../api/supplier.api';
import { GiftCardBuilderModal } from '../gift-cards';
import type { SavedGiftCard } from '../gift-cards';

const WalkInPOS: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const bgColor = dk ? '#0f0f0f' : '#f8f9fa';

  const { hasFeature } = useTenant();
  const wireEnabled = hasFeature('WIRE_MANAGEMENT');
  const { addOrder } = useOrders();

  const { state, addProduct, removeItem, updateQty, setDiscount, clearCart, holdOrder, resumeOrder, removeHeld, setOrderSource } = useCart();

  // ─── API-loaded data ──────────────────────────────────────
  const [products, setProducts] = useState<Product[]>([]);
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [vendorFlorists, setVendorFlorists] = useState<Array<{ id: string; name: string; city?: string; state?: string; isActive?: boolean; defaultCommissionRate?: number }>>([]);
  const [dataLoading, setDataLoading] = useState(true);
  const [dataError, setDataError] = useState('');

  useEffect(() => {
    const loadData = async () => {
      setDataLoading(true);
      setDataError('');
      try {
        const [prodRes, custRes, supplierRes] = await Promise.all([
          searchProducts({ IsActive: true, PageSize: 500 }),
          searchCustomers({ PageSize: 500 }),
          getAllSuppliers(),
        ]);
        const prodItems = Array.isArray(prodRes) ? prodRes : prodRes.items ?? [];
        setProducts(prodItems);
        const custItems = Array.isArray(custRes) ? custRes : custRes.items ?? [];
        setCustomers(custItems);
        const suppliers = Array.isArray(supplierRes) ? supplierRes : supplierRes.items ?? [];
        setVendorFlorists(suppliers);
      } catch (err: any) {
        console.error('❌ POS data load failed:', err);
        setDataError('Failed to load POS data. Please refresh or re-login.');
      } finally {
        setDataLoading(false);
      }
    };
    loadData();
  }, []);

  const [search, setSearch] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<ProductCategory | ''>('');
  const [snackMsg, setSnackMsg] = useState('');
  const [holdDialogOpen, setHoldDialogOpen] = useState(false);
  const [holdLabel, setHoldLabel] = useState('');
  const [payModalOpen, setPayModalOpen] = useState(false);
  const [paymentOrderId, setPaymentOrderId] = useState('');
  const [giftCardOpen, setGiftCardOpen] = useState(false);
  const [attachedGiftCard, setAttachedGiftCard] = useState<SavedGiftCard | null>(null);
  const searchRef = useRef<HTMLInputElement>(null);

  // Customer info
  const [customerName, setCustomerName] = useState('');
  const [customerPhone, setCustomerPhone] = useState('');
  const [selectedCustomer, setSelectedCustomer] = useState<Customer | null>(null);
  const [customerError, setCustomerError] = useState(false);
  const customerCardRef = useRef<HTMLDivElement>(null);

  const isCustomerValid = Boolean(customerName.trim() && customerPhone.trim());

  // Filtered customer suggestions based on name or phone input
  const customerSuggestions = useMemo(() => {
    const q = (customerName || customerPhone || '').toLowerCase().trim();
    if (!q) return customers;
    return customers.filter(
      (c) => c.name.toLowerCase().includes(q) || c.phone.replace(/\s/g, '').includes(q.replace(/\s/g, '')),
    );
  }, [customerName, customerPhone]);

  const [orderType, setOrderType] = useState<OrderType>('LOCAL');
  const [vendorId, setVendorId] = useState('');
  const [vendorAmount, setVendorAmount] = useState(0);
  const [wireFee, setWireFee] = useState(0);
  const [sourceNetwork, setSourceNetwork] = useState('');
  const [commissionPercent, setCommissionPercent] = useState(10);

  // Set order source on mount
  useEffect(() => { setOrderSource('WALK_IN'); }, [setOrderSource]);

  useEffect(() => {
    if (!wireEnabled && orderType !== 'LOCAL') {
      setOrderType('LOCAL');
    }
  }, [wireEnabled, orderType]);

  // Product search (name, SKU, barcode for non-perishables)
  const filteredProducts = useMemo(() => {
    let list = products;
    if (categoryFilter) list = list.filter((p) => p.category === categoryFilter);
    if (search.trim()) {
      const q = search.toLowerCase();
      list = list.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.sku.toLowerCase().includes(q) ||
          (!!p.barcode && !p.isPerishable && p.barcode.includes(q)),
      );
    }
    return list;
  }, [search, categoryFilter]);

  const handleBarcodeSubmit = () => {
    const product = products.find((p) => !p.isPerishable && p.barcode === search.trim());
    if (product) {
      addProduct(product);
      setSearch('');
      setSnackMsg(`Added ${product.name}`);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') handleBarcodeSubmit();
  };

  const handleHold = () => {
    if (state.items.length === 0) return;
    holdOrder(holdLabel || `POS Hold`, customerName || undefined);
    setHoldDialogOpen(false);
    setHoldLabel('');
    setSnackMsg('Order held');
  };

  const handleOpenPay = useCallback(() => {
    if (orderType === 'INCOMING_NETWORK') return;
    // Generate a temporary order ID for the payment session
    setPaymentOrderId(`pos_${Date.now()}`);
    setPayModalOpen(true);
  }, [orderType]);

  const handleFullyPaid = useCallback((payments: OrderPaymentEntry[]) => {
    const now = new Date().toISOString();
    const orderId = paymentOrderId;
    // Determine inventory mode: walk-in paid → IMMEDIATE (deduct now)
    const mode = inferFulfillmentMode({ orderSource: 'WALK_IN', paymentStatus: 'PAID' });
    const invResult = processOrderInventory(orderId, state.items, mode, 'loc_default');
    const newOrder: Order = {
      id: orderId,
      orderNumber: `ORD-${new Date().getFullYear()}-${String(Date.now()).slice(-4)}`,
      orderSource: 'WALK_IN',
      orderType,
      customerName: customerName || 'Walk-in Customer',
      customerPhone: customerPhone || undefined,
      fulfillmentStatus: 'CONFIRMED',
      paymentStatus: 'PAID',
      orderStatus: 'PAID',
      isPriceEditable: false,
      totalAmount: state.totals.grandTotal,
      totalPaid: state.totals.grandTotal,
      balanceDue: 0,
      payments,
      items: state.items,
      totals: state.totals,
      ...invResult,
      createdAt: now,
      updatedAt: now,
    };
    addOrder(newOrder);
    setPayModalOpen(false);
    setSnackMsg(`Order completed — ${fmtCurrency(state.totals.grandTotal)}`);
    setCustomerName('');
    setCustomerPhone('');
    setSelectedCustomer(null);
    setCustomerError(false);
    clearCart();
  }, [clearCart, addOrder, paymentOrderId, orderType, customerName, customerPhone, state.items, state.totals]);

  const handlePartialSave = useCallback((payments: OrderPaymentEntry[], totalPaid: number, balanceDue: number) => {
    if (!isCustomerValid) {
      setCustomerError(true);
      setPayModalOpen(false);
      customerCardRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      return;
    }
    const now = new Date().toISOString();
    const orderId = paymentOrderId;
    // Walk-in partial → IMMEDIATE (customer takes items now)
    const mode = inferFulfillmentMode({ orderSource: 'WALK_IN', paymentStatus: 'PARTIAL' });
    const invResult = processOrderInventory(orderId, state.items, mode, 'loc_default');
    const newOrder: Order = {
      id: orderId,
      orderNumber: `ORD-${new Date().getFullYear()}-${String(Date.now()).slice(-4)}`,
      orderSource: 'WALK_IN',
      orderType,
      customerName,
      customerPhone,
      fulfillmentStatus: 'CONFIRMED',
      paymentStatus: 'PARTIAL',
      orderStatus: 'PARTIALLY_PAID',
      isPriceEditable: false,
      totalAmount: state.totals.grandTotal,
      totalPaid,
      balanceDue,
      payments,
      items: state.items,
      totals: state.totals,
      ...invResult,
      createdAt: now,
      updatedAt: now,
    };
    addOrder(newOrder);
    setPayModalOpen(false);
    setSnackMsg(`Order saved — ${fmtCurrency(totalPaid)} paid, ${fmtCurrency(balanceDue)} due`);
    setCustomerName('');
    setCustomerPhone('');
    setSelectedCustomer(null);
    setCustomerError(false);
    clearCart();
  }, [clearCart, addOrder, paymentOrderId, orderType, customerName, customerPhone, state.items, state.totals]);

  const selectedVendor = useMemo(
    () => vendorFlorists.find((vendor) => vendor.id === vendorId) ?? null,
    [vendorId, vendorFlorists],
  );

  const customerPaid = state.totals.grandTotal;
  const outgoingProfit = customerPaid - vendorAmount - wireFee;
  const netReceived = Math.round((customerPaid * (1 - commissionPercent / 100)) * 100) / 100;
  const incomingProfit = netReceived - state.totals.totalCost;
  const localProfit = customerPaid - state.totals.totalCost;
  const showPayment = orderType !== 'INCOMING_NETWORK';

  const ProductCard = ({ p }: { p: Product }) => (
    <Card
      elevation={dk ? 0 : 1}
      onClick={() => { addProduct(p); setSnackMsg(`Added ${p.name}`); }}
      sx={{
        cursor: 'pointer',
        bgcolor: dk ? '#1a1a2e' : '#fff',
        border: dk ? '1px solid rgba(255,255,255,0.06)' : '1px solid #eee',
        transition: 'all 0.15s',
        '&:hover': {
          transform: 'translateY(-2px)',
          boxShadow: dk ? '0 4px 16px rgba(0,0,0,0.4)' : '0 4px 16px rgba(0,0,0,0.08)',
          borderColor: theme.palette.primary.main,
        },
      }}
    >
      <CardContent sx={{ py: 1.5, '&:last-child': { pb: 1.5 } }}>
        <Typography variant="body2" sx={{ fontWeight: 700, fontSize: '0.82rem', mb: 0.3 }} noWrap>
          {p.name}
        </Typography>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="caption" sx={{ color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled' }}>
            {p.sku}
          </Typography>
          <Typography variant="body2" sx={{ fontWeight: 700, color: dk ? '#fdd835' : theme.palette.primary.main }}>
            {fmtCurrency(p.sellingPrice)}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', mt: 0.5 }}>
          <Chip label={p.category} size="small" sx={{ fontSize: '0.65rem', height: 20 }} />
          <Typography variant="caption" sx={{ color: p.availableStock < 10 ? theme.palette.error.main : 'text.secondary' }}>
            Stock: {p.availableStock}
          </Typography>
        </Box>
      </CardContent>
    </Card>
  );

  return (
    <Box sx={{ display: 'flex', height: '100vh', bgcolor: bgColor, overflow: 'hidden' }}>
      {/* Loading / Error overlay */}
      {dataLoading && (
        <Box sx={{ position: 'absolute', inset: 0, zIndex: 10, display: 'flex', alignItems: 'center', justifyContent: 'center', bgcolor: bgColor }}>
          <Box sx={{ textAlign: 'center' }}>
            <CircularProgress size={28} sx={{ mb: 1 }} />
            <Typography variant="body2" color="text.secondary">Loading POS data…</Typography>
          </Box>
        </Box>
      )}
      {dataError && (
        <Alert severity="error" sx={{ position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)', zIndex: 10 }}>
          {dataError}
        </Alert>
      )}
      {/* ─── LEFT: Products ─────────────────────────────── */}
      <Box sx={{ width: 340, minWidth: 300, borderRight: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Header */}
        <Box sx={{ p: 2, pb: 1 }}>
          <Typography variant="h6" sx={{ fontWeight: 800, mb: 1.5 }}>
            🌸 Walk-In POS
          </Typography>

          {/* Search / Barcode */}
          <TextField
            inputRef={searchRef}
            size="small"
            fullWidth
            placeholder="Search or scan barcode..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={handleKeyDown}
            slotProps={{
              input: {
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchIcon sx={{ fontSize: 20, color: dk ? 'rgba(255,255,255,0.4)' : undefined }} />
                  </InputAdornment>
                ),
                endAdornment: (
                  <InputAdornment position="end">
                    <IconButton size="small" onClick={handleBarcodeSubmit} title="Scan barcode">
                      <BarcodeIcon sx={{ fontSize: 20 }} />
                    </IconButton>
                  </InputAdornment>
                ),
              },
            }}
            sx={{
              mb: 1.5,
              '& .MuiOutlinedInput-root': dk
                ? { color: '#e0e0e0', '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' } }
                : {},
            }}
          />

          {/* Category chips */}
          <Box sx={{ display: 'flex', gap: 0.5, flexWrap: 'wrap', mb: 1 }}>
            <Chip
              label="All"
              size="small"
              onClick={() => setCategoryFilter('')}
              variant={categoryFilter === '' ? 'filled' : 'outlined'}
              color={categoryFilter === '' ? 'primary' : 'default'}
              sx={{ fontSize: '0.7rem' }}
            />
            {PRODUCT_CATEGORIES.map((cat) => (
              <Chip
                key={cat}
                label={cat}
                size="small"
                onClick={() => setCategoryFilter(cat === categoryFilter ? '' : cat)}
                variant={categoryFilter === cat ? 'filled' : 'outlined'}
                color={categoryFilter === cat ? 'primary' : 'default'}
                sx={{ fontSize: '0.7rem' }}
              />
            ))}
          </Box>
        </Box>

        {/* Product grid */}
        <Box sx={{ flex: 1, overflow: 'auto', px: 2, pb: 2 }}>
          <Grid container spacing={1}>
            {filteredProducts.map((p) => (
              <Grid key={p.id} size={{ xs: 12 }}>
                <ProductCard p={p} />
              </Grid>
            ))}
            {filteredProducts.length === 0 && (
              <Grid size={{ xs: 12 }}>
                <Typography variant="body2" color="text.secondary" sx={{ py: 4, textAlign: 'center' }}>
                  No products match
                </Typography>
              </Grid>
            )}
          </Grid>
        </Box>
      </Box>

      {/* ─── CENTER: Cart ───────────────────────────────── */}
      <Box sx={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        {/* Cart header + held orders */}
        <Box sx={{ p: 2, pb: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <CartIcon sx={{ color: dk ? '#fdd835' : theme.palette.primary.main }} />
            <Typography variant="subtitle1" sx={{ fontWeight: 700 }}>
              Cart ({state.totals.itemCount} items)
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 1 }}>
            {state.heldOrders.length > 0 && (
              <Chip
                icon={<ResumeIcon />}
                label={`${state.heldOrders.length} Held`}
                color="info"
                size="small"
                variant="outlined"
                sx={{ fontWeight: 600 }}
              />
            )}
            <Button
              size="small"
              variant="outlined"
              startIcon={<HoldIcon />}
              disabled={state.items.length === 0}
              onClick={() => setHoldDialogOpen(true)}
              sx={dk ? { borderColor: 'rgba(255,255,255,0.2)', color: '#e0e0e0' } : {}}
            >
              Hold
            </Button>
          </Box>
        </Box>

        {/* Held orders bar */}
        {state.heldOrders.length > 0 && (
          <Box sx={{ px: 2, pb: 1, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
            {state.heldOrders.map((h) => (
              <Chip
                key={h.id}
                label={`${h.label} · ${fmtCurrency(h.totals.grandTotal)}`}
                color="info"
                size="small"
                onClick={() => { resumeOrder(h.id); setSnackMsg('Order resumed'); }}
                onDelete={() => removeHeld(h.id)}
                sx={{ fontWeight: 600, cursor: 'pointer' }}
              />
            ))}
          </Box>
        )}

        {/* Cart table */}
        <Box sx={{ flex: 1, overflow: 'auto', px: 2 }}>
          <CartTable
            items={state.items}
            products={products}
            isPriceEditable={state.isPriceEditable}
            onUpdateQty={updateQty}
            onRemove={removeItem}
            onSetDiscount={setDiscount}
          />
        </Box>
      </Box>

      {/* ─── RIGHT: Summary + Pay ───────────────────────── */}
      <Box sx={{
        width: 280, minWidth: 260,
        borderLeft: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        display: 'flex', flexDirection: 'column', p: 2, gap: 2,
      }}>
        {/* Customer Info */}
        <Card
          ref={customerCardRef}
          elevation={dk ? 0 : 1}
          sx={{
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: customerError
              ? `2px solid ${dk ? '#f44336' : '#d32f2f'}`
              : dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            borderRadius: 2,
          }}
        >
          <CardContent sx={{ pb: 2 }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
              Customer
            </Typography>
            <Autocomplete
              freeSolo
              size="small"
              options={customerSuggestions}
              getOptionLabel={(opt) => typeof opt === 'string' ? opt : opt.name}
              value={selectedCustomer}
              inputValue={customerName}
              onInputChange={(_e, val) => { setCustomerName(val); if (val.trim()) setCustomerError(false); }}
              onChange={(_e, val) => {
                if (val && typeof val !== 'string') {
                  setSelectedCustomer(val);
                  setCustomerName(val.name);
                  setCustomerPhone(val.phone);
                  setCustomerError(false);
                } else {
                  setSelectedCustomer(null);
                  if (typeof val === 'string') setCustomerName(val);
                }
              }}
              renderOption={(props, option) => (
                <li {...props} key={option.id}>
                  <Box>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>{option.name}</Typography>
                    <Typography variant="caption" color="text.secondary">{option.phone}{option.email ? ` · ${option.email}` : ''}</Typography>
                  </Box>
                </li>
              )}
              renderInput={(params) => (
                <TextField
                  {...params}
                  label="Name"
                  placeholder="Walk-in customer"
                  error={customerError && !customerName.trim()}
                  slotProps={{
                    input: {
                      ...params.InputProps,
                      startAdornment: (
                        <>
                          <InputAdornment position="start">
                            <PersonIcon sx={{ fontSize: 18, color: dk ? 'rgba(255,255,255,0.4)' : undefined }} />
                          </InputAdornment>
                          {params.InputProps.startAdornment}
                        </>
                      ),
                    },
                  }}
                />
              )}
              sx={{ mb: 1 }}
            />
            <Autocomplete
              freeSolo
              size="small"
              options={customerSuggestions}
              getOptionLabel={(opt) => typeof opt === 'string' ? opt : opt.phone}
              value={selectedCustomer}
              inputValue={customerPhone}
              onInputChange={(_e, val) => { setCustomerPhone(val); if (val.trim()) setCustomerError(false); }}
              onChange={(_e, val) => {
                if (val && typeof val !== 'string') {
                  setSelectedCustomer(val);
                  setCustomerName(val.name);
                  setCustomerPhone(val.phone);
                  setCustomerError(false);
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
                  label="Phone"
                  placeholder="Optional"
                  error={customerError && !customerPhone.trim()}
                  slotProps={{
                    input: {
                      ...params.InputProps,
                      startAdornment: (
                        <>
                          <InputAdornment position="start">
                            <PhoneIcon sx={{ fontSize: 18, color: dk ? 'rgba(255,255,255,0.4)' : undefined }} />
                          </InputAdornment>
                          {params.InputProps.startAdornment}
                        </>
                      ),
                    },
                  }}
                />
              )}
            />
          </CardContent>
        </Card>

        {customerError && (
          <Typography variant="caption" sx={{ color: '#d32f2f', fontWeight: 600, mt: -1.5, px: 1 }}>
            Customer Name and Phone are required for partial payment orders.
          </Typography>
        )}

        {wireEnabled && (
          <Card
            elevation={dk ? 0 : 1}
            sx={{
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
              borderRadius: 2,
            }}
          >
            <CardContent sx={{ pb: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                Order Type
              </Typography>
              <FormControl size="small" fullWidth>
                <InputLabel>Order Type</InputLabel>
                <Select
                  value={orderType}
                  label="Order Type"
                  onChange={(e) => setOrderType(e.target.value as OrderType)}
                >
                  <MenuItem value="LOCAL">Local</MenuItem>
                  <MenuItem value="OUTGOING_NETWORK">Outgoing Network</MenuItem>
                  <MenuItem value="INCOMING_NETWORK">Incoming Network</MenuItem>
                </Select>
              </FormControl>
            </CardContent>
          </Card>
        )}

        {wireEnabled && orderType === 'OUTGOING_NETWORK' && (
          <Card
            elevation={dk ? 0 : 1}
            sx={{
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
              borderRadius: 2,
            }}
          >
            <CardContent sx={{ pb: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                Outgoing Network Details
              </Typography>
              <FormControl size="small" fullWidth sx={{ mb: 1 }}>
                <InputLabel>Vendor Florist</InputLabel>
                <Select
                  value={vendorId}
                  label="Vendor Florist"
                  onChange={(e) => setVendorId(e.target.value)}
                >
                  {vendorFlorists.filter((v) => v.isActive !== false).map((vendor) => (
                    <MenuItem key={vendor.id} value={vendor.id}>
                      {vendor.name}{vendor.city ? ` (${vendor.city})` : ''}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
              <TextField
                size="small"
                fullWidth
                type="number"
                label="Amount Sent to Vendor"
                value={vendorAmount}
                onChange={(e) => setVendorAmount(Number(e.target.value))}
                sx={{ mb: 1 }}
              />
              <TextField
                size="small"
                fullWidth
                type="number"
                label="Wire Fee"
                value={wireFee}
                onChange={(e) => setWireFee(Number(e.target.value))}
              />
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                Inventory will not be deducted for outgoing network orders.
              </Typography>
            </CardContent>
          </Card>
        )}

        {wireEnabled && orderType === 'INCOMING_NETWORK' && (
          <Card
            elevation={dk ? 0 : 1}
            sx={{
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
              borderRadius: 2,
            }}
          >
            <CardContent sx={{ pb: 2 }}>
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
                Incoming Network Details
              </Typography>
              <TextField
                size="small"
                fullWidth
                label="Source Network"
                value={sourceNetwork}
                onChange={(e) => setSourceNetwork(e.target.value)}
                sx={{ mb: 1 }}
              />
              <TextField
                size="small"
                fullWidth
                type="number"
                label="Commission %"
                value={commissionPercent}
                onChange={(e) => setCommissionPercent(Number(e.target.value))}
              />
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                Customer payment is handled by the network.
              </Typography>
            </CardContent>
          </Card>
        )}

        <CartSummaryPanel totals={state.totals} orderSource="WALK_IN" />

        <Card
          elevation={dk ? 0 : 1}
          sx={{
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: dk ? '1px solid rgba(255,255,255,0.08)' : 'none',
            borderRadius: 2,
          }}
        >
          <CardContent sx={{ pb: 2 }}>
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 1 }}>
              Profit Summary
            </Typography>
            <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
              <Typography variant="body2" color="text.secondary">Customer Paid</Typography>
              <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(customerPaid)}</Typography>
            </Box>
            {orderType === 'OUTGOING_NETWORK' && (
              <>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">Vendor Amount</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(vendorAmount)}</Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                  <Typography variant="body2" color="text.secondary">Wire Fee</Typography>
                  <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(wireFee)}</Typography>
                </Box>
              </>
            )}
            {orderType === 'INCOMING_NETWORK' && (
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 0.5 }}>
                <Typography variant="body2" color="text.secondary">Net Received</Typography>
                <Typography variant="body2" sx={{ fontWeight: 700 }}>{fmtCurrency(netReceived)}</Typography>
              </Box>
            )}
            <Divider sx={{ my: 1, borderColor: dk ? 'rgba(255,255,255,0.08)' : undefined }} />
            <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
              <Typography variant="body2" color="text.secondary">Estimated Profit</Typography>
              <Typography variant="body2" sx={{ fontWeight: 800, color: theme.palette.success.main }}>
                {fmtCurrency(
                  orderType === 'OUTGOING_NETWORK'
                    ? outgoingProfit
                    : orderType === 'INCOMING_NETWORK'
                      ? incomingProfit
                      : localProfit
                )}
              </Typography>
            </Box>
            {orderType === 'OUTGOING_NETWORK' && selectedVendor && (
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                Vendor: {selectedVendor.name}
              </Typography>
            )}
          </CardContent>
        </Card>

        <Divider sx={{ borderColor: dk ? 'rgba(255,255,255,0.06)' : undefined }} />

        {showPayment ? (
          <Button
            variant="contained"
            size="large"
            fullWidth
            startIcon={<PayIcon />}
            disabled={state.items.length === 0}
            onClick={handleOpenPay}
            sx={{
              py: 1.5, fontWeight: 800, fontSize: '1rem',
              bgcolor: dk ? '#fdd835' : undefined,
              color: dk ? '#000' : undefined,
              '&:hover': { bgcolor: dk ? '#fbc02d' : undefined },
              '&.Mui-disabled': {
                bgcolor: dk ? 'rgba(255,255,255,0.08)' : undefined,
                color: dk ? 'rgba(255,255,255,0.3)' : undefined,
              },
            }}
          >
            Pay {state.totals.grandTotal > 0 ? fmtCurrency(state.totals.grandTotal) : ''}
          </Button>
        ) : (
          <Alert severity="info" sx={{ fontSize: '0.85rem' }}>
            Customer payment is handled by the wire network.
          </Alert>
        )}

        <Button
          variant="outlined"
          size="small"
          fullWidth
          startIcon={<GiftCardIcon />}
          onClick={() => setGiftCardOpen(true)}
          sx={{
            borderColor: dk ? 'rgba(156,39,176,0.5)' : '#9c27b0',
            color: dk ? '#ce93d8' : '#9c27b0',
            '&:hover': {
              borderColor: '#9c27b0',
              bgcolor: dk ? 'rgba(156,39,176,0.08)' : 'rgba(156,39,176,0.04)',
            },
          }}
        >
          {attachedGiftCard ? 'Gift Card Attached ✓' : 'Add Gift Card'}
        </Button>

        <Button
          variant="outlined"
          size="small"
          fullWidth
          color="error"
          disabled={state.items.length === 0}
          onClick={() => { clearCart(); setCustomerName(''); setCustomerPhone(''); setSelectedCustomer(null); setCustomerError(false); setSnackMsg('Cart cleared'); }}
        >
          Clear Cart
        </Button>
      </Box>

      {/* ─── Hold Dialog ────────────────────────────────── */}
      <Dialog open={holdDialogOpen} onClose={() => setHoldDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ fontWeight: 700 }}>Hold Order</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus fullWidth size="small" label="Label (optional)"
            value={holdLabel} onChange={(e) => setHoldLabel(e.target.value)}
            placeholder="e.g., Customer name"
            sx={{ mt: 1 }}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setHoldDialogOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={handleHold}>Hold Order</Button>
        </DialogActions>
      </Dialog>

      {/* ─── Payment Modal (terminal-ready) ──────────── */}
      {showPayment && (
        <PaymentModal
          open={payModalOpen}
          onClose={() => setPayModalOpen(false)}
          orderId={paymentOrderId}
          grandTotal={state.totals.grandTotal}
          onFullyPaid={handleFullyPaid}
          onPartialSave={handlePartialSave}
          customerValid={isCustomerValid}
        />
      )}

      {/* ─── Gift Card Builder Modal ───────────────── */}
      <GiftCardBuilderModal
        open={giftCardOpen}
        onClose={() => setGiftCardOpen(false)}
        onSave={(card) => { setAttachedGiftCard(card); setSnackMsg('Gift Card attached to order'); }}
      />

      {/* ─── Snackbar ───────────────────────────────────── */}
      <Snackbar
        open={!!snackMsg}
        autoHideDuration={2000}
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

export default WalkInPOS;
