export default function FeatureComparison() {
  return (
    <section className="py-20 bg-white">
      <div className="max-w-6xl mx-auto px-6">

        <h2 className="text-3xl font-semibold text-center mb-4">
          Built for Operational Depth.
        </h2>

        <p className="text-center text-gray-600 mb-12">
          Floraprise is engineered for structured florist operations — not just billing.
        </p>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">

            <thead>
              <tr className="border-b border-gray-200">
                <th className="py-4">Capability</th>
                <th className="py-4 text-[var(--brand-green)]">Floraprise</th>
                <th className="py-4 text-gray-500">Typical Florist POS</th>
              </tr>
            </thead>

            <tbody className="text-gray-700">

              {[
                ["Inventory-First Architecture", "✔ Native Core", "Transaction-Based"],
                ["Perishable Batch Tracking", "✔ Real-Time FIFO", "Limited / Manual"],
                ["Production Workflow Engine", "✔ Built-In", "Not Available"],
                ["Delivery Route Intelligence", "✔ Integrated", "External Tool"],
                ["Multi-Location SaaS", "✔ Centralized", "Separate Systems"],
                ["Staff & Shift Management", "✔ Built-In", "Add-On"],
              ].map((row, i) => (
                <tr key={i} className="border-b border-gray-100">
                  <td className="py-4">{row[0]}</td>
                  <td className="py-4 text-[var(--brand-green)] font-medium">{row[1]}</td>
                  <td className="py-4 text-gray-500">{row[2]}</td>
                </tr>
              ))}

            </tbody>

          </table>
        </div>

      </div>
    </section>
  );
}