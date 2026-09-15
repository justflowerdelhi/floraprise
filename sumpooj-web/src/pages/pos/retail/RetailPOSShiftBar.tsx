/**
 * RetailPOSShiftBar.tsx — Header bar for Retail POS
 *
 * Displays:
 * - Floraprise Retail POS branding & current location
 * - Shift status indicator (Active / Inactive)
 * - Shift sales & cash info
 * - "Close Shift" / "Open Shift" action buttons
 * - View switcher to toggling back to Professional ERP
 */

import React from 'react';
import {
  Box,
  Typography,
  Button,
  Chip,
  Tooltip,
  IconButton,
  alpha,
  useTheme,
} from '@mui/material';
import {
  PointOfSale as POSIcon,
  LocationOn as LocationIcon,
  LockOpen as OpenIcon,
  Lock as CloseIcon,
  SwapHoriz as SwitchViewIcon,
  Refresh as RefreshIcon,
  WarningAmber as WarningIcon,
  AccountBalanceWallet as WalletIcon,
} from '@mui/icons-material';
import { useShift } from '../ShiftContext';
import { useLocation as useLocationCtx } from '../../../core/location/LocationContext';
import { useOperationalView } from '../../../core/tenant';
import { formatCurrency } from '../../../core/i18n';

interface RetailPOSShiftBarProps {
  onOpenShiftModal?: () => void;
  onRefreshCatalog?: () => void;
  catalogLoading?: boolean;
}

export const RetailPOSShiftBar: React.FC<RetailPOSShiftBarProps> = ({
  onOpenShiftModal,
  onRefreshCatalog,
  catalogLoading = false,
}) => {
  const theme = useTheme();
  const { activeShift, loading: shiftLoading, setCloseDrawerOpen, refreshShift } = useShift();
  const { currentLocation } = useLocationCtx();
  const { setOperationalView } = useOperationalView();

  const locationName = currentLocation?.name || 'Main Store';

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        flexWrap: 'wrap',
        gap: 1.5,
        p: { xs: 1.5, sm: 2 },
        bgcolor: 'background.paper',
        borderRadius: 2,
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        border: '1px solid',
        borderColor: 'divider',
        mb: 2,
      }}
    >
      {/* Left: Branding & Location */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5 }}>
        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            width: 40,
            height: 40,
            borderRadius: 2,
            bgcolor: alpha(theme.palette.primary.main, 0.1),
            color: theme.palette.primary.main,
          }}
        >
          <POSIcon />
        </Box>
        <Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
            <Typography variant="h6" fontWeight={700} sx={{ lineHeight: 1.2 }}>
              Retail POS
            </Typography>
            <Chip
              label="RETAIL"
              size="small"
              color="primary"
              variant="filled"
              sx={{ height: 20, fontSize: '0.675rem', fontWeight: 700 }}
            />
          </Box>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mt: 0.25 }}>
            <LocationIcon sx={{ fontSize: 14, color: 'text.secondary' }} />
            <Typography variant="caption" color="text.secondary" fontWeight={500}>
              {locationName}
            </Typography>
          </Box>
        </Box>
      </Box>

      {/* Center: Shift Status */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1.5, flexWrap: 'wrap' }}>
        {shiftLoading ? (
          <Chip label="Checking shift..." size="small" variant="outlined" />
        ) : activeShift ? (
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1.5,
              px: 1.5,
              py: 0.75,
              borderRadius: 2,
              bgcolor: alpha(theme.palette.success.main, 0.08),
              border: '1px solid',
              borderColor: alpha(theme.palette.success.main, 0.3),
            }}
          >
            <Chip
              icon={<OpenIcon sx={{ fontSize: '14px !important' }} />}
              label="Shift Open"
              size="small"
              color="success"
              sx={{ fontWeight: 600, height: 24 }}
            />
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5 }}>
              <WalletIcon sx={{ fontSize: 15, color: 'success.dark' }} />
              <Typography variant="caption" fontWeight={600} color="success.dark">
                Cash in Drawer: {formatCurrency(activeShift.expectedCash ?? activeShift.openingCash ?? 0)}
              </Typography>
            </Box>
            <Typography variant="caption" color="text.secondary">
              • {activeShift.transactionCount ?? 0} Sales
            </Typography>
            <Button
              size="small"
              variant="outlined"
              color="warning"
              onClick={() => setCloseDrawerOpen(true)}
              startIcon={<CloseIcon sx={{ fontSize: 14 }} />}
              sx={{ height: 24, fontSize: '0.725rem', textTransform: 'none', px: 1 }}
            >
              Close Shift
            </Button>
          </Box>
        ) : (
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1.5,
              px: 1.5,
              py: 0.75,
              borderRadius: 2,
              bgcolor: alpha(theme.palette.error.main, 0.08),
              border: '1px solid',
              borderColor: alpha(theme.palette.error.main, 0.3),
            }}
          >
            <Chip
              icon={<WarningIcon sx={{ fontSize: '14px !important' }} />}
              label="No Active Shift"
              size="small"
              color="error"
              sx={{ fontWeight: 600, height: 24 }}
            />
            <Typography variant="caption" color="error.dark" fontWeight={500}>
              Open a shift to process orders
            </Typography>
            {onOpenShiftModal && (
              <Button
                size="small"
                variant="contained"
                color="primary"
                onClick={onOpenShiftModal}
                startIcon={<OpenIcon sx={{ fontSize: 14 }} />}
                sx={{ height: 24, fontSize: '0.725rem', textTransform: 'none', px: 1.25 }}
              >
                Open Shift
              </Button>
            )}
          </Box>
        )}
      </Box>

      {/* Right: Actions & Switch View */}
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        {onRefreshCatalog && (
          <Tooltip title="Refresh Catalog">
            <span>
              <IconButton
                size="small"
                onClick={onRefreshCatalog}
                disabled={catalogLoading}
                sx={{ border: '1px solid', borderColor: 'divider' }}
              >
                <RefreshIcon fontSize="small" className={catalogLoading ? 'animate-spin' : ''} />
              </IconButton>
            </span>
          </Tooltip>
        )}
        <Tooltip title="Switch to ERP Professional POS">
          <Button
            size="small"
            variant="outlined"
            onClick={() => setOperationalView('PROFESSIONAL')}
            startIcon={<SwitchViewIcon />}
            sx={{
              textTransform: 'none',
              fontWeight: 600,
              borderRadius: 1.5,
              fontSize: '0.775rem',
            }}
          >
            ERP Pro POS
          </Button>
        </Tooltip>
      </Box>
    </Box>
  );
};

export default RetailPOSShiftBar;
