export default function FeaturesPage() {
  return (
    <div className="bg-white">

      {/* ================= HERO ================= */}
      <section className="py-24">
        <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-2 gap-12 items-center">

          <div>
            <h1 className="text-4xl md:text-5xl font-semibold mb-6">
              A Complete Operational Platform for Modern Florists
            </h1>

            <p className="text-gray-600 text-lg">
              Floraprise connects retail billing, inventory,
              production, delivery, accounting, and multi-location
              management into one structured florist ERP system.
            </p>
          </div>

          {/* Smaller Image */}
          <div className="flex justify-center">
            <img
              src="/pos-ui.png"
              alt="Floraprise POS Interface"
              className="rounded-xl shadow-xl max-w-md"
            />
          </div>

        </div>
      </section>


      {/* ================= ECOSYSTEM ================= */}
<section className="py-24 bg-[#f8f8f6]">
  <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-2 gap-14 items-center">

    {/* LEFT IMAGE */}
    <div className="flex justify-center md:justify-start">
      <img
        src="/ecosystem.jpg"
        alt="Floraprise Operational Ecosystem"
        className="rounded-xl shadow-xl max-w-md"
      />
    </div>

    {/* RIGHT TEXT */}
    <div>
      <h2 className="text-3xl font-semibold mb-6">
        One Connected Operational Ecosystem
      </h2>

      <p className="text-gray-600 mb-5 leading-relaxed">
        Floraprise is not just a billing system — it connects
        every operational layer of a florist business into one
        structured platform.
      </p>

      <p className="text-gray-600 leading-relaxed">
        From perishable inventory and bouquet production
        to delivery routing, accounting, and multi-location control,
        every transaction automatically flows into the right workflow.
      </p>

    </div>

  </div>
</section>


      {/* ================= FEATURES ================= */}

      {/* RETAIL */}
      <FeatureRow
        title="Retail & Billing Intelligence"
        bg="bg-green-50"
        items={[
          {
            title: "Intent-Based Retail POS",
            text: `Smart billing designed for Take Away, Delivery, and Pickup workflows with purpose-driven order processing.\nAutomatically adapts pricing, taxes, and fulfillment logic based on order intent.\nSupports walk-in, phone, and online orders in one unified, florist-optimized interface.`
          },
          {
            title: "Professional Billing & Invoicing",
            text: `Generate tax-ready, compliant invoices with multi-currency and country-based tax configuration.\nSupports GST/VAT rules, discounts, service charges, and customizable invoice templates.\nEnables seamless export to accounting platforms like QuickBooks and Tally for simplified bookkeeping.`
          },
          {
            title: "Integrated Payment Support",
            text: `Accept cash, card, UPI, online gateway payments, and store credits.\nSupports advance deposits, partial payments, and split billing.\nAuto-reconciliation to simplify daily closing.`
          }
        ]}
      />

      {/* ACCOUNTING */}
      <FeatureRow
        title="Accounting & Financial Control"
        bg="bg-yellow-50"
        items={[
          {
            title: "Florist-Friendly Accounting",
            text: `Built-in lightweight accounting designed specifically for retail florists.\nTrack income, expenses, cash flow, and vendor payments without complex accounting jargon.\nIncludes ledger summaries, basic P&L, tax reports, and easy reconciliation.\nOptional integration with QuickBooks and Tally for advanced accounting needs.`
          },
          {
            title: "Profit & Margin Intelligence",
            text: `Live cost tracking based on purchase price and raw material usage.\nProduct-level and category-level margin analysis.\nHelps optimize pricing strategy and reduce hidden losses.`
          }
        ]}
      />

      {/* INVENTORY */}
      <FeatureRow
        title="Inventory & Production Engine"
        bg="bg-pink-50"
        items={[
          {
            title: "Perishable Inventory Management",
            text: `Advanced batch tracking with FIFO logic to ensure fresh stock utilization.\nExpiry alerts, spoilage recording, and automated stock deduction reduce wastage.\nReal-time stock visibility across flowers, fillers, packaging materials, and accessories.`
          },
          {
            title: "Recipe-Based Production Engine",
            text: `Design bouquets and floral products using structured recipes with controlled raw material deduction.\nAutomatically calculates true product cost including wastage and overhead allocation.\nImproves production accuracy while protecting margins on custom and ready-made designs.`
          },
          {
            title: "Wedding & Event Management",
            text: `Create professional proposals with itemized costing and approval workflows.\nManage event production timelines, staff assignments, and vendor coordination.\nTrack deposits, milestone payments, and final settlements with profitability insights.`
          }
        ]}
      />

      {/* OPERATIONS */}
      <FeatureRow
        title="Operations & Multi-Location"
        bg="bg-blue-50"
        items={[
          {
            title: "Delivery & Route Management",
            text: `Assign drivers, define delivery zones, and generate optimized delivery routes.\nReal-time order tracking and status updates enhance customer transparency.\nBatch route planning for peak seasons like Valentine’s Day and Mother’s Day.`
          },
          {
            title: "Staff & Shift Control",
            text: `Role-based access ensures secure and controlled system usage.\nShift opening/closing with cash drawer accountability and audit logs.\nMonitor staff performance, attendance, and time tracking in one place.`
          },
          {
            title: "Multi-Location Management",
            text: `Centralized control for multi-branch florist businesses.\nInter-branch stock transfers with real-time inventory synchronization.\nLocation-wise sales, expense, and profit comparison dashboards.`
          },
          {
            title: "Gift Card Management",
            text: `Issue digital or physical gift cards with customizable values.\nTrack balances, redemption history, and expiry automatically.\nBoost repeat business through seasonal promotions and loyalty campaigns.`
          },
          {
            title: "Wire Order Support",
            text: `Manage incoming and outgoing wire orders with full lifecycle tracking.\nCommission calculation, partner settlements, and status monitoring included.\nReady for integration with major floral wire networks.`
          }
        ]}
      />

      {/* PLATFORM */}
      <FeatureRow
        title="Enterprise SaaS Platform"
        bg="bg-gray-50"
        items={[
          {
            title: "Secure Cloud-Based SaaS Platform",
            text: `Multi-tenant, API-ready architecture built for scalability.\nRole-controlled access with secure cloud hosting and encryption.\nAutomatic backups and seamless updates without downtime.`
          }
        ]}
      />


      {/* ================= CTA ================= */}
      <section className="py-24 bg-green-700 text-white text-center">
        <h2 className="text-3xl font-semibold mb-6">
          Ready to Transform Your Flower Shop?
        </h2>

        <a
          href="/demo"
          className="bg-orange-500 px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
        >
          Request a Live Demo
        </a>
      </section>

    </div>
  );
}


/* ================= ROW COMPONENT ================= */

interface FeatureRowProps {
  title: string;
  items: Array<{ title: string; text: string }>;
  bg: string;
}

function FeatureRow({ title, items, bg }: FeatureRowProps) {
  return (
    <section className={`py-10 ${bg}`}>
      <div className="max-w-7xl mx-auto px-6">
        <h3 className="text-2xl font-semibold mb-6 border-l-4 border-green-700 pl-4">
          {title}
        </h3>
        <div className="grid md:grid-cols-2 gap-8">
          {items.map((item, index) => (
            <div key={index}>
              <h4 className="font-semibold text-lg mb-2">
                {item.title}
              </h4>
              <p className="text-gray-600 leading-relaxed">
                {item.text}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}