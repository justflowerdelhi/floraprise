/**
 * LocationSwitcher.tsx — Multi-Location Selector Component
 *
 * Features:
 * - Dropdown to switch between locations
 * - Shows current location in header
 * - Role-based access (Admin/Manager can switch freely)
 * - Staff see only assigned location(s)
 */
import React, { useState } from 'react';
import {
  Box,
  Typography,
  Menu,
  MenuItem,
  Chip,
  alpha,
  useTheme,
  ListItemIcon,
  ListItemText,
  Divider,
  Badge,
} from '@mui/material';
import {
  Store as StoreIcon,
  ExpandMore as ExpandIcon,
  Check as CheckIcon,
  AllInclusive as AllIcon,
  Place as PlaceIcon,
} from '@mui/icons-material';
import { useLocation } from './LocationContext';
import { getLocationShortName, LOCATION_CONFIG } from './LocationTypes';

// ─── Location Switcher Component ────────────────────────────

export const LocationSwitcher: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const {
    currentLocation,
    currentLocationId,
    isAllLocations,
    accessibleLocations,
    canSwitchLocation,
    canViewAllLocations,
    setCurrentLocationId,
  } = useLocation();

  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    if (canSwitchLocation) {
      setAnchorEl(event.currentTarget);
    }
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleSelectLocation = (locationId: string) => {
    setCurrentLocationId(locationId);
    handleClose();
  };

  // Display name for current selection
  const displayName = isAllLocations
    ? LOCATION_CONFIG.ALL_LOCATIONS_LABEL
    : currentLocation
    ? getLocationShortName(currentLocation)
    : 'Select Location';

  // If only one location and can't switch, show simpler view
  if (!canSwitchLocation && accessibleLocations.length <= 1) {
    return (
      <Box
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          px: 1.5,
          py: 0.75,
          borderRadius: 2,
          bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
        }}
      >
        <StoreIcon sx={{ fontSize: 18, color: '#fdd835' }} />
        <Typography variant="body2" sx={{ fontWeight: 600, color: dk ? '#fff' : 'text.primary' }}>
          {displayName}
        </Typography>
      </Box>
    );
  }

  return (
    <>
      <Box
        onClick={handleClick}
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 1,
          px: 1.5,
          py: 0.75,
          borderRadius: 2,
          cursor: 'pointer',
          transition: 'all 0.2s',
          bgcolor: dk ? 'rgba(255,255,255,0.03)' : 'rgba(0,0,0,0.02)',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
          '&:hover': {
            bgcolor: dk ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.04)',
            borderColor: '#fdd835',
          },
        }}
      >
        <Badge
          color="success"
          variant="dot"
          invisible={!currentLocation?.isActive && !isAllLocations}
          sx={{
            '& .MuiBadge-badge': {
              top: 4,
              right: 4,
            },
          }}
        >
          <StoreIcon sx={{ fontSize: 20, color: '#fdd835' }} />
        </Badge>
        <Box sx={{ display: { xs: 'none', sm: 'block' }, minWidth: 80 }}>
          <Typography
            variant="body2"
            sx={{
              fontWeight: 600,
              lineHeight: 1.2,
              color: dk ? '#fff' : 'text.primary',
              maxWidth: 120,
              overflow: 'hidden',
              textOverflow: 'ellipsis',
              whiteSpace: 'nowrap',
            }}
          >
            {displayName}
          </Typography>
          {!isAllLocations && currentLocation && (
            <Typography
              variant="caption"
              sx={{
                color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
                fontSize: '0.65rem',
              }}
            >
              {currentLocation.code}
            </Typography>
          )}
        </Box>
        <ExpandIcon
          sx={{
            fontSize: 18,
            color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary',
            transition: 'transform 0.2s',
            transform: open ? 'rotate(180deg)' : 'rotate(0deg)',
          }}
        />
      </Box>

      {/* Dropdown Menu */}
      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
        PaperProps={{
          sx: {
            mt: 1,
            minWidth: 240,
            bgcolor: dk ? '#1a1a2e' : '#fff',
            border: `1px solid ${dk ? 'rgba(255,255,255,0.06)' : '#e0e0e0'}`,
            boxShadow: dk
              ? '0 8px 32px rgba(0,0,0,0.4)'
              : '0 4px 20px rgba(0,0,0,0.1)',
          },
        }}
        transformOrigin={{ horizontal: 'left', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'left', vertical: 'bottom' }}
      >
        {/* All Locations Option (Admin only) */}
        {canViewAllLocations && (
          <>
            <MenuItem
              onClick={() => handleSelectLocation(LOCATION_CONFIG.ALL_LOCATIONS_ID)}
              selected={isAllLocations}
              sx={{
                py: 1.5,
                '&.Mui-selected': {
                  bgcolor: alpha('#fdd835', 0.1),
                },
                '&:hover': {
                  bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
                },
              }}
            >
              <ListItemIcon>
                <AllIcon sx={{ color: '#fdd835' }} />
              </ListItemIcon>
              <ListItemText>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  {LOCATION_CONFIG.ALL_LOCATIONS_LABEL}
                </Typography>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  View data from all stores
                </Typography>
              </ListItemText>
              {isAllLocations && <CheckIcon sx={{ color: '#fdd835', ml: 1 }} />}
            </MenuItem>
            <Divider sx={{ my: 0.5 }} />
          </>
        )}

        {/* Location List */}
        {accessibleLocations.map((location) => {
          const isSelected = currentLocationId === location.id;
          return (
            <MenuItem
              key={location.id}
              onClick={() => handleSelectLocation(location.id)}
              selected={isSelected}
              sx={{
                py: 1.5,
                '&.Mui-selected': {
                  bgcolor: alpha('#fdd835', 0.1),
                },
                '&:hover': {
                  bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
                },
              }}
            >
              <ListItemIcon>
                <PlaceIcon sx={{ color: location.isActive ? '#4caf50' : '#9e9e9e' }} />
              </ListItemIcon>
              <ListItemText>
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  {getLocationShortName(location)}
                </Typography>
                <Typography variant="caption" sx={{ color: 'text.secondary' }}>
                  {location.code} • {location.city}
                </Typography>
              </ListItemText>
              {isSelected && <CheckIcon sx={{ color: '#fdd835', ml: 1 }} />}
            </MenuItem>
          );
        })}

        {/* Footer hint */}
        <Divider sx={{ my: 0.5 }} />
        <Box sx={{ px: 2, py: 1 }}>
          <Typography
            variant="caption"
            sx={{
              color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled',
              fontSize: '0.65rem',
            }}
          >
            {accessibleLocations.length} location{accessibleLocations.length !== 1 ? 's' : ''} available
          </Typography>
        </Box>
      </Menu>
    </>
  );
};

// ─── Compact Location Badge (for mobile) ────────────────────

export const LocationBadge: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { currentLocation, isAllLocations } = useLocation();

  const label = isAllLocations
    ? 'All'
    : currentLocation
    ? currentLocation.code
    : '—';

  return (
    <Chip
      icon={<StoreIcon sx={{ fontSize: 14 }} />}
      label={label}
      size="small"
      sx={{
        height: 24,
        fontSize: '0.7rem',
        fontWeight: 600,
        bgcolor: dk ? 'rgba(253,216,53,0.1)' : 'rgba(253,216,53,0.15)',
        color: '#fdd835',
        border: `1px solid ${alpha('#fdd835', 0.3)}`,
        '& .MuiChip-icon': {
          color: '#fdd835',
        },
      }}
    />
  );
};

export default LocationSwitcher;
