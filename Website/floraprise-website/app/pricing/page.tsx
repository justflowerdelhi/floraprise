"use client";
type PlanCardProps = {
  title: string;
  subtitle: string;
  suitable: string[];
  features: string[];
  highlight: boolean;
  badge?: string;
  yearly: boolean;
};
// ================= FAQItem (Bottom Version) =================
import { useState } from "react";

function FAQItem({ question, answer }: { question: string; answer: string }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="mb-6">
      <button
        className="w-full text-left font-semibold text-lg bg-white p-4 rounded-lg shadow-sm border border-gray-200 focus:outline-none"
        onClick={() => setOpen(!open)}
      >
        {question}
      </button>
      {open && (
        <div className="mt-2 text-gray-600 bg-white p-4 rounded-lg border border-gray-100">
          {answer}
        </div>
      )}
    </div>
  );
}

function FAQSection() {
  return (
    <section className="py-28 bg-[#f8f8f6]">
      <div className="max-w-4xl mx-auto px-6">
        <h2 className="text-3xl font-semibold text-center mb-12">
          Frequently Asked Questions
        </h2>
        <FAQItem
          question="Do you charge per user?"
          answer="No. Floraprise plans are structured around operational scale and order volume, not individual user counts."
        />
        <FAQItem
          question="Can I upgrade my plan later?"
          answer="Yes. You can upgrade anytime as your business grows. All data and workflows remain intact."
        />
        <FAQItem
          question="Does Floraprise support GST / VAT?"
          answer="Yes. The system supports country-based tax configuration including GST and VAT rules."
        />
        <FAQItem
          question="Do you integrate with QuickBooks or Tally?"
          answer="Yes. Growth and Pro plans include accounting integrations for seamless financial management."
        />
        <FAQItem
          question="Is there a contract lock-in?"
          answer="No long-term lock-ins. Annual plans offer savings of up to 30%, but you can choose monthly billing as well."
        />
      </div>
    </section>
  );
}

export default function PricingPage() {
  const [yearly, setYearly] = useState(false);

  return (
    <div className="bg-white">

      {/* ================= HERO ================= */}
      <section className="py-12 text-center">
        <div className="max-w-4xl mx-auto px-6">

          <h1 className="text-4xl md:text-5xl font-semibold mb-6">
            🌿 Floraprise Plans
          </h1>

          <p className="text-xl text-gray-600 mb-4">
            Built for Every Stage of Your Florist Business
          </p>

          <p className="text-gray-600 mb-10">
            Scale confidently — from a small neighborhood flower shop
            to a multi-location floral brand.
          </p>

          {/* Billing Toggle */}
          <div className="flex justify-center items-center gap-4">

            <span className={!yearly ? "font-semibold" : "text-gray-500"}>
              Monthly
            </span>

            <button
              onClick={() => setYearly(!yearly)}
              className="relative w-14 h-7 bg-gray-300 rounded-full transition"
            >
              <div
                className={`absolute top-1 left-1 w-5 h-5 bg-white rounded-full shadow transition ${
                  yearly ? "translate-x-7" : ""
                }`}
              />
            </button>

            <span className={yearly ? "font-semibold" : "text-gray-500"}>
              Yearly
            </span>

            {yearly && (
              <span className="ml-3 text-sm bg-green-100 text-green-700 px-3 py-1 rounded-full font-semibold">
                Save up to 30%
              </span>
            )}

          </div>
        </div>
      </section>


      {/* ================= PLANS ================= */}
      <section className="pb-28">
        <div className="max-w-7xl mx-auto px-6 grid md:grid-cols-3 gap-10">

          <PlanCard
            title="🌱 Starter Plan"
            subtitle="For Small Florist Shops"
            highlight={false}
            yearly={yearly}
            suitable={[
              "1–50 Orders Per Day",
              "Single Location",
              "Small Team Operations"
            ]}
            features={[
              "Intent-Based Retail POS",
              "Professional Billing & Tax Invoicing",
              "Basic Perishable Inventory (Batch + FIFO)",
              "Basic Florist-Friendly Accounting",
              "Integrated Payment Support",
              "Sales Dashboard & Reports",
              "Email Support"
            ]}
          />

          <PlanCard
            title="🌿 Growth Plan"
            subtitle="For Busy Retail & Delivery Florists"
            highlight={true}
            badge="⭐ Most Popular"
            yearly={yearly}
            suitable={[
              "1–100 Orders Per Day",
              "Single Location",
              "Delivery & Event-Focused Businesses"
            ]}
            features={[
              "Everything in Starter",
              "Recipe-Based Production Engine",
              "Delivery & Route Management",
              "Wedding & Event Management",
              "Advanced Inventory Controls",
              "Staff & Shift Management",
              "Gift Card Management",
              "Profit & Margin Intelligence",
              "Accounting with P&L Reports",
              "QuickBooks / Tally Integration",
              "Priority Support"
            ]}
          />

          <PlanCard
            title="🌳 Pro Plan"
            subtitle="For Multi-Location & High-Volume Florists"
            highlight={false}
            yearly={yearly}
            suitable={[
              "Unlimited Order Processing",
              "Multi-Location Setup",
              "High-Volume & Wire-Ready Operations"
            ]}
            features={[
              "Everything in Growth",
              "Multi-Location Management",
              "Wire Order Support",
              "Centralized Financial Reporting",
              "Advanced Role-Based Access Control",
              "API & Third-Party Integrations",
              "Custom Workflow Automation",
              "Dedicated Onboarding & Migration",
              "Early Access to New Features"
            ]}
          />

        </div>
      </section>


      {/* ================= SWITCHING REASSURANCE ================= */}
      <section className="py-24 bg-white border-t">
        <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-2 gap-16 items-center">
          <div>
            <h2 className="text-3xl font-semibold mb-6">
              Switching to Floraprise is Simple
            </h2>
            <p className="text-gray-600 mb-6">
              Moving from spreadsheets or another POS system?
              Our onboarding team ensures a smooth transition with
              guided setup, training, and data migration support.
            </p>
            <ul className="space-y-4 text-gray-700">
              <li>✔ Free onboarding assistance</li>
              <li>✔ Data migration support</li>
              <li>✔ Staff training sessions</li>
              <li>✔ Dedicated account manager (Pro Plan)</li>
              <li>✔ Go-live assistance during peak seasons</li>
            </ul>
          </div>
          <div className="bg-[#f8f8f6] p-8 rounded-2xl shadow-sm">
            <h3 className="text-xl font-semibold mb-4">
              Typical Setup Timeline
            </h3>
            <ul className="space-y-3 text-gray-600">
              <li><strong>Day 1–2:</strong> System setup & configuration</li>
              <li><strong>Day 3–5:</strong> Inventory & product import</li>
              <li><strong>Week 1:</strong> Staff training & trial billing</li>
              <li><strong>Week 2:</strong> Full operational launch</li>
            </ul>
            <p className="mt-6 text-sm text-gray-500">
              Most florists are fully operational within 7–14 days.
            </p>
          </div>
        </div>
      </section>
      {/* ================= HELP SECTION ================= */}
      <section className="py-24 bg-[#f8f8f6] text-center">
        <div className="max-w-3xl mx-auto px-6">
          <h2 className="text-3xl font-semibold mb-6">
            🌼 Not Sure Which Plan Fits You?
          </h2>

          <p className="text-gray-600 mb-8">
            Tell us your average daily order volume and business model —
            and we’ll guide you to the right setup.
          </p>

          <a
            href="/demo"
            className="bg-green-700 text-white px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
          >
            Talk to Our Team
          </a>
        </div>
      </section>


      <FAQSection />
    </div>
  );
}


/* ================= PLAN CARD ================= */

function PlanCard({
    title,
    subtitle,
    suitable,
    features,
    highlight,
    badge,
    yearly
  }: PlanCardProps) {
  return (
    <div
      className={`p-8 rounded-2xl border transition ${
        highlight
          ? "border-green-700 shadow-xl scale-105"
          : "border-gray-200 shadow-sm"
      }`}
    >

      {badge && (
        <div className="mb-4 text-sm font-semibold text-green-700">
          {badge}
        </div>
      )}

      <h3 className="text-2xl font-semibold mb-2">{title}</h3>
      <p className="text-gray-600 mb-6">{subtitle}</p>

      {yearly && (
        <div className="mb-6 text-sm bg-green-50 text-green-700 px-4 py-2 rounded-lg font-medium">
          Annual billing applied – Save up to 30%
        </div>
      )}

      <div className="mb-6">
        <p className="font-semibold mb-2">Suitable for:</p>
        <ul className="space-y-2 text-gray-600">
          {suitable.map((item, i) => (
            <li key={i}>✔ {item}</li>
          ))}
        </ul>
      </div>

      <div className="mb-8">
        <p className="font-semibold mb-2">Includes:</p>
        <ul className="space-y-2 text-gray-600">
          {features.map((item, i) => (
            <li key={i}>✔ {item}</li>
          ))}
        </ul>
      </div>

      <a
        href="/demo"
        className={`block text-center py-3 rounded-lg font-semibold transition ${
          highlight
            ? "bg-green-700 text-white hover:opacity-90"
            : "bg-gray-900 text-white hover:opacity-90"
        }`}
      >
        Request Demo
      </a>
    </div>
  );
}