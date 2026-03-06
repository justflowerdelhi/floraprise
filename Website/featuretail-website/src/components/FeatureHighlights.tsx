export default function FeatureHighlights() {
  const items = [
    { title: "Fast Shipping", icon: "🚚" },
    { title: "Secure Payments", icon: "🔒" },
    { title: "Quality Guaranteed", icon: "⭐" },
    { title: "Easy Returns", icon: "↩️" },
  ];

  return (
    <section className="py-4 bg-gray-50">
      <div className="max-w-6xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-4 text-center">
        {items.map((item) => (
          <div key={item.title}>
            <div className="text-2xl">{item.icon}</div>
            <p className="text-sm mt-1">{item.title}</p>
          </div>
        ))}
      </div>
    </section>
  );
}
