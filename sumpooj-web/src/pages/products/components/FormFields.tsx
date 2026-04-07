/**
 * Reusable Form Components
 * Integrated with React Hook Form and MUI
 */

import { Controller } from 'react-hook-form';
import type { Control } from 'react-hook-form';
import {
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  FormHelperText,
  Switch,
  FormControlLabel,
  Tooltip,
  InputAdornment,
  Chip,
  Box,
  Autocomplete,
  Typography,
} from '@mui/material';
import HelpOutlineIcon from '@mui/icons-material/HelpOutline';
import type { ReactNode } from 'react';
import { useCurrency } from '../../../core/i18n';

// ============================================
// COMMON PROPS
// ============================================

interface CommonFieldProps {
  name: string;
  control: Control<any>;
  label: string;
  required?: boolean;
  disabled?: boolean;
  tooltip?: string;
  darkMode?: boolean;
}

// ============================================
// FORM TEXT FIELD
// ============================================

interface FormTextFieldProps extends CommonFieldProps {
  type?: 'text' | 'number' | 'email' | 'tel';
  multiline?: boolean;
  rows?: number;
  placeholder?: string;
  startAdornment?: ReactNode;
  endAdornment?: ReactNode;
  maxLength?: number;
  autoFocus?: boolean;
}

export const FormTextField = ({
  name,
  control,
  label,
  required = false,
  disabled = false,
  tooltip,
  type = 'text',
  multiline = false,
  rows = 1,
  placeholder,
  startAdornment,
  endAdornment,
  maxLength,
  autoFocus = false,
  darkMode = false,
}: FormTextFieldProps) => {
  return (
    <Controller
      name={name}
      control={control}
      render={({ field, fieldState: { error } }) => (
        <TextField
          {...field}
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {label}
              {required && <span style={{ color: '#e57373' }}>*</span>}
              {tooltip && (
                <Tooltip title={tooltip} arrow placement="top">
                  <HelpOutlineIcon 
                    sx={{ 
                      fontSize: 16, 
                      color: darkMode ? 'grey.500' : 'grey.400',
                      cursor: 'help',
                    }} 
                  />
                </Tooltip>
              )}
            </Box>
          }
          type={type}
          fullWidth
          multiline={multiline}
          rows={rows}
          placeholder={placeholder}
          disabled={disabled}
          error={!!error}
          helperText={error?.message}
          autoFocus={autoFocus}
          value={field.value ?? ''}
          onChange={(e) => {
            const value = type === 'number' 
              ? (e.target.value === '' ? '' : parseFloat(e.target.value))
              : e.target.value;
            field.onChange(value);
          }}
          InputProps={{
            startAdornment: startAdornment ? (
              <InputAdornment position="start">{startAdornment}</InputAdornment>
            ) : undefined,
            endAdornment: endAdornment ? (
              <InputAdornment position="end">{endAdornment}</InputAdornment>
            ) : undefined,
          }}
          inputProps={{
            maxLength,
          }}
          sx={{
            '& .MuiOutlinedInput-root': {
              backgroundColor: darkMode ? 'grey.900' : 'white',
              ...(darkMode && {
                color: 'grey.100',
                '& fieldset': { borderColor: 'grey.700' },
                '&:hover fieldset': { borderColor: 'grey.500' },
                '&.Mui-focused fieldset': { borderColor: 'primary.main' },
              }),
            },
            ...(darkMode && {
              '& .MuiInputLabel-root': { color: 'grey.400' },
              '& .MuiInputLabel-root.Mui-focused': { color: 'primary.light' },
              '& .MuiInputBase-input': { color: 'grey.100' },
              '& .MuiInputBase-input::placeholder': { color: 'grey.600', opacity: 1 },
              '& .MuiInputAdornment-root': { color: 'grey.500' },
            }),
          }}
        />
      )}
    />
  );
};

// ============================================
// FORM CURRENCY FIELD
// ============================================

interface FormCurrencyFieldProps extends CommonFieldProps {
  placeholder?: string;
}

export const FormCurrencyField = ({
  name,
  control,
  label,
  required = false,
  disabled = false,
  tooltip,
  placeholder,
  darkMode = false,
}: FormCurrencyFieldProps) => {
  const { currencySymbol } = useCurrency();

  return (
    <Controller
      name={name}
      control={control}
      render={({ field, fieldState: { error } }) => (
        <TextField
          {...field}
          label={
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {label}
              {required && <span style={{ color: '#e57373' }}>*</span>}
              {tooltip && (
                <Tooltip title={tooltip} arrow placement="top">
                  <HelpOutlineIcon 
                    sx={{ fontSize: 16, color: 'grey.400', cursor: 'help' }} 
                  />
                </Tooltip>
              )}
            </Box>
          }
          type="number"
          fullWidth
          placeholder={placeholder}
          disabled={disabled}
          error={!!error}
          helperText={error?.message}
          value={field.value ?? ''}
          onChange={(e) => {
            const value = e.target.value === '' ? '' : parseFloat(e.target.value);
            field.onChange(value);
          }}
          InputProps={{
            startAdornment: <InputAdornment position="start">{currencySymbol}</InputAdornment>,
          }}
          inputProps={{
            min: 0,
            step: 0.01,
          }}
          sx={{
            '& .MuiOutlinedInput-root': {
              backgroundColor: darkMode ? 'grey.900' : 'white',
              ...(darkMode && {
                color: 'grey.100',
                '& fieldset': { borderColor: 'grey.700' },
                '&:hover fieldset': { borderColor: 'grey.500' },
                '&.Mui-focused fieldset': { borderColor: 'primary.main' },
              }),
            },
            ...(darkMode && {
              '& .MuiInputLabel-root': { color: 'grey.400' },
              '& .MuiInputLabel-root.Mui-focused': { color: 'primary.light' },
              '& .MuiInputBase-input': { color: 'grey.100' },
              '& .MuiInputBase-input::placeholder': { color: 'grey.600', opacity: 1 },
              '& .MuiInputAdornment-root': { color: 'grey.500' },
            }),
          }}
        />
      )}
    />
  );
};

// ============================================
// FORM SELECT
// ============================================

interface SelectOption {
  value: string;
  label: string;
}

interface FormSelectProps extends CommonFieldProps {
  options: readonly SelectOption[];
  placeholder?: string;
}

export const FormSelect = ({
  name,
  control,
  label,
  options,
  required = false,
  disabled = false,
  tooltip,
  placeholder,
  darkMode = false,
}: FormSelectProps) => {
  return (
    <Controller
      name={name}
      control={control}
      render={({ field, fieldState: { error } }) => (
        <FormControl fullWidth error={!!error} disabled={disabled}
          sx={darkMode ? {
            '& .MuiInputLabel-root': { color: 'grey.400' },
            '& .MuiInputLabel-root.Mui-focused': { color: 'primary.light' },
          } : {}}
        >
          <InputLabel>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              {label}
              {required && <span style={{ color: '#e57373' }}>*</span>}
            </Box>
          </InputLabel>
          <Select
            {...field}
            label={label}
            value={field.value ?? ''}
            sx={{
              backgroundColor: darkMode ? 'grey.900' : 'white',
              ...(darkMode && {
                color: 'grey.100',
                '& fieldset': { borderColor: 'grey.700' },
                '&:hover fieldset': { borderColor: 'grey.500' },
                '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                '& .MuiSvgIcon-root': { color: 'grey.400' },
              }),
            }}
          >
            {placeholder && (
              <MenuItem value="" disabled>
                <em>{placeholder}</em>
              </MenuItem>
            )}
            {options.map((option) => (
              <MenuItem key={option.value} value={option.value}>
                {option.label}
              </MenuItem>
            ))}
          </Select>
          {error && <FormHelperText>{error.message}</FormHelperText>}
          {tooltip && !error && (
            <FormHelperText sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <HelpOutlineIcon sx={{ fontSize: 14 }} />
              {tooltip}
            </FormHelperText>
          )}
        </FormControl>
      )}
    />
  );
};

// ============================================
// FORM MULTI SELECT (WITH CHIPS)
// ============================================

interface FormMultiSelectProps extends CommonFieldProps {
  options: readonly SelectOption[];
}

export const FormMultiSelect = ({
  name,
  control,
  label,
  options,
  required = false,
  disabled = false,
  tooltip,
  darkMode = false,
}: FormMultiSelectProps) => {
  return (
    <Controller
      name={name}
      control={control}
      render={({ field, fieldState: { error } }) => (
        <FormControl fullWidth error={!!error} disabled={disabled}>
          <Autocomplete
            multiple
            options={options}
            getOptionLabel={(option) => 
              typeof option === 'string' 
                ? options.find(o => o.value === option)?.label || option
                : option.label
            }
            value={
              (field.value || []).map((v: string) => 
                options.find(o => o.value === v) || { value: v, label: v }
              )
            }
            onChange={(_, newValue) => {
              field.onChange(newValue.map((v: SelectOption) => v.value));
            }}
            renderTags={(value, getTagProps) =>
              value.map((option: SelectOption, index: number) => (
                <Chip
                  label={option.label}
                  size="small"
                  {...getTagProps({ index })}
                  key={option.value}
                  sx={{
                    backgroundColor: darkMode ? 'primary.dark' : 'primary.light',
                    color: darkMode ? 'white' : 'primary.dark',
                  }}
                />
              ))
            }
            renderInput={(params) => (
              <TextField
                {...params}
                label={
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                    {label}
                    {required && <span style={{ color: '#e57373' }}>*</span>}
                    {tooltip && (
                      <Tooltip title={tooltip} arrow placement="top">
                        <HelpOutlineIcon 
                          sx={{ fontSize: 16, color: 'grey.400', cursor: 'help' }} 
                        />
                      </Tooltip>
                    )}
                  </Box>
                }
                error={!!error}
                helperText={error?.message}
              />
            )}
            sx={{
              '& .MuiOutlinedInput-root': {
                backgroundColor: darkMode ? 'grey.900' : 'white',
                ...(darkMode && {
                  color: 'grey.100',
                  '& fieldset': { borderColor: 'grey.700' },
                  '&:hover fieldset': { borderColor: 'grey.500' },
                  '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                }),
              },
              ...(darkMode && {
                '& .MuiInputLabel-root': { color: 'grey.400' },
                '& .MuiInputLabel-root.Mui-focused': { color: 'primary.light' },
                '& .MuiInputBase-input': { color: 'grey.100' },
              }),
            }}
          />
        </FormControl>
      )}
    />
  );
};

// ============================================
// FORM SWITCH
// ============================================

interface FormSwitchProps extends CommonFieldProps {
  helperText?: string;
}

export const FormSwitch = ({
  name,
  control,
  label,
  disabled = false,
  tooltip,
  helperText,
  darkMode = false,
}: FormSwitchProps) => {
  return (
    <Controller
      name={name}
      control={control}
      render={({ field }) => (
        <Box>
          <FormControlLabel
            control={
              <Switch
                {...field}
                checked={field.value ?? false}
                disabled={disabled}
                color="primary"
              />
            }
            label={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
                <Typography variant="body2">{label}</Typography>
                {tooltip && (
                  <Tooltip title={tooltip} arrow placement="top">
                    <HelpOutlineIcon 
                      sx={{ 
                        fontSize: 16, 
                        color: darkMode ? 'grey.500' : 'grey.400',
                        cursor: 'help',
                      }} 
                    />
                  </Tooltip>
                )}
              </Box>
            }
          />
          {helperText && (
            <Typography variant="caption" color="text.secondary" sx={{ ml: 6 }}>
              {helperText}
            </Typography>
          )}
        </Box>
      )}
    />
  );
};

// ============================================
// FORM TAG INPUT
// ============================================

interface FormTagInputProps extends CommonFieldProps {
  suggestions?: string[];
  placeholder?: string;
}

export const FormTagInput = ({
  name,
  control,
  label,
  suggestions = [],
  placeholder = 'Type and press Enter to add tags',
  disabled = false,
  darkMode = false,
}: FormTagInputProps) => {
  return (
    <Controller
      name={name}
      control={control}
      render={({ field, fieldState: { error } }) => (
        <Autocomplete
          multiple
          freeSolo
          options={suggestions}
          value={field.value || []}
          onChange={(_, newValue) => {
            field.onChange(newValue);
          }}
          disabled={disabled}
          renderTags={(value: string[], getTagProps) =>
            value.map((option: string, index: number) => (
              <Chip
                label={option}
                size="small"
                {...getTagProps({ index })}
                key={option}
                sx={{
                  backgroundColor: darkMode ? 'secondary.dark' : 'secondary.light',
                  color: darkMode ? 'white' : 'secondary.dark',
                }}
              />
            ))
          }
          renderInput={(params) => (
            <TextField
              {...params}
              label={label}
              placeholder={placeholder}
              error={!!error}
              helperText={error?.message || 'Press Enter after each tag'}
              sx={{
                '& .MuiOutlinedInput-root': {
                  backgroundColor: darkMode ? 'grey.900' : 'white',
                  ...(darkMode && {
                    color: 'grey.100',
                    '& fieldset': { borderColor: 'grey.700' },
                    '&:hover fieldset': { borderColor: 'grey.500' },
                    '&.Mui-focused fieldset': { borderColor: 'primary.main' },
                  }),
                },
                ...(darkMode && {
                  '& .MuiInputLabel-root': { color: 'grey.400' },
                  '& .MuiInputLabel-root.Mui-focused': { color: 'primary.light' },
                  '& .MuiInputBase-input': { color: 'grey.100' },
                }),
              }}
            />
          )}
        />
      )}
    />
  );
};

export default {
  FormTextField,
  FormCurrencyField,
  FormSelect,
  FormMultiSelect,
  FormSwitch,
  FormTagInput,
};
