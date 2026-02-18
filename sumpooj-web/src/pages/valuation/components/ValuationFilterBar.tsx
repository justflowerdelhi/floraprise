/**
 * Valuation Filter Bar — Category, Location, Date, Perishable toggle,
 * Search, Sort, Export CSV, Print
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
  FormControlLabel,
  Switch,
  useTheme,
  alpha,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import PrintIcon from '@mui/icons-material/Print';
import FilterListOffIcon from '@mui/icons-material/FilterListOff';
import SwapVertIcon from '@mui/icons-material/SwapVert';
import SearchIcon from '@mui/icons-material/Search';

import type { ValuationFilterState, ValuationProduct } from '../data/valuation.data';
import {
  CATEGORIES,
  LOCATIONS,
  DEFAULT_VALUATION_FILTERS,
} from '../data/valuation.data';
import { exportCSV, printReport } from '../utils/valuation.utils';

interface Props {
  filters: ValuationFilterState;
  onChange: (f: ValuationFilterState) => void;
  products: ValuationProduct[];
  darkMode: boolean;
}

const ValuationFilterBar = ({ filters, onChange, products, darkMode }: Props) => {
  const theme = useTheme();

  const up = (patch: Partial<ValuationFilterState>) =>
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
    filters.category !== '' ||
    filters.location !== '' ||
    filters.asOfDate !== '' ||
    filters.perishableOnly;

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
          placeholder="Search products…"
          value={filters.search}
          onChange={(e) => up({ search: e.target.value })}
          sx={{ minWidth: 180, flex: '1 1 180px', ...fieldSx }}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  <SearchIcon
                    sx={{ fontSize: 18, color: darkMode ? 'grey.500' : 'grey.400' }}
                  />
                </InputAdornment>
              ),
            },
          }}
        />

        {/* Category */}
        <TextField
          select
          size="small"
          label="Category"
          value={filters.category}
          onChange={(e) => up({ category: e.target.value as ValuationFilterState['category'] })}
          sx={{ minWidth: 165, ...fieldSx }}
        >
          <MenuItem value="">All Categories</MenuItem>
          {CATEGORIES.map((c) => (
            <MenuItem key={c} value={c}>
              {c}
            </MenuItem>
          ))}
        </TextField>

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

        {/* As-of Date */}
        <TextField
          size="small"
          type="date"
          label="Valuation Date"
          value={filters.asOfDate}
          onChange={(e) => up({ asOfDate: e.target.value })}
          sx={{ width: 165, ...fieldSx }}
          slotProps={{ inputLabel: { shrink: true } }}
        />

        {/* Perishable Only */}
        <FormControlLabel
          control={
            <Switch
              size="small"
              checked={filters.perishableOnly}
              onChange={(e) => up({ perishableOnly: e.target.checked })}
              sx={{
                '& .MuiSwitch-switchBase.Mui-checked': {
                  color: '#c62828',
                },
                '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                  backgroundColor: '#c62828',
                },
              }}
            />
          }
          label="Perishable Only"
          sx={{
            '& .MuiFormControlLabel-label': {
              fontSize: '0.78rem',
              fontWeight: 600,
              color: darkMode ? 'grey.400' : 'grey.600',
            },
          }}
        />

        {/* Sort direction */}
        <Tooltip title={`Sort: ${filters.sortDir === 'desc' ? 'Highest first' : 'Lowest first'}`}>
          <IconButton
            onClick={() => up({ sortDir: filters.sortDir === 'desc' ? 'asc' : 'desc' })}
            size="small"
            sx={{
              color: darkMode ? 'grey.400' : 'grey.600',
              backgroundColor: darkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
              '&:hover': {
                backgroundColor: darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
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
              onClick={() => onChange(DEFAULT_VALUATION_FILTERS)}
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

        {/* Spacer */}
        <Box sx={{ flex: 1 }} />

        {/* Export CSV */}
        <Tooltip title="Export to CSV">
          <IconButton
            onClick={() => exportCSV(products)}
            size="small"
            sx={{
              color: darkMode ? 'grey.400' : 'grey.600',
              backgroundColor: darkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
              '&:hover': {
                backgroundColor: darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
              },
            }}
          >
            <FileDownloadIcon sx={{ fontSize: 20 }} />
          </IconButton>
        </Tooltip>

        {/* Print */}
        <Tooltip title="Print report">
          <IconButton
            onClick={printReport}
            size="small"
            sx={{
              color: darkMode ? 'grey.400' : 'grey.600',
              backgroundColor: darkMode ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
              '&:hover': {
                backgroundColor: darkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)',
              },
            }}
          >
            <PrintIcon sx={{ fontSize: 20 }} />
          </IconButton>
        </Tooltip>
      </Box>
    </Paper>
  );
};

export default ValuationFilterBar;
