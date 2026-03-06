/**
 * AppRoutes.tsx — Production-Ready Route Configuration
 */
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

import ProfitDashboard from '../pages/profit-intelligence/ProfitDashboard';
import ExternalOrdersInbox from '../pages/orders/ExternalOrdersInbox';
import DeliveryRoutesPage from '../pages/DeliveryRoutesPage';
import DeliveryRouteDetailPage from '../pages/DeliveryRouteDetailPage';

// Phone-Orders Module
import PhoneOrderPage from '../modules/phone-orders/PhoneOrderPage';
import PhoneOrdersHome from '../modules/phone-orders/PhoneOrdersHome';
import UnifiedPhoneOrderPage from '../modules/phone-orders/UnifiedPhoneOrderPage';
import PhoneOrdersListPage from '../modules/phone-orders/PhoneOrdersListPage';
import ProductionDashboard from '../modules/phone-orders/ProductionDashboard';
import DeliveryScheduler from '../pages/orders/DeliveryScheduler';
import DeliveryBoardPage from '../modules/deliveries/DeliveryBoardPage';
import OrderList from '../pages/orders/OrderList';
import WireVendorsPage from '../pages/orders/WireVendorsPage';
import WireSettlementsPage from '../pages/orders/WireSettlementsPage';
import RefundScreen from '../pages/refunds/RefundScreen';

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

// Settings
import TenantSettingsPage from '../pages/settings/TenantSettingsPage';
import PaymentGatewaySettings from '../pages/settings/PaymentGatewaySettings';
import TaxRulesSettings from '../pages/settings/TaxRulesSettings';
import LocationsSettings from '../pages/settings/LocationsSettings';
import DeliveryZonesSettings from '../pages/settings/DeliveryZonesSettings';

// Suppliers
import SuppliersPage from '../pages/suppliers/SuppliersPage';

// Admin
import AuditLogsPage from '../pages/admin/AuditLogsPage';
import PlatformAdminDashboard from '../pages/admin/PlatformAdminDashboard';
import CompanyManagementPage from '../pages/admin/CompanyManagementPage';
import PlatformAnalyticsPage from '../pages/admin/PlatformAnalyticsPage';
import PlatformSettingsPage from '../pages/admin/PlatformSettingsPage';

// Categories
import { CategoryManagementPage } from '../pages/categories';

// Onboarding
import OnboardingWizard from '../pages/onboarding/OnboardingWizard';

// Day Close
import { DayCloseScreen } from '../pages/day-close';

// CRM & Customer Intelligence
import { CustomerListPage, Customer360View, SmartReminderDashboard, LoyaltyProgramPage } from '../pages/crm';

// Gift Cards
import { GiftCardPage } from '../pages/gift-cards';

// Floral Production Engine
import {
  FloralRecipeList,
  FloralRecipeForm,
  ProductionScreen,
  FinishedGoodsInventory,
  CustomBouquetBuilder,
  WastageLogPage,
} from '../pages/production';

import ProductionJobDetailPage from '../pages/production/ProductionJobDetailPage';

// Role-Based Dashboard
import { DashboardPage } from '../pages/dashboard';

// Home / Control Center
import { HomeDashboard } from '../pages/home';

// Production-Ready SaaS Infrastructure
import { RBACProvider } from '../core/rbac/RBACContext';
import { MasterLayout } from '../core/layout/MasterLayout';
import { FeatureGate } from '../core/tenant';
import { DiscountApprovalProvider } from '../core/rbac/DiscountApprovalModal';

// Accounting
import AccountingDashboard from "../modules/accounting/pages/AccountingDashboard";
import ChartOfAccounts from "../modules/accounting/pages/ChartOfAccounts";
import AccountLedger from "../modules/accounting/pages/AccountLedger";
import ExpenseManager from "../modules/accounting/pages/ExpenseManager";
import JournalViewer from "../modules/accounting/pages/JournalViewer";
import ProfitLossReport from "../modules/accounting/pages/ProfitLossReport";
import TaxSummary from "../modules/accounting/pages/TaxSummary";

// Production Intelligence
import ProductionIntelligenceDashboard from "../modules/production/ProductionIntelligenceDashboard";

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
          <Route path="/staff" element={<StaffList />} />
          <Route path="/staff/new" element={<StaffForm />} />
          <Route path="/staff/:staffId/edit" element={<StaffForm />} />
          <Route path="/staff/:staffId" element={<StaffPerformancePage />} />

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
          <Route path="/day-close" element={<DayCloseScreen />} />

          {/* ─── Admin ──────────────────────────────────── */}
          <Route path="/admin/dashboard" element={<PlatformAdminDashboard />} />
          <Route path="/admin/audit-logs" element={<AuditLogsPage />} />
          <Route path="/admin/companies" element={<CompanyManagementPage />} />
          <Route path="/admin/analytics" element={<PlatformAnalyticsPage />} />
          <Route path="/admin/settings" element={<PlatformSettingsPage />} />

          {/* ─── CRM & Customer Intelligence ────────────── */}
          <Route path="/crm/customers" element={<CustomerListPage />} />
          <Route path="/crm/customers/:customerId" element={<Customer360View />} />
          <Route path="/crm/reminders" element={<SmartReminderDashboard />} />
          <Route path="/crm/loyalty" element={<LoyaltyProgramPage />} />

          {/* ─── Gift Cards ────────────────────────────── */}
          <Route path="/gift-cards/designer" element={<GiftCardPage />} />

          {/* ─── Floral Production Engine ───────────────── */}
          <Route path="/production/recipes" element={<FloralRecipeList />} />
          <Route path="/production/recipes/new" element={<FloralRecipeForm />} />
          <Route path="/production/recipes/:id/edit" element={<FloralRecipeForm />} />
          <Route path="/production/produce" element={<ProductionScreen />} />
          <Route path="/production/finished-goods" element={<FinishedGoodsInventory />} />
          <Route path="/production/custom-builder" element={<CustomBouquetBuilder />} />
          <Route path="/production/wastage" element={<WastageLogPage />} />

            <Route path="/production/jobs/:jobId" element={<ProductionJobDetailPage jobId={":jobId"} />} />

          {/* ─── Delivery Routes ───────────────────────────── */}
          <Route path="/delivery-routes" element={<DeliveryRoutesPage />} />
          <Route path="/delivery-routes/:routeId" element={<DeliveryRouteDetailPage />} />
          <Route path="/accounting/dashboard" element={<AccountingDashboard />} />
          <Route path="/accounting/chart-of-accounts" element={<ChartOfAccounts />} />
          <Route path="/accounting/account-ledger" element={<AccountLedger />} />
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
      </DiscountApprovalProvider>
    </RBACProvider>
  );
}
