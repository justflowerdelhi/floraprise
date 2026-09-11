/**
 * OperationalViewSwitcher.tsx — Header View Switcher Component
 *
 * Features:
 * - Compact view switcher in the ERP header
 * - Only visible when tenant is eligible for both Retail and Professional views
 *   (Growth, Pro, Enterprise plans).
 * - Hidden for Starter plan tenants (who are locked to Retail View).
 * - Allows switching between "Retail View" and "ERP Professional".
 */

import React, { useState } from 'react';
import {
  Box,
  Typography,
  Menu,
  MenuItem,
  useTheme,
  ListItemIcon,
  ListItemText,
  Divider,
} from '@mui/material';
import {
  Store as StoreIcon,
  BusinessCenter as BusinessIcon,
  ExpandMore as ExpandIcon,
  Check as CheckIcon,
} from '@mui/icons-material';
import { useOperationalView } from './OperationalViewContext';
import { OPERATIONAL_VIEWS, OPERATIONAL_VIEW_LABELS } from './TenantTypes';

export const OperationalViewSwitcher: React.FC = () => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const { view, isRetail, canUseProfessionalView, setView } = useOperationalView();

  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const open = Boolean(anchorEl);

  // Hidden for tenants not eligible for both views (e.g. Starter)
  if (!canUseProfessionalView) {
    return null;
  }

  const handleClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleSelect = (targetView: typeof view) => {
    setView(targetView);
    handleClose();
  };

  const activeLabel = OPERATIONAL_VIEW_LABELS[view];
  const activeColor = isRetail ? '#2e7d32' : '#1565c0';

  return (
    <>
      <Box
        onClick={handleClick}
        sx={{
          display: 'flex',
          alignItems: 'center',
          gap: 0.75,
          px: 1.25,
          py: 0.6,
          borderRadius: 2,
          bgcolor: dk ? 'rgba(255,255,255,0.04)' : 'rgba(0,0,0,0.02)',
          border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
          cursor: 'pointer',
          transition: 'all 0.15s ease-in-out',
          '&:hover': {
            bgcolor: dk ? 'rgba(255,255,255,0.08)' : 'rgba(0,0,0,0.05)',
            borderColor: activeColor,
          },
        }}
        aria-label="Switch Operational View"
        title="Switch Operational View"
      >
        {isRetail ? (
          <StoreIcon sx={{ fontSize: 18, color: '#2e7d32' }} />
        ) : (
          <BusinessIcon sx={{ fontSize: 18, color: '#1565c0' }} />
        )}
        <Typography
          variant="body2"
          sx={{
            fontWeight: 600,
            fontSize: '0.8125rem',
            color: dk ? '#fff' : 'text.primary',
            userSelect: 'none',
          }}
        >
          {activeLabel}
        </Typography>
        <ExpandIcon sx={{ fontSize: 16, color: 'text.secondary', ml: -0.25 }} />
      </Box>

      <Menu
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
        transformOrigin={{ horizontal: 'right', vertical: 'top' }}
        anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
        slotProps={{
          paper: {
            sx: {
              mt: 1,
              minWidth: 260,
              borderRadius: 2,
              boxShadow: dk
                ? '0 8px 24px rgba(0,0,0,0.6)'
                : '0 8px 24px rgba(0,0,0,0.12)',
              bgcolor: dk ? '#1a1a2e' : '#fff',
              border: `1px solid ${dk ? 'rgba(255,255,255,0.08)' : '#e0e0e0'}`,
            },
          },
        }}
      >
        <Box sx={{ px: 2, py: 1 }}>
          <Typography variant="caption" sx={{ color: 'text.secondary', fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5 }}>
            Operational Experience
          </Typography>
        </Box>
        <Divider sx={{ mb: 0.5 }} />

        {/* Retail View Option */}
        <MenuItem
          onClick={() => handleSelect(OPERATIONAL_VIEWS.RETAIL)}
          selected={isRetail}
          sx={{
            py: 1,
            px: 2,
            gap: 1.5,
            '&.Mui-selected': {
              bgcolor: dk ? 'rgba(46,125,50,0.15)' : 'rgba(46,125,50,0.08)',
            },
          }}
        >
          <ListItemIcon sx={{ minWidth: 28, color: '#2e7d32' }}>
            <StoreIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText
            primary={OPERATIONAL_VIEW_LABELS.RETAIL}
            secondary="Fast florist operations: POS, Catalog, Stock, Delivery"
            primaryTypographyProps={{
              variant: 'body2',
              fontWeight: isRetail ? 700 : 500,
              color: isRetail ? '#2e7d32' : 'inherit',
            }}
            secondaryTypographyProps={{
              variant: 'caption',
              sx: { display: 'block', fontSize: '0.72rem' },
            }}
          />
          {isRetail && <CheckIcon sx={{ fontSize: 18, color: '#2e7d32' }} />}
        </MenuItem>

        {/* ERP Professional Option */}
        <MenuItem
          onClick={() => handleSelect(OPERATIONAL_VIEWS.PROFESSIONAL)}
          selected={!isRetail}
          sx={{
            py: 1,
            px: 2,
            gap: 1.5,
            '&.Mui-selected': {
              bgcolor: dk ? 'rgba(21,101,192,0.15)' : 'rgba(21,101,192,0.08)',
            },
          }}
        >
          <ListItemIcon sx={{ minWidth: 28, color: '#1565c0' }}>
            <BusinessIcon fontSize="small" />
          </ListItemIcon>
          <ListItemText
            primary={OPERATIONAL_VIEW_LABELS.PROFESSIONAL}
            secondary="Full ERP: Batches, FIFO, Accounting, Reports, CRM"
            primaryTypographyProps={{
              variant: 'body2',
              fontWeight: !isRetail ? 700 : 500,
              color: !isRetail ? '#1565c0' : 'inherit',
            }}
            secondaryTypographyProps={{
              variant: 'caption',
              sx: { display: 'block', fontSize: '0.72rem' },
            }}
          />
          {!isRetail && <CheckIcon sx={{ fontSize: 18, color: '#1565c0' }} />}
        </MenuItem>
      </Menu>
    </>
  );
};
