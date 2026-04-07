/**
 * Quick Add Flowers Modal
 * Bulk-creates fresh flower products from preset names + selected colors.
 */

import {
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  Box,
  Typography,
  Chip,
  Stack,
  alpha,
  useTheme,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  FormHelperText,
  TextField,
} from '@mui/material';
import LocalFloristIcon from '@mui/icons-material/LocalFlorist';
import { useState, useEffect } from 'react';
import type {
  CategoryOption,
  TaxCategory,
  IncomeAccount,
  ExpenseAccount,
} from '../types/product.types';

// ============================================
// DATA
// ============================================

interface FlowerPreset {
  name: string;
  unit: string;
}

const FLOWER_PRESETS: FlowerPreset[] = [
  { name: 'Rose', unit: 'stem' },
  { name: 'Carnation', unit: 'stem' },
  { name: 'Lily', unit: 'stem' },
  { name: 'Gerbera', unit: 'stem' },
  { name: 'Orchid', unit: 'stem' },
  { name: 'Tulip', unit: 'stem' },
  { name: 'Sunflower', unit: 'stem' },
  { name: 'Chrysanthemum', unit: 'stem' },
];

const ALL_COLORS = ['Red', 'Yellow', 'Pink', 'White', 'Orange', 'Purple', 'Blue', 'Peach'];

const COLOR_SWATCHES: Record<string, string> = {
  Red: '#ef5350',
  Yellow: '#ffd54f',
  Pink: '#f48fb1',
  White: '#eeeeee',
  Orange: '#ffa726',
  Purple: '#ab47bc',
  Blue: '#42a5f5',
  Peach: '#ffab91',
};

// ============================================
// TYPES
// ============================================

export interface QuickFlowerProduct {
  productName: string;
  productType: 'fresh_flower';
  unitOfMeasure: string;
  isPerishable: boolean;
  trackInventory: boolean;
  trackBatch: boolean;
  categoryId: string;
  /** Variant color (mapped to existing flowerAttributes.color field) */
  color: string | undefined;
  /** Tags for this specific variant */
  colors: string[];
  retailPrice: number;
  costPrice: number;
  openingStock: number;
  reorderLevel: number;
  shelfLifeDays: number;
  taxCategory: TaxCategory;
  incomeAccount: IncomeAccount;
  expenseAccount: ExpenseAccount;
  status: 'active' | 'inactive';
}

interface Props {
  open: boolean;
  onClose: () => void;
  onCreate: (products: QuickFlowerProduct[]) => void;
  categories: CategoryOption[];
  defaultCategoryId?: string;
}

// ============================================
// COMPONENT
// ============================================

export default function QuickAddFlowersModal({ open, onClose, onCreate, categories, defaultCategoryId }: Props) {
  const theme = useTheme();
  const [selectedFlowers, setSelectedFlowers] = useState<string[]>([]);
  const [selectedColors, setSelectedColors] = useState<string[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<string>(defaultCategoryId ?? '');
  const [retailPrice, setRetailPrice] = useState<number>(20);
  const [costPrice, setCostPrice] = useState<number>(10);
  const [openingStock, setOpeningStock] = useState<number>(0);
  const [reorderLevel, setReorderLevel] = useState<number>(0);
  const [shelfLifeDays, setShelfLifeDays] = useState<number>(7);
  const [taxCategory, setTaxCategory] = useState<TaxCategory>('standard');
  const [incomeAccount, setIncomeAccount] = useState<IncomeAccount>('4000');
  const [expenseAccount, setExpenseAccount] = useState<ExpenseAccount>('5000');
  const [status, setStatus] = useState<'active' | 'inactive'>('active');

  // Sync defaultCategoryId when it changes (e.g. user selects a category in the main form)
  useEffect(() => {
    if (defaultCategoryId) setSelectedCategoryId(defaultCategoryId);
  }, [defaultCategoryId]);

  const toggleFlower = (name: string) =>
    setSelectedFlowers((prev) =>
      prev.includes(name) ? prev.filter((f) => f !== name) : [...prev, name],
    );

  const toggleColor = (color: string) =>
    setSelectedColors((prev) =>
      prev.includes(color) ? prev.filter((c) => c !== color) : [...prev, color],
    );

  const handleClose = () => {
    setSelectedFlowers([]);
    setSelectedColors([]);
    setSelectedCategoryId(defaultCategoryId ?? '');
    setRetailPrice(20);
    setCostPrice(10);
    setOpeningStock(0);
    setReorderLevel(0);
    setShelfLifeDays(7);
    setTaxCategory('standard');
    setIncomeAccount('4000');
    setExpenseAccount('5000');
    setStatus('active');
    onClose();
  };

  const handleCreate = () => {
    const colorsToCreate = selectedColors.length > 0 ? selectedColors : [undefined];

    const products: QuickFlowerProduct[] = selectedFlowers.flatMap((flowerName) => {
      const preset = FLOWER_PRESETS.find((f) => f.name === flowerName)!;

      return colorsToCreate.map((color) => {
        const variantName = color ? `${flowerName} - ${color}` : flowerName;
        return {
          productName: variantName,
          productType: 'fresh_flower' as const,
          unitOfMeasure: preset.unit,
          isPerishable: true,
          trackInventory: true,
          trackBatch: true,
          categoryId: selectedCategoryId,
          color,
          colors: color ? [color] : [],
          retailPrice,
          costPrice,
          openingStock,
          reorderLevel,
          shelfLifeDays,
          taxCategory,
          incomeAccount,
          expenseAccount,
          status,
        };
      });
    });

    onCreate(products);
    handleClose();
  };

  const productCount = selectedFlowers.length * (selectedColors.length > 0 ? selectedColors.length : 1);
  const canCreate =
    productCount > 0
    && !!selectedCategoryId
    && retailPrice >= 0
    && costPrice >= 0
    && retailPrice >= costPrice
    && openingStock >= 0
    && reorderLevel >= 0
    && shelfLifeDays >= 1;

  return (
    <Dialog open={open} onClose={handleClose} fullWidth maxWidth="sm">
      <DialogTitle>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: 36,
              height: 36,
              borderRadius: 1.5,
              background: 'linear-gradient(135deg, #e91e63 0%, #9c27b0 100%)',
            }}
          >
            <LocalFloristIcon sx={{ color: 'white', fontSize: 20 }} />
          </Box>
          <Box>
            <Typography variant="h6" fontWeight={700} sx={{ lineHeight: 1.2 }}>
              Quick Add Flowers
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Bulk-create fresh flower products with preset defaults
            </Typography>
          </Box>
        </Box>
      </DialogTitle>

      <DialogContent dividers>
        <Stack spacing={3}>
          {/* ── Flower Selection ─────────────────────────────── */}
          <Box>
            <Typography variant="subtitle2" fontWeight={600} gutterBottom>
              Select Flowers
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 0.5 }}>
              {FLOWER_PRESETS.map((f) => {
                const selected = selectedFlowers.includes(f.name);
                return (
                  <Chip
                    key={f.name}
                    label={f.name}
                    clickable
                    icon={<LocalFloristIcon />}
                    color={selected ? 'primary' : 'default'}
                    variant={selected ? 'filled' : 'outlined'}
                    onClick={() => toggleFlower(f.name)}
                  />
                );
              })}
            </Box>
          </Box>

          {/* ── Color Selection ──────────────────────────────── */}
          <Box>
            <Typography variant="subtitle2" fontWeight={600} gutterBottom>
              Select Colors{' '}
              <Typography component="span" variant="caption" color="text.secondary">
                (optional — creates a separate variant for each selected color)
              </Typography>
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 0.5 }}>
              {ALL_COLORS.map((color) => {
                const selected = selectedColors.includes(color);
                return (
                  <Chip
                    key={color}
                    label={color}
                    clickable
                    color={selected ? 'secondary' : 'default'}
                    variant={selected ? 'filled' : 'outlined'}
                    onClick={() => toggleColor(color)}
                    sx={{
                      '&::before': {
                        content: '""',
                        display: 'inline-block',
                        width: 10,
                        height: 10,
                        borderRadius: '50%',
                        backgroundColor: COLOR_SWATCHES[color] ?? '#ccc',
                        marginRight: 0.5,
                        border: '1px solid rgba(0,0,0,0.15)',
                      },
                    }}
                  />
                );
              })}
            </Box>
          </Box>

          {/* ── Category Selection ───────────────────────────── */}
          <Box>
            <FormControl fullWidth required error={!selectedCategoryId}>
              <InputLabel id="quick-add-category-label">Category</InputLabel>
              <Select
                labelId="quick-add-category-label"
                label="Category"
                value={selectedCategoryId}
                onChange={(e) => setSelectedCategoryId(e.target.value)}
              >
                {categories.filter((c) => c.isActive).map((cat) => (
                  <MenuItem key={cat.id} value={cat.id}>{cat.name}</MenuItem>
                ))}
              </Select>
              {!selectedCategoryId && (
                <FormHelperText>Category is required by the backend</FormHelperText>
              )}
            </FormControl>
          </Box>

          {/* ── Required Product Fields ─────────────────────── */}
          <Box>
            <Typography variant="subtitle2" fontWeight={600} gutterBottom>
              Required Product Fields
            </Typography>
            <Typography variant="caption" color="text.secondary">
              Fill these as per product-entry SOP: Sales price, purchase cost, stock control, tax class, and ledger mapping.
            </Typography>
            <Stack spacing={2} sx={{ mt: 1 }}>
              <Box sx={{ display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' } }}>
                <TextField
                  type="number"
                  label="Retail Price (Sales Rate)"
                  value={retailPrice}
                  onChange={(e) => setRetailPrice(Number(e.target.value))}
                  inputProps={{ min: 0, step: '0.01' }}
                  required
                  helperText="Selling price used for POS billing"
                  fullWidth
                />
                <TextField
                  type="number"
                  label="Cost Price (Purchase Rate)"
                  value={costPrice}
                  onChange={(e) => setCostPrice(Number(e.target.value))}
                  inputProps={{ min: 0, step: '0.01' }}
                  required
                  error={costPrice > retailPrice}
                  helperText={costPrice > retailPrice ? 'Cost cannot exceed retail' : 'Used for COGS and margin calculation'}
                  fullWidth
                />
              </Box>

              <Box sx={{ display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr 1fr' } }}>
                <TextField
                  type="number"
                  label="Opening Stock (Qty)"
                  value={openingStock}
                  onChange={(e) => setOpeningStock(Math.max(0, Number(e.target.value)))}
                  inputProps={{ min: 0, step: '1' }}
                  required
                  helperText="Current available quantity"
                  fullWidth
                />
                <TextField
                  type="number"
                  label="Reorder Level (Min Qty)"
                  value={reorderLevel}
                  onChange={(e) => setReorderLevel(Math.max(0, Number(e.target.value)))}
                  inputProps={{ min: 0, step: '1' }}
                  required
                  helperText="Alert threshold for purchase"
                  fullWidth
                />
                <TextField
                  type="number"
                  label="Shelf Life (Days)"
                  value={shelfLifeDays}
                  onChange={(e) => setShelfLifeDays(Math.max(1, Number(e.target.value)))}
                  inputProps={{ min: 1, step: '1' }}
                  required
                  helperText="Used for expiry tracking"
                  fullWidth
                />
              </Box>

              <Box sx={{ display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' } }}>
                <FormControl fullWidth required>
                  <InputLabel id="quick-add-tax-category-label">Tax Category</InputLabel>
                  <Select
                    labelId="quick-add-tax-category-label"
                    label="Tax Category"
                    value={taxCategory}
                    onChange={(e) => setTaxCategory(e.target.value as TaxCategory)}
                  >
                    <MenuItem value="standard">Standard</MenuItem>
                    <MenuItem value="reduced">Reduced</MenuItem>
                    <MenuItem value="exempt">Exempt</MenuItem>
                    <MenuItem value="zero">Zero</MenuItem>
                  </Select>
                  <FormHelperText>GST/VAT class for sales calculations</FormHelperText>
                </FormControl>

                <FormControl fullWidth required>
                  <InputLabel id="quick-add-status-label">Status</InputLabel>
                  <Select
                    labelId="quick-add-status-label"
                    label="Status"
                    value={status}
                    onChange={(e) => setStatus(e.target.value as 'active' | 'inactive')}
                  >
                    <MenuItem value="active">Active</MenuItem>
                    <MenuItem value="inactive">Inactive</MenuItem>
                  </Select>
                  <FormHelperText>Active products are immediately available</FormHelperText>
                </FormControl>
              </Box>

              <Box sx={{ display: 'grid', gap: 2, gridTemplateColumns: { xs: '1fr', sm: '1fr 1fr' } }}>
                <FormControl fullWidth required>
                  <InputLabel id="quick-add-income-account-label">Income Account (Sales Ledger)</InputLabel>
                  <Select
                    labelId="quick-add-income-account-label"
                    label="Income Account (Sales Ledger)"
                    value={incomeAccount}
                    onChange={(e) => setIncomeAccount(e.target.value as IncomeAccount)}
                  >
                    <MenuItem value="4000">4000 - Product Sales</MenuItem>
                    <MenuItem value="4010">4010 - Fresh Flower Sales</MenuItem>
                    <MenuItem value="4020">4020 - Plant Sales</MenuItem>
                    <MenuItem value="4030">4030 - Gift Sales</MenuItem>
                    <MenuItem value="4040">4040 - Service Revenue</MenuItem>
                    <MenuItem value="4050">4050 - Event Revenue</MenuItem>
                  </Select>
                  <FormHelperText>Revenue posting account in accounting</FormHelperText>
                </FormControl>

                <FormControl fullWidth required>
                  <InputLabel id="quick-add-expense-account-label">Expense Account (COGS Ledger)</InputLabel>
                  <Select
                    labelId="quick-add-expense-account-label"
                    label="Expense Account (COGS Ledger)"
                    value={expenseAccount}
                    onChange={(e) => setExpenseAccount(e.target.value as ExpenseAccount)}
                  >
                    <MenuItem value="5000">5000 - Cost of Goods Sold</MenuItem>
                    <MenuItem value="5010">5010 - Fresh Flower Purchases</MenuItem>
                    <MenuItem value="5020">5020 - Plant Purchases</MenuItem>
                    <MenuItem value="5030">5030 - Supply Purchases</MenuItem>
                    <MenuItem value="5040">5040 - Delivery Costs</MenuItem>
                  </Select>
                  <FormHelperText>Cost posting account for product movement</FormHelperText>
                </FormControl>
              </Box>
            </Stack>
          </Box>

          {/* ── Summary ──────────────────────────────────────── */}
          <Box
            sx={{
              p: 1.5,
              borderRadius: 2,
              bgcolor: productCount > 0
                ? alpha(theme.palette.primary.main, 0.06)
                : alpha(theme.palette.grey[500], 0.06),
              border: `1px dashed ${productCount > 0 ? theme.palette.primary.light : theme.palette.grey[300]}`,
              minHeight: 48,
              display: 'flex',
              alignItems: 'center',
            }}
          >
            {productCount === 0 ? (
              <Typography variant="caption" color="text.secondary">
                Select at least one flower to continue.
              </Typography>
            ) : (
              <Typography variant="caption" color="text.secondary">
                Will create{' '}
                <Typography component="span" variant="caption" fontWeight={700} color="primary.main">
                  {productCount} product{productCount > 1 ? 's' : ''}
                </Typography>
                {selectedColors.length > 0 && (
                  <>
                    {' '}from{' '}
                    <Typography component="span" variant="caption" fontWeight={700} color="secondary.main">
                      {selectedFlowers.length} flower{selectedFlowers.length > 1 ? 's' : ''} × {selectedColors.length} color{selectedColors.length > 1 ? 's' : ''}
                    </Typography>
                  </>
                )}
                {' '}— uses your required field values (pricing, inventory, shelf life, tax, accounting) and creates perishable, batch-tracked variants.
              </Typography>
            )}
          </Box>
        </Stack>
      </DialogContent>

      <DialogActions sx={{ px: 3, py: 2 }}>
        <Button onClick={handleClose} color="inherit">
          Cancel
        </Button>
        <Button
          variant="contained"
          onClick={handleCreate}
          disabled={!canCreate}
          startIcon={<LocalFloristIcon />}
          sx={{
            background: 'linear-gradient(135deg, #e91e63 0%, #9c27b0 100%)',
            '&:hover': {
              background: 'linear-gradient(135deg, #c2185b 0%, #7b1fa2 100%)',
            },
          }}
        >
          Create{productCount > 0 ? ` ${productCount} Product${productCount > 1 ? 's' : ''}` : ''}
        </Button>
      </DialogActions>
    </Dialog>
  );
}
