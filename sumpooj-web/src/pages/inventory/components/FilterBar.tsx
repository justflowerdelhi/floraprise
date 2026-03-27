/**
 * Filter Bar — Search, filters, sort, export
 */

import {
  Box,
  TextField,
  MenuItem,
  Button,
  InputAdornment,
  useTheme,
  alpha,
  IconButton,
  Tooltip,
  Paper,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material';
import SearchIcon from '@mui/icons-material/Search';
import FilterListOffIcon from '@mui/icons-material/FilterListOff';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import SwapVertIcon from '@mui/icons-material/SwapVert';

import type { FilterState, BatchStatus } from '../data/inventory.data';
import { DEFAULT_FILTERS } from '../data/inventory.data';
import type { InventoryBatch } from '../data/inventory.data';
import { exportCSV } from '../utils/inventory.utils';

interface FilterBarProps {
  filters: FilterState;
  onChange: (f: FilterState) => void;
  batches: InventoryBatch[];
  darkMode: boolean;
  storageLocations: string[];
  suppliers: string[];
  productTypes: string[];
}

const STATUS_OPTIONS: { value: BatchStatus | 'all'; label: string }[] = [
  { value: 'all', label: 'All Status' },
  { value: 'fresh', label: 'Fresh' },
  { value: 'good', label: 'Good (7+ days)' },
  { value: 'warning', label: 'Warning (3-6 days)' },
  { value: 'critical', label: 'Critical (≤2 days)' },
  { value: 'expired', label: 'Expired' },
];

const EXPIRY_OPTIONS = [
  { value: '', label: 'All Expiry' },
  { value: '1', label: 'Today' },
  { value: '3', label: 'Within 3 days' },
  { value: '5', label: 'Within 5 days' },
  { value: '7', label: 'Within 7 days' },
  { value: '14', label: 'Within 14 days' },
];

const SORT_OPTIONS = [
  { value: 'expiryDate', label: 'Expiry Date' },
  { value: 'daysLeft', label: 'Days Left' },
  { value: 'productName', label: 'Product Name' },
  { value: 'value', label: 'Value' },
];

const FilterBar = ({
  filters,
  onChange,
  batches,
  darkMode,
  storageLocations,
  suppliers,
  productTypes,
}: FilterBarProps) => {
  const theme = useTheme();

  const up = (patch: Partial<FilterState>) =>
    onChange({ ...filters, ...patch });

  const fieldSx: SxProps<Theme> = darkMode
    ? {
        '& .MuiOutlinedInput-root': {
          color: '#e0e0e0',
          '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' },
          '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.3)' },
          '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
        },
        '& .MuiInputLabel-root': { color: 'rgba(255,255,255,0.5)' },
        '& .MuiSelect-icon': { color: 'rgba(255,255,255,0.5)' },
      }
    : {};

  const hasActiveFilters =
    filters.search ||
    filters.status !== 'all' ||
    filters.storageLocation ||
    filters.supplier ||
    filters.productType ||
    filters.expiringWithinDays !== null;

  return (
    <Paper
      elevation={0}
      sx={{
        p: 2,
        borderRadius: 2,
        border: `1px solid ${darkMode ? theme.palette.grey[800] : theme.palette.grey[200]}`,
        backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
      }}
    >
      {/* Row 1: Search + Actions */}
      <Box sx={{ display: 'flex', gap: 1.5, mb: 2, flexWrap: 'wrap', alignItems: 'center' }}>
        <TextField
          size="small"
          placeholder="Search product, batch, supplier…"
          value={filters.search}
          onChange={(e) => up({ search: e.target.value })}
          sx={{ flex: 1, minWidth: 220, ...fieldSx }}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon sx={{ fontSize: 20, color: darkMode ? 'grey.500' : 'grey.400' }} />
                </InputAdornment>
              ),
            },
          }}
        />
        <Box sx={{ display: 'flex', gap: 1, ml: 'auto' }}>
          {hasActiveFilters && (
            <Tooltip title="Reset Filters">
              <IconButton
                size="small"
                onClick={() => onChange(DEFAULT_FILTERS)}
                sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
              >
                <FilterListOffIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          )}
          <Tooltip title="Toggle Sort Direction">
            <IconButton
              size="small"
              onClick={() =>
                up({ sortDir: filters.sortDir === 'asc' ? 'desc' : 'asc' })
              }
              sx={{
                color: darkMode ? 'grey.400' : 'grey.600',
                transform: filters.sortDir === 'desc' ? 'scaleY(-1)' : 'none',
                transition: 'transform 0.2s',
              }}
            >
              <SwapVertIcon fontSize="small" />
            </IconButton>
          </Tooltip>
          <Button
            size="small"
            variant="outlined"
            startIcon={<FileDownloadIcon />}
            onClick={() => exportCSV(batches)}
            sx={{
              textTransform: 'none',
              borderColor: darkMode ? 'rgba(255,255,255,0.15)' : undefined,
              color: darkMode ? 'grey.300' : undefined,
              '&:hover': {
                borderColor: darkMode ? 'rgba(255,255,255,0.3)' : undefined,
              },
            }}
          >
            Export CSV
          </Button>
        </Box>
      </Box>

      {/* Row 2: Filter dropdowns */}
      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: {
            xs: '1fr',
            sm: 'repeat(2, 1fr)',
            md: 'repeat(3, 1fr)',
            lg: 'repeat(5, 1fr)',
          },
          gap: 1.5,
        }}
      >
        <TextField
          select
          size="small"
          label="Status"
          value={filters.status}
          onChange={(e) => up({ status: e.target.value as BatchStatus | 'all' })}
          sx={fieldSx}
        >
          {STATUS_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>
              {o.label}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          select
          size="small"
          label="Storage Location"
          value={filters.storageLocation}
          onChange={(e) => up({ storageLocation: e.target.value })}
          sx={fieldSx}
        >
          <MenuItem value="">All Locations</MenuItem>
          {storageLocations.map((l) => (
            <MenuItem key={l} value={l}>
              {l}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          select
          size="small"
          label="Supplier"
          value={filters.supplier}
          onChange={(e) => up({ supplier: e.target.value })}
          sx={fieldSx}
        >
          <MenuItem value="">All Suppliers</MenuItem>
          {suppliers.map((s) => (
            <MenuItem key={s} value={s}>
              {s}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          select
          size="small"
          label="Product Type"
          value={filters.productType}
          onChange={(e) => up({ productType: e.target.value })}
          sx={fieldSx}
        >
          <MenuItem value="">All Types</MenuItem>
          {productTypes.map((t) => (
            <MenuItem key={t} value={t}>
              {t}
            </MenuItem>
          ))}
        </TextField>

        <TextField
          select
          size="small"
          label="Expiring Within"
          value={filters.expiringWithinDays !== null ? String(filters.expiringWithinDays) : ''}
          onChange={(e) =>
            up({
              expiringWithinDays: e.target.value ? Number(e.target.value) : null,
            })
          }
          sx={fieldSx}
        >
          {EXPIRY_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>
              {o.label}
            </MenuItem>
          ))}
        </TextField>
      </Box>

      {/* Sort field selector — compact row */}
      <Box sx={{ mt: 1.5, display: 'flex', alignItems: 'center', gap: 1 }}>
        <TextField
          select
          size="small"
          label="Sort By"
          value={filters.sortField}
          onChange={(e) =>
            up({ sortField: e.target.value as FilterState['sortField'] })
          }
          sx={{ width: 180, ...fieldSx }}
        >
          {SORT_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>
              {o.label}
            </MenuItem>
          ))}
        </TextField>
        {hasActiveFilters && (
          <Button
            size="small"
            onClick={() => onChange(DEFAULT_FILTERS)}
            sx={{
              textTransform: 'none',
              color: darkMode ? 'grey.400' : 'grey.600',
              fontSize: '0.75rem',
            }}
          >
            Reset All Filters
          </Button>
        )}
      </Box>
    </Paper>
  );
};

export default FilterBar;
