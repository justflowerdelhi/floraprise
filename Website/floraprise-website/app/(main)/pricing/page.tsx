"use client";

import { useState } from "react";
import Link from "next/link";

type BillingCycle = "quarterly" | "halfYearly" | "annual" | "monthly";

function FAQItem({ question, answer }: { question: string; answer: string }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="mb-4">
      <button
        type="button"
        className="w-full text-left font-semibold text-lg bg-white p-5 rounded-xl shadow-xs border border-gray-200 focus:outline-none flex justify-between items-center transition hover:border-[#25784a]"
        onClick={() => setOpen(!open)}
      >
        <span>{question}</span>
        <span className="text-[#25784a] font-bold text-xl ml-4">
          {open ? "−" : "+"}
        </span>
      </button>
      {open && (
        <div className="mt-2 text-gray-600 bg-white p-5 rounded-xl border border-gray-100 text-base leading-relaxed">
          {answer}
        </div>
      )}
    </div>
  );
}

function FAQSection() {
  return (
    <section className="py-24 bg-[#f5f6f1]">
      <div className="max-w-4xl mx-auto px-6">
        <h2 className="text-3xl font-serif font-normal text-center mb-12 text-[#142219]">
          Frequently Asked Questions
        </h2>
        <FAQItem
          question="What is included in the Floraprise Starter plan?"
          answer="Floraprise Starter includes all essential florist POS, inventory, order management, cash book, day close, expenses, designer & delivery management, WhatsApp billing, and multi-device cloud features for single-store operations. It includes three operating modes: Android Local, Android Cloud, and Web."
        />
        <FAQItem
          question="What is the difference between Android Local and Android Cloud modes?"
          answer="Android Local runs fully offline with data saved locally on your primary device. Android Cloud connects your devices, allowing real-time multi-device access and cloud backups. Both are included in the Starter subscription."
        />
        <FAQItem
          question="When should we upgrade to Floraprise Professional?"
          answer="Professional is designed for growing businesses managing 1 to 3 store locations. It adds multi-location inventory, store-to-store stock transfers, multi-user permissions, location-wise reporting, and full central Web ERP controls."
        />
        <FAQItem
          question="How does Offline POS synchronization work?"
          answer="You can process sales, orders, and receipts even when internet connection is lost. As soon as connectivity is restored, your data automatically synchronizes with the cloud."
        />
        <FAQItem
          question="Can I upgrade or change my billing cycle later?"
          answer="Yes. You can upgrade from Starter to Professional or shift to annual billing anytime. All your business data, product catalogues, customer history, and workflows carry over seamlessly."
        />
        <FAQItem
          question="Do you offer onboarding and data migration support?"
          answer="Yes. Our team helps you import existing product lists, customer data, and stock levels, and provides staff training so your team can go live quickly."
        />
      </div>
    </section>
  );
}

export default function PricingPage() {
  const [cycle, setCycle] = useState<BillingCycle>("annual");

  return (
    <div className="bg-[#f5f6f1] text-[#142219]">
      {/* ================= HERO ================= */}
      <section className="pt-16 pb-12 text-center">
        <div className="max-w-4xl mx-auto px-6">
          <span className="inline-block text-[#25784a] text-xs font-extrabold uppercase tracking-widest mb-3">
            Floraprise Plans & Pricing
          </span>

          <h1 className="text-4xl md:text-5xl lg:text-6xl font-serif font-normal mb-4 text-[#142219] leading-tight">
            One Florist Platform. Three Ways to Work.
          </h1>

          <p className="text-xl md:text-2xl text-[#25784a] font-serif mb-4">
            Start with your shop. Grow with Floraprise.
          </p>

          <p className="text-gray-600 max-w-2xl mx-auto text-base sm:text-lg mb-10 leading-relaxed">
            From single-store florist shops to multi-location floral brands — select the operating scale built specifically for the business of flowers.
          </p>

          {/* Growth Path Visual */}
          <div className="my-8 max-w-3xl mx-auto p-4 sm:p-5 bg-white rounded-2xl border border-[#d9dfd7] shadow-xs">
            <div className="text-xs font-bold uppercase tracking-widest text-[#25784a] mb-3">
              Seamless Operational Growth Path
            </div>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-2 sm:gap-3 text-center">
              <div className="p-3 bg-[#f5f6f1] rounded-xl border border-gray-200">
                <div className="text-[11px] text-gray-500 font-bold uppercase tracking-wider">Mode 1</div>
                <div className="font-bold text-gray-900 text-sm mt-0.5">Android Local</div>
                <div className="text-[11px] text-gray-600 mt-1">Offline POS & Local Data</div>
              </div>
              <div className="p-3 bg-[#f5f6f1] rounded-xl border border-gray-200">
                <div className="text-[11px] text-gray-500 font-bold uppercase tracking-wider">Mode 2</div>
                <div className="font-bold text-gray-900 text-sm mt-0.5">Android Cloud</div>
                <div className="text-[11px] text-gray-600 mt-1">Multi-Device Sync</div>
              </div>
              <div className="p-3 bg-[#f5f6f1] rounded-xl border border-gray-200">
                <div className="text-[11px] text-gray-500 font-bold uppercase tracking-wider">Mode 3</div>
                <div className="font-bold text-gray-900 text-sm mt-0.5">Web ERP</div>
                <div className="text-[11px] text-gray-600 mt-1">Browser Workspace</div>
              </div>
              <div className="p-3 bg-[#124e2c] text-white rounded-xl border border-[#124e2c]">
                <div className="text-[11px] text-green-200 font-bold uppercase tracking-wider">Multi-Store</div>
                <div className="font-bold text-sm mt-0.5">Multi-Store ERP</div>
                <div className="text-[11px] text-green-100 mt-1">1 to 4+ Locations</div>
              </div>
            </div>
          </div>

          {/* Billing Cycle Selector */}
          <div className="inline-flex flex-wrap justify-center items-center p-1.5 bg-white border border-[#d9dfd7] rounded-xl shadow-xs gap-1">
            <button
              type="button"
              onClick={() => setCycle("monthly")}
              className={`px-4 py-2 text-sm font-semibold rounded-lg transition ${
                cycle === "monthly"
                  ? "bg-[#124e2c] text-white shadow-xs"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              Monthly
            </button>
            <button
              type="button"
              onClick={() => setCycle("quarterly")}
              className={`px-4 py-2 text-sm font-semibold rounded-lg transition ${
                cycle === "quarterly"
                  ? "bg-[#124e2c] text-white shadow-xs"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              Quarterly (3 Mos)
            </button>
            <button
              type="button"
              onClick={() => setCycle("halfYearly")}
              className={`px-4 py-2 text-sm font-semibold rounded-lg transition ${
                cycle === "halfYearly"
                  ? "bg-[#124e2c] text-white shadow-xs"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              Half-Yearly (6 Mos)
            </button>
            <button
              type="button"
              onClick={() => setCycle("annual")}
              className={`px-4 py-2 text-sm font-semibold rounded-lg transition flex items-center gap-1.5 ${
                cycle === "annual"
                  ? "bg-[#124e2c] text-white shadow-xs"
                  : "text-gray-600 hover:text-gray-900"
              }`}
            >
              <span>Annual</span>
              <span className="text-[10px] bg-[#e48a24] text-white px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">
                Best Value
              </span>
            </button>
          </div>
        </div>
      </section>

      {/* ================= PLANS ================= */}
      <section className="pb-24 px-6">
        <div className="max-w-7xl mx-auto grid lg:grid-cols-3 gap-8 items-stretch">
          
          {/* ================= 1. FLORAPRISE STARTER ================= */}
          <div className="bg-white rounded-2xl border border-[#d9dfd7] p-8 shadow-sm flex flex-direction flex-col justify-between relative hover:border-[#25784a] transition">
            <div>
              <div className="text-xs font-extrabold uppercase tracking-widest text-[#25784a] mb-1">
                Single Store / Small Business
              </div>
              <h3 className="text-2xl sm:text-3xl font-serif font-normal text-[#142219] mb-2">
                Floraprise Starter
              </h3>
              <p className="text-gray-600 text-sm mb-6 min-h-[40px]">
                &ldquo;Everything a modern florist needs to run their business.&rdquo;
              </p>

              {/* Price display */}
              <div className="mb-6 p-4 bg-[#f5f6f1] rounded-xl border border-gray-200">
                {cycle === "annual" && (
                  <div>
                    <div className="flex items-baseline gap-2">
                      <span className="text-3xl font-extrabold text-[#124e2c]">₹14,999</span>
                      <span className="text-gray-600 text-sm font-medium">/ year</span>
                    </div>
                    <div className="text-xs text-[#25784a] font-bold mt-1 flex items-center justify-between">
                      <span>Equivalent to ~₹1,250 / month</span>
                      <span className="bg-[#e48a24] text-white text-[10px] px-2 py-0.5 rounded-md uppercase">Best Value</span>
                    </div>
                  </div>
                )}

                {cycle === "halfYearly" && (
                  <div>
                    <div className="flex items-baseline gap-2">
                      <span className="text-3xl font-extrabold text-[#124e2c]">₹8,999</span>
                      <span className="text-gray-600 text-sm font-medium">/ 6 months</span>
                    </div>
                    <div className="text-xs text-gray-600 font-medium mt-1">
                      Equivalent to ~₹1,500 / month
                    </div>
                  </div>
                )}

                {(cycle === "quarterly" || cycle === "monthly") && (
                  <div>
                    <div className="flex items-baseline gap-2">
                      <span className="text-3xl font-extrabold text-[#124e2c]">₹4,999</span>
                      <span className="text-gray-600 text-sm font-medium">/ 3 months</span>
                    </div>
                    <div className="text-xs text-gray-600 font-medium mt-1">
                      Billed quarterly (~₹1,666 / month)
                    </div>
                  </div>
                )}

                {/* Duration options pill summary */}
                <div className="mt-3 pt-3 border-t border-gray-200 text-xs text-gray-600 flex flex-wrap gap-2">
                  <span className={`px-2 py-0.5 rounded ${cycle === "quarterly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border"}`}>
                    ₹4,999 / 3m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${cycle === "halfYearly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border"}`}>
                    ₹8,999 / 6m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${cycle === "annual" ? "bg-[#124e2c] text-white font-bold" : "bg-white border"}`}>
                    ₹14,999 / yr
                  </span>
                </div>
              </div>

              {/* Operating modes callout */}
              <div className="mb-6 p-3 bg-[#e6ede5] rounded-xl text-xs text-[#124e2c] font-medium leading-relaxed">
                <strong className="block font-bold mb-1">1 Subscription • 3 Operating Modes:</strong>
                Android Local (Offline) • Android Cloud (Synced) • Web
              </div>

              {/* Features list */}
              <div className="mb-8">
                <p className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-3">
                  Key Florist Features Included:
                </p>
                <ul className="space-y-2.5 text-sm text-gray-700">
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Florist-focused POS</strong> (Take Away, Pickup & Delivery)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Products & Inventory</strong> (Perishables & Accessories)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Offline POS</strong> with automatic cloud synchronization</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Orders & Payments</strong> with split payment tracking</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Customers & Order History</strong> with credit lookup</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Cash Book & Day Close</strong> with cash variance audit</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Expenses</strong> tracking by payment mode</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Designer & Delivery Management</strong> workflow</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Product Catalogue & Album</strong> for walk-ins</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>WhatsApp-ready</strong> billing & receipt communication</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Cloud multi-device</strong> connected operation</span>
                  </li>
                </ul>
              </div>
            </div>

            <Link
              href="/demo"
              className="block w-full text-center py-3.5 px-6 rounded-xl font-bold bg-[#124e2c] text-white hover:bg-[#0b3c20] transition shadow-xs"
            >
              Get Started
            </Link>
          </div>

          {/* ================= 2. FLORAPRISE PROFESSIONAL ================= */}
          <div className="bg-white rounded-2xl border-2 border-[#124e2c] p-8 shadow-xl flex flex-direction flex-col justify-between relative scale-100 lg:scale-[1.02]">
            
            {/* Badge */}
            <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-[#124e2c] text-white text-xs font-extrabold uppercase tracking-widest px-4 py-1 rounded-full shadow-md flex items-center gap-1.5">
              <span>⭐</span> MOST POPULAR
            </div>

            <div>
              <div className="text-xs font-extrabold uppercase tracking-widest text-[#25784a] mb-1 pt-1">
                Growing Business (1–3 Stores)
              </div>
              <h3 className="text-2xl sm:text-3xl font-serif font-normal text-[#142219] mb-2">
                Floraprise Professional
              </h3>
              <p className="text-gray-600 text-sm mb-6 min-h-[40px]">
                &ldquo;When one shop becomes a growing business.&rdquo;
              </p>

              {/* Price display */}
              <div className="mb-6 p-4 bg-[#e6ede5] rounded-xl border border-[#c4d6c2]">
                {cycle === "annual" && (
                  <div>
                    <div className="flex items-baseline gap-2">
                      <span className="text-3xl font-extrabold text-[#124e2c]">₹20,999</span>
                      <span className="text-gray-600 text-sm font-medium">/ year</span>
                    </div>
                    <div className="text-xs text-[#124e2c] font-bold mt-1 flex items-center justify-between">
                      <span>Equivalent to ~₹1,750 / month</span>
                      <span className="bg-[#e48a24] text-white text-[10px] px-2 py-0.5 rounded-md uppercase font-bold">
                        Save 30% • BEST VALUE
                      </span>
                    </div>
                  </div>
                )}

                {cycle === "halfYearly" && (
                  <div>
                    <div className="flex items-baseline gap-2">
                      <span className="text-3xl font-extrabold text-[#124e2c]">₹12,999</span>
                      <span className="text-gray-600 text-sm font-medium">/ 6 months</span>
                    </div>
                    <div className="text-xs text-[#124e2c] font-bold mt-1 flex items-center justify-between">
                      <span>Equivalent to ~₹2,166 / month</span>
                      <span className="bg-[#124e2c] text-white text-[10px] px-2 py-0.5 rounded-md uppercase font-bold">
                        Save ~13%
                      </span>
                    </div>
                  </div>
                )}

                {cycle === "quarterly" && (
                  <div>
                    <div className="flex items-baseline gap-2">
                      <span className="text-3xl font-extrabold text-[#124e2c]">₹6,999</span>
                      <span className="text-gray-600 text-sm font-medium">/ 3 months</span>
                    </div>
                    <div className="text-xs text-[#124e2c] font-bold mt-1 flex items-center justify-between">
                      <span>Equivalent to ~₹2,333 / month</span>
                      <span className="bg-[#124e2c] text-white text-[10px] px-2 py-0.5 rounded-md uppercase font-bold">
                        Save ~7%
                      </span>
                    </div>
                  </div>
                )}

                {cycle === "monthly" && (
                  <div>
                    <div className="flex items-baseline gap-2">
                      <span className="text-3xl font-extrabold text-[#124e2c]">₹2,499</span>
                      <span className="text-gray-600 text-sm font-medium">/ month</span>
                    </div>
                    <div className="text-xs text-gray-600 font-medium mt-1">
                      Flexible monthly billing
                    </div>
                  </div>
                )}

                {/* Duration options pill summary */}
                <div className="mt-3 pt-3 border-t border-[#c4d6c2] text-xs text-gray-700 flex flex-wrap gap-1.5">
                  <span className={`px-2 py-0.5 rounded ${cycle === "monthly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border"}`}>
                    ₹2,499 / mo
                  </span>
                  <span className={`px-2 py-0.5 rounded ${cycle === "quarterly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border"}`}>
                    ₹6,999 / 3m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${cycle === "halfYearly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border"}`}>
                    ₹12,999 / 6m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${cycle === "annual" ? "bg-[#124e2c] text-white font-bold" : "bg-white border"}`}>
                    ₹20,999 / yr
                  </span>
                </div>
              </div>

              {/* Includes everything in Starter plus */}
              <div className="mb-8">
                <p className="text-xs font-bold uppercase tracking-wider text-[#124e2c] mb-3">
                  Includes Everything in Starter, Plus:
                </p>
                <ul className="space-y-2.5 text-sm text-gray-700">
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>1–3 locations</strong> supported natively</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Multi-location inventory</strong> tracking & batches</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Store-to-store stock transfers</strong> & fulfillment</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Centralized business management</strong></span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Multiple staff & user access</strong> control</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Advanced inventory controls</strong> (FIFO & wastage)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Location-wise sales & reports</strong></span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Designer & Delivery workflow</strong> intelligence</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Advanced business reports</strong> & P&L analytics</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Centralized dashboard</strong> for multi-store overview</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Full Web ERP experience</strong> across browsers</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Cloud-based multi-store operations</strong></span>
                  </li>
                </ul>
              </div>
            </div>

            <Link
              href="/demo"
              className="block w-full text-center py-3.5 px-6 rounded-xl font-bold bg-[#124e2c] text-white hover:bg-[#0b3c20] transition shadow-md"
            >
              Get Started with Professional
            </Link>
          </div>

          {/* ================= 3. FLORAPRISE ENTERPRISE ================= */}
          <div className="bg-white rounded-2xl border border-[#d9dfd7] p-8 shadow-sm flex flex-direction flex-col justify-between relative hover:border-[#25784a] transition">
            <div>
              <div className="text-xs font-extrabold uppercase tracking-widest text-[#25784a] mb-1">
                4+ Locations / Chains
              </div>
              <h3 className="text-2xl sm:text-3xl font-serif font-normal text-[#142219] mb-2">
                Floraprise Enterprise
              </h3>
              <p className="text-gray-600 text-sm mb-6 min-h-[40px]">
                &ldquo;Built for larger florist businesses and chains.&rdquo;
              </p>

              {/* Price display */}
              <div className="mb-6 p-4 bg-[#f5f6f1] rounded-xl border border-gray-200">
                <div className="text-3xl font-extrabold text-[#124e2c]">Custom Pricing</div>
                <div className="text-xs text-gray-600 font-medium mt-1">
                  Tailored to your store network & requirements
                </div>
              </div>

              {/* Features list */}
              <div className="mb-8">
                <p className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-3">
                  Enterprise Capabilities:
                </p>
                <ul className="space-y-2.5 text-sm text-gray-700">
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Multi-store enterprise management</strong> (4+ stores)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Advanced inventory & controls</strong> across warehouses</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Centralized management</strong> & corporate accounts</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Advanced permissions</strong> & custom role hierarchy</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Enterprise reporting</strong> & custom BI analytics</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Custom integrations</strong> (ERP, e-commerce, accounting)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Custom business requirements</strong> & workflows</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Dedicated onboarding & support</strong> engineer</span>
                  </li>
                </ul>
              </div>
            </div>

            <Link
              href="/demo"
              className="block w-full text-center py-3.5 px-6 rounded-xl font-bold bg-[#142219] text-white hover:bg-black transition shadow-xs"
            >
              Talk to Floraprise
            </Link>
          </div>

        </div>
      </section>

      {/* ================= SWITCHING REASSURANCE ================= */}
      <section className="py-24 bg-white border-t border-[#d9dfd7]">
        <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-2 gap-16 items-center">
          <div>
            <span className="text-[#25784a] text-xs font-extrabold uppercase tracking-widest mb-2 block">
              Hassle-Free Setup
            </span>
            <h2 className="text-3xl sm:text-4xl font-serif font-normal mb-6 text-[#142219]">
              Switching to Floraprise is Simple
            </h2>
            <p className="text-gray-600 mb-6 text-base leading-relaxed">
              Moving from spreadsheets or a legacy POS system?
              Our onboarding specialists ensure a smooth transition with guided setup, product imports, training, and go-live support.
            </p>
            <ul className="space-y-3.5 text-gray-700 text-sm font-medium">
              <li className="flex items-center gap-2.5">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Free onboarding & setup guidance</span>
              </li>
              <li className="flex items-center gap-2.5">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Product catalogue & stock data migration support</span>
              </li>
              <li className="flex items-center gap-2.5">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Staff & designer workflow training sessions</span>
              </li>
              <li className="flex items-center gap-2.5">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Dedicated onboarding support for Professional & Enterprise</span>
              </li>
              <li className="flex items-center gap-2.5">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Go-live assistance during busy floral seasons</span>
              </li>
            </ul>
          </div>

          <div className="bg-[#f5f6f1] p-8 rounded-2xl border border-[#d9dfd7]">
            <h3 className="text-xl font-serif font-normal text-[#142219] mb-4">
              Typical Onboarding Timeline
            </h3>
            <ul className="space-y-3.5 text-sm text-gray-700">
              <li className="flex justify-between items-center border-b border-gray-200 pb-2.5">
                <strong>Day 1:</strong>
                <span className="text-gray-600">System setup & store configuration</span>
              </li>
              <li className="flex justify-between items-center border-b border-gray-200 pb-2.5">
                <strong>Day 2–3:</strong>
                <span className="text-gray-600">Product & inventory catalog import</span>
              </li>
              <li className="flex justify-between items-center border-b border-gray-200 pb-2.5">
                <strong>Day 4–5:</strong>
                <span className="text-gray-600">Staff training & trial billing</span>
              </li>
              <li className="flex justify-between items-center pb-1">
                <strong>Week 2:</strong>
                <span className="text-gray-600">Full operational launch</span>
              </li>
            </ul>
            <p className="mt-6 text-xs text-gray-500 italic">
              Most florist shops are fully operational within 3 to 7 days.
            </p>
          </div>
        </div>
      </section>

      {/* ================= HELP SECTION ================= */}
      <section className="py-20 bg-[#124e2c] text-white text-center">
        <div className="max-w-3xl mx-auto px-6">
          <span className="text-green-300 text-xs font-extrabold uppercase tracking-widest mb-2 block">
            Expert Guidance
          </span>
          <h2 className="text-3xl sm:text-4xl font-serif font-normal mb-4">
            Not Sure Which Setup Fits Your Business?
          </h2>

          <p className="text-green-100 text-base sm:text-lg mb-8 leading-relaxed max-w-xl mx-auto">
            Tell us about your daily order volume and store setup — we&apos;ll recommend the exact operating mode and plan for your business.
          </p>

          <Link
            href="/demo"
            className="inline-block bg-white text-[#124e2c] px-8 py-4 rounded-xl font-extrabold hover:bg-green-50 transition shadow-md"
          >
            Talk to Our Team
          </Link>
        </div>
      </section>

      {/* ================= FAQ ================= */}
      <FAQSection />
    </div>
  );
}
