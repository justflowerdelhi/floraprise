import Link from "next/link";

export default function Hero() {
  return (
    <section className="relative bg-[#0f1e17] text-white py-32 overflow-hidden">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <p className="text-green-400 uppercase tracking-widest text-sm font-medium">
          Enterprise Florist Intelligence
        </p>

        <h1 className="mt-6 text-4xl md:text-6xl font-semibold leading-tight">
          The Luxury Operating System <br />
          for Modern Flower Businesses
        </h1>

        <p className="mt-8 text-lg text-gray-300 max-w-3xl mx-auto leading-relaxed">
          Floraprise is a premium inventory-first POS & ERP platform
          built exclusively for serious florists. Manage high-volume orders,
          perishable inventory, delivery fleets, and multi-location operations —
          from one refined control center.
        </p>

        <div className="mt-12 flex justify-center gap-6 flex-wrap">
          <Link
            href="/demo"
            className="bg-gradient-to-r from-[#c8a34d] to-[#e2c27d] text-black px-8 py-4 rounded-xl text-lg font-semibold hover:opacity-90 transition shadow-lg"
          >
            Request Private Demo
          </Link>

          <Link
            href="/features"
            className="border border-gray-100 shadow-sm hover:shadow-md px-8 py-4 rounded-xl text-lg transition"
          >
            Explore Platform
          </Link>
        </div>
        {/* Trust Signals / Badges */}
        <div className="flex flex-wrap justify-center gap-6 text-sm text-gray-600 mt-6">
          <span>🇮🇳 Made for Indian Florists</span>
          <span>✔ GST Ready Billing</span>
          <span>✔ UPI & Card Payments</span>
          <span>✔ Secure Cloud Platform</span>
        </div>
      </div>

      <div className="absolute inset-0 bg-gradient-to-b from-transparent to-black opacity-30"></div>
    </section>
  );
}