/**
 * RequireTenantAccess.tsx — Guards tenant-specific features
 * 
 * Prevents platform admins from accessing company-specific features like:
 * - POS
 * - Orders
 * - Customers
 * - Products
 * - Inventory
 * 
 * Platform admins should only access platform-level features like company management.
 */
import { Navigate } from 'react-router-dom';
import { useAuth } from './AuthContext';
import type { ReactNode } from 'react';

interface RequireTenantAccessProps {
  children: ReactNode;
  redirectTo?: string;
}

export default function RequireTenantAccess({ 
  children, 
  redirectTo = '/admin/dashboard' 
}: RequireTenantAccessProps) {
  const { user } = useAuth();

  // Block platform admins from accessing tenant-specific features
  if (user?.role === 'PLATFORMSUPERADMIN') {
    return <Navigate to={redirectTo} replace />;
  }

  return <>{children}</>;
}
