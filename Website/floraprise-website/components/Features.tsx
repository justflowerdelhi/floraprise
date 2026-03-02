export default function Features() {
  return (
    <section className="py-20 bg-[#f8f8f6]">
      <div className="max-w-6xl mx-auto px-6">

        <h2 className="text-3xl md:text-4xl font-semibold text-center mb-6">
          Everything a Modern Florist Business Needs
        </h2>


        <p className="text-center text-gray-600 max-w-3xl mx-auto mb-16">
          Floraprise connects retail, inventory, production, delivery,
          accounting, and multi-location control into one structured
          operational platform.
        </p>

        <div className="max-w-4xl mx-auto mt-16 mb-20">
          <img
            src="/ecosystem.jpg"
            alt="Floraprise Ecosystem for Florists"
            className="rounded-2xl shadow-md mx-auto"
          />
        </div>

        {/* Deep Feature Sections */}
        <section className="py-20">
          <div className="max-w-5xl mx-auto px-6">
            <img src="/retail.jpg" alt="Retail & Transactions" className="rounded-2xl shadow-md mx-auto mb-10" />
            <h2 className="text-2xl font-semibold mb-6">Retail & Transaction Intelligence</h2>
            <p className="text-gray-600 mb-6">
              Floraprise redefines florist billing by aligning transactions with operational intent — Take Away, Delivery, and Pickup. Each order automatically adapts workflows across production, inventory, and delivery.
            </p>
            <p className="text-gray-600 mb-6">
              The POS is designed for real-world florist needs, supporting professional invoicing, tax compliance, and integrated multi-payment support. Gift cards and wire orders are managed seamlessly, ensuring every transaction is tracked and reconciled.
            </p>
            <ul className="space-y-4 text-gray-700">
              <li>Intent-based POS workflow</li>
              <li>Professional invoicing & tax compliance</li>
              <li>Integrated multi-payment support</li>
              <li>Gift cards & wire orders</li>
            </ul>
          </div>
        </section>

        <section className="py-20">
          <div className="max-w-5xl mx-auto px-6">
            <img src="/inventory.jpg" alt="Inventory & Production" className="rounded-2xl shadow-md mx-auto mb-10" />
            <h2 className="text-2xl font-semibold mb-6">Inventory & Production</h2>
            <p className="text-gray-600 mb-6">
              Floraprise’s inventory engine is built for perishables, with batch tracking, FIFO logic, expiry alerts, and spoilage control. Recipe-based production lets florists create bouquets with controlled raw material deduction and wastage tracking.
            </p>
            <p className="text-gray-600 mb-6">
              Wedding and event management is fully integrated, from proposal creation and costing to scheduling and production tracking, ensuring every event is profitable and organized.
            </p>
            <ul className="space-y-4 text-gray-700">
              <li>Perishable inventory management</li>
              <li>Recipe-based production workflows</li>
              <li>Wedding & event management</li>
              <li>Batch tracking & spoilage control</li>
            </ul>
          </div>
        </section>

        <section className="py-20">
          <div className="max-w-5xl mx-auto px-6">
            <img src="/operations.jpg" alt="Operations & Logistics" className="rounded-2xl shadow-md mx-auto mb-10" />
            <h2 className="text-2xl font-semibold mb-6">Operations & Logistics</h2>
            <p className="text-gray-600 mb-6">
              Delivery and route management features include driver assignment, delivery zones, optimized routing, and live tracking. Staff and shift control is role-based, with performance monitoring and time tracking for every team member.
            </p>
            <p className="text-gray-600 mb-6">
              Multi-location management provides centralized control and reporting across all outlets, giving chain owners complete visibility and operational efficiency.
            </p>
            <ul className="space-y-4 text-gray-700">
              <li>Delivery & route management</li>
              <li>Staff & shift control</li>
              <li>Multi-location management</li>
              <li>Performance monitoring</li>
            </ul>
          </div>
        </section>

        <section className="py-20">
          <div className="max-w-5xl mx-auto px-6">
            <img src="/financial.jpg" alt="Financial & Intelligence" className="rounded-2xl shadow-md mx-auto mb-10" />
            <h2 className="text-2xl font-semibold mb-6">Financial & Intelligence</h2>
            <p className="text-gray-600 mb-6">
              Floraprise delivers real-time profit and margin intelligence, with built-in accounting for ledgers, expenses, and revenue summaries. The cloud SaaS platform is secure and scalable, supporting multi-tenant architecture for growing businesses.
            </p>
            <p className="text-gray-600 mb-6">
              Accounting is fully integrated, allowing florists to manage finances, track expenses, and generate reports without leaving the platform. Every transaction is reconciled for complete financial clarity.
            </p>
            <ul className="space-y-4 text-gray-700">
              <li>Profit & margin intelligence</li>
              <li>Built-in accounting</li>
              <li>Cloud SaaS platform</li>
              <li>Expense & revenue tracking</li>
            </ul>
          </div>
        </section>

        <div className="grid md:grid-cols-2 gap-10">

          {/* Card 1 */}
          <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition">

            <div className="bg-green-100 text-green-800 px-4 py-2 rounded-lg inline-block mb-6 text-sm font-semibold">
              Retail & Transactions
            </div>

            <ul className="space-y-4 text-gray-700">
              <li><strong>Intent-Based POS:</strong> Smart billing for Take Away, Delivery, and Pickup.</li>
              <li><strong>Professional Invoicing:</strong> Multi-currency & tax-ready billing.</li>
              <li><strong>Integrated Payments:</strong> Cash, card, UPI, split & partial payments.</li>
              <li><strong>Gift Cards:</strong> Issue, redeem & track balances.</li>
              <li><strong>Wire Orders:</strong> Manage incoming & outgoing orders.</li>
            </ul>

          </div>

          {/* Card 2 */}
          <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition">

            <div className="bg-emerald-100 text-emerald-800 px-4 py-2 rounded-lg inline-block mb-6 text-sm font-semibold">
              Inventory & Production
            </div>

            <ul className="space-y-4 text-gray-700">
              <li><strong>Perishable Inventory:</strong> Batch tracking, FIFO & expiry alerts.</li>
              <li><strong>Recipe Engine:</strong> Controlled raw material deduction.</li>
              <li><strong>Wedding & Events:</strong> Proposal, costing & production planning.</li>
            </ul>

          </div>

          {/* Card 3 */}
          <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition">

            <div className="bg-lime-100 text-lime-800 px-4 py-2 rounded-lg inline-block mb-6 text-sm font-semibold">
              Operations & Logistics
            </div>

            <ul className="space-y-4 text-gray-700">
              <li><strong>Delivery Management:</strong> Driver assignment & route optimization.</li>
              <li><strong>Staff & Shift Control:</strong> Role-based access & time tracking.</li>
              <li><strong>Multi-Location:</strong> Centralized chain-level visibility.</li>
            </ul>

          </div>

          {/* Card 4 */}
          <div className="bg-white p-8 rounded-2xl shadow-sm hover:shadow-md transition">

            <div className="bg-teal-100 text-teal-800 px-4 py-2 rounded-lg inline-block mb-6 text-sm font-semibold">
              Financial & Intelligence
            </div>

            <ul className="space-y-4 text-gray-700">
              <li><strong>Profit Intelligence:</strong> Real-time margin tracking.</li>
              <li><strong>Built-In Accounting:</strong> Ledger, expenses & revenue summaries.</li>
              <li><strong>Cloud SaaS Platform:</strong> Secure, scalable multi-tenant architecture.</li>
            </ul>

          </div>

        </div>

      </div>
    </section>
  );
}