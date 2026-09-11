/**
 * RetailInventoryPage.tsx — Floraprise ERP Retail View Inventory Management Page
 *
 * Dedicated Retail Inventory experience:
 * - Simple, responsive florist-centric operational dashboard
 * - Live stock metrics: Total Tracked, In Stock, Low Stock, Out of Stock, Total Units
 * - Authoritative low-stock rule based on domain MinimumStockLevel and IsLowStock
 * - Authoritative post-transaction refresh directly from backend APIs
 * - Fast multi-attribute search: Name, SKU, Barcode
 * - Category filter chips & Stock Status filter chips
 * - Dual view modes: Visual Cards Grid & Compact Table
 * - Direct florist actions: + Stock In, - Stock Out, Wastage, Adjustments
 * - Live audit history inspection per product
 */

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  Box,
  Typography,
  Button,
  TextField,
  InputAdornment,
  Chip,
  IconButton,
  Tooltip,
  CircularProgress,
  Alert,
  Snackbar,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  ToggleButtonGroup,
  ToggleButton,
  useTheme,
  alpha,
  useMediaQuery,
  Card,
  CardContent,
} from '@mui/material';
import {
  Search as SearchIcon,
  Clear as ClearIcon,
  Refresh as RefreshIcon,
  GridView as GridViewIcon,
  TableRows as TableViewIcon,
  Add as AddIcon,
  Remove as RemoveIcon,
  DeleteOutline as WastageIcon,
  Tune as AdjustIcon,
  History as HistoryIcon,
  WarningAmber as WarningIcon,
  ErrorOutline as OutOfStockIcon,
  CheckCircleOutline as InStockIcon,
  Inventory2 as InventoryIcon,
} from '@mui/icons-material';

import { searchProducts } from '../../../api/product.api';
import { getCategories, type ProductCategoryDto } from '../../../api/category.api';
import { getBatchSummary, type BatchSummaryItem } from '../../../api/inventory.api';
import { useTenant } from '../../../core/tenant';
import { CURRENCY_SYMBOL_MAP } from '../../../core/tenant/TenantTypes';

import {
  RetailStockCard,
  getStockStatus,
  type RetailStockItem,
  type StockStatus,
} from './RetailStockCard';
import { RetailStockChangeModal, type StockOperationType } from './RetailStockChangeModal';
import { RetailStockHistoryModal } from './RetailStockHistoryModal';

export const RetailInventoryPage: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const { tenant } = useTenant();

  const currencySymbol = tenant?.currency ? (CURRENCY_SYMBOL_MAP[tenant.currency] ?? '$') : '$';

  // Data State
  const [items, setItems] = useState<RetailStockItem[]>([]);
  const [categories, setCategories] = useState<ProductCategoryDto[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Filter & Search State
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [statusFilter, setStatusFilter] = useState<'all' | StockStatus>('all');
  const [viewLayout, setViewLayout] = useState<'cards' | 'table'>('cards');

  // Modal State
  const [changeModalOpen, setChangeModalOpen] = useState(false);
  const [activeItem, setActiveItem] = useState<RetailStockItem | null>(null);
  const [activeOperation, setActiveOperation] = useState<StockOperationType>('purchase');

  const [historyModalOpen, setHistoryModalOpen] = useState(false);
  const [historyItem, setHistoryItem] = useState<RetailStockItem | null>(null);

  // Toast Notification
  const [toast, setToast] = useState<{
    open: boolean;
    message: string;
    severity: 'success' | 'info' | 'error';
  }>({
    open: false,
    message: '',
    severity: 'info',
  });

  // Load products and inventory batch projections
  const loadData = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const [productRes, categoryRes, batchRes] = await Promise.all([
        searchProducts({ PageSize: 500 }),
        getCategories(),
        getBatchSummary().catch(() => [] as BatchSummaryItem[]),
      ]);

      // Categories
      const activeCats = Array.isArray(categoryRes) ? categoryRes.filter((c) => c.isActive) : [];
      setCategories(activeCats);

      // Batch stock mapping
      const invMap = new Map<string, number>();
      if (Array.isArray(batchRes)) {
        batchRes.forEach((b: BatchSummaryItem) => {
          invMap.set(b.productId, (invMap.get(b.productId) ?? 0) + (b.availableUnits ?? 0));
        });
      }

      // Map products to RetailStockItem
      const rawItems = productRes?.items ?? (Array.isArray(productRes) ? productRes : []);
      const mapped: RetailStockItem[] = rawItems
        .filter((p: any) => p.isActive !== false)
        .map((p: any) => {
          const batchStock = invMap.get(p.id);
          const effectiveStock = batchStock !== undefined ? batchStock : (p.stockQuantity ?? 0);

          return {
            id: p.id,
            name: p.name || p.productName || 'Unnamed Product',
            sku: p.sku || '',
            barcode: p.barcode || null,
            manufacturerBarcode: p.manufacturerBarcode || null,
            internalBarcode: p.internalBarcode || null,
            category: p.categoryName || p.category || 'Other',
            categoryId: p.categoryId || null,
            unitOfMeasure: p.unitOfMeasure || 'Stem',
            retailPrice: Number(p.retailPrice ?? 0),
            costPrice: Number(p.costPrice ?? 0),
            stockQuantity: effectiveStock,
            minimumStockLevel: Number(p.minimumStockLevel ?? 0),
            reorderLevel: Number(p.reorderLevel ?? 0),
            isLowStock: Boolean(p.isLowStock),
            needsReorder: Boolean(p.needsReorder),
            trackInventory: Boolean(p.trackInventory),
            trackBatch: Boolean(p.trackBatch),
            isActive: p.isActive !== false,
            description: p.description || null,
          };
        });

      setItems(mapped);
    } catch (err: any) {
      console.error('Failed to load retail inventory:', err);
      setError(err?.message || 'Failed to load inventory. Please check your connection.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  // Handle opening stock change modal
  const handleOpenStockAction = (
    item: RetailStockItem,
    operation: StockOperationType = 'purchase',
  ) => {
    setActiveItem(item);
    setActiveOperation(operation);
    setChangeModalOpen(true);
  };

  // Handle opening stock history modal
  const handleOpenHistory = (item: RetailStockItem) => {
    setHistoryItem(item);
    setHistoryModalOpen(true);
  };

  // Authoritative post-transaction callback: immediately re-fetch backend state
  const handleStockChangeSuccess = async () => {
    setToast({
      open: true,
      message: 'Stock change applied. Updating latest balances...',
      severity: 'success',
    });
    await loadData();
  };

  // Filter and search computation
  const filteredItems = useMemo(() => {
    return items.filter((item) => {
      // Search
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const matchesName = item.name.toLowerCase().includes(q);
        const matchesSku = item.sku.toLowerCase().includes(q);
        const matchesBarcode =
          (item.barcode && item.barcode.toLowerCase().includes(q)) ||
          (item.manufacturerBarcode && item.manufacturerBarcode.toLowerCase().includes(q)) ||
          (item.internalBarcode && item.internalBarcode.toLowerCase().includes(q));

        if (!matchesName && !matchesSku && !matchesBarcode) {
          return false;
        }
      }

      // Category
      if (selectedCategory !== 'all') {
        const itemCatId = item.categoryId;
        const itemCatName = item.category?.toLowerCase();
        if (itemCatId !== selectedCategory && itemCatName !== selectedCategory.toLowerCase()) {
          return false;
        }
      }

      // Stock Status
      if (statusFilter !== 'all') {
        const itemStatus = getStockStatus(item);
        if (itemStatus !== statusFilter) {
          return false;
        }
      }

      return true;
    });
  }, [items, searchQuery, selectedCategory, statusFilter]);

  // Overall Inventory Metrics
  const metrics = useMemo(() => {
    let totalTracked = 0;
    let inStock = 0;
    let lowStock = 0;
    let outOfStock = 0;
    let totalUnits = 0;

    items.forEach((item) => {
      if (item.trackInventory) {
        totalTracked++;
        totalUnits += Math.max(0, item.stockQuantity);
        const st = getStockStatus(item);
        if (st === 'in_stock') inStock++;
        else if (st === 'low_stock') lowStock++;
        else if (st === 'out_of_stock') outOfStock++;
      }
    });

    return { totalTracked, inStock, lowStock, outOfStock, totalUnits };
  }, [items]);

  return (
    <Box sx={{ p: { xs: 2, md: 3 }, maxWidth: 1440, mx: 'auto' }}>
      {/* ─── Top Header ────────────────────────────────────────── */}
      <Box
        sx={{
          display: 'flex',
          flexDirection: { xs: 'column', sm: 'row' },
          justifyContent: 'space-between',
          alignItems: { xs: 'flex-start', sm: 'center' },
          gap: 2,
          mb: 3,
        }}
      >
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
            <Typography variant="h5" fontWeight={800} color="text.primary">
              Retail Inventory
            </Typography>
            <Chip
              label="Retail View"
              size="small"
              color="primary"
              variant="outlined"
              sx={{ fontWeight: 700, borderRadius: 1.5 }}
            />
          </Box>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 0.3 }}>
            Live stock levels, purchase receipts, manual sales, wastage recording, and audit trails.
          </Typography>
        </Box>

        <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
          <Tooltip title="Refresh Inventory">
            <IconButton onClick={loadData} disabled={loading} color="inherit">
              <RefreshIcon />
            </IconButton>
          </Tooltip>

          {items.length > 0 && (
            <Button
              variant="contained"
              color="success"
              startIcon={<AddIcon />}
              onClick={() => {
                const firstTracked = items.find((i) => i.trackInventory) ?? items[0];
                handleOpenStockAction(firstTracked, 'purchase');
              }}
              sx={{
                borderRadius: 2.5,
                fontWeight: 700,
                textTransform: 'none',
                px: 2.2,
                boxShadow: dk ? 'none' : '0 4px 12px rgba(46,125,50,0.25)',
              }}
            >
              + Stock In
            </Button>
          )}
        </Box>
      </Box>

      {/* ─── Metrics Cards Bar ──────────────────────────────────── */}
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: {
            xs: 'repeat(2, 1fr)',
            sm: 'repeat(3, 1fr)',
            md: 'repeat(5, 1fr)',
          },
          gap: 1.5,
          mb: 3,
        }}
      >
        {/* Total Tracked */}
        <Card
          elevation={0}
          sx={{
            borderRadius: 3,
            border: '1px solid',
            borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
            bgcolor: dk ? 'background.paper' : '#FFFFFF',
          }}
        >
          <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
            <Typography variant="caption" color="text.secondary" fontWeight={600}>
              TRACKED ITEMS
            </Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>
              {metrics.totalTracked}
            </Typography>
          </CardContent>
        </Card>

        {/* In Stock */}
        <Card
          elevation={0}
          sx={{
            borderRadius: 3,
            border: '1px solid',
            borderColor: dk ? alpha(theme.palette.success.main, 0.3) : '#C8E6C9',
            bgcolor: dk ? alpha(theme.palette.success.main, 0.1) : '#F1F8E9',
          }}
        >
          <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <InStockIcon sx={{ fontSize: 16, color: theme.palette.success.main }} />
              <Typography
                variant="caption"
                fontWeight={700}
                sx={{ color: theme.palette.success.main }}
              >
                IN STOCK
              </Typography>
            </Box>
            <Typography
              variant="h5"
              fontWeight={800}
              sx={{ color: theme.palette.success.main, mt: 0.5 }}
            >
              {metrics.inStock}
            </Typography>
          </CardContent>
        </Card>

        {/* Low Stock */}
        <Card
          elevation={0}
          sx={{
            borderRadius: 3,
            border: '1px solid',
            borderColor:
              metrics.lowStock > 0
                ? dk
                  ? alpha(theme.palette.warning.main, 0.4)
                  : '#FFE0B2'
                : dk
                ? 'rgba(255,255,255,0.08)'
                : 'rgba(0,0,0,0.08)',
            bgcolor:
              metrics.lowStock > 0
                ? dk
                  ? alpha(theme.palette.warning.main, 0.12)
                  : '#FFF8E1'
                : dk
                ? 'background.paper'
                : '#FFFFFF',
          }}
        >
          <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <WarningIcon sx={{ fontSize: 16, color: theme.palette.warning.main }} />
              <Typography
                variant="caption"
                fontWeight={700}
                sx={{ color: theme.palette.warning.main }}
              >
                LOW STOCK
              </Typography>
            </Box>
            <Typography
              variant="h5"
              fontWeight={800}
              sx={{ color: theme.palette.warning.main, mt: 0.5 }}
            >
              {metrics.lowStock}
            </Typography>
          </CardContent>
        </Card>

        {/* Out of Stock */}
        <Card
          elevation={0}
          sx={{
            borderRadius: 3,
            border: '1px solid',
            borderColor:
              metrics.outOfStock > 0
                ? dk
                  ? alpha(theme.palette.error.main, 0.4)
                  : '#FFCDD2'
                : dk
                ? 'rgba(255,255,255,0.08)'
                : 'rgba(0,0,0,0.08)',
            bgcolor:
              metrics.outOfStock > 0
                ? dk
                  ? alpha(theme.palette.error.main, 0.12)
                  : '#FFEBEE'
                : dk
                ? 'background.paper'
                : '#FFFFFF',
          }}
        >
          <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <OutOfStockIcon sx={{ fontSize: 16, color: theme.palette.error.main }} />
              <Typography
                variant="caption"
                fontWeight={700}
                sx={{ color: theme.palette.error.main }}
              >
                OUT OF STOCK
              </Typography>
            </Box>
            <Typography
              variant="h5"
              fontWeight={800}
              sx={{ color: theme.palette.error.main, mt: 0.5 }}
            >
              {metrics.outOfStock}
            </Typography>
          </CardContent>
        </Card>

        {/* Total Units */}
        <Card
          elevation={0}
          sx={{
            borderRadius: 3,
            border: '1px solid',
            borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
            bgcolor: dk ? 'background.paper' : '#FFFFFF',
          }}
        >
          <CardContent sx={{ p: 2, '&:last-child': { pb: 2 } }}>
            <Typography variant="caption" color="text.secondary" fontWeight={600}>
              TOTAL UNITS ON HAND
            </Typography>
            <Typography variant="h5" fontWeight={800} sx={{ mt: 0.5 }}>
              {metrics.totalUnits.toLocaleString()}
            </Typography>
          </CardContent>
        </Card>
      </Box>

      {/* ─── Search & View Controls Bar ────────────────────────── */}
      <Box
        sx={{
          display: 'flex',
          flexDirection: { xs: 'column', md: 'row' },
          gap: 2,
          alignItems: { xs: 'stretch', md: 'center' },
          justifyContent: 'space-between',
          mb: 2.5,
        }}
      >
        {/* Search Input */}
        <TextField
          placeholder="Search by flower name, SKU, or barcode..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          size="small"
          sx={{
            minWidth: { xs: '100%', md: 360 },
            '& .MuiOutlinedInput-root': {
              borderRadius: 2.5,
              bgcolor: dk ? 'background.paper' : '#FFFFFF',
            },
          }}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon color="action" />
                </InputAdornment>
              ),
              endAdornment: searchQuery ? (
                <InputAdornment position="end">
                  <IconButton size="small" onClick={() => setSearchQuery('')}>
                    <ClearIcon fontSize="small" />
                  </IconButton>
                </InputAdornment>
              ) : null,
            },
          }}
        />

        {/* View Switcher Toggle */}
        <Box sx={{ display: 'flex', gap: 1.5, alignItems: 'center' }}>
          <ToggleButtonGroup
            value={viewLayout}
            exclusive
            onChange={(_, val) => val && setViewLayout(val)}
            size="small"
            sx={{
              bgcolor: dk ? 'background.paper' : '#FFFFFF',
              borderRadius: 2,
              '& .MuiToggleButton-root': {
                px: 1.5,
                py: 0.5,
                borderRadius: 2,
              },
            }}
          >
            <ToggleButton value="cards" aria-label="cards view">
              <GridViewIcon sx={{ fontSize: 18, mr: 0.5 }} />
              Cards
            </ToggleButton>
            <ToggleButton value="table" aria-label="table view">
              <TableViewIcon sx={{ fontSize: 18, mr: 0.5 }} />
              Table
            </ToggleButton>
          </ToggleButtonGroup>
        </Box>
      </Box>

      {/* ─── Stock Status Filter Chips ─────────────────────────── */}
      <Box sx={{ display: 'flex', gap: 1, overflowX: 'auto', pb: 1, mb: 1 }}>
        <Chip
          label={`All Statuses (${items.length})`}
          clickable
          color={statusFilter === 'all' ? 'primary' : 'default'}
          variant={statusFilter === 'all' ? 'filled' : 'outlined'}
          onClick={() => setStatusFilter('all')}
          sx={{ fontWeight: 600, borderRadius: 2 }}
        />
        <Chip
          icon={<InStockIcon sx={{ fontSize: '16px !important' }} />}
          label={`In Stock (${metrics.inStock})`}
          clickable
          color={statusFilter === 'in_stock' ? 'success' : 'default'}
          variant={statusFilter === 'in_stock' ? 'filled' : 'outlined'}
          onClick={() => setStatusFilter('in_stock')}
          sx={{ fontWeight: 600, borderRadius: 2 }}
        />
        <Chip
          icon={<WarningIcon sx={{ fontSize: '16px !important' }} />}
          label={`Low Stock (${metrics.lowStock})`}
          clickable
          color={statusFilter === 'low_stock' ? 'warning' : 'default'}
          variant={statusFilter === 'low_stock' ? 'filled' : 'outlined'}
          onClick={() => setStatusFilter('low_stock')}
          sx={{ fontWeight: 600, borderRadius: 2 }}
        />
        <Chip
          icon={<OutOfStockIcon sx={{ fontSize: '16px !important' }} />}
          label={`Out of Stock (${metrics.outOfStock})`}
          clickable
          color={statusFilter === 'out_of_stock' ? 'error' : 'default'}
          variant={statusFilter === 'out_of_stock' ? 'filled' : 'outlined'}
          onClick={() => setStatusFilter('out_of_stock')}
          sx={{ fontWeight: 600, borderRadius: 2 }}
        />
      </Box>

      {/* ─── Category Filter Chips ─────────────────────────────── */}
      <Box sx={{ display: 'flex', gap: 1, overflowX: 'auto', pb: 1, mb: 3 }}>
        <Chip
          label="All Categories"
          clickable
          variant={selectedCategory === 'all' ? 'filled' : 'outlined'}
          onClick={() => setSelectedCategory('all')}
          sx={{
            fontWeight: 600,
            borderRadius: 2,
            bgcolor: selectedCategory === 'all' ? (dk ? 'grey.800' : 'grey.300') : undefined,
          }}
        />
        {categories.map((cat) => (
          <Chip
            key={cat.id}
            label={cat.name}
            clickable
            variant={selectedCategory === cat.id ? 'filled' : 'outlined'}
            onClick={() => setSelectedCategory(cat.id)}
            sx={{
              fontWeight: 600,
              borderRadius: 2,
              bgcolor: selectedCategory === cat.id ? (dk ? 'grey.800' : 'grey.300') : undefined,
            }}
          />
        ))}
      </Box>

      {/* ─── Main Content Area ─────────────────────────────────── */}
      {error && (
        <Alert severity="error" sx={{ mb: 3, borderRadius: 2 }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box sx={{ display: 'flex', flexDirection: 'column', alignItems: 'center', py: 12, gap: 2 }}>
          <CircularProgress size={44} />
          <Typography variant="body2" color="text.secondary">
            Loading retail inventory...
          </Typography>
        </Box>
      ) : filteredItems.length === 0 ? (
        <Paper
          elevation={0}
          sx={{
            textAlign: 'center',
            py: 10,
            px: 3,
            borderRadius: 3.5,
            border: '1px dashed',
            borderColor: dk ? 'rgba(255,255,255,0.15)' : 'rgba(0,0,0,0.15)',
            bgcolor: 'transparent',
          }}
        >
          <InventoryIcon sx={{ fontSize: 48, color: 'text.secondary', opacity: 0.6, mb: 1 }} />
          <Typography variant="h6" fontWeight={700} color="text.secondary">
            No products match your inventory filters
          </Typography>
          <Typography variant="body2" color="text.disabled" sx={{ mt: 0.5, mb: 2 }}>
            Try changing the search query, category, or stock status filter.
          </Typography>
          <Button
            variant="outlined"
            onClick={() => {
              setSearchQuery('');
              setSelectedCategory('all');
              setStatusFilter('all');
            }}
            sx={{ borderRadius: 2, fontWeight: 600 }}
          >
            Clear Filters
          </Button>
        </Paper>
      ) : viewLayout === 'cards' ? (
        /* ─── Cards Grid View ─── */
        <Box
          sx={{
            display: 'grid',
            gridTemplateColumns: {
              xs: '1fr',
              sm: 'repeat(2, 1fr)',
              md: 'repeat(3, 1fr)',
              lg: 'repeat(4, 1fr)',
            },
            gap: 2.5,
          }}
        >
          {filteredItems.map((item) => (
            <RetailStockCard
              key={item.id}
              item={item}
              currencySymbol={currencySymbol}
              onStockAction={handleOpenStockAction}
              onViewHistory={handleOpenHistory}
            />
          ))}
        </Box>
      ) : (
        /* ─── Compact Table View ─── */
        <TableContainer
          component={Paper}
          elevation={0}
          sx={{
            borderRadius: 3,
            border: '1px solid',
            borderColor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.08)',
            overflow: 'hidden',
          }}
        >
          <Table size="medium">
            <TableHead>
              <TableRow sx={{ bgcolor: dk ? '#222222' : '#F8FAFC' }}>
                <TableCell sx={{ fontWeight: 700 }}>Product Name</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Category</TableCell>
                <TableCell sx={{ fontWeight: 700 }}>SKU / Barcode</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>
                  Stock Quantity
                </TableCell>
                <TableCell sx={{ fontWeight: 700 }}>Status</TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>
                  Min Level
                </TableCell>
                <TableCell align="right" sx={{ fontWeight: 700 }}>
                  Cost
                </TableCell>
                <TableCell align="center" sx={{ fontWeight: 700 }}>
                  Actions
                </TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {filteredItems.map((item) => {
                const status = getStockStatus(item);
                const statusColor =
                  status === 'in_stock'
                    ? 'success'
                    : status === 'low_stock'
                    ? 'warning'
                    : status === 'out_of_stock'
                    ? 'error'
                    : 'default';

                const statusLabel =
                  status === 'in_stock'
                    ? 'In Stock'
                    : status === 'low_stock'
                    ? 'Low Stock'
                    : status === 'out_of_stock'
                    ? 'Out of Stock'
                    : 'Untracked';

                return (
                  <TableRow
                    key={item.id}
                    hover
                    sx={{
                      '&:last-child td, &:last-child th': { border: 0 },
                    }}
                  >
                    <TableCell>
                      <Typography variant="body2" fontWeight={700}>
                        {item.name}
                      </Typography>
                      {item.trackBatch && (
                        <Chip
                          label="Batch Tracked"
                          size="small"
                          color="primary"
                          variant="outlined"
                          sx={{ fontSize: '0.68rem', height: 18, mt: 0.3 }}
                        />
                      )}
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={item.category}
                        size="small"
                        sx={{ fontSize: '0.72rem', height: 20 }}
                      />
                    </TableCell>
                    <TableCell>
                      <Typography variant="caption" display="block" sx={{ fontFamily: 'monospace' }}>
                        {item.sku}
                      </Typography>
                      {item.barcode && (
                        <Typography
                          variant="caption"
                          color="text.secondary"
                          sx={{ fontFamily: 'monospace' }}
                        >
                          {item.barcode}
                        </Typography>
                      )}
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body1" fontWeight={800}>
                        {item.trackInventory ? item.stockQuantity : '—'}{' '}
                        <Typography component="span" variant="caption" color="text.secondary">
                          {item.trackInventory ? item.unitOfMeasure : ''}
                        </Typography>
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Chip
                        label={statusLabel}
                        size="small"
                        color={statusColor as any}
                        sx={{ fontWeight: 700, fontSize: '0.72rem' }}
                      />
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="caption" color="text.secondary">
                        {item.trackInventory
                          ? item.minimumStockLevel > 0
                            ? item.minimumStockLevel
                            : '—'
                          : '—'}
                        {item.trackInventory && item.reorderLevel > 0 && (
                          <span style={{ marginLeft: 6, opacity: 0.7 }}>
                            (Reorder: {item.reorderLevel})
                          </span>
                        )}
                      </Typography>
                    </TableCell>
                    <TableCell align="right">
                      <Typography variant="body2" fontWeight={600}>
                        {currencySymbol}
                        {item.costPrice.toFixed(2)}
                      </Typography>
                    </TableCell>
                    <TableCell align="center">
                      <Box sx={{ display: 'flex', gap: 0.5, justifyContent: 'center' }}>
                        <Tooltip title="Stock In">
                          <span>
                            <IconButton
                              size="small"
                              color="success"
                              disabled={!item.trackInventory}
                              onClick={() => handleOpenStockAction(item, 'purchase')}
                            >
                              <AddIcon fontSize="small" />
                            </IconButton>
                          </span>
                        </Tooltip>
                        <Tooltip title="Stock Out">
                          <span>
                            <IconButton
                              size="small"
                              color="info"
                              disabled={!item.trackInventory || item.stockQuantity <= 0}
                              onClick={() => handleOpenStockAction(item, 'sale')}
                            >
                              <RemoveIcon fontSize="small" />
                            </IconButton>
                          </span>
                        </Tooltip>
                        <Tooltip title="Wastage">
                          <span>
                            <IconButton
                              size="small"
                              color="error"
                              disabled={!item.trackInventory || item.stockQuantity <= 0}
                              onClick={() => handleOpenStockAction(item, 'wastage')}
                            >
                              <WastageIcon fontSize="small" />
                            </IconButton>
                          </span>
                        </Tooltip>
                        <Tooltip title="Adjustment">
                          <span>
                            <IconButton
                              size="small"
                              color="secondary"
                              disabled={!item.trackInventory}
                              onClick={() => handleOpenStockAction(item, 'adjustment')}
                            >
                              <AdjustIcon fontSize="small" />
                            </IconButton>
                          </span>
                        </Tooltip>
                        <Tooltip title="History">
                          <IconButton
                            size="small"
                            onClick={() => handleOpenHistory(item)}
                          >
                            <HistoryIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                      </Box>
                    </TableCell>
                  </TableRow>
                );
              })}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* ─── Modals ────────────────────────────────────────────── */}
      <RetailStockChangeModal
        open={changeModalOpen}
        item={activeItem}
        initialOperation={activeOperation}
        currencySymbol={currencySymbol}
        onClose={() => setChangeModalOpen(false)}
        onSuccess={handleStockChangeSuccess}
      />

      <RetailStockHistoryModal
        open={historyModalOpen}
        item={historyItem}
        currencySymbol={currencySymbol}
        onClose={() => setHistoryModalOpen(false)}
      />

      {/* ─── Toast Feedback ────────────────────────────────────── */}
      <Snackbar
        open={toast.open}
        autoHideDuration={4000}
        onClose={() => setToast((prev) => ({ ...prev, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          severity={toast.severity}
          onClose={() => setToast((prev) => ({ ...prev, open: false }))}
          sx={{ width: '100%', borderRadius: 2 }}
        >
          {toast.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};
