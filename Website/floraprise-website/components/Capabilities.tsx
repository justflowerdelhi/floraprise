export default function Capabilities() {
  const features = [
    "Inventory Intelligence",
    "Hybrid POS System",
    "Smart Delivery Routing",
    "Multi-Location Control",
    "Staff & Shift Management",
    "Integrated Online Sales",
  ];

  return (
    <section className="py-28 bg-[#f9f8f5]">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h2 className="text-3xl md:text-4xl font-semibold">
          Everything a Modern Florist Requires — Without Compromise
        </h2>

        <div className="grid md:grid-cols-3 gap-8 mt-16">
          {features.map((item, index) => (
            <div
              key={index}
              className="bg-white p-10 rounded-2xl shadow-sm border border-gray-100"
            >
              <h3 className="font-semibold text-lg">{item}</h3>
            </div>
          ))}
        </div>

      </div>
    </section>
  );
}