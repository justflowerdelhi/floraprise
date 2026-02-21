/**
 * Barcode Scanner Input
 * Auto-focusing, fast-capture input for barcode scanners
 * Florist POS + ERP SaaS Platform
 */

import { useState, useEffect, useRef, useCallback, forwardRef, useImperativeHandle } from 'react';
import {
  TextField,
  InputAdornment,
  IconButton,
  Box,
  Typography,
  CircularProgress,
  Tooltip,
  useTheme,
  alpha,
} from '@mui/material';
import QrCodeScannerIcon from '@mui/icons-material/QrCodeScanner';
import ClearIcon from '@mui/icons-material/Clear';
import CheckCircleIcon from '@mui/icons-material/CheckCircle';

import { cleanBarcodeInput, isScannerInput } from './BarcodeUtils';

// ============================================
// TYPES
// ============================================

export interface BarcodeScannerInputProps {
  /** Callback when barcode is captured */
  onScan: (barcode: string) => void;
  /** Placeholder text */
  placeholder?: string;
  /** Label text */
  label?: string;
  /** Auto-focus on mount */
  autoFocus?: boolean;
  /** Disabled state */
  disabled?: boolean;
  /** Show loading state */
  loading?: boolean;
  /** Last scan status (for visual feedback) */
  scanStatus?: 'idle' | 'success' | 'error';
  /** Error message to display */
  errorMessage?: string;
  /** Size */
  size?: 'small' | 'medium';
  /** Full width */
  fullWidth?: boolean;
  /** Show clear button */
  showClear?: boolean;
  /** Debounce delay in ms (for keyboard input, scanner is instant) */
  debounceMs?: number;
}

export interface BarcodeScannerInputRef {
  focus: () => void;
  clear: () => void;
  getValue: () => string;
}

// ============================================
// COMPONENT
// ============================================

const BarcodeScannerInput = forwardRef<BarcodeScannerInputRef, BarcodeScannerInputProps>(
  (
    {
      onScan,
      placeholder = 'Scan barcode or type...',
      label = 'Barcode',
      autoFocus = true,
      disabled = false,
      loading = false,
      scanStatus = 'idle',
      errorMessage,
      size = 'small',
      fullWidth = true,
      showClear = true,
      debounceMs = 300,
    },
    ref
  ) => {
    const theme = useTheme();
    const dk = theme.palette.mode === 'dark';
    const inputRef = useRef<HTMLInputElement>(null);
    const debounceTimeoutRef = useRef<number | null>(null);
    const lastInputTimeRef = useRef<number>(0);

    const [value, setValue] = useState('');
    const [isScanning, setIsScanning] = useState(false);

    // Expose methods via ref
    useImperativeHandle(ref, () => ({
      focus: () => inputRef.current?.focus(),
      clear: () => {
        setValue('');
        inputRef.current?.focus();
      },
      getValue: () => value,
    }));

    // Auto-focus on mount
    useEffect(() => {
      if (autoFocus && !disabled) {
        const timer = setTimeout(() => {
          inputRef.current?.focus();
        }, 100);
        return () => clearTimeout(timer);
      }
    }, [autoFocus, disabled]);

    // Handle input change
    const handleChange = useCallback(
      (e: React.ChangeEvent<HTMLInputElement>) => {
        const rawValue = e.target.value;
        const now = Date.now();
        const timeSinceLast = now - lastInputTimeRef.current;
        lastInputTimeRef.current = now;

        setValue(rawValue);

        // Clear any pending debounce
        if (debounceTimeoutRef.current) {
          clearTimeout(debounceTimeoutRef.current);
        }

        // Check if this looks like scanner input (fast, complete barcode)
        if (isScannerInput(rawValue, timeSinceLast)) {
          setIsScanning(true);
          const cleaned = cleanBarcodeInput(rawValue);
          onScan(cleaned);
          setValue('');
          setTimeout(() => setIsScanning(false), 200);
          return;
        }

        // For keyboard input, debounce
        if (rawValue.length >= 3) {
          debounceTimeoutRef.current = window.setTimeout(() => {
            // Don't auto-submit keyboard input - user should press Enter
          }, debounceMs);
        }
      },
      [onScan, debounceMs]
    );

    // Handle Enter key
    const handleKeyDown = useCallback(
      (e: React.KeyboardEvent<HTMLInputElement>) => {
        if (e.key === 'Enter' && value.trim()) {
          e.preventDefault();
          const cleaned = cleanBarcodeInput(value);
          onScan(cleaned);
          setValue('');
        }
      },
      [value, onScan]
    );

    // Handle clear
    const handleClear = useCallback(() => {
      setValue('');
      inputRef.current?.focus();
    }, []);

    // Status icon
    const getStatusIcon = () => {
      if (loading || isScanning) {
        return (
          <CircularProgress
            size={20}
            sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'rgba(0,0,0,0.4)' }}
          />
        );
      }
      if (scanStatus === 'success') {
        return <CheckCircleIcon sx={{ color: theme.palette.success.main, fontSize: 20 }} />;
      }
      return (
        <QrCodeScannerIcon
          sx={{
            color: dk ? 'rgba(255,255,255,0.5)' : 'rgba(0,0,0,0.4)',
            fontSize: 20,
          }}
        />
      );
    };

    // Border color based on status
    const getBorderColor = () => {
      if (scanStatus === 'success') return theme.palette.success.main;
      if (scanStatus === 'error') return theme.palette.error.main;
      if (isScanning) return theme.palette.primary.main;
      return undefined;
    };

    return (
      <Box sx={{ width: fullWidth ? '100%' : 'auto' }}>
        <TextField
          inputRef={inputRef}
          value={value}
          onChange={handleChange}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          label={label}
          size={size}
          fullWidth={fullWidth}
          disabled={disabled || loading}
          error={scanStatus === 'error'}
          helperText={errorMessage}
          slotProps={{
            input: {
              startAdornment: (
                <InputAdornment position="start">
                  {getStatusIcon()}
                </InputAdornment>
              ),
              endAdornment: showClear && value ? (
                <InputAdornment position="end">
                  <Tooltip title="Clear">
                    <IconButton size="small" onClick={handleClear} edge="end">
                      <ClearIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </InputAdornment>
              ) : null,
              sx: {
                fontFamily: 'monospace',
                fontWeight: 600,
                letterSpacing: '0.05em',
              },
            },
          }}
          sx={{
            '& .MuiOutlinedInput-root': {
              borderColor: getBorderColor(),
              transition: 'all 0.2s',
              ...(isScanning && {
                boxShadow: `0 0 0 2px ${alpha(theme.palette.primary.main, 0.25)}`,
              }),
            },
          }}
        />
        {isScanning && (
          <Typography
            variant="caption"
            sx={{
              display: 'block',
              mt: 0.5,
              color: theme.palette.primary.main,
              fontWeight: 600,
            }}
          >
            Scanning...
          </Typography>
        )}
      </Box>
    );
  }
);

BarcodeScannerInput.displayName = 'BarcodeScannerInput';

export default BarcodeScannerInput;
