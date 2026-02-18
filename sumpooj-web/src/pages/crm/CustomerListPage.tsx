// =============================================================================
// CUSTOMER LIST PAGE - Enhanced CRM Customer Management
// Florist ERP SaaS — CRM & Customer Intelligence
// =============================================================================

import { useState, useMemo } from 'react';
import {
  Box,
  Paper,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  TextField,
  InputAdornment,
  Button,
  IconButton,
  Chip,
  Avatar,
  Menu,
  MenuItem,
  Checkbox,
  FormControlLabel,
  Stack,
  Tooltip,
  Badge,
  Divider,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Grid,
  Select,
  FormControl,
  InputLabel,
} from '@mui/material';
import {
  Search,
  Add,
  FilterList,
  Download,
  Upload,
  MoreVert,
  Phone,
  Email,
  WhatsApp,
  Visibility,
  Edit,
  Star,
  LocalOffer,
  Cake,
  Favorite,
  TrendingUp,
  Warning,
  CheckCircle,
  Clear,
} from '@mui/icons-material';
import type {
  Customer,
  CustomerTagType,
  LoyaltyTier,
  CustomerSearchFilters,
} from './CRMTypes';
import {
  CUSTOMER_TAGS,
  LOYALTY_TIER_CONFIGS,
  formatCurrency,
  daysSince,
  isWithinDays,
  MOCK_CUSTOMERS,
} from './CRMTypes';
import { LoyaltyTierBadge, PointsDisplay } from './LoyaltyComponents';

// -----------------------------------------------------------------------------
// Filter Panel
// -----------------------------------------------------------------------------

interface FilterPanelProps {
  filters: CustomerSearchFilters;
  onFilterChange: (filters: CustomerSearchFilters) => void;
  onClear: () => void;
}

function FilterPanel({ filters, onFilterChange, onClear }: FilterPanelProps) {
  const hasActiveFilters = Boolean(
    filters.tags?.length ||
    filters.loyaltyTiers?.length ||
    filters.minLifetimeValue ||
    filters.hasUpcomingBirthday ||
    filters.hasUpcomingAnniversary ||
    filters.daysSinceLastOrder
  );

  return (
    <Paper sx={{ p: 2, bgcolor: '#1a1a2e', mb: 2 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 2 }}>
        <Typography variant="subtitle2">Filters</Typography>
        {hasActiveFilters && (
          <Button size="small" startIcon={<Clear />} onClick={onClear}>
            Clear All
          </Button>
        )}
      </Box>

      <Grid container spacing={2}>
        {/* Tags Filter */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Typography variant="caption" sx={{ opacity: 0.7, mb: 1, display: 'block' }}>
            Customer Tags
          </Typography>
          <Stack direction="row" flexWrap="wrap" gap={0.5}>
            {Object.values(CUSTOMER_TAGS).slice(0, 6).map((tag) => (
              <Chip
                key={tag.type}
                label={tag.label}
                size="small"
                onClick={() => {
                  const currentTags = filters.tags || [];
                  const newTags = currentTags.includes(tag.type)
                    ? currentTags.filter((t) => t !== tag.type)
                    : [...currentTags, tag.type];
                  onFilterChange({ ...filters, tags: newTags });
                }}
                sx={{
                  bgcolor: filters.tags?.includes(tag.type) ? `${tag.color}30` : 'transparent',
                  color: filters.tags?.includes(tag.type) ? tag.color : 'inherit',
                  border: `1px solid ${filters.tags?.includes(tag.type) ? tag.color : 'rgba(255,255,255,0.2)'}`,
                }}
              />
            ))}
          </Stack>
        </Grid>

        {/* Loyalty Tier Filter */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Typography variant="caption" sx={{ opacity: 0.7, mb: 1, display: 'block' }}>
            Loyalty Tier
          </Typography>
          <Stack direction="row" gap={0.5}>
            {(['SILVER', 'GOLD', 'PLATINUM'] as LoyaltyTier[]).map((tier) => {
              const config = LOYALTY_TIER_CONFIGS[tier];
              return (
                <Chip
                  key={tier}
                  label={config.label}
                  size="small"
                  onClick={() => {
                    const currentTiers = filters.loyaltyTiers || [];
                    const newTiers = currentTiers.includes(tier)
                      ? currentTiers.filter((t) => t !== tier)
                      : [...currentTiers, tier];
                    onFilterChange({ ...filters, loyaltyTiers: newTiers });
                  }}
                  sx={{
                    bgcolor: filters.loyaltyTiers?.includes(tier) ? config.backgroundColor : 'transparent',
                    color: filters.loyaltyTiers?.includes(tier) ? config.color : 'inherit',
                    border: `1px solid ${filters.loyaltyTiers?.includes(tier) ? config.color : 'rgba(255,255,255,0.2)'}`,
                  }}
                />
              );
            })}
          </Stack>
        </Grid>

        {/* Quick Filters */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Typography variant="caption" sx={{ opacity: 0.7, mb: 1, display: 'block' }}>
            Quick Filters
          </Typography>
          <Stack direction="row" gap={0.5}>
            <Chip
              icon={<Cake sx={{ fontSize: 16 }} />}
              label="Birthday Soon"
              size="small"
              onClick={() => onFilterChange({ ...filters, hasUpcomingBirthday: !filters.hasUpcomingBirthday })}
              sx={{
                bgcolor: filters.hasUpcomingBirthday ? 'rgba(233,30,99,0.2)' : 'transparent',
                color: filters.hasUpcomingBirthday ? '#e91e63' : 'inherit',
                border: `1px solid ${filters.hasUpcomingBirthday ? '#e91e63' : 'rgba(255,255,255,0.2)'}`,
              }}
            />
            <Chip
              icon={<Warning sx={{ fontSize: 16 }} />}
              label="At Risk"
              size="small"
              onClick={() => {
                const newDays = filters.daysSinceLastOrder === 60 ? undefined : 60;
                onFilterChange({ ...filters, daysSinceLastOrder: newDays });
              }}
              sx={{
                bgcolor: filters.daysSinceLastOrder ? 'rgba(255,152,0,0.2)' : 'transparent',
                color: filters.daysSinceLastOrder ? '#ff9800' : 'inherit',
                border: `1px solid ${filters.daysSinceLastOrder ? '#ff9800' : 'rgba(255,255,255,0.2)'}`,
              }}
            />
          </Stack>
        </Grid>

        {/* Lifetime Value Filter */}
        <Grid size={{ xs: 12, sm: 6, md: 3 }}>
          <Typography variant="caption" sx={{ opacity: 0.7, mb: 1, display: 'block' }}>
            Min Lifetime Value
          </Typography>
          <TextField
            size="small"
            type="number"
            placeholder="₹0"
            value={filters.minLifetimeValue || ''}
            onChange={(e) => onFilterChange({ ...filters, minLifetimeValue: Number(e.target.value) || undefined })}
            InputProps={{
              startAdornment: <InputAdornment position="start">₹</InputAdornment>,
            }}
            sx={{ width: 150 }}
          />
        </Grid>
      </Grid>
    </Paper>
  );
}

// -----------------------------------------------------------------------------
// Customer Row
// -----------------------------------------------------------------------------

interface CustomerRowProps {
  customer: Customer;
  onView: (id: string) => void;
  onEdit: (id: string) => void;
}

function CustomerRow({ customer, onView, onEdit }: CustomerRowProps) {
  const [menuAnchor, setMenuAnchor] = useState<null | HTMLElement>(null);
  const lastOrderDays = daysSince(customer.lastOrderDate);
  const tierConfig = LOYALTY_TIER_CONFIGS[customer.loyaltyTier];
  const hasBirthdaySoon = isWithinDays(customer.birthday, 7);

  return (
    <TableRow hover>
      <TableCell>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
          <Avatar sx={{ bgcolor: tierConfig.color, width: 36, height: 36, fontSize: 14 }}>
            {customer.name.charAt(0)}
          </Avatar>
          <Box>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <Typography variant="body2" fontWeight={500}>
                {customer.name}
              </Typography>
              {hasBirthdaySoon && (
                <Tooltip title="Birthday in 7 days">
                  <Cake sx={{ fontSize: 16, color: '#e91e63' }} />
                </Tooltip>
              )}
            </Box>
            <Typography variant="caption" sx={{ opacity: 0.6 }}>
              {customer.phone}
            </Typography>
          </Box>
        </Box>
      </TableCell>

      <TableCell>
        <Stack direction="row" spacing={0.5} flexWrap="wrap" sx={{ maxWidth: 200 }}>
          {customer.tags.slice(0, 3).map((tagType) => {
            const tag = CUSTOMER_TAGS[tagType];
            return (
              <Chip
                key={tagType}
                label={tag.label}
                size="small"
                sx={{
                  bgcolor: `${tag.color}20`,
                  color: tag.color,
                  fontSize: 10,
                  height: 20,
                }}
              />
            );
          })}
          {customer.tags.length > 3 && (
            <Chip
              label={`+${customer.tags.length - 3}`}
              size="small"
              sx={{ fontSize: 10, height: 20 }}
            />
          )}
        </Stack>
      </TableCell>

      <TableCell>
        <LoyaltyTierBadge tier={customer.loyaltyTier} size="small" />
      </TableCell>

      <TableCell>
        <PointsDisplay points={customer.loyaltyPoints} size="small" />
      </TableCell>

      <TableCell>
        <Typography variant="body2" fontWeight={500} sx={{ color: '#4caf50' }}>
          {formatCurrency(customer.lifetimeValue)}
        </Typography>
        <Typography variant="caption" sx={{ opacity: 0.6 }}>
          {customer.totalOrders} orders
        </Typography>
      </TableCell>

      <TableCell>
        {lastOrderDays !== null ? (
          <Box>
            <Typography
              variant="body2"
              sx={{
                color: lastOrderDays > 90 ? '#f44336' : lastOrderDays > 60 ? '#ff9800' : 'inherit',
              }}
            >
              {lastOrderDays} days ago
            </Typography>
            {lastOrderDays > 60 && (
              <Chip
                label={lastOrderDays > 90 ? 'Lost' : 'At Risk'}
                size="small"
                sx={{
                  bgcolor: lastOrderDays > 90 ? 'rgba(244,67,54,0.2)' : 'rgba(255,152,0,0.2)',
                  color: lastOrderDays > 90 ? '#f44336' : '#ff9800',
                  fontSize: 10,
                  height: 18,
                  mt: 0.5,
                }}
              />
            )}
          </Box>
        ) : (
          <Typography variant="body2" sx={{ opacity: 0.5 }}>Never</Typography>
        )}
      </TableCell>

      <TableCell align="center">
        {customer.marketingConsent ? (
          <CheckCircle sx={{ color: '#4caf50', fontSize: 20 }} />
        ) : (
          <Clear sx={{ color: '#f44336', fontSize: 20 }} />
        )}
      </TableCell>

      <TableCell>
        <Stack direction="row" spacing={0.5}>
          <Tooltip title="Call">
            <IconButton size="small" sx={{ color: '#4caf50' }}>
              <Phone sx={{ fontSize: 18 }} />
            </IconButton>
          </Tooltip>
          <Tooltip title="WhatsApp">
            <IconButton size="small" sx={{ color: '#25D366' }}>
              <WhatsApp sx={{ fontSize: 18 }} />
            </IconButton>
          </Tooltip>
          <Tooltip title="View Profile">
            <IconButton size="small" onClick={() => onView(customer.id)}>
              <Visibility sx={{ fontSize: 18 }} />
            </IconButton>
          </Tooltip>
          <IconButton size="small" onClick={(e) => setMenuAnchor(e.currentTarget)}>
            <MoreVert sx={{ fontSize: 18 }} />
          </IconButton>
        </Stack>

        <Menu
          anchorEl={menuAnchor}
          open={Boolean(menuAnchor)}
          onClose={() => setMenuAnchor(null)}
        >
          <MenuItem onClick={() => { onView(customer.id); setMenuAnchor(null); }}>
            View Profile
          </MenuItem>
          <MenuItem onClick={() => { onEdit(customer.id); setMenuAnchor(null); }}>
            Edit Customer
          </MenuItem>
          <Divider />
          <MenuItem>Add Tag</MenuItem>
          <MenuItem>Send Message</MenuItem>
        </Menu>
      </TableCell>
    </TableRow>
  );
}

// -----------------------------------------------------------------------------
// Create Customer Dialog
// -----------------------------------------------------------------------------

interface CreateCustomerDialogProps {
  open: boolean;
  onClose: () => void;
  onSave: (customer: Partial<Customer>) => void;
}

function CreateCustomerDialog({ open, onClose, onSave }: CreateCustomerDialogProps) {
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    email: '',
    birthday: '',
    anniversary: '',
    preferredAddress: '',
    notes: '',
    marketingConsent: true,
  });

  const handleSave = () => {
    onSave(formData);
    setFormData({
      name: '',
      phone: '',
      email: '',
      birthday: '',
      anniversary: '',
      preferredAddress: '',
      notes: '',
      marketingConsent: true,
    });
    onClose();
  };

  return (
    <Dialog open={open} onClose={onClose} maxWidth="sm" fullWidth>
      <DialogTitle>Add New Customer</DialogTitle>
      <DialogContent>
        <Grid container spacing={2} sx={{ mt: 1 }}>
          <Grid size={{ xs: 12 }}>
            <TextField
              label="Full Name"
              fullWidth
              required
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Phone"
              fullWidth
              required
              value={formData.phone}
              onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Email"
              fullWidth
              type="email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Birthday"
              fullWidth
              type="date"
              value={formData.birthday}
              onChange={(e) => setFormData({ ...formData, birthday: e.target.value })}
              slotProps={{ inputLabel: { shrink: true } }}
            />
          </Grid>
          <Grid size={{ xs: 12, sm: 6 }}>
            <TextField
              label="Anniversary"
              fullWidth
              type="date"
              value={formData.anniversary}
              onChange={(e) => setFormData({ ...formData, anniversary: e.target.value })}
              slotProps={{ inputLabel: { shrink: true } }}
            />
          </Grid>
          <Grid size={{ xs: 12 }}>
            <TextField
              label="Preferred Address"
              fullWidth
              multiline
              rows={2}
              value={formData.preferredAddress}
              onChange={(e) => setFormData({ ...formData, preferredAddress: e.target.value })}
            />
          </Grid>
          <Grid size={{ xs: 12 }}>
            <TextField
              label="Notes"
              fullWidth
              multiline
              rows={2}
              value={formData.notes}
              onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
            />
          </Grid>
          <Grid size={{ xs: 12 }}>
            <FormControlLabel
              control={
                <Checkbox
                  checked={formData.marketingConsent}
                  onChange={(e) => setFormData({ ...formData, marketingConsent: e.target.checked })}
                />
              }
              label="Customer consents to marketing communications"
            />
          </Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={onClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={handleSave}
          disabled={!formData.name || !formData.phone}
          sx={{ bgcolor: '#fdd835', color: '#000' }}
        >
          Add Customer
        </Button>
      </DialogActions>
    </Dialog>
  );
}

// -----------------------------------------------------------------------------
// Main CustomerListPage Component
// -----------------------------------------------------------------------------

interface CustomerListPageProps {
  onViewCustomer?: (id: string) => void;
}

export default function CustomerListPage({ onViewCustomer }: CustomerListPageProps) {
  const [searchQuery, setSearchQuery] = useState('');
  const [filters, setFilters] = useState<CustomerSearchFilters>({});
  const [showFilters, setShowFilters] = useState(false);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);

  // Filter customers
  const filteredCustomers = useMemo(() => {
    return MOCK_CUSTOMERS.filter((customer) => {
      // Search query
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const matchesSearch =
          customer.name.toLowerCase().includes(query) ||
          customer.phone.includes(query) ||
          customer.email?.toLowerCase().includes(query);
        if (!matchesSearch) return false;
      }

      // Tags filter
      if (filters.tags?.length) {
        const hasTag = filters.tags.some((tag) => customer.tags.includes(tag));
        if (!hasTag) return false;
      }

      // Loyalty tier filter
      if (filters.loyaltyTiers?.length) {
        if (!filters.loyaltyTiers.includes(customer.loyaltyTier)) return false;
      }

      // Lifetime value filter
      if (filters.minLifetimeValue) {
        if (customer.lifetimeValue < filters.minLifetimeValue) return false;
      }

      // Birthday filter
      if (filters.hasUpcomingBirthday) {
        if (!isWithinDays(customer.birthday, 7)) return false;
      }

      // Days since last order
      if (filters.daysSinceLastOrder) {
        const days = daysSince(customer.lastOrderDate);
        if (days === null || days < filters.daysSinceLastOrder) return false;
      }

      return true;
    });
  }, [searchQuery, filters]);

  // Paginated customers
  const paginatedCustomers = filteredCustomers.slice(
    page * rowsPerPage,
    page * rowsPerPage + rowsPerPage
  );

  // Stats
  const stats = useMemo(() => ({
    total: MOCK_CUSTOMERS.length,
    vip: MOCK_CUSTOMERS.filter((c) => c.tags.includes('VIP')).length,
    atRisk: MOCK_CUSTOMERS.filter((c) => {
      const days = daysSince(c.lastOrderDate);
      return days !== null && days > 60;
    }).length,
    birthdaySoon: MOCK_CUSTOMERS.filter((c) => isWithinDays(c.birthday, 7)).length,
  }), []);

  const handleViewCustomer = (id: string) => {
    if (onViewCustomer) {
      onViewCustomer(id);
    } else {
      console.log('View customer:', id);
    }
  };

  const handleEditCustomer = (id: string) => {
    console.log('Edit customer:', id);
  };

  const handleCreateCustomer = (customer: Partial<Customer>) => {
    console.log('Create customer:', customer);
    // TODO: API call
  };

  return (
    <Box sx={{ p: 3, bgcolor: '#0f0f0f', minHeight: '100vh' }}>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', mb: 3 }}>
        <Box>
          <Typography variant="h5" fontWeight={600} sx={{ color: '#fff' }}>
            Customers
          </Typography>
          <Typography variant="body2" sx={{ opacity: 0.7 }}>
            {filteredCustomers.length} customers • {stats.vip} VIP • {stats.atRisk} at risk
          </Typography>
        </Box>
        <Stack direction="row" spacing={1}>
          <Button
            startIcon={<FilterList />}
            onClick={() => setShowFilters(!showFilters)}
            sx={{ color: showFilters ? '#fdd835' : 'inherit' }}
          >
            Filters
          </Button>
          <Button startIcon={<Download />}>
            Export
          </Button>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => setCreateDialogOpen(true)}
            sx={{ bgcolor: '#fdd835', color: '#000' }}
          >
            Add Customer
          </Button>
        </Stack>
      </Box>

      {/* Quick Stats */}
      <Grid container spacing={2} sx={{ mb: 3 }}>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Paper
            sx={{
              p: 2,
              bgcolor: '#1a1a2e',
              cursor: 'pointer',
              '&:hover': { bgcolor: '#252542' },
            }}
            onClick={() => setFilters({})}
          >
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Total Customers</Typography>
            <Typography variant="h5" fontWeight={600}>{stats.total}</Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Paper
            sx={{
              p: 2,
              bgcolor: '#1a1a2e',
              cursor: 'pointer',
              '&:hover': { bgcolor: '#252542' },
            }}
            onClick={() => setFilters({ tags: ['VIP'] })}
          >
            <Typography variant="caption" sx={{ opacity: 0.7 }}>VIP Customers</Typography>
            <Typography variant="h5" fontWeight={600} sx={{ color: '#9c27b0' }}>
              {stats.vip}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Paper
            sx={{
              p: 2,
              bgcolor: '#1a1a2e',
              cursor: 'pointer',
              '&:hover': { bgcolor: '#252542' },
            }}
            onClick={() => setFilters({ daysSinceLastOrder: 60 })}
          >
            <Typography variant="caption" sx={{ opacity: 0.7 }}>At Risk</Typography>
            <Typography variant="h5" fontWeight={600} sx={{ color: '#ff9800' }}>
              {stats.atRisk}
            </Typography>
          </Paper>
        </Grid>
        <Grid size={{ xs: 6, sm: 3 }}>
          <Paper
            sx={{
              p: 2,
              bgcolor: '#1a1a2e',
              cursor: 'pointer',
              '&:hover': { bgcolor: '#252542' },
            }}
            onClick={() => setFilters({ hasUpcomingBirthday: true })}
          >
            <Typography variant="caption" sx={{ opacity: 0.7 }}>Birthday Soon</Typography>
            <Typography variant="h5" fontWeight={600} sx={{ color: '#e91e63' }}>
              {stats.birthdaySoon}
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      {/* Filters Panel */}
      {showFilters && (
        <FilterPanel
          filters={filters}
          onFilterChange={setFilters}
          onClear={() => setFilters({})}
        />
      )}

      {/* Search Bar */}
      <Paper sx={{ bgcolor: '#1a1a2e', mb: 2 }}>
        <Box sx={{ p: 2 }}>
          <TextField
            fullWidth
            size="small"
            placeholder="Search by name, phone, or email..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search sx={{ color: 'rgba(255,255,255,0.5)' }} />
                </InputAdornment>
              ),
            }}
          />
        </Box>

        {/* Customer Table */}
        <TableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Customer</TableCell>
                <TableCell>Tags</TableCell>
                <TableCell>Tier</TableCell>
                <TableCell>Points</TableCell>
                <TableCell>Lifetime Value</TableCell>
                <TableCell>Last Order</TableCell>
                <TableCell align="center">Marketing</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {paginatedCustomers.map((customer) => (
                <CustomerRow
                  key={customer.id}
                  customer={customer}
                  onView={handleViewCustomer}
                  onEdit={handleEditCustomer}
                />
              ))}
              {paginatedCustomers.length === 0 && (
                <TableRow>
                  <TableCell colSpan={8} align="center" sx={{ py: 4, opacity: 0.6 }}>
                    No customers found matching your criteria
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </TableContainer>

        <TablePagination
          component="div"
          count={filteredCustomers.length}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={rowsPerPage}
          onRowsPerPageChange={(e) => {
            setRowsPerPage(parseInt(e.target.value, 10));
            setPage(0);
          }}
          rowsPerPageOptions={[10, 25, 50]}
        />
      </Paper>

      {/* Create Customer Dialog */}
      <CreateCustomerDialog
        open={createDialogOpen}
        onClose={() => setCreateDialogOpen(false)}
        onSave={handleCreateCustomer}
      />
    </Box>
  );
}
