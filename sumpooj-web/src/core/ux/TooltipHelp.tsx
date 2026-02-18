/**
 * TooltipHelp.tsx — Help Icon with Tooltip
 *
 * Simple help icons for low-tech users to understand fields
 */
import React from 'react';
import { Tooltip, IconButton, Box, Typography, useTheme, alpha } from '@mui/material';
import { HelpOutline as HelpIcon, Info as InfoIcon } from '@mui/icons-material';
import { getHelpText } from './SimplifiedLabels';

// ─── Types ──────────────────────────────────────────────────

interface TooltipHelpProps {
  fieldKey?: string;
  text?: string;
  title?: string;
  size?: 'small' | 'medium';
  variant?: 'icon' | 'inline';
}

// ─── Component ──────────────────────────────────────────────

export const TooltipHelp: React.FC<TooltipHelpProps> = ({
  fieldKey,
  text,
  title,
  size = 'small',
  variant = 'icon',
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  // Get help text from fieldKey or use provided text
  const helpText = text ?? (fieldKey ? getHelpText(fieldKey) : undefined);

  if (!helpText) return null;

  const iconSize = size === 'small' ? 16 : 20;

  if (variant === 'inline') {
    return (
      <Tooltip
        title={
          <Box sx={{ p: 0.5 }}>
            {title && (
              <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 0.5 }}>
                {title}
              </Typography>
            )}
            <Typography variant="body2" sx={{ lineHeight: 1.5 }}>
              {helpText}
            </Typography>
          </Box>
        }
        arrow
        placement="top"
        slotProps={{
          tooltip: {
            sx: {
              bgcolor: dk ? '#2a2a3e' : '#333',
              maxWidth: 280,
              p: 1.5,
              borderRadius: 2,
              boxShadow: '0 4px 16px rgba(0,0,0,0.2)',
            },
          },
          arrow: {
            sx: { color: dk ? '#2a2a3e' : '#333' },
          },
        }}
      >
        <Box
          component="span"
          sx={{
            display: 'inline-flex',
            alignItems: 'center',
            ml: 0.5,
            cursor: 'help',
          }}
        >
          <InfoIcon
            sx={{
              fontSize: iconSize,
              color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled',
              '&:hover': {
                color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
              },
            }}
          />
        </Box>
      </Tooltip>
    );
  }

  return (
    <Tooltip
      title={
        <Box sx={{ p: 0.5 }}>
          {title && (
            <Typography variant="subtitle2" sx={{ fontWeight: 700, mb: 0.5 }}>
              {title}
            </Typography>
          )}
          <Typography variant="body2" sx={{ lineHeight: 1.5 }}>
            {helpText}
          </Typography>
        </Box>
      }
      arrow
      placement="top"
      slotProps={{
        tooltip: {
          sx: {
            bgcolor: dk ? '#2a2a3e' : '#333',
            maxWidth: 280,
            p: 1.5,
            borderRadius: 2,
            boxShadow: '0 4px 16px rgba(0,0,0,0.2)',
          },
        },
        arrow: {
          sx: { color: dk ? '#2a2a3e' : '#333' },
        },
      }}
    >
      <IconButton
        size="small"
        sx={{
          p: 0.5,
          color: dk ? 'rgba(255,255,255,0.4)' : 'text.disabled',
          '&:hover': {
            color: dk ? 'rgba(255,255,255,0.7)' : 'text.secondary',
            bgcolor: 'transparent',
          },
        }}
      >
        <HelpIcon sx={{ fontSize: iconSize }} />
      </IconButton>
    </Tooltip>
  );
};

// ─── Field Label with Help ──────────────────────────────────

interface FieldLabelProps {
  label: string;
  required?: boolean;
  helpKey?: string;
  helpText?: string;
}

export const FieldLabel: React.FC<FieldLabelProps> = ({
  label,
  required = false,
  helpKey,
  helpText,
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  return (
    <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.5, mb: 0.5 }}>
      <Typography
        variant="body2"
        sx={{
          fontWeight: 600,
          color: dk ? 'rgba(255,255,255,0.9)' : 'text.primary',
        }}
      >
        {label}
        {required && (
          <Typography component="span" sx={{ color: '#f44336', ml: 0.5 }}>
            *
          </Typography>
        )}
      </Typography>
      <TooltipHelp fieldKey={helpKey} text={helpText} variant="inline" />
    </Box>
  );
};

// ─── Info Banner ────────────────────────────────────────────

interface InfoBannerProps {
  title?: string;
  message: string;
  variant?: 'info' | 'tip' | 'warning';
}

export const InfoBanner: React.FC<InfoBannerProps> = ({
  title,
  message,
  variant = 'info',
}) => {
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  const colors = {
    info: { bg: dk ? 'rgba(33,150,243,0.15)' : '#e3f2fd', text: '#1976d2', icon: '#2196f3' },
    tip: { bg: dk ? 'rgba(76,175,80,0.15)' : '#e8f5e9', text: '#2e7d32', icon: '#4caf50' },
    warning: { bg: dk ? 'rgba(255,152,0,0.15)' : '#fff3e0', text: '#e65100', icon: '#ff9800' },
  };

  const c = colors[variant];

  return (
    <Box
      sx={{
        display: 'flex',
        alignItems: 'flex-start',
        gap: 1.5,
        p: 2,
        borderRadius: 2,
        bgcolor: c.bg,
      }}
    >
      <InfoIcon sx={{ fontSize: 20, color: c.icon, mt: 0.25 }} />
      <Box>
        {title && (
          <Typography variant="subtitle2" sx={{ fontWeight: 700, color: c.text, mb: 0.25 }}>
            {title}
          </Typography>
        )}
        <Typography variant="body2" sx={{ color: c.text, lineHeight: 1.5 }}>
          {message}
        </Typography>
      </Box>
    </Box>
  );
};

export default TooltipHelp;
