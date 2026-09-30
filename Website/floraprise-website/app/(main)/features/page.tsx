import Link from "next/link";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Features — Floraprise Florist POS, Inventory & ERP",
  description:
    "Explore Floraprise features built specifically for flower shops: florist POS, perishable flower batch inventory, bouquet recipe costing, delivery dispatch, day close cash variance, and multi-store ERP.",
  alternates: {
    canonical: "https://floraprise.com/features",
  },
};

const FEATURES_LIST = [
  {
    category: "POS & Billing",
    tag: "Counter Speed",
    title: "Florist Point of Sale & Intent-Based Billing",
    desc: "Fast, florist-tailored counter checkout designed for walk-in rush and phone orders. Every transaction captures fulfillment intent (Take Away, Delivery, Pickup) to route orders instantly into production and delivery queues.",
    points: [
      "Order intent selection: Take Away, Delivery, or Pickup with dedicated workflows",
      "Instant WhatsApp & SMS digital bill sharing with 1-tap customer receipt",
      "Split tender & multi-mode payments (Cash, UPI, Card, Store Credit, Deposits)",
      "Advance booking deposit collection with automatic remaining balance tracking",
      "Thermal ticket printing & customer card message printing",
      "Full offline POS resilience with automatic cloud synchronization",
    ],
    badgeColor: "bg-emerald-50 text-emerald-800 border-emerald-200",
  },
  {
    category: "Perishable Inventory",
    tag: "Fresh Flower Control",
    title: "Perishable Batch & Stem-Level Inventory",
    desc: "Flowers aren't dry goods. Floraprise tracks perishable flower arrivals in distinct dated batches with FIFO (First-In, First-Out) logic, preventing stale stems from hiding in cool rooms while newer stock is sold.",
    points: [
      "Stem-level and bunch-level perishable inventory tracking",
      "Batch receiving with supplier cost, arrival date, and cool room location",
      "FIFO flower rotation alerts to minimize flower decay and spoilage",
      "Dedicated spoilage and wastage logging with reason categorization",
      "Non-perishable inventory tracking for vases, ribbons, wraps, and cards",
      "Low-stock alerts before peak floral weekends and festive dates",
    ],
    badgeColor: "bg-rose-50 text-rose-800 border-rose-200",
  },
  {
    category: "Production & Recipes",
    tag: "Margin Protection",
    title: "Bouquet Recipe Costing & Assembly Engine",
    desc: "Protect your margins on signature bouquets, standing arrangements, and wedding packages. Standardize bouquet recipes with exact stem counts, foliage, wrapping materials, and labor costing.",
    points: [
      "Standard recipe creation with auto-calculated cost-of-goods (COGS)",
      "Automatic stock deduction of individual stems and accessories upon sale",
      "Custom arrangement builder for walk-in customers with live pricing",
      "Wastage allowance buffers built into arrangement costing",
      "Seasonal price fluctuation updates across all bouquet recipes",
      "Wedding & large event proposal costing with multi-item quotes",
    ],
    badgeColor: "bg-amber-50 text-amber-800 border-amber-200",
  },
  {
    category: "Order Management",
    tag: "Zero Missed Orders",
    title: "Complete Floral Order Lifecycle Tracking",
    desc: "Replace disorganized paper notepads and WhatsApp chats. Every floral order moves through clear operational stages: Received → In Production → Ready for Dispatch → Out for Delivery → Delivered.",
    points: [
      "Unified order board for walk-in, phone, WhatsApp, and online orders",
      "Advance event order scheduling with calendar and production timelines",
      "Status alerts keeping counter staff, florists, and drivers aligned",
      "Card message capturing with font-ready greeting card printing",
      "Recipient delivery notes and special instruction highlighting",
      "Audit trail tracking order modifications, cancellations, and refunds",
    ],
    badgeColor: "bg-blue-50 text-blue-800 border-blue-200",
  },
  {
    category: "Designer Workflow",
    tag: "Florist Workstation",
    title: "Designer Assignment & Workstation Queue",
    desc: "Keep your floral artists focused on arranging flowers rather than chasing paper chits. Assign incoming orders to specific florists or workstations based on skill, style, or event queue.",
    points: [
      "Live florist workstation screen displaying pending arrangements",
      "Clear visual recipe guides and stem breakdown for each order",
      "One-click 'Ready for Delivery' completion marking",
      "Photo attachment of completed arrangement before packing",
      "Designer productivity and arrangement output tracking",
    ],
    badgeColor: "bg-purple-50 text-purple-800 border-purple-200",
  },
  {
    category: "Delivery Logistics",
    tag: "Punctual Delivery",
    title: "Delivery Dispatch & Driver Route Management",
    desc: "Flowers delivered late ruin special moments. Manage delivery drivers, batch nearby orders into efficient delivery runs, and verify delivery completion with photo and recipient signature.",
    points: [
      "Time-slot based delivery scheduling (Morning, Afternoon, Evening, Midnight)",
      "Driver assignment and delivery run sheet generation",
      "Dedicated mobile driver view for delivery navigation and status updates",
      "Proof-of-delivery capture via photo upload and recipient confirmation",
      "Delivery zone configuration with distance-based or pincode-based delivery fees",
      "Live delivery status updates sent to sender via WhatsApp",
    ],
    badgeColor: "bg-cyan-50 text-cyan-800 border-cyan-200",
  },
  {
    category: "Cash & Accounting",
    tag: "Financial Clarity",
    title: "Cash Book, Day Close & Variance Detection",
    desc: "Eliminate evening cash reconciliation confusion. Floraprise audits opening float, counter cash collections, card/UPI gateway receipts, petty cash expenses, and closing balance.",
    points: [
      "Structured Day Close wizard with expected vs counted cash variance",
      "Petty cash expense recording categorized by payment mode and vendor",
      "Split tender reconciliation across cash, UPI, cards, and payment links",
      "Staff shift handover reporting with drawer accountability",
      "Daily, weekly, and monthly sales summaries with profit margins",
      "Accounting exports compatible with Tally and QuickBooks",
    ],
    badgeColor: "bg-teal-50 text-teal-800 border-teal-200",
  },
  {
    category: "Customer & CRM",
    tag: "Repeat Relationships",
    title: "Customer Credit Ledger & Floral CRM",
    desc: "Floral businesses thrive on repeat buyers. Build customer loyalty with order history lookup, corporate account credit balances, anniversary reminders, and personalized recommendations.",
    points: [
      "Fast customer search by mobile number or name at counter checkout",
      "Complete customer order history with favorite flower preferences",
      "Corporate client credit ledger with outstanding balance limits and statements",
      "Occasion reminders (Birthdays, Anniversaries, Corporate annual events)",
      "Customer segment reporting for seasonal marketing and WhatsApp outreach",
    ],
    badgeColor: "bg-indigo-50 text-indigo-800 border-indigo-200",
  },
  {
    category: "Visual Merchandising",
    tag: "Upsell Walk-ins",
    title: "Digital Product Catalogue & Lookbook Album",
    desc: "Showcase your complete bouquet portfolio on your tablet or counter screen. Help walk-in customers visualize arrangements by occasion, color palette, and price range.",
    points: [
      "High-resolution bouquet photo catalogue organized by categories and themes",
      "Occasion filtering: Romance, Sympathy, Birthday, Get Well, Weddings",
      "1-tap 'Order This Design' directly from the visual lookbook",
      "Seasonal catalogue updates for Valentine’s Day, Mother’s Day, and festive seasons",
      "Add-on suggestion prompts (Chocolates, Vases, Teddy bears, Luxury cards)",
    ],
    badgeColor: "bg-fuchsia-50 text-fuchsia-800 border-fuchsia-200",
  },
  {
    category: "Multi-Store ERP",
    tag: "Scalable Growth",
    title: "Multi-Location Control & Central Warehouse",
    desc: "Scale from a single boutique to a multi-location floral business. Manage multiple store locations, central warehouses, inter-store flower transfers, and multi-location reporting from one dashboard.",
    points: [
      "Centralized master catalogue with location-specific pricing and availability",
      "Store-to-store stock transfers and central warehouse replenishment requests",
      "Multi-location sales, inventory valuation, and reporting dashboards",
      "Role-based staff permissions (Chain Owner, Branch Manager, Florist, Cashier)",
      "Multi-branch performance benchmarks and activity logs",
    ],
    badgeColor: "bg-orange-50 text-orange-800 border-orange-200",
  },
];

export default function FeaturesPage() {
  return (
    <div className="bg-[#f5f6f1] text-[#142219]">
      {/* ================= HERO ================= */}
      <section className="pt-20 pb-16 text-center">
        <div className="max-w-4xl mx-auto px-6">
          <span className="inline-block text-[#25784a] text-xs font-extrabold uppercase tracking-widest mb-3 bg-[#e6ede5] px-3.5 py-1 rounded-full border border-[#c4d6c2]">
            Comprehensive Florist Platform
          </span>

          <h1 className="text-4xl md:text-5xl lg:text-6xl font-serif font-normal mb-6 text-[#142219] leading-tight">
            Every Tool Your Flower Shop Needs to Run Flawlessly
          </h1>

          <p className="text-gray-600 text-lg md:text-xl max-w-3xl mx-auto leading-relaxed mb-8">
            Floraprise replaces fragmented tools with one purpose-built operating system: fast counter billing, perishable batch inventory, bouquet recipe costing, driver dispatch, and cash variance control.
          </p>

          <div className="flex flex-wrap justify-center gap-4">
            <Link
              href="/pricing"
              className="bg-[#124e2c] text-white px-8 py-3.5 rounded-xl font-bold hover:bg-[#0b3c20] transition shadow-xs"
            >
              View Plans & Pricing
            </Link>
            <Link
              href="/demo"
              className="bg-white text-[#142219] px-8 py-3.5 rounded-xl font-bold hover:bg-gray-100 transition border border-[#d9dfd7] shadow-xs"
            >
              Book a Live Demo
            </Link>
          </div>
        </div>
      </section>

      {/* ================= 10 FEATURES GRID ================= */}
      <section className="pb-24 px-6">
        <div className="max-w-7xl mx-auto space-y-12">
          {FEATURES_LIST.map((feat, idx) => (
            <div
              key={idx}
              className="bg-white rounded-3xl border border-[#d9dfd7] p-8 lg:p-10 shadow-xs hover:border-[#25784a] transition grid lg:grid-cols-12 gap-8 items-start"
            >
              {/* Left Column: Category & Overview */}
              <div className="lg:col-span-5">
                <div className="flex items-center gap-2 mb-3">
                  <span className={`text-xs font-bold uppercase tracking-wider px-3 py-1 rounded-full border ${feat.badgeColor}`}>
                    {feat.category}
                  </span>
                  <span className="text-xs font-semibold text-gray-500">
                    • {feat.tag}
                  </span>
                </div>

                <h2 className="text-2xl sm:text-3xl font-serif font-normal text-[#142219] mb-4 leading-snug">
                  {feat.title}
                </h2>

                <p className="text-gray-600 text-base leading-relaxed">
                  {feat.desc}
                </p>
              </div>

              {/* Right Column: Key Capabilities */}
              <div className="lg:col-span-7 bg-[#f5f6f1] p-6 sm:p-8 rounded-2xl border border-gray-200">
                <h3 className="text-xs font-extrabold uppercase tracking-wider text-[#25784a] mb-4">
                  Key Capabilities:
                </h3>
                <ul className="grid sm:grid-cols-2 gap-3.5 text-sm text-gray-700">
                  {feat.points.map((pt, pIdx) => (
                    <li key={pIdx} className="flex items-start gap-2.5">
                      <span className="text-[#25784a] font-bold mt-0.5">✓</span>
                      <span>{pt}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* ================= 3 EDITIONS SUMMARY ================= */}
      <section className="py-20 bg-white border-t border-[#d9dfd7]">
        <div className="max-w-6xl mx-auto px-6 text-center">
          <span className="text-[#25784a] text-xs font-extrabold uppercase tracking-widest block mb-2">
            Tailored Deployment
          </span>
          <h2 className="text-3xl sm:text-4xl font-serif font-normal text-[#142219] mb-4">
            Available in Three Operating Scales
          </h2>
          <p className="text-gray-600 max-w-2xl mx-auto mb-12">
            Start small with your phone or run a multi-store floral enterprise.
          </p>

          <div className="grid md:grid-cols-3 gap-8 text-left">
            <div className="p-6 bg-[#f5f6f1] rounded-2xl border border-gray-200">
              <div className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-1">Single Android Device</div>
              <h3 className="text-xl font-serif font-normal text-gray-900 mb-2">Floraprise Solo</h3>
              <p className="text-sm text-gray-600 mb-4">
                Complete florist business management saved locally on your Android phone or tablet. 100% offline-ready with local database.
              </p>
              <Link href="/pricing" className="text-xs font-bold text-[#124e2c] hover:underline">
                Explore Solo Pricing →
              </Link>
            </div>

            <div className="p-6 bg-[#e6ede5] rounded-2xl border border-[#c4d6c2]">
              <div className="text-xs font-bold uppercase tracking-wider text-[#25784a] mb-1">Single Store Cloud</div>
              <h3 className="text-xl font-serif font-normal text-[#124e2c] mb-2">Floraprise Pro ⭐</h3>
              <p className="text-sm text-gray-700 mb-4">
                Multi-device cloud sync, perishable batch inventory, WhatsApp bills, designer & delivery queues.
              </p>
              <Link href="/pricing" className="text-xs font-bold text-[#124e2c] hover:underline">
                Explore Pro Pricing →
              </Link>
            </div>

            <div className="p-6 bg-[#f5f6f1] rounded-2xl border border-gray-200">
              <div className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-1">Multi-Store Operations</div>
              <h3 className="text-xl font-serif font-normal text-gray-900 mb-2">Floraprise ERP</h3>
              <p className="text-sm text-gray-600 mb-4">
                Multi-store inventory, inter-store flower transfers, central catalogue & multi-location reporting.
              </p>
              <Link href="/demo" className="text-xs font-bold text-[#124e2c] hover:underline">
                Book an ERP Demo →
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ================= FINAL CTA ================= */}
      <section className="py-20 bg-[#124e2c] text-white text-center">
        <div className="max-w-3xl mx-auto px-6">
          <h2 className="text-3xl sm:text-4xl font-serif font-normal mb-4">
            See Floraprise in Action
          </h2>
          <p className="text-green-100 text-base sm:text-lg mb-8 leading-relaxed max-w-xl mx-auto">
            Experience how Floraprise can organize your orders, protect flower margins, and streamline delivery.
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              href="/demo"
              className="bg-white text-[#124e2c] px-8 py-4 rounded-xl font-bold hover:bg-green-50 transition shadow-md"
              style={{ color: "#124e2c" }}
            >
              Request a Live Demo
            </Link>
            <Link
              href="/pricing"
              className="bg-[#25784a] text-white px-8 py-4 rounded-xl font-bold hover:bg-[#1a5b36] transition border border-green-400/30"
            >
              View Pricing Options
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}