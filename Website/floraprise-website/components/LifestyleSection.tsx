export default function LifestyleSection() {
  return (
    <section className="py-28 bg-white">
      <div className="max-w-6xl mx-auto px-6 grid md:grid-cols-2 gap-16 items-center">

        <div>
          <h2 className="text-3xl md:text-4xl font-semibold">
            Built Around the Reality of Modern Flower Shops
          </h2>

          <p className="mt-6 text-gray-600 leading-relaxed">
            From busy Valentine’s Day rushes to complex wedding orders,
            Floraprise is engineered to handle real operational pressure.
            Inventory volatility. Delivery coordination. Staff management.
            Online integrations.
          </p>

          <p className="mt-6 text-gray-800 font-medium">
            This is not generic retail software.
            It is florist-specific intelligence.
          </p>
        </div>

        <div>
          <img
            src="https://images.unsplash.com/photo-1528740561666-dc2479dc08ab?q=80&w=1400&auto=format&fit=crop"
            alt="Professional florist shop"
            className="rounded-3xl border border-gray-100 shadow-sm"
          />
        </div>

      </div>
    </section>
  );
}