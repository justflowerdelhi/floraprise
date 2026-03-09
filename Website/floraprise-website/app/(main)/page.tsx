import HeroPremium from "@/components/HeroPremium";
import Features from "@/components/Features";
import FinalCTA from "@/components/FinalCTA";
import CredibilityStrip from "@/components/CredibilityStrip";
import ProblemSection from "@/components/ProblemSection";
import FeatureComparison from "@/components/FeatureComparison";
import Testimonials from "@/components/Testimonials";
import LifestyleSection from "@/components/LifestyleSection";
import DashboardShowcase from "@/components/DashboardShowcase";
import Integrations from "@/components/Integrations";
import AccountingModule from "@/components/AccountingModule";
import PlatformSection from "@/components/PlatformSection";
import ComparisonSection from "@/components/ComparisonSection";
import FloristTypes from "@/components/FloristTypes";
import ImpactStats from "@/components/ImpactStats";
import Capabilities from "@/components/Capabilities";
import FinalPremiumCTA from "@/components/FinalPremiumCTA";
import ProductGallery from "@/components/ProductGallery";

export default function Home() {
  return (
    <>
      <HeroPremium />
      <CredibilityStrip />
      <ProblemSection />
      {/* ================= FEATURE SECTION ================= */}
      <section className="py-4 bg-white">
        <div className="max-w-7xl mx-auto px-6">
          {/* Section Header */}
          <div className="text-center mb-6">
            <h2 className="text-4xl font-semibold mb-6">
              Operational Intelligence for Modern Florists
            </h2>
            <p className="text-gray-600 max-w-3xl mx-auto text-lg">
              Floraprise unifies retail sales, perishable inventory,
              production workflows, delivery logistics, accounting,
              and multi-location management into one intelligent,
              inventory-first florist ERP platform.
            </p>
          </div>
          {/* GRID START */}
          <div className="grid md:grid-cols-2 gap-10">
            {/* 1️⃣ Retail & Transactions */}
            <div>
              <h3 className="text-2xl font-semibold mb-6 text-green-700">
                Retail & Transactions
              </h3>
              <ul className="space-y-4 text-gray-700">
                <li>
                  🌿 <strong>Intent-Based Retail POS</strong><br />
                  Smart billing for Take Away, Delivery, and Pickup orders
                  with workflow-triggered operations.
                </li>
                <li>
                  🧾 <strong>Professional Billing & Invoicing</strong><br />
                  Tax-ready invoices with multi-currency and country-based tax support.
                </li>
                <li>
                  💳 <strong>Integrated Payment Support</strong><br />
                  Cash, card, UPI, online payments, partial payments,
                  and split billing support.
                </li>
                <li>
                  🎁 <strong>Gift Card & Wire Order Management</strong><br />
                  Issue, redeem, and track balances while managing
                  incoming and outgoing wire orders.
                </li>
              </ul>
            </div>
            {/* 2️⃣ Inventory & Production */}
            <div>
              <h3 className="text-2xl font-semibold mb-6 text-green-700">
                Inventory & Production
              </h3>
              <ul className="space-y-4 text-gray-700">
                <li>
                  📦 <strong>Perishable Inventory Management</strong><br />
                  Batch tracking, FIFO logic, expiry alerts,
                  and spoilage control for floral stock.
                </li>
                <li>
                  🌸 <strong>Recipe-Based Production Engine</strong><br />
                  Create bouquets with controlled raw material deduction
                  and wastage tracking.
                </li>
                <li>
                  💍 <strong>Wedding & Event Management</strong><br />
                  Proposal creation, costing, scheduling,
                  and event production tracking.
                </li>
              </ul>
            </div>
            {/* 3️⃣ Operations & Logistics */}
            <div>
              <h3 className="text-2xl font-semibold mb-6 text-green-700">
                Operations & Logistics
              </h3>
              <ul className="space-y-4 text-gray-700">
                <li>
                  🚚 <strong>Delivery & Route Management</strong><br />
                  Driver assignment, delivery zones,
                  route planning, and order tracking.
                </li>
                <li>
                  👥 <strong>Staff & Shift Control</strong><br />
                  Role-based access, shift opening/closing,
                  performance tracking, and time management.
                </li>
                <li>
                  🏬 <strong>Multi-Location Management</strong><br />
                  Centralized operational visibility
                  for growing florist chains.
                </li>
              </ul>
            </div>
            {/* 4️⃣ Financial & Intelligence */}
            <div>
              <h3 className="text-2xl font-semibold mb-6 text-green-700">
                Financial Control & Intelligence
              </h3>
              <ul className="space-y-4 text-gray-700">
                <li>
                  📊 <strong>Profit & Margin Intelligence</strong><br />
                  Real-time cost tracking, bouquet-level margin visibility,
                  and operational profitability insights.
                </li>
                <li>
                  📚 <strong>Integrated Accounting Module</strong><br />
                  Ledger management, expense tracking,
                  tax summaries, and QuickBooks-ready integration.
                </li>
                <li>
                  🔐 <strong>Secure Cloud-Based SaaS Platform</strong><br />
                  Multi-tenant, role-controlled, scalable architecture
                  built for enterprise-grade reliability.
                </li>
              </ul>
            </div>
          </div>
          {/* Explore All Features Button */}
          <div className="text-center mt-6">
            <a
              href="/features"
              className="bg-green-700 text-white px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
            >
              Explore All Features
            </a>
          </div>
        </div>
      </section>
      <DashboardShowcase />
      <ProductGallery />
      <PlatformSection />
      <ComparisonSection />
      <FloristTypes />
      <AccountingModule />
      <Integrations />
      <ImpactStats />
      <FeatureComparison />
      <Testimonials />
      <FinalCTA />
    </>
  );
}