/**
 * AppRoutes.tsx — Production-Ready Route Configuration
 */
import { Navigate, Routes, Route } from 'react-router-dom';
import Login from '../pages/auth/Login';
import RequireAuth from '../auth/RequireAuth';
import CustomerList from '../pages/customers/CustomerList';
import OrderForm from '../pages/orders/OrderForm';
import AddProductForm from '../pages/products/AddProductForm';
import PurchaseEntryForm from '../pages/purchases/PurchaseEntryForm';
import InventoryBatchDashboard from '../pages/inventory/InventoryBatchDashboard';
import AdjustmentEntryPage from '../pages/adjustments/AdjustmentEntryPage';
import ExpiryAlertCenter from '../pages/expiry-alerts/ExpiryAlertCenter';
import StockMovementLedger from '../pages/stock-ledger/StockMovementLedger';
import InventoryValuationReport from '../pages/valuation/InventoryValuationReport';
import ReorderIntelligence from '../pages/reorder/ReorderIntelligence';
import InventoryHealthDashboard from '../pages/health-dashboard/InventoryHealthDashboard';
import { CartProvider } from '../pages/cart/CartContext';
import { PaymentProvider } from '../pages/payments/PaymentContext';
import { OrderProvider } from '../pages/orders/OrderContext';
import WalkInPOS from '../pages/orders/WalkInPOS';
import ProfitDashboard from '../pages/profit-intelligence/ProfitDashboard';
import PhoneOrder from '../pages/orders/PhoneOrder';
import ExternalOrdersInbox from '../pages/orders/ExternalOrdersInbox';
import DeliveryScheduler from '../pages/orders/DeliveryScheduler';
import OrderList from '../pages/orders/OrderList';
import WireVendorsPage from '../pages/orders/WireVendorsPage';
import WireSettlementsPage from '../pages/orders/WireSettlementsPage';

// Event Module
import EventList from '../pages/events/EventList';
import EventForm from '../pages/events/EventForm';
import ProposalList from '../pages/events/ProposalList';
import ProposalBuilder from '../pages/events/ProposalBuilder';
import EventPaymentPage from '../pages/events/EventPaymentPage';
import EventProductionPage from '../pages/events/EventProductionPage';

// Staff & Performance
import StaffList from '../pages/staff/StaffList';
import StaffPerformancePage from '../pages/staff/StaffPerformancePage';
import StaffForm from '../pages/staff/StaffForm';

// Tasks
import { MyTasksPage } from '../pages/tasks';

// Subscription
import { SubscriptionPage } from '../pages/subscription';

// Day Close
import { DayCloseScreen } from '../pages/day-close';

// CRM & Customer Intelligence
import { CustomerListPage, Customer360View, SmartReminderDashboard, LoyaltyProgramPage } from '../pages/crm';

// Production-Ready SaaS Infrastructure
import { RBACProvider } from '../core/rbac/RBACContext';
import { MasterLayout } from '../core/layout/MasterLayout';
import { FeatureGate } from '../core/tenant';

export default function AppRoutes() {
  return (
    <RBACProvider>
      <Routes>
        {/* Public Routes */}
        <Route path="/" element={<Navigate to="/pos" replace />} />
        <Route path="/auth/login" element={<Login />} />

        {/* Protected Routes with MasterLayout */}
        <Route
          element={
            <RequireAuth>
              <MasterLayout />
            </RequireAuth>
          }
        >
          {/* ─── Sales / POS ────────────────────────────── */}
          <Route
            path="/pos"
            element={
              <PaymentProvider>
                <CartProvider>
                  <WalkInPOS />
                </CartProvider>
              </PaymentProvider>
            }
          />
          <Route
            path="/phone-order"
            element={
              <PaymentProvider>
                <CartProvider>
                  <PhoneOrder />
                </CartProvider>
              </PaymentProvider>
            }
          />

          {/* ─── Orders ─────────────────────────────────── */}
          <Route path="/external-orders" element={<OrderProvider><ExternalOrdersInbox /></OrderProvider>} />
          <Route path="/order-list" element={<OrderProvider><OrderList /></OrderProvider>} />
          <Route path="/orders/new" element={<OrderForm />} />
          <Route path="/delivery-scheduler" element={<DeliveryScheduler />} />
          <Route
            path="/wire-vendors"
            element={
              <FeatureGate feature="WIRE_MANAGEMENT" fallback={<Navigate to="/pos" replace />}>
                <WireVendorsPage />
              </FeatureGate>
            }
          />
          <Route
            path="/wire-settlements"
            element={
              <FeatureGate feature="WIRE_MANAGEMENT" fallback={<Navigate to="/pos" replace />}>
                <WireSettlementsPage />
              </FeatureGate>
            }
          />

          {/* ─── Inventory ──────────────────────────────── */}
          <Route path="/inventory" element={<InventoryBatchDashboard />} />
          <Route path="/purchases/new" element={<PurchaseEntryForm />} />
          <Route path="/adjustments/new" element={<AdjustmentEntryPage />} />
          <Route path="/expiry-alerts" element={<ExpiryAlertCenter />} />
          <Route path="/stock-ledger" element={<StockMovementLedger />} />
          <Route path="/valuation" element={<InventoryValuationReport />} />
          <Route path="/reorder" element={<ReorderIntelligence />} />

          {/* ─── Reports / Intelligence ─────────────────── */}
          <Route path="/health-dashboard" element={<InventoryHealthDashboard />} />
          <Route path="/profit-intelligence" element={<ProfitDashboard />} />

          {/* ─── Catalog ────────────────────────────────── */}
          <Route path="/products/new" element={<AddProductForm />} />
          <Route path="/customers" element={<CustomerList />} />

          {/* ─── Events & Weddings ──────────────────────── */}
          <Route path="/events" element={<EventList />} />
          <Route path="/events/new" element={<EventForm />} />
          <Route path="/events/:id" element={<EventForm />} />
          <Route path="/events/:id/edit" element={<EventForm />} />
          <Route path="/events/:eventId/payments" element={<EventPaymentPage />} />
          <Route path="/events/:eventId/production" element={<EventProductionPage />} />

          {/* ─── Proposals ──────────────────────────────── */}
          <Route path="/proposals" element={<ProposalList />} />
          <Route path="/proposals/new" element={<ProposalBuilder />} />
          <Route path="/proposals/:proposalId" element={<ProposalBuilder />} />
          <Route path="/proposals/:proposalId/edit" element={<ProposalBuilder />} />
          <Route path="/events/:eventId/proposals/new" element={<ProposalBuilder />} />

          {/* ─── Staff & Performance ────────────────────── */}
          <Route path="/staff" element={<StaffList />} />
          <Route path="/staff/new" element={<StaffForm />} />
          <Route path="/staff/:staffId/edit" element={<StaffForm />} />
          <Route path="/staff/:staffId" element={<StaffPerformancePage />} />

          {/* ─── Tasks ──────────────────────────────────── */}
          <Route path="/tasks" element={<MyTasksPage />} />

          {/* ─── Settings / Subscription ────────────────── */}
          <Route path="/subscription" element={<SubscriptionPage />} />
          <Route path="/day-close" element={<DayCloseScreen />} />

          {/* ─── CRM & Customer Intelligence ────────────── */}
          <Route path="/crm/customers" element={<CustomerListPage />} />
          <Route path="/crm/customers/:customerId" element={<Customer360View />} />
          <Route path="/crm/reminders" element={<SmartReminderDashboard />} />
          <Route path="/crm/loyalty" element={<LoyaltyProgramPage />} />
        </Route>
      </Routes>
    </RBACProvider>
  );
}
