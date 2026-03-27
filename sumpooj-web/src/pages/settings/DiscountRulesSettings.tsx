import React, { useMemo, useState } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Stack,
  TextField,
  Button,
  Alert,
  InputAdornment,
} from '@mui/material';
import { Save, Percent, CurrencyRupee } from '@mui/icons-material';
import { useTenant } from '../../core/tenant/TenantContext';
import {
  getDefaultPosDiscountRules,
  getPosDiscountRules,
  savePosDiscountRules,
} from '../../core/settings/discountRules';

export default function DiscountRulesSettings() {
  const { tenant } = useTenant();
  const defaults = useMemo(() => getDefaultPosDiscountRules(), []);
  const initial = useMemo(() => getPosDiscountRules(tenant.id), [tenant.id]);

  const [maxPercent, setMaxPercent] = useState<number>(initial.maxDiscountPercent);
  const [maxAmount, setMaxAmount] = useState<number>(initial.maxDiscountAmount);
  const [saved, setSaved] = useState(false);

  const effectiveMaxFor1000 = Math.min(maxAmount, (1000 * maxPercent) / 100);

  const handleSave = () => {
    const persisted = savePosDiscountRules(
      {
        maxDiscountPercent: maxPercent,
        maxDiscountAmount: maxAmount,
      },
      tenant.id,
    );

    setMaxPercent(persisted.maxDiscountPercent);
    setMaxAmount(persisted.maxDiscountAmount);
    setSaved(true);
    window.setTimeout(() => setSaved(false), 2500);
  };

  const handleReset = () => {
    setMaxPercent(defaults.maxDiscountPercent);
    setMaxAmount(defaults.maxDiscountAmount);
  };

  return (
    <Box sx={{ p: { xs: 2, sm: 3 }, maxWidth: 860, mx: 'auto' }}>
      <Box sx={{ mb: 3 }}>
        <Typography variant="h5" fontWeight={700}>
          Discount Rules
        </Typography>
        <Typography variant="body2" color="text.secondary" mt={0.5}>
          Configure the maximum discount allowed at POS checkout.
        </Typography>
      </Box>

      {saved && (
        <Alert severity="success" sx={{ mb: 2 }}>
          Discount rules saved successfully.
        </Alert>
      )}

      <Card>
        <CardContent>
          <Stack spacing={2.5}>
            <TextField
              label="Max Discount Percent"
              type="number"
              value={maxPercent}
              onChange={(e) => setMaxPercent(Number(e.target.value))}
              inputProps={{ min: 0, max: 100, step: 0.5 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Percent fontSize="small" />
                  </InputAdornment>
                ),
              }}
              helperText="Allowed range: 0 to 100"
              fullWidth
            />

            <TextField
              label="Max Discount Amount"
              type="number"
              value={maxAmount}
              onChange={(e) => setMaxAmount(Number(e.target.value))}
              inputProps={{ min: 0, step: 1 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <CurrencyRupee fontSize="small" />
                  </InputAdornment>
                ),
              }}
              helperText="Maximum fixed discount amount in INR"
              fullWidth
            />

            <Alert severity="info">
              Effective cap at checkout = lower of percentage cap and amount cap.
              {' '}Example on Rs 1000 bill: max discount = Rs {effectiveMaxFor1000.toFixed(2)}.
            </Alert>

            <Stack direction="row" spacing={1.5}>
              <Button variant="contained" startIcon={<Save />} onClick={handleSave}>
                Save Rules
              </Button>
              <Button variant="outlined" onClick={handleReset}>
                Reset to Defaults
              </Button>
            </Stack>
          </Stack>
        </CardContent>
      </Card>
    </Box>
  );
}
