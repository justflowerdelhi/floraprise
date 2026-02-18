/**
 * ReorderFilterBar — search, risk, supplier, category dropdowns
 */
import React from 'react';
import {
  Box,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  InputAdornment,
  useTheme,
} from '@mui/material';
import type { SxProps, Theme } from '@mui/material/styles';
import type { SelectChangeEvent } from '@mui/material/Select';
import SearchIcon from '@mui/icons-material/Search';
import type { ReorderFilterState, StockRisk, ProductCategory } from '../data/reorder.data';
import { SUPPLIERS, CATEGORIES } from '../data/reorder.data';
import { RISK_CONFIG } from '../utils/reorder.utils';

interface Props {
  filters: ReorderFilterState;
  onChange: (f: ReorderFilterState) => void;
}

const RISKS: StockRisk[] = ['stockout', 'low', 'optimal', 'overstock'];

const ReorderFilterBar: React.FC<Props> = ({ filters, onChange }) => {
  const theme = useTheme();
  const darkMode = theme.palette.mode === 'dark';

  const fieldSx: SxProps<Theme> = darkMode
    ? {
        '& .MuiOutlinedInput-root': {
          color: '#e0e0e0',
          '& fieldset': { borderColor: 'rgba(255,255,255,0.2)' },
          '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.4)' },
          '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
        },
        '& .MuiInputLabel-root': { color: 'rgba(255,255,255,0.6)' },
        '& .MuiSelect-icon': { color: 'rgba(255,255,255,0.5)' },
      }
    : {};

  const set = (patch: Partial<ReorderFilterState>) =>
    onChange({ ...filters, ...patch });

  return (
    <Box
      sx={{
        display: 'grid',
        gridTemplateColumns: { xs: '1fr', sm: 'repeat(2, 1fr)', md: 'repeat(4, 1fr)' },
        gap: 2,
        mb: 3,
      }}
    >
      {/* Search */}
      <TextField
        size="small"
        label="Search products"
        value={filters.search}
        onChange={(e) => set({ search: e.target.value })}
        slotProps={{
          input: {
            startAdornment: (
              <InputAdornment position="start">
                <SearchIcon sx={{ color: darkMode ? 'rgba(255,255,255,0.5)' : undefined }} />
              </InputAdornment>
            ),
          },
        }}
        sx={fieldSx}
      />

      {/* Risk */}
      <FormControl size="small" sx={fieldSx}>
        <InputLabel>Risk Level</InputLabel>
        <Select
          value={filters.risk}
          label="Risk Level"
          onChange={(e: SelectChangeEvent) =>
            set({ risk: e.target.value as StockRisk | '' })
          }
        >
          <MenuItem value="">All</MenuItem>
          {RISKS.map((r) => (
            <MenuItem key={r} value={r}>
              {RISK_CONFIG[r].label}
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Supplier */}
      <FormControl size="small" sx={fieldSx}>
        <InputLabel>Supplier</InputLabel>
        <Select
          value={filters.supplier}
          label="Supplier"
          onChange={(e: SelectChangeEvent) => set({ supplier: e.target.value })}
        >
          <MenuItem value="">All Suppliers</MenuItem>
          {SUPPLIERS.map((s) => (
            <MenuItem key={s} value={s}>
              {s}
            </MenuItem>
          ))}
        </Select>
      </FormControl>

      {/* Category */}
      <FormControl size="small" sx={fieldSx}>
        <InputLabel>Category</InputLabel>
        <Select
          value={filters.category}
          label="Category"
          onChange={(e: SelectChangeEvent) =>
            set({ category: e.target.value as ProductCategory | '' })
          }
        >
          <MenuItem value="">All Categories</MenuItem>
          {CATEGORIES.map((c) => (
            <MenuItem key={c} value={c}>
              {c}
            </MenuItem>
          ))}
        </Select>
      </FormControl>
    </Box>
  );
};

export default ReorderFilterBar;
