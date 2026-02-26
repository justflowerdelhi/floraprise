/**
 * AppBootGuard.tsx — Blocks rendering until auth identity is resolved.
 *
 * While status === 'loading' (i.e. /auth/me is in-flight or hasn't fired yet)
 * the entire app tree is replaced with a branded loading screen.
 *
 * Once resolved:
 *  • authenticated → render children (the app)
 *  • unauthenticated → children render but RequireAuth will redirect protected routes
 */
import React from 'react';
import { Box, CircularProgress, Typography, useTheme } from '@mui/material';
import { useAuth } from './AuthContext';

interface AppBootGuardProps {
  children: React.ReactNode;
}

export const AppBootGuard: React.FC<AppBootGuardProps> = ({ children }) => {
  const { isLoading } = useAuth();
  const theme = useTheme();
  const dk = theme.palette.mode === 'dark';

  if (isLoading) {
    return (
      <Box
        sx={{
          minHeight: '100vh',
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          bgcolor: dk ? '#0f0f0f' : '#f5f5f5',
          gap: 3,
        }}
      >
        <img
          src={dk ? '/assets/logo/floraprise-logo-light.svg' : '/assets/logo/floraprise-logo.svg'}
          alt="FloraPrice"
          style={{ height: 48 }}
        />
        <CircularProgress size={28} />
        <Typography variant="body2" sx={{ color: dk ? 'rgba(255,255,255,0.5)' : 'text.secondary' }}>
          Loading your workspace…
        </Typography>
      </Box>
    );
  }

  return <>{children}</>;
};
