export default function Features() {
  const features = [
    {
      title: "Inventory-First Architecture",
      desc: "Track floral batches, recipes, wastage, and perishable stock in real time. Reduce shrinkage and increase profitability with data-driven inventory control.",
    },
    {
      title: "Hybrid POS System",
      desc: "Seamlessly manage walk-in customers, phone orders, and online orders from a single POS interface designed specifically for florists.",
    },
    {
      title: "Smart Delivery Routing",
      desc: "Automatically generate optimized delivery routes. Assign drivers, track orders, and reduce fuel costs with route intelligence.",
    },
    {
      title: "Multi-Location Control",
      desc: "Manage multiple flower shop locations from one centralized dashboard with shared inventory visibility and reporting.",
    },
    {
      title: "Staff & Shift Management",
      desc: "Track employee shifts, cash drawers, performance, and accountability — all integrated into your POS workflow.",
    },
    {
      title: "Integrated Online Sales",
      desc: "Connect with online ordering platforms and manage website orders without switching between systems.",
    },
  ];

  return (
    <section className="py-20 bg-[#f9f8f5]">
      <div className="max-w-6xl mx-auto px-6">
        <h2 className="text-3xl md:text-4xl font-semibold text-center">
          Everything a Modern Florist Needs
        </h2>

        <p className="text-center text-gray-600 mt-4 max-w-3xl mx-auto">
          Floraprise replaces disconnected tools with one intelligent,
          purpose-built operating system for flower businesses.
        </p>

        <div className="grid md:grid-cols-3 gap-8 mt-12">
          {features.map((feature, index) => (
            <div
              key={index}
              className="p-10 bg-white border border-gray-100 rounded-2xl hover:shadow-2xl transition duration-300"
            >
              <h3 className="text-xl font-semibold mb-4">
                {feature.title}
              </h3>
              <p className="text-gray-600 leading-relaxed">
                {feature.desc}
              </p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}