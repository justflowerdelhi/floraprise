/**
 * Ledger Filter Bar — Product, Date Range, Location, Movement Type, Search, Export
 */

import {
  Box,
  TextField,
  MenuItem,
  Button,
  Paper,
  Tooltip,
  IconButton,
  InputAdornment,
  useTheme,
  alpha,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import FilterListOffIcon from '@mui/icons-material/FilterListOff';
import SwapVertIcon from '@mui/icons-material/SwapVert';
import SearchIcon from '@mui/icons-material/Search';

import type { LedgerFilterState, StockMovement } from '../data/ledger.data';
import {
  PRODUCTS,
  LOCATIONS,
  REFERENCE_TYPES,
  DEFAULT_LEDGER_FILTERS,
} from '../data/ledger.data';
import { exportCSV } from '../utils/ledger.utils';

interface Props {
  filters: LedgerFilterState;
  onChange: (f: LedgerFilterState) => void;
  movements: StockMovement[];
  darkMode: boolean;
}

const LedgerFilterBar = ({ filters, onChange, movements, darkMode }: Props) => {
  const theme = useTheme();

  const up = (patch: Partial<LedgerFilterState>) =>
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

  const hasActive =
    filters.search !== '' ||
    filters.productId !== '' ||
    filters.dateFrom !== '' ||
    filters.dateTo !== '' ||
    filters.location !== '' ||
    filters.referenceType !== '';

  const borderColor = darkMode ? theme.palette.grey[800] : theme.palette.grey[200];

  return (
    <Paper
      elevation={0}
      sx={{
        p: 2,
        borderRadius: 2,
        border: `1px solid ${borderColor}`,
        backgroundColor: darkMode ? alpha(theme.palette.grey[900], 0.85) : '#fff',
      }}
    >
      <Box
        sx={{
          display: 'flex',
          flexWrap: 'wrap',
          gap: 1.5,
          alignItems: 'center',
        }}
      >
        {/* Search */}
        <TextField
          size="small"
          placeholder="Search movements…"
          value={filters.search}
          onChange={(e) => up({ search: e.target.value })}
          sx={{ minWidth: 200, flex: '1 1 200px', ...fieldSx }}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon
                    sx={{
                      fontSize: 18,
                      color: darkMode ? 'grey.500' : 'grey.400',
                    }}
                  />
                </InputAdornment>
              ),
            },
          }}
        />

        {/* Product */}
        <TextField
          select
          size="small"
          label="Product"
          value={filters.productId}
          onChange={(e) => up({ productId: e.target.value })}
          sx={{ minWidth: 180, ...fieldSx }}
        >
          <MenuItem value="">All Products</MenuItem>
          {PRODUCTS.map((p) => (
            <MenuItem key={p.id} value={p.id}>
              {p.name}
            </MenuItem>
          ))}
        </TextField>

        {/* Date From */}
        <TextField
          size="small"
          type="date"
          label="From"
          value={filters.dateFrom}
          onChange={(e) => up({ dateFrom: e.target.value })}
          sx={{ width: 155, ...fieldSx }}
          slotProps={{ inputLabel: { shrink: true } }}
        />

        {/* Date To */}
        <TextField
          size="small"
          type="date"
          label="To"
          value={filters.dateTo}
          onChange={(e) => up({ dateTo: e.target.value })}
          sx={{ width: 155, ...fieldSx }}
          slotProps={{ inputLabel: { shrink: true } }}
        />

        {/* Location */}
        <TextField
          select
          size="small"
          label="Location"
          value={filters.location}
          onChange={(e) => up({ location: e.target.value })}
          sx={{ minWidth: 155, ...fieldSx }}
        >
          <MenuItem value="">All Locations</MenuItem>
          {LOCATIONS.map((l) => (
            <MenuItem key={l} value={l}>
              {l}
            </MenuItem>
          ))}
        </TextField>

        {/* Movement Type */}
        <TextField
          select
          size="small"
          label="Movement Type"
          value={filters.referenceType}
          onChange={(e) => up({ referenceType: e.target.value as LedgerFilterState['referenceType'] })}
          sx={{ minWidth: 150, ...fieldSx }}
        >
          <MenuItem value="">All Types</MenuItem>
          {REFERENCE_TYPES.map((t) => (
            <MenuItem key={t} value={t}>
              {t}
            </MenuItem>
          ))}
        </TextField>

        {/* Sort direction */}
        <Tooltip title={`Sort: ${filters.sortDir === 'desc' ? 'Newest first' : 'Oldest first'}`}>
          <IconButton
            onClick={() =>
              up({ sortDir: filters.sortDir === 'desc' ? 'asc' : 'desc' })
            }
            size="small"
            sx={{
              color: darkMode ? 'grey.400' : 'grey.600',
              backgroundColor: darkMode
                ? 'rgba(255,255,255,0.05)'
                : 'rgba(0,0,0,0.04)',
              '&:hover': {
                backgroundColor: darkMode
                  ? 'rgba(255,255,255,0.1)'
                  : 'rgba(0,0,0,0.08)',
              },
            }}
          >
            <SwapVertIcon sx={{ fontSize: 20 }} />
          </IconButton>
        </Tooltip>

        {/* Reset */}
        {hasActive && (
          <Tooltip title="Reset all filters">
            <Button
              size="small"
              startIcon={<FilterListOffIcon sx={{ fontSize: 16 }} />}
              onClick={() => onChange(DEFAULT_LEDGER_FILTERS)}
              sx={{
                textTransform: 'none',
                fontWeight: 600,
                fontSize: '0.75rem',
                color: darkMode ? 'grey.400' : 'grey.600',
              }}
            >
              Reset
            </Button>
          </Tooltip>
        )}

        {/* Export CSV */}
        <Tooltip title="Export filtered data to CSV">
          <IconButton
            onClick={() => exportCSV(movements)}
            size="small"
            sx={{
              color: darkMode ? 'grey.400' : 'grey.600',
              backgroundColor: darkMode
                ? 'rgba(255,255,255,0.05)'
                : 'rgba(0,0,0,0.04)',
              '&:hover': {
                backgroundColor: darkMode
                  ? 'rgba(255,255,255,0.1)'
                  : 'rgba(0,0,0,0.08)',
              },
            }}
          >
            <FileDownloadIcon sx={{ fontSize: 20 }} />
          </IconButton>
        </Tooltip>
      </Box>
    </Paper>
  );
};

export default LedgerFilterBar;
