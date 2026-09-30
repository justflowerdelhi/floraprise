import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { NotificationProvider } from './context/NotificationContext';
import { AdminLayout } from './components/layout/AdminLayout';

// Pages
import { LoginPage } from './pages/auth/LoginPage';
import { DashboardPage } from './pages/dashboard/DashboardPage';
import { SubscribersListPage } from './pages/subscribers/SubscribersListPage';
import { PendingOnboardingPage } from './pages/subscribers/PendingOnboardingPage';
import { ProvisioningHealthPage } from './pages/subscribers/ProvisioningHealthPage';
import { Subscriber360Page } from './pages/subscribers/Subscriber360Page';
import { PlansPage } from './pages/subscriptions/PlansPage';
import { SubscriptionsListPage } from './pages/subscriptions/SubscriptionsListPage';
import { DevicesListPage } from './pages/devices/DevicesListPage';
import { AppVersionsPage } from './pages/devices/AppVersionsPage';
import { LiveTrackingPage } from './pages/delivery/LiveTrackingPage';
import { DriversListPage } from './pages/delivery/DriversListPage';
import { DeliverySessionsPage } from './pages/delivery/DeliverySessionsPage';
import { DiagnosticsPage } from './pages/support/DiagnosticsPage';
import { MigrationPage } from './pages/support/MigrationPage';
import { IssuesPage } from './pages/support/IssuesPage';
import { ReportsPage } from './pages/reports/ReportsPage';
import { ExistingToolsPage } from './pages/existing-tools/ExistingToolsPage';
import { AdminUsersPage } from './pages/platform/AdminUsersPage';
import { SettingsPage } from './pages/platform/SettingsPage';

const ProtectedRoute: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { isAuthenticated } = useAuth();
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <NotificationProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />

            <Route
              path="/"
              element={
                <ProtectedRoute>
                  <AdminLayout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Navigate to="/dashboard" replace />} />
              <Route path="dashboard" element={<DashboardPage />} />

              {/* Subscribers */}
              <Route path="subscribers" element={<SubscribersListPage />} />
              <Route path="subscribers/pending" element={<PendingOnboardingPage />} />
              <Route path="subscribers/provisioning" element={<ProvisioningHealthPage />} />
              <Route path="subscribers/:id" element={<Subscriber360Page />} />

              {/* Subscriptions */}
              <Route path="subscriptions" element={<Navigate to="/subscriptions/plans" replace />} />
              <Route path="subscriptions/plans" element={<PlansPage />} />
              <Route path="subscriptions/active" element={<SubscriptionsListPage initialFilter="Active" />} />
              <Route path="subscriptions/trial" element={<SubscriptionsListPage initialFilter="Trial" />} />
              <Route path="subscriptions/grace" element={<SubscriptionsListPage initialFilter="Grace" />} />
              <Route path="subscriptions/expired" element={<SubscriptionsListPage initialFilter="Expired" />} />

              {/* Devices & Applications */}
              <Route path="devices" element={<DevicesListPage />} />
              <Route path="devices/android" element={<DevicesListPage />} />
              <Route path="devices/solo" element={<DevicesListPage />} />
              <Route path="devices/web" element={<DevicesListPage />} />
              <Route path="devices/versions" element={<AppVersionsPage />} />

              {/* Delivery */}
              <Route path="delivery" element={<Navigate to="/delivery/live" replace />} />
              <Route path="delivery/live" element={<LiveTrackingPage />} />
              <Route path="delivery/drivers" element={<DriversListPage />} />
              <Route path="delivery/sessions" element={<DeliverySessionsPage />} />

              {/* Support */}
              <Route path="support" element={<Navigate to="/support/diagnostics" replace />} />
              <Route path="support/diagnostics" element={<DiagnosticsPage />} />
              <Route path="support/migration" element={<MigrationPage />} />
              <Route path="support/issues" element={<IssuesPage />} />

              {/* Reports */}
              <Route path="reports" element={<ReportsPage />} />

              {/* Existing Admin Tools */}
              <Route path="existing-tools" element={<ExistingToolsPage />} />

              {/* Platform */}
              <Route path="platform" element={<Navigate to="/platform/plans" replace />} />
              <Route path="platform/plans" element={<PlansPage />} />
              <Route path="platform/users" element={<AdminUsersPage />} />
              <Route path="platform/settings" element={<SettingsPage />} />

              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Route>
          </Routes>
        </BrowserRouter>
      </NotificationProvider>
    </AuthProvider>
  );
};
