/**
 * DashboardPage.tsx — Role-based dashboard router.
 *
 * Single entry point for /dashboard. Fetches data per role,
 * shows skeleton while loading, renders the correct role dashboard.
 */
import { useState, useEffect } from 'react';
import { useRBAC } from '../../core/rbac/RBACContext';
import { fetchDashboard } from './api/dashboardApi';
import type { DashboardResponse } from './api/dashboardApi';
import DashboardSkeleton from './components/SkeletonLoader';
import ErrorState from './components/ErrorState';
import AdminDashboard from './roles/AdminDashboard';
import ManagerDashboard from './roles/ManagerDashboard';
import DesignerDashboard from './roles/DesignerDashboard';
import CashierDashboard from './roles/CashierDashboard';
import DriverDashboard from './roles/DriverDashboard';

// ─── Greeting helper ────────────────────────────────────────

function getGreeting(): string {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

function formatToday(): string {
  return new Date().toLocaleDateString('en-IN', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  });
}

// ─── Component ──────────────────────────────────────────────

export default function DashboardPage() {
  const { user, role } = useRBAC();
  const [response, setResponse] = useState<DashboardResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<{ message: string; status?: number } | null>(null);

  const loadDashboard = () => {
    if (!role) return;
    setLoading(true);
    setError(null);
    fetchDashboard(role, user?.primaryLocationId)
      .then((res) => setResponse(res))
      .catch((err) => {
        const status = err?.status ?? err?.response?.status;
        setError({
          message: status === 403
            ? "You don't have permission to view this dashboard."
            : 'Unable to load dashboard. Please try again.',
          status,
        });
      })
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadDashboard();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [role, user?.primaryLocationId]);

  // Loading state
  if (loading) {
    return (
      <div className="max-w-7xl mx-auto px-6 py-6">
        <DashboardSkeleton />
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="max-w-7xl mx-auto px-6 py-6">
        <ErrorState
          message={error.message}
          status={error.status}
          onRetry={loadDashboard}
        />
      </div>
    );
  }

  // No data
  if (!response) return null;

  return (
    <div className="max-w-7xl mx-auto px-6 py-6">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-800">
          {getGreeting()}, {user?.name?.split(' ')[0] ?? 'there'}
        </h1>
        <p className="text-sm text-slate-500 mt-1">{formatToday()}</p>
      </div>

      {/* Role Dashboard */}
      {response.role === 'ADMIN' && <AdminDashboard data={response.data} />}
      {response.role === 'MANAGER' && <ManagerDashboard data={response.data} />}
      {response.role === 'DESIGNER' && <DesignerDashboard data={response.data} />}
      {response.role === 'CASHIER' && <CashierDashboard data={response.data} />}
      {response.role === 'DRIVER' && <DriverDashboard data={response.data} />}
    </div>
  );
}
