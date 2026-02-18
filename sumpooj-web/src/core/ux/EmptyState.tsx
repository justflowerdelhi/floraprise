/**
 * EmptyState.tsx — Guided Empty States for Low-Tech Users
 *
 * Shows friendly messages when lists are empty, with clear actions
 */
import React from 'react';
import { Box, Typography, Button, useTheme, alpha } from '@mui/material';
import {
  Inbox as EmptyIcon,
  ShoppingCart as CartIcon,
  Search as SearchIcon,
  LocalFlorist as FlowerIcon,
  People as PeopleIcon,
  LocalShipping as DeliveryIcon,
  Receipt as OrderIcon,
  CheckCircle as SuccessIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import { getEmptyState } from './SimplifiedLabels';

// ─── Types ──────────────────────────────────────────────────

type EmptyStateContext = 
  | 'orders'
  | 'cart'
  | 'inventory'
  | 'customers'
  | 'deliveries'
  | 'search_results'
  | 'external_orders'
  | 'products';

interface EmptyStateProps {
  /** Pre-defined context for automatic content */
  context?: EmptyStateContext;
  /** Custom title (overrides context) */
  title?: string;
  /** Custom message (overrides context) */
  message?: string;
  /** Custom action label (overrides context) */
  actionLabel?: string;
  /** Action callback */
  onAction?: () => void;
  /** Custom icon */
  icon?: React.ReactNode;
  /** Size variant */
  size?: 'small' | 'medium' | 'large';
  /** Show as success/positive state */
  isSuccess?: boolean;
}

// ─── Icon Mapping ───────────────────────────────────────────

const CONTEXT_ICONS: Record<EmptyStateContext, React.ReactNode> = {
  orders: <OrderIcon sx={{ fontSize: 'inherit' }} />,
  cart: <CartIcon sx={{ fontSize: 'inherit' }} />,
  inventory: <FlowerIcon sx={{ fontSize: 'inherit' }} />,
  customers: <PeopleIcon sx={{ fontSize: 'inherit' }} />,
  deliveries: <DeliveryIcon sx={{ fontSize: 'inherit' }} />,
  search_results: <SearchIcon sx={{ fontSize: 'inherit' }} />,
  external_orders: <SuccessIcon sx={{ fontSize: 'inherit' }} />,
  products: <FlowerIcon sx={{ fontSize: 'inherit' }} />,
};

// ─── Size Config ────────────────────────────────────────────

const SIZE_CONFIG = {
  small: {
    iconSize: 48,
    titleSize: '1rem',
    messageSize: '0.875rem',
    padding: 3,
    buttonSize: 'small' as const,
  },
  medium: {
    iconSize: 64,
    titleSize: '1.25rem',
    messageSize: '0.9375rem',
    padding: 4,
    buttonSize: 'medium' as const,
  },
  large: {
    iconSize: 80,
    titleSize: '1.5rem',
    messageSize: '1rem',
    padding: 6,
    buttonSize: 'large' as const,
  },
};

// ─── Component ──────────────────────────────────────────────

export const EmptyState: React.FC<EmptyStateProps> = ({
  context,
  title: customTitle,
  message: customMessage,
  actionLabel: customAction,
  onAction,
  icon: customIcon,
  size = 'medium',
  isSuccess = false,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';
  const config = SIZE_CONFIG[size];

  // Get content from context or use custom values
  const contextContent = context ? getEmptyState(context) : null;
  const title = customTitle ?? contextContent?.title ?? 'Nothing Here';
  const message = customMessage ?? contextContent?.message ?? 'No data to display.';
  const actionLabel = customAction ?? contextContent?.action;

  // Determine icon
  const icon = customIcon ?? (context ? CONTEXT_ICONS[context] : <EmptyIcon sx={{ fontSize: 'inherit' }} />);

  // Colors
  const iconColor = isSuccess
    ? '#4caf50'
    : context === 'external_orders'
    ? '#4caf50'
    : dk
    ? 'rgba(255,255,255,0.2)'
    : 'rgba(0,0,0,0.12)';

  const iconBgColor = isSuccess
    ? alpha('#4caf50', dk ? 0.15 : 0.1)
    : context === 'external_orders'
    ? alpha('#4caf50', dk ? 0.15 : 0.1)
    : dk
    ? 'rgba(255,255,255,0.05)'
    : 'rgba(0,0,0,0.04)';

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        textAlign: 'center',
        py: config.padding,
        px: 3,
      }}
    >
      {/* Icon */}
      <Box
        sx={{
          width: config.iconSize * 1.5,
          height: config.iconSize * 1.5,
          borderRadius: '50%',
          bgcolor: iconBgColor,
          color: iconColor,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontSize: config.iconSize,
          mb: 2,
        }}
      >
        {icon}
      </Box>

      {/* Title */}
      <Typography
        variant="h6"
        sx={{
          fontWeight: 700,
          fontSize: config.titleSize,
          mb: 1,
          color: isSuccess || context === 'external_orders'
            ? '#4caf50'
            : dk
            ? 'rgba(255,255,255,0.9)'
            : 'text.primary',
        }}
      >
        {title}
      </Typography>

      {/* Message */}
      <Typography
        variant="body1"
        sx={{
          fontSize: config.messageSize,
          color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
          maxWidth: 320,
          lineHeight: 1.6,
          mb: actionLabel && onAction ? 3 : 0,
        }}
      >
        {message}
      </Typography>

      {/* Action Button */}
      {actionLabel && onAction && (
        <Button
          variant="contained"
          size={config.buttonSize}
          onClick={onAction}
          startIcon={<AddIcon />}
          sx={{
            fontWeight: 700,
            borderRadius: 2,
            px: 3,
            bgcolor: '#fdd835',
            color: '#000',
            boxShadow: '0 4px 14px rgba(253,216,53,0.4)',
            '&:hover': {
              bgcolor: '#ffeb3b',
              boxShadow: '0 6px 20px rgba(253,216,53,0.5)',
            },
          }}
        >
          {actionLabel}
        </Button>
      )}
    </Box>
  );
};

// ─── Search Empty State ─────────────────────────────────────

interface SearchEmptyStateProps {
  query: string;
  onClear?: () => void;
}

export const SearchEmptyState: React.FC<SearchEmptyStateProps> = ({ query, onClear }) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        py: 4,
        px: 3,
        textAlign: 'center',
      }}
    >
      <Box
        sx={{
          width: 72,
          height: 72,
          borderRadius: '50%',
          bgcolor: dk ? 'rgba(255,255,255,0.05)' : 'rgba(0,0,0,0.04)',
          color: dk ? 'rgba(255,255,255,0.2)' : 'rgba(0,0,0,0.15)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          mb: 2,
        }}
      >
        <SearchIcon sx={{ fontSize: 36 }} />
      </Box>

      <Typography variant="h6" sx={{ fontWeight: 700, mb: 1 }}>
        No Results Found
      </Typography>

      <Typography
        variant="body1"
        sx={{
          color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
          maxWidth: 280,
          mb: onClear ? 2 : 0,
        }}
      >
        Nothing matches "<strong>{query}</strong>". Try different words or check spelling.
      </Typography>

      {onClear && (
        <Button
          variant="outlined"
          onClick={onClear}
          sx={{
            fontWeight: 600,
            borderRadius: 2,
            borderColor: dk ? 'rgba(255,255,255,0.2)' : 'divider',
          }}
        >
          Clear Search
        </Button>
      )}
    </Box>
  );
};

// ─── Loading State ──────────────────────────────────────────

interface LoadingStateProps {
  message?: string;
}

export const LoadingState: React.FC<LoadingStateProps> = ({
  message = 'Loading...',
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box
      sx={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
        justifyContent: 'center',
        py: 6,
        px: 3,
      }}
    >
      {/* Simple spinner */}
      <Box
        sx={{
          width: 48,
          height: 48,
          borderRadius: '50%',
          border: `3px solid ${dk ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.08)'}`,
          borderTopColor: '#fdd835',
          animation: 'spin 1s linear infinite',
          mb: 2,
          '@keyframes spin': {
            '0%': { transform: 'rotate(0deg)' },
            '100%': { transform: 'rotate(360deg)' },
          },
        }}
      />
      <Typography
        variant="body1"
        sx={{
          color: dk ? 'rgba(255,255,255,0.6)' : 'text.secondary',
          fontWeight: 500,
        }}
      >
        {message}
      </Typography>
    </Box>
  );
};

export default EmptyState;
