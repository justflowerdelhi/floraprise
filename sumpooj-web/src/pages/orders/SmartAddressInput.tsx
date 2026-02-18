/**
 * SmartAddressInput.tsx — Google Places Autocomplete Address Input
 * 
 * Single-field address input with:
 * - Google Places Autocomplete
 * - Auto-extraction of structured address components
 * - Automatic delivery zone matching
 * - Inline validation and feedback
 * 
 * Minimal clicks, maximum intelligence.
 */

import React, { useRef, useEffect, useState, useCallback, useMemo } from 'react';
import {
  TextField,
  Box,
  Alert,
  Chip,
  CircularProgress,
  IconButton,
  MenuItem,
  useTheme,
  alpha,
} from '@mui/material';
import {
  LocationOn as LocationIcon,
  CheckCircle as CheckIcon,
  Map as MapIcon,
} from '@mui/icons-material';
import type { DeliveryAddress, DeliveryZone } from './DeliveryZoneTypes';
import { MOCK_DELIVERY_ZONES } from './DeliveryZoneTypes';
import { fmtCurrency } from '../cart/CartUtils';
import { parseGooglePlaceResult, validateDeliveryAddress, extractZipFromString, findDeliveryZone } from './DeliveryZoneUtils';

// ─── Component Props ────────────────────────────────────────

interface SmartAddressInputProps {
  value: Partial<DeliveryAddress> | null;
  onChange: (address: Partial<DeliveryAddress> | null) => void;
  label?: string;
  required?: boolean;
  disabled?: boolean;
  helperText?: string;
  error?: boolean;
  onValidationChange?: (isValid: boolean, errors: string[]) => void;
}

// ─── Component ─────────────────────────────────────────────

export default function SmartAddressInput({
  value,
  onChange,
  label = 'Delivery Address',
  required = false,
  disabled = false,
  helperText,
  error,
  onValidationChange,
}: SmartAddressInputProps) {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  
  const inputRef = useRef<HTMLInputElement>(null);
  const autocompleteRef = useRef<any>(null); // google.maps.places.Autocomplete when API loaded
  
  const [inputValue, setInputValue] = useState(value?.fullAddress || '');
  const [isLoading, setIsLoading] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);

  const zones = useMemo(
    () => MOCK_DELIVERY_ZONES.filter((zone) => zone.isServiceable),
    [],
  );
  
  // Initialize Google Places Autocomplete
  useEffect(() => {
    if (!inputRef.current || autocompleteRef.current) return;
    
    // Check if Google Maps API is loaded
    if (typeof (window as any).google === 'undefined' || !(window as any).google.maps?.places) {
      console.warn('Google Maps API not loaded. SmartAddressInput will work with basic text input.');
      return;
    }
    
    try {
      const google = (window as any).google;
      autocompleteRef.current = new google.maps.places.Autocomplete(inputRef.current, {
        fields: ['address_components', 'formatted_address', 'geometry', 'place_id'],
        types: ['address'],
      });
      
      autocompleteRef.current.addListener('place_changed', handlePlaceSelect);
    } catch (err) {
      console.error('Failed to initialize Google Places Autocomplete:', err);
    }
    
    return () => {
      if (autocompleteRef.current && (window as any).google) {
        (window as any).google.maps.event.clearInstanceListeners(autocompleteRef.current);
      }
    };
  }, []);
  
  // Handle place selection from autocomplete
  const handlePlaceSelect = useCallback(() => {
    if (!autocompleteRef.current) return;
    
    setIsLoading(true);
    
    const place = autocompleteRef.current.getPlace();
    
    if (!place.geometry) {
      setIsLoading(false);
      return;
    }
    
    const parsedAddress = parseGooglePlaceResult(place);
    
    // Validate the parsed address
    const errors = validateDeliveryAddress(parsedAddress);
    setValidationErrors(errors);
    
    if (onValidationChange) {
      onValidationChange(errors.length === 0, errors);
    }
    
    onChange(parsedAddress);
    setInputValue(parsedAddress.fullAddress || '');
    setIsLoading(false);
  }, [onChange, onValidationChange]);
  
  // Handle manual input (fallback when Places API unavailable)
  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    setInputValue(newValue);
    
    // If user clears the input, reset the address
    if (!newValue) {
      onChange(null);
      setValidationErrors([]);
      if (onValidationChange) {
        onValidationChange(false, ['Address is required']);
      }
    }
  };
  
  // Handle blur - finalize manual text entry as basic address
  const handleBlur = useCallback(() => {
    const trimmedValue = inputValue.trim();
    
    // If there's text but no structured address yet, create a basic one
    if (trimmedValue && !value?.fullAddress) {
      const zipCode = extractZipFromString(trimmedValue);
      const zone = zipCode ? findDeliveryZone(zipCode) : null;
      
      const basicAddress: Partial<DeliveryAddress> = {
        fullAddress: trimmedValue,
        street: trimmedValue,
        city: '',
        state: '',
        zipCode: zipCode,
        country: '',
        latitude: 0,
        longitude: 0,
        deliveryZone: zone || undefined,
      };

      const errors = validateDeliveryAddress(basicAddress);
      setValidationErrors(errors);
      
      onChange(basicAddress);
      
      if (onValidationChange) {
        onValidationChange(errors.length === 0, errors);
      }
    }
  }, [inputValue, value, onChange, onValidationChange]);
  
  // Open Google Maps with the address
  const handleViewOnMap = () => {
    if (!value?.latitude || !value?.longitude) return;
    
    const url = `https://www.google.com/maps?q=${value.latitude},${value.longitude}`;
    window.open(url, '_blank');
  };
  
  // Determine validation state
  const hasAddress = !!value?.fullAddress;
  const hasZone = !!value?.deliveryZone;
  const isValid = hasAddress && hasZone && validationErrors.length === 0;
  const showZoneSelect = hasAddress && !hasZone && zones.length > 0;

  const handleZoneSelect = (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!value?.fullAddress) return;
    const zone = zones.find((z) => z.id === event.target.value) as DeliveryZone | undefined;
    if (!zone) return;
    onChange({
      ...value,
      deliveryZone: zone,
    });
    setValidationErrors([]);
    if (onValidationChange) {
      onValidationChange(true, []);
    }
  };
  
  return (
    <Box>
      <TextField
        inputRef={inputRef}
        fullWidth
        required={required}
        disabled={disabled}
        label={label}
        value={inputValue}
        onChange={handleInputChange}
        onBlur={handleBlur}
        placeholder="Start typing address..."
        error={error}
        helperText={helperText}
        slotProps={{
          input: {
            startAdornment: (
              <LocationIcon
                sx={{
                  mr: 1,
                  fontSize: 20,
                  color: isValid ? theme.palette.success.main : 'text.secondary',
                }}
              />
            ),
            endAdornment: isLoading ? (
              <CircularProgress size={20} />
            ) : hasAddress && value?.latitude && value?.longitude ? (
              <IconButton size="small" onClick={handleViewOnMap} title="View on Map">
                <MapIcon fontSize="small" />
              </IconButton>
            ) : null,
          },
        }}
        sx={{
          '& .MuiOutlinedInput-root': dk
            ? {
                color: '#e0e0e0',
                '& fieldset': { borderColor: 'rgba(255,255,255,0.15)' },
                '&:hover fieldset': { borderColor: 'rgba(255,255,255,0.3)' },
                '&.Mui-focused fieldset': { borderColor: theme.palette.primary.main },
              }
            : {},
        }}
      />
      
      {/* Delivery Zone Info */}
      {hasAddress && hasZone && value?.deliveryZone && (
        <Alert
          icon={<CheckIcon />}
          severity="success"
          sx={{
            mt: 1.5,
            py: 0.5,
            bgcolor: alpha(theme.palette.success.main, dk ? 0.15 : 0.1),
            '& .MuiAlert-icon': { fontSize: 18 },
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, flexWrap: 'wrap' }}>
            <strong>
              Delivery Zone: {value.deliveryZone.name} - {fmtCurrency(value.deliveryZone.deliveryFee)}
            </strong>
            {value.city && (
              <Chip
                label={`${value.city}, ${value.state}`}
                size="small"
                sx={{
                  height: 20,
                  fontSize: '0.7rem',
                  bgcolor: alpha(theme.palette.success.main, 0.2),
                  color: theme.palette.success.main,
                }}
              />
            )}
          </Box>
        </Alert>
      )}

      {/* Zone Selection (fallback) */}
      {showZoneSelect && (
        <TextField
          select
          fullWidth
          size="small"
          label="Select Delivery Zone"
          value={value?.deliveryZone?.id ?? ''}
          onChange={handleZoneSelect}
          sx={{ mt: 1.5 }}
          SelectProps={{ displayEmpty: true }}
        >
          <MenuItem value="">Select Delivery Zone</MenuItem>
          {zones.map((zone) => (
            <MenuItem key={zone.id} value={zone.id}>
              {zone.name} - {fmtCurrency(zone.deliveryFee)}
            </MenuItem>
          ))}
        </TextField>
      )}

      {/* No Zones Configured */}
      {hasAddress && zones.length === 0 && (
        <Alert
          severity="info"
          sx={{
            mt: 1.5,
            py: 0.5,
            bgcolor: alpha(theme.palette.info.main, dk ? 0.15 : 0.1),
            '& .MuiAlert-icon': { fontSize: 18 },
          }}
        >
          No delivery zones configured for this location
        </Alert>
      )}
      
      {/* Address Components (for debugging - can be hidden in production) */}
      {hasAddress && value?.street && (
        <Box
          sx={{
            mt: 1,
            p: 1,
            bgcolor: dk ? alpha(theme.palette.grey[800], 0.3) : alpha(theme.palette.grey[300], 0.3),
            borderRadius: 1,
            fontSize: '0.75rem',
          }}
        >
          <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
            {value.street && <Chip label={value.street} size="small" sx={{ height: 20, fontSize: '0.7rem' }} />}
            {value.city && <Chip label={value.city} size="small" sx={{ height: 20, fontSize: '0.7rem' }} />}
            {value.state && <Chip label={value.state} size="small" sx={{ height: 20, fontSize: '0.7rem' }} />}
            {value.zipCode && (
              <Chip
                label={`ZIP: ${value.zipCode}`}
                size="small"
                sx={{
                  height: 20,
                  fontSize: '0.7rem',
                  bgcolor: alpha(theme.palette.primary.main, 0.2),
                  color: theme.palette.primary.main,
                }}
              />
            )}
          </Box>
        </Box>
      )}
    </Box>
  );
}
