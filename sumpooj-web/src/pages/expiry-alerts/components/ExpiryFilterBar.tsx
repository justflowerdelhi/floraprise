/**
 * Expiry Filter Bar — Days Left, Supplier, Location, Fresh Flowers toggle, Export
 */

import {
  Box,
  TextField,
  MenuItem,
  Button,
  FormControlLabel,
  Switch,
  Paper,
  Tooltip,
  IconButton,
  useTheme,
  alpha,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material';
import FileDownloadIcon from '@mui/icons-material/FileDownload';
import FilterListOffIcon from '@mui/icons-material/FilterListOff';
import SwapVertIcon from '@mui/icons-material/SwapVert';

import type { ExpiryFilterState, ExpiryAlertBatch } from '../data/expiry.data';
import {
  STORAGE_LOCATIONS,
  SUPPLIERS,
  DEFAULT_EXPIRY_FILTERS,
  DAYS_LEFT_OPTIONS,
} from '../data/expiry.data';
import { exportCSV } from '../utils/expiry.utils';

interface Props {
  filters: ExpiryFilterState;
  onChange: (f: ExpiryFilterState) => void;
  batches: ExpiryAlertBatch[];
  darkMode: boolean;
}

const ExpiryFilterBar = ({ filters, onChange, batches, darkMode }: Props) => {
  const theme = useTheme();

  const up = (patch: Partial<ExpiryFilterState>) =>
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
    filters.daysLeftMax !== null ||
    filters.supplier ||
    filters.location ||
    filters.freshFlowersOnly;

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
        {/* Days Left */}
        <TextField
          select
          size="small"
          label="Days Left"
          value={filters.daysLeftMax !== null ? String(filters.daysLeftMax) : ''}
          onChange={(e) =>
            up({ daysLeftMax: e.target.value !== '' ? Number(e.target.value) : null })
          }
          sx={{ minWidth: 155, ...fieldSx }}
        >
          {DAYS_LEFT_OPTIONS.map((o) => (
            <MenuItem key={o.value} value={o.value}>
              {o.label}
            </MenuItem>
          ))}
        </TextField>

        {/* Supplier */}
        <TextField
          select
          size="small"
          label="Supplier"
          value={filters.supplier}
          onChange={(e) => up({ supplier: e.target.value })}
          sx={{ minWidth: 175, ...fieldSx }}
        >
          <MenuItem value="">All Suppliers</MenuItem>
          {SUPPLIERS.map((s) => (
            <MenuItem key={s} value={s}>{s}</MenuItem>
          ))}
        </TextField>

        {/* Location */}
        <TextField
          select
          size="small"
          label="Location"
          value={filters.location}
          onChange={(e) => up({ location: e.target.value })}
          sx={{ minWidth: 175, ...fieldSx }}
        >
          <MenuItem value="">All Locations</MenuItem>
          {STORAGE_LOCATIONS.map((l) => (
            <MenuItem key={l} value={l}>{l}</MenuItem>
          ))}
        </TextField>

        {/* Fresh Flowers Toggle */}
        <FormControlLabel
          control={
            <Switch
              size="small"
              checked={filters.freshFlowersOnly}
              onChange={(e) => up({ freshFlowersOnly: e.target.checked })}
              sx={{
                '& .MuiSwitch-switchBase.Mui-checked': {
                  color: '#d81b60',
                },
                '& .MuiSwitch-switchBase.Mui-checked + .MuiSwitch-track': {
                  backgroundColor: '#d81b60',
                },
              }}
            />
          }
          label="Fresh Flowers Only"
          sx={{
            ml: 0,
            '& .MuiFormControlLabel-label': {
              fontSize: '0.8rem',
              fontWeight: 600,
              color: darkMode ? 'grey.400' : 'grey.700',
            },
          }}
        />

        {/* Spacer */}
        <Box sx={{ flex: 1 }} />

        {/* Actions */}
        {hasActive && (
          <Tooltip title="Reset Filters">
            <IconButton
              size="small"
              onClick={() => onChange(DEFAULT_EXPIRY_FILTERS)}
              sx={{ color: darkMode ? 'grey.400' : 'grey.600' }}
            >
              <FilterListOffIcon fontSize="small" />
            </IconButton>
          </Tooltip>
        )}

        <Tooltip title="Toggle Sort Direction">
          <IconButton
            size="small"
            onClick={() => up({ sortDir: filters.sortDir === 'asc' ? 'desc' : 'asc' })}
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
            fontWeight: 600,
            borderColor: darkMode ? 'rgba(255,255,255,0.15)' : undefined,
            color: darkMode ? 'grey.300' : undefined,
            '&:hover': { borderColor: darkMode ? 'rgba(255,255,255,0.3)' : undefined },
          }}
        >
          Export CSV
        </Button>
      </Box>
    </Paper>
  );
};

export default ExpiryFilterBar;
