import { Navigate } from 'react-router-dom';
import { useAuth } from './AuthContext';
import type { ReactNode } from 'react';

/**
 * Route guard — redirects to login when unauthenticated.
 * The boot guard already handles the 'loading' state, so by the
 * time RequireAuth renders, status is either authenticated or unauthenticated.
 */
export default function RequireAuth({ children }: { children: ReactNode }) {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? children : <Navigate to="/auth/login" replace />;
}
