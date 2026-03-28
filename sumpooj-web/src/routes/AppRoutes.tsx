/**
 * AppRoutes.tsx — Production-Ready Route Configuration
 */
import { lazy, Suspense } from 'react';
import { Navigate, Routes, Route } from 'react-router-dom';
import Login from '../pages/auth/Login';
import RequireAuth from '../auth/RequireAuth';
import RequireTenantAccess from '../auth/RequireTenantAccess';
import CustomerList from '../pages/customers/CustomerList';
import OrderForm from '../pages/orders/OrderForm';
import AddProductForm from '../pages/products/AddProductForm';
import ProductsListPage from '../pages/products/ProductsListPage';
import PurchaseEntryForm from '../pages/purchases/PurchaseEntryForm';
import PurchaseListPage from '../pages/purchases/PurchaseListPage';
import InventoryBatchDashboard from '../pages/inventory/InventoryBatchDashboard';
import InventoryLedgerPage from '../pages/inventory/InventoryLedger';
import DailyInventoryReportPage from '../pages/inventory/daily-report';
import InventoryReconciliationPage from '../pages/inventory/reconciliation';
import AdjustmentEntryPage from '../pages/adjustments/AdjustmentEntryPage';
import ExpiryAlertCenter from '../pages/expiry-alerts/ExpiryAlertCenter';
import StockMovementLedger from '../pages/stock-ledger/StockMovementLedger';
import InventoryValuationReport from '../pages/valuation/InventoryValuationReport';
import ReorderIntelligence from '../pages/reorder/ReorderIntelligence';
import InventoryHealthDashboard from '../pages/health-dashboard/InventoryHealthDashboard';
import { CartProvider } from '../pages/cart/CartContext';
import { PaymentProvider } from '../pages/payments/PaymentContext';
import { OrderProvider } from '../pages/orders/OrderContext';
import { POSLayout } from '../pages/pos';
import { ShiftProvider } from '../pages/pos/ShiftContext';
import ManualSaleEntry from "../pages/pos/ManualSaleEntry";

import ProfitDashboard from '../pages/profit-intelligence/ProfitDashboard';
import ExternalOrdersInbox from '../pages/orders/ExternalOrdersInbox';
const DeliveryRoutesPage = lazy(() => import('../pages/DeliveryRoutesPage'));
const DeliveryRouteDetailPage = lazy(() => import('../pages/DeliveryRouteDetailPage'));

// Phone-Orders Module
const PhoneOrderPage = lazy(() => import('../modules/phone-orders/PhoneOrderPage'));
const PhoneOrdersHome = lazy(() => import('../modules/phone-orders/PhoneOrdersHome'));
const UnifiedPhoneOrderPage = lazy(() => import('../modules/phone-orders/UnifiedPhoneOrderPage'));
const PhoneOrdersListPage = lazy(() => import('../modules/phone-orders/PhoneOrdersListPage'));
const ProductionDashboard = lazy(() => import('../modules/phone-orders/ProductionDashboard'));
const DeliveryBoardPage = lazy(() => import('../modules/deliveries/DeliveryBoardPage'));
import OrderList from '../pages/orders/OrderList';
const WireVendorsPage = lazy(() => import('../pages/orders/WireVendorsPage'));
const WireSettlementsPage = lazy(() => import('../pages/orders/WireSettlementsPage'));
import RefundScreen from '../pages/refunds/RefundScreen';

// Event Module
const EventList = lazy(() => import('../pages/events/EventList'));
const EventForm = lazy(() => import('../pages/events/EventForm'));
const ProposalList = lazy(() => import('../pages/events/ProposalList'));
const ProposalBuilder = lazy(() => import('../pages/events/ProposalBuilder'));
const EventPaymentPage = lazy(() => import('../pages/events/EventPaymentPage'));
const EventProductionPage = lazy(() => import('../pages/events/EventProductionPage'));

// Staff & Performance
import StaffList from '../pages/staff/StaffList';
import StaffPerformancePage from '../pages/staff/StaffPerformancePage';
import StaffForm from '../pages/staff/StaffForm';
import StaffAttendancePage from "../pages/staff/StaffAttendance";

// Tasks
const MyTasksPage = lazy(() =>
  import('../pages/tasks').then((module) => ({ default: module.MyTasksPage }))
);

// Subscription
const SubscriptionPage = lazy(() =>
  import('../pages/subscription').then((module) => ({ default: module.SubscriptionPage }))
);

// Settings
const TenantSettingsPage = lazy(() => import('../pages/settings/TenantSettingsPage'));
const PaymentGatewaySettings = lazy(() => import('../pages/settings/PaymentGatewaySettings'));
const TaxRulesSettings = lazy(() => import('../pages/settings/TaxRulesSettings'));
const LocationsSettings = lazy(() => import('../pages/settings/LocationsSettings'));
const DeliveryZonesSettings = lazy(() => import('../pages/settings/DeliveryZonesSettings'));
const DiscountRulesSettings = lazy(() => import('../pages/settings/DiscountRulesSettings'));

// Suppliers
import SuppliersPage from '../pages/suppliers/SuppliersPage';

// Admin
const AuditLogsPage = lazy(() => import('../pages/admin/AuditLogsPage'));
const PlatformAdminDashboard = lazy(() => import('../pages/admin/PlatformAdminDashboard'));
const CompanyManagementPage = lazy(() => import('../pages/admin/CompanyManagementPage'));
const PlatformAnalyticsPage = lazy(() => import('../pages/admin/PlatformAnalyticsPage'));
const PlatformSettingsPage = lazy(() => import('../pages/admin/PlatformSettingsPage'));
const AdminDemoRequestsPage = lazy(() => import('../pages/admin/AdminDemoRequestsPage'));
const DataCleanupPage = lazy(() => import('../pages/admin/DataCleanupPage'));

// Categories
const CategoryManagementPage = lazy(() =>
  import('../pages/categories').then((module) => ({ default: module.CategoryManagementPage }))
);

// Onboarding
import OnboardingWizard from '../pages/onboarding/OnboardingWizard';

// Day Close
const DayCloseScreen = lazy(() =>
  import('../pages/day-close').then((module) => ({ default: module.DayCloseScreen }))
);

// CRM & Customer Intelligence
const CustomerListPage = lazy(() =>
  import('../pages/crm').then((module) => ({ default: module.CustomerListPage }))
);
const Customer360View = lazy(() =>
  import('../pages/crm').then((module) => ({ default: module.Customer360View }))
);
const SmartReminderDashboard = lazy(() =>
  import('../pages/crm').then((module) => ({ default: module.SmartReminderDashboard }))
);
const LoyaltyProgramPage = lazy(() =>
  import('../pages/crm').then((module) => ({ default: module.LoyaltyProgramPage }))
);
const CustomerLedgerPage = lazy(() =>
  import('../pages/crm').then((module) => ({ default: module.CustomerLedgerPage }))
);

// Gift Cards
const GiftCardPage = lazy(() =>
  import('../pages/gift-cards').then((module) => ({ default: module.GiftCardPage }))
);
// Removed duplicate import of BouquetScanner
const BouquetScanner = lazy(() => import('../pages/ai/BouquetScanner'));

// Floral Production Engine
const FloralRecipeList = lazy(() =>
  import('../pages/production').then((module) => ({ default: module.FloralRecipeList }))
);
const FloralRecipeForm = lazy(() =>
  import('../pages/production').then((module) => ({ default: module.FloralRecipeForm }))
);
const ProductionScreen = lazy(() =>
  import('../pages/production').then((module) => ({ default: module.ProductionScreen }))
);
const FinishedGoodsInventory = lazy(() =>
  import('../pages/production').then((module) => ({ default: module.FinishedGoodsInventory }))
);
const CustomBouquetBuilder = lazy(() =>
  import('../pages/production').then((module) => ({ default: module.CustomBouquetBuilder }))
);
const WastageLogPage = lazy(() =>
  import('../pages/production').then((module) => ({ default: module.WastageLogPage }))
);

const ProductionJobDetailPage = lazy(() => import('../pages/production/ProductionJobDetailPage'));

// Role-Based Dashboard
const DashboardPage = lazy(() =>
  import('../pages/dashboard').then((module) => ({ default: module.DashboardPage }))
);

// Home / Control Center
const HomeDashboard = lazy(() =>
  import('../pages/home').then((module) => ({ default: module.HomeDashboard }))
);

// Production-Ready SaaS Infrastructure
import { RBACProvider } from '../core/rbac/RBACContext';
import { MasterLayout } from '../core/layout/MasterLayout';
import { FeatureGate } from '../core/tenant';
import { DiscountApprovalProvider } from '../core/rbac/DiscountApprovalModal';

// Accounting
const AccountingDashboard = lazy(() => import('../modules/accounting/pages/AccountingDashboard'));
const ChartOfAccounts = lazy(() => import('../modules/accounting/pages/ChartOfAccounts'));
const AccountLedger = lazy(() => import('../modules/accounting/pages/AccountLedger'));
const ExpenseManager = lazy(() => import('../modules/accounting/pages/ExpenseManager'));
const JournalViewer = lazy(() => import('../modules/accounting/pages/JournalViewer'));
const ProfitLossReport = lazy(() => import('../modules/accounting/pages/ProfitLossReport'));
const TaxSummary = lazy(() => import('../modules/accounting/pages/TaxSummary'));
const TrialBalance = lazy(() => import('../modules/accounting/pages/TrialBalance'));
const BalanceSheet = lazy(() => import('../modules/accounting/pages/BalanceSheet'));

// Production Intelligence
const ProductionIntelligenceDashboard = lazy(() => import('../modules/production/ProductionIntelligenceDashboard'));

function RouteFallback() {
  return (
    <div style={{ display: 'grid', placeItems: 'center', minHeight: '40vh', fontSize: 14 }}>
      Loading...
    </div>
  );
}

/** Wrapper that wires ShiftProvider (reads location from LocationContext) + POSLayout */
function POSWithShift() {
  return (
    <ShiftProvider>
      <PaymentProvider>
        <CartProvider>
          <POSLayout />
        </CartProvider>
      </PaymentProvider>
    </ShiftProvider>
  );
}

export default function AppRoutes() {
  return (
    <RBACProvider>
      <DiscountApprovalProvider>
      <Suspense fallback={<RouteFallback />}>
      <Routes>
        {/* Public Routes */}
        <Route path="/" element={<Navigate to="/home" replace />} />
        <Route path="/auth/login" element={<Login />} />

        {/* Onboarding (authenticated but before main layout) */}
        <Route
          path="/onboarding"
          element={
            <RequireAuth>
              <OnboardingWizard />
            </RequireAuth>
          }
        />

        {/* Protected Routes with MasterLayout */}
        <Route
          element={
            <RequireAuth>
              <OrderProvider>
                <MasterLayout />
              </OrderProvider>
            </RequireAuth>
          }
        >
          {/* ─── Home / Control Center ──────────────────── */}
          <Route path="/home" element={<HomeDashboard />} />

          {/* ─── Dashboard ───────────────────────────────── */}
          <Route path="/dashboard" element={<DashboardPage />} />

          {/* ─── Sales / POS ────────────────────────────── */}
          <Route 
            path="/pos" 
            element={
              <RequireTenantAccess>
                <POSWithShift />
              </RequireTenantAccess>
            } 
          />
            <Route path="/pos/manual-sale" element={<ManualSaleEntry />} />

          {/* ─── Orders ─────────────────────────────────── */}
          <Route path="/external-orders" element={<ExternalOrdersInbox />} />
          <Route path="/order-list" element={<OrderList />} />
          <Route path="/orders/:orderId/refund" element={<RefundScreen />} />
          <Route path="/orders/new" element={<OrderForm />} />

          {/* ─── Phone Orders Module ────────────────────── */}
          <Route path="/phone-orders">
            <Route index element={<PhoneOrdersHome />} />
            <Route path="new" element={<UnifiedPhoneOrderPage />} />
            <Route path="production" element={<ProductionDashboard />} />
            <Route path="list" element={<PhoneOrdersListPage />} />
            <Route path=":orderId" element={<PhoneOrderPage />} />
          </Route>

          {/* Backward compatibility: /phone-order → /phone-orders */}
          <Route path="/phone-order/*" element={<Navigate to="/phone-orders" replace />} />
          <Route path="/deliveries" element={<DeliveryBoardPage />} />
          <Route path="/delivery-scheduler" element={<Navigate to="/deliveries" replace />} />
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
          <Route path="/inventory/ledger" element={<InventoryLedgerPage />} />
          <Route path="/inventory/daily-report" element={<DailyInventoryReportPage />} />
          <Route path="/inventory/reconciliation" element={<InventoryReconciliationPage />} />
          <Route path="/purchases" element={<PurchaseListPage />} />
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
          <Route path="/products" element={<ProductsListPage />} />
          <Route path="/products/new" element={<AddProductForm />} />
          <Route path="/products/:id" element={<AddProductForm />} />
          <Route path="/categories" element={<CategoryManagementPage />} />
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
          <Route path="/staff">
            <Route path="StaffAttendance" element={<Navigate to="/staff/attendance" replace />} />
            <Route index element={<StaffList />} />
            <Route path="new" element={<StaffForm />} />
            <Route path="attendance" element={<StaffAttendancePage />} />
            <Route path=":staffId/edit" element={<StaffForm />} />
              <Route path="performance/:staffId" element={<StaffPerformancePage />} />
          </Route>

          {/* ─── Tasks ──────────────────────────────────── */}
          <Route path="/tasks" element={<MyTasksPage />} />

          {/* ─── Suppliers ──────────────────────────────── */}
          <Route path="/suppliers" element={<SuppliersPage />} />

          {/* ─── Settings / Subscription ────────────────── */}
          <Route path="/subscription" element={<SubscriptionPage />} />
          <Route path="/settings/tenant" element={<TenantSettingsPage />} />
          <Route path="/settings/payment-gateways" element={<PaymentGatewaySettings />} />
          <Route path="/settings/tax-rules" element={<TaxRulesSettings />} />
          <Route path="/settings/locations" element={<LocationsSettings />} />
          <Route path="/settings/delivery-zones" element={<DeliveryZonesSettings />} />
          <Route path="/settings/discount-rules" element={<DiscountRulesSettings />} />
          <Route path="/settings/data-cleanup" element={<DataCleanupPage />} />
          <Route path="/day-close" element={<DayCloseScreen />} />

          {/* ─── Admin ──────────────────────────────────── */}
          <Route path="/admin/dashboard" element={<PlatformAdminDashboard />} />
          <Route path="/admin/audit-logs" element={<AuditLogsPage />} />
          <Route path="/admin/companies" element={<CompanyManagementPage />} />
          <Route path="/admin/analytics" element={<PlatformAnalyticsPage />} />
          <Route path="/admin/settings" element={<PlatformSettingsPage />} />
          <Route path="/admin/demo-requests" element={<AdminDemoRequestsPage />} />

          {/* ─── CRM & Customer Intelligence ────────────── */}
          <Route path="/crm/customers" element={<CustomerListPage />} />
          <Route path="/crm/customers/:customerId" element={<Customer360View />} />
          <Route path="/crm/customer-ledger" element={<CustomerLedgerPage />} />
          <Route path="/crm/reminders" element={<SmartReminderDashboard />} />
          <Route path="/crm/loyalty" element={<LoyaltyProgramPage />} />

          {/* ─── Floraprise AI ───────────────────────────── */}
          <Route path="/ai/bouquet-scanner" element={<BouquetScanner />} />

          {/* ─── Gift Cards ────────────────────────────── */}
          <Route path="/gift-cards/designer" element={<GiftCardPage />} />

          {/* ─── Floral Production Engine ───────────────── */}
          <Route path="/production/recipes" element={<FloralRecipeList />} />
          <Route path="/production/recipes/new" element={<FloralRecipeForm />} />
          <Route path="/production/recipes/:id/edit" element={<FloralRecipeForm />} />
          <Route path="/production/produce" element={<ProductionScreen />} />
          <Route path="/production/finished-goods" element={<FinishedGoodsInventory />} />
          <Route
            path="/production/custom-builder"
            element={<CustomBouquetBuilder />}
          />
          <Route path="/production/wastage" element={<WastageLogPage />} />

            <Route path="/production/jobs/:jobId" element={<ProductionJobDetailPage jobId={":jobId"} />} />

          {/* ─── Delivery Routes ───────────────────────────── */}
          <Route path="/delivery-routes" element={<DeliveryRoutesPage />} />
          <Route path="/delivery-routes/:routeId" element={<DeliveryRouteDetailPage />} />
          <Route path="/accounting/dashboard" element={<AccountingDashboard />} />
          <Route path="/accounting/chart-of-accounts" element={<ChartOfAccounts />} />
          <Route path="/accounting/account-ledger" element={<AccountLedger />} />
          <Route path="/accounting/trial-balance" element={<TrialBalance />} />
          <Route path="/accounting/balance-sheet" element={<BalanceSheet />} />
          <Route path="/accounting/expenses" element={<ExpenseManager />} />
          <Route path="/accounting/journal" element={<JournalViewer />} />
          <Route path="/accounting/profit-loss" element={<ProfitLossReport />} />
          <Route path="/accounting/tax-summary" element={<TaxSummary />} />
          <Route
            path="/production/intelligence"
            element={<ProductionIntelligenceDashboard />}
          />
        </Route>
      </Routes>
      </Suspense>
      </DiscountApprovalProvider>
    </RBACProvider>
  );
}
