export default function ImpactStats() {
  return (
    <section className="py-20 bg-[#f8f8f6] border-t border-gray-100">
      <div className="max-w-6xl mx-auto px-6 text-center">
        <h3 className="text-sm tracking-widest text-green-700 font-semibold mb-4">
          MEASURABLE IMPACT
        </h3>

        <h2 className="text-3xl md:text-4xl font-semibold mb-12">
          Built to Improve Real Flower Shop Operations
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
          <div>
            <div className="text-4xl md:text-5xl font-bold text-green-700 mb-4 transition-all duration-500 hover:scale-105">
              30%
            </div>
            <p className="text-gray-700 font-medium mb-2">
              Reduction in Perishable Waste
            </p>
            <p className="text-sm text-gray-500">
              Inventory-first tracking helps reduce over-ordering and spoilage.
            </p>
          </div>

          <div>
            <div className="text-4xl md:text-5xl font-bold text-orange-500 mb-4">
              2×
            </div>
            <p className="text-gray-700 font-medium mb-2">
              Faster Delivery Route Planning
            </p>
            <p className="text-sm text-gray-500">
              Smart batching and optimized routing reduce driver time.
            </p>
          </div>

          <div>
            <div className="text-4xl md:text-5xl font-bold text-green-700 mb-4 transition-all duration-500 hover:scale-105">
              100%
            </div>
            <p className="text-gray-700 font-medium mb-2">
              Multi-Location Visibility
            </p>
            <p className="text-sm text-gray-500">
              Centralized dashboards unify reporting across stores.
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
