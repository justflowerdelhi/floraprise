import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Box,
  Button,
  CircularProgress,
  Container,
  FormControl,
  Grid,
  InputLabel,
  MenuItem,
  Paper,
  Select,
  TextField,
  Typography,
} from '@mui/material';
import { AddCircleOutline as AddIcon, Save as SaveIcon } from '@mui/icons-material';
import { CustomerDatalist } from '../../components/CustomerDatalist';
import { useApiCall } from '../../hooks/useApiCall';
import { searchCustomers } from '../../api/customer.api';
import {
  findCustomerByName,
  findCustomerByPhone,
} from '../../utils\customerLookup';
import { createPhoneOrder } from './phoneOrders.api';

const TIME_SLOT_OPTIONS = [
  '10:00 AM – 12:00 PM',
  '12:00 PM – 2:00 PM',
  '2:00 PM – 4:00 PM',
  '4:00 PM – 6:00 PM',
  'Custom',
];

type CustomerSuggestion = {
  id: string;
  name: string;
  phone: string;
  email?: string;
};

const CreatePhoneOrderPage: React.FC = () => {
  const navigate = useNavigate();
  const { loading, execute } = useApiCall();

  // ── Form state ─────────────────────────────────────────────────────────

  const [customerName, setCustomerName] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [orderType, setOrderType] = useState<'PhoneLocal' | 'PhoneOutstation'>('PhoneLocal');
  const [deliveryDate, setDeliveryDate] = useState('');
  const [timeSlot, setTimeSlot] = useState('');
  const [customTimeSlot, setCustomTimeSlot] = useState('');
  const [city, setCity] = useState('');
  const [occasion, setOccasion] = useState('');
  const [budget, setBudget] = useState('');
  const [specialInstructions, setSpecialInstructions] = useState('');
  const [customerSuggestions, setCustomerSuggestions] = useState<CustomerSuggestion[]>([]);
  const [activeSuggestField, setActiveSuggestField] = useState<'name' | 'phone' | null>(null);

  // ── Touched state (for showing validation errors after blur) ───────────

  const [touched, setTouched] = useState({
    customerName: false,
    phoneNumber: false,
    deliveryDate: false,
    city: false,
  });

  const handleBlur = (field: keyof typeof touched) => {
    setTouched((prev) => ({ ...prev, [field]: true }));
  };

  useEffect(() => {
    if (!activeSuggestField) return;

    const query = activeSuggestField === 'phone' ? phoneNumber.trim() : customerName.trim();
    if (query.length < 2) {
      setCustomerSuggestions([]);
      return;
    }

    let cancelled = false;
    const timer = setTimeout(async () => {
      try {
        const data = await searchCustomers({ Query: query, PageSize: 20 });
        const items = Array.isArray(data) ? data : data?.items ?? [];
        if (cancelled) return;
        setCustomerSuggestions(
          items
            .filter((customer: CustomerSuggestion) => !!(customer?.name || customer?.phone))
            .map((customer: CustomerSuggestion) => ({
              id: customer.id,
              name: customer.name || '',
              phone: customer.phone || '',
              email: customer.email || '',
            })),
        );
      } catch {
        if (!cancelled) setCustomerSuggestions([]);
      }
    }, 250);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [activeSuggestField, customerName, phoneNumber]);

  const applyMatchedCustomer = useCallback((customer: CustomerSuggestion) => {
    setCustomerName(customer.name || '');
    setPhoneNumber(customer.phone || '');
  }, []);

  const handleCustomerNameChange = useCallback((value: string) => {
    setCustomerName(value);
    setActiveSuggestField('name');

    const match = findCustomerByName(customerSuggestions, value);

    if (match) applyMatchedCustomer(match);
  }, [applyMatchedCustomer, customerSuggestions]);

  const handlePhoneNumberChange = useCallback((value: string) => {
    setPhoneNumber(value);
    setActiveSuggestField('phone');

    const match = findCustomerByPhone(customerSuggestions, value);

    if (match) applyMatchedCustomer(match);
  }, [applyMatchedCustomer, customerSuggestions]);

  // ── Validation ─────────────────────────────────────────────────────────

  const errors = {
    customerName: customerName.trim().length === 0 ? 'Customer Name is required' : '',
    phoneNumber: phoneNumber.trim().length === 0 ? 'Phone Number is required' : '',
    deliveryDate: deliveryDate.length === 0 ? 'Delivery Date is required' : '',
    city: city.trim().length === 0 ? 'City is required' : '',
  };

  const isValid =
    !errors.customerName &&
    !errors.phoneNumber &&
    !errors.deliveryDate &&
    !errors.city;

  // ── Submit handler ─────────────────────────────────────────────────────

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!isValid) return;

    const finalTimeSlot = timeSlot === 'Custom' ? customTimeSlot.trim() : timeSlot;

    const result = await execute(
      () =>
        createPhoneOrder({
          customerName: customerName.trim(),
          phoneNumber: phoneNumber.trim(),
          orderType,
          deliveryDate,
          deliveryCity: city.trim(),
          timeSlot: finalTimeSlot || undefined,
          occasion: occasion.trim() || undefined,
          budget: budget ? parseFloat(budget) : undefined,
          specialInstructions: specialInstructions.trim() || undefined,
        }),
      {
        successMessage: 'Draft order created',
        errorMessage: 'Failed to create order',
      },
    );

    if (result) {
      navigate(`/phone-orders/${result.id}`);
    }
  };

  // ── Render ─────────────────────────────────────────────────────────────

  return (
    <Container maxWidth="md" sx={{ py: 4 }}>
      <Typography
        variant="h5"
        sx={{ fontWeight: 700, display: 'flex', alignItems: 'center', gap: 1, mb: 3 }}
      >
        <AddIcon /> Create Phone Order
      </Typography>

      <Paper variant="outlined" sx={{ p: 3 }}>
        <Box component="form" onSubmit={handleSubmit}>
          <Grid container spacing={3}>
            {/* ── Customer Info ───────────────────────────── */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Customer Name"
                value={customerName}
                onChange={(e) => handleCustomerNameChange(e.target.value)}
                onFocus={() => setActiveSuggestField('name')}
                onBlur={() => {
                  handleBlur('customerName');
                  setTimeout(() => setActiveSuggestField(null), 100);
                }}
                fullWidth
                required
                size="small"
                slotProps={{ htmlInput: { list: 'phone-order-customer-names' } }}
                error={touched.customerName && !!errors.customerName}
                helperText={touched.customerName && errors.customerName}
              />
              <CustomerDatalist id="phone-order-customer-names" customers={customerSuggestions} field="name" />
            </Grid>
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Phone Number"
                value={phoneNumber}
                onChange={(e) => handlePhoneNumberChange(e.target.value)}
                onFocus={() => setActiveSuggestField('phone')}
                onBlur={() => {
                  handleBlur('phoneNumber');
                  setTimeout(() => setActiveSuggestField(null), 100);
                }}
                fullWidth
                required
                size="small"
                slotProps={{ htmlInput: { list: 'phone-order-customer-phones' } }}
                error={touched.phoneNumber && !!errors.phoneNumber}
                helperText={touched.phoneNumber && errors.phoneNumber}
              />
              <CustomerDatalist id="phone-order-customer-phones" customers={customerSuggestions} field="phone" />
            </Grid>

            {/* ── Order Type ──────────────────────────────── */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <FormControl fullWidth size="small">
                <InputLabel id="order-type-label">Order Type</InputLabel>
                <Select
                  labelId="order-type-label"
                  value={orderType}
                  label="Order Type"
                  onChange={(e) => setOrderType(e.target.value as 'PhoneLocal' | 'PhoneOutstation')}
                >
                  <MenuItem value="PhoneLocal">Phone Local</MenuItem>
                  <MenuItem value="PhoneOutstation">Phone Outstation</MenuItem>
                </Select>
              </FormControl>
            </Grid>

            {/* ── Delivery Date ───────────────────────────── */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Delivery Date"
                type="date"
                value={deliveryDate}
                onChange={(e) => setDeliveryDate(e.target.value)}
                onBlur={() => handleBlur('deliveryDate')}
                fullWidth
                required
                size="small"
                slotProps={{ inputLabel: { shrink: true } }}
                error={touched.deliveryDate && !!errors.deliveryDate}
                helperText={touched.deliveryDate && errors.deliveryDate}
              />
            </Grid>

            {/* ── Time Slot ───────────────────────────────── */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <FormControl fullWidth size="small">
                <InputLabel id="time-slot-label">Time Slot</InputLabel>
                <Select
                  labelId="time-slot-label"
                  value={timeSlot}
                  label="Time Slot"
                  onChange={(e) => setTimeSlot(e.target.value)}
                >
                  {TIME_SLOT_OPTIONS.map((slot) => (
                    <MenuItem key={slot} value={slot}>
                      {slot}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* ── Custom Time Slot (shown when Custom selected) ── */}
            {timeSlot === 'Custom' && (
              <Grid size={{ xs: 12, sm: 6 }}>
                <TextField
                  label="Custom Time Slot"
                  value={customTimeSlot}
                  onChange={(e) => setCustomTimeSlot(e.target.value)}
                  placeholder="e.g., 9:00 AM - 11:00 AM"
                  fullWidth
                  size="small"
                />
              </Grid>
            )}

            {/* ── City ────────────────────────────────────── */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="City"
                value={city}
                onChange={(e) => setCity(e.target.value)}
                onBlur={() => handleBlur('city')}
                fullWidth
                required
                size="small"
                error={touched.city && !!errors.city}
                helperText={touched.city && errors.city}
              />
            </Grid>

            {/* ── Occasion ────────────────────────────────── */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Occasion"
                value={occasion}
                onChange={(e) => setOccasion(e.target.value)}
                placeholder="e.g., Birthday, Anniversary"
                fullWidth
                size="small"
              />
            </Grid>

            {/* ── Budget ──────────────────────────────────── */}
            <Grid size={{ xs: 12, sm: 6 }}>
              <TextField
                label="Budget"
                type="number"
                value={budget}
                onChange={(e) => setBudget(e.target.value)}
                fullWidth
                size="small"
                slotProps={{ htmlInput: { min: 0, step: '0.01' } }}
              />
            </Grid>

            {/* ── Special Instructions ────────────────────── */}
            <Grid size={{ xs: 12 }}>
              <TextField
                label="Special Instructions"
                value={specialInstructions}
                onChange={(e) => setSpecialInstructions(e.target.value)}
                fullWidth
                multiline
                rows={3}
                size="small"
              />
            </Grid>

            {/* ── Submit Button ───────────────────────────── */}
            <Grid size={{ xs: 12 }}>
              <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2, mt: 2 }}>
                <Button
                  variant="outlined"
                  onClick={() => navigate('/phone-orders')}
                  disabled={loading}
                  sx={{ textTransform: 'none' }}
                >
                  Cancel
                </Button>
                <Button
                  type="submit"
                  variant="contained"
                  disabled={loading || !isValid}
                  startIcon={loading ? <CircularProgress size={16} /> : <SaveIcon />}
                  sx={{ textTransform: 'none', fontWeight: 700 }}
                >
                  Create Draft Order
                </Button>
              </Box>
            </Grid>
          </Grid>
        </Box>
      </Paper>
    </Container>
  );
};

export default CreatePhoneOrderPage;
