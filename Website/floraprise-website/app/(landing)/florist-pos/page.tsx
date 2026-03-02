export default function FloristPOSIndiaLanding() {
  return (
    <div className="bg-white">

      {/* HERO */}
      <section className="py-28 text-center bg-gradient-to-b from-[#f8f8f6] to-white">
        <div className="max-w-4xl mx-auto px-6">

          <div className="mb-10 flex justify-center">
            <img
              src="/pos-ui.png"
              alt="Floraprise POS Dashboard"
              className="rounded-2xl shadow-xl max-w-4xl w-full"
            />
          </div>

          <div className="flex justify-center mb-6">
            <div className="border border-green-600 text-green-700 px-5 py-2 rounded-full text-sm font-semibold">
              Made for Indian Florists
            </div>
          </div>

          <p className="text-green-700 font-semibold mb-4">
            Built for Indian Flower Shops
          </p>

          <h1 className="text-4xl md:text-5xl font-bold mb-4">
            India’s Complete Florist POS & ERP Platform
          </h1>

          {/* Hindi Sub Heading */}
          <p className="text-lg text-gray-700 mb-6 font-medium">
            आपके फूलों के व्यवसाय के लिए एक स्मार्ट और पूरा मैनेजमेंट सिस्टम
          </p>

          <p className="text-gray-600 mb-10">
            Manage GST billing, perishable inventory, bouquet production,
            delivery routing, and Tally-ready accounting —
            all in one powerful system built specifically for Indian florists.
          </p>

          <div className="flex justify-center gap-4 flex-wrap">
            <a
              href="/demo"
              className="bg-green-700 text-white px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
            >
              Book Free Demo
            </a>

            <a
              href="https://wa.me/919990224611"
              className="bg-green-500 text-white px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
            >
              WhatsApp Us
            </a>
          </div>

          <div className="mt-6 text-sm text-gray-500">
            GST-ready • Tally-friendly • UPI-supported • Built in India
          </div>

        </div>
      </section>


      {/* TRUST STRIP */}
      <section className="py-12 border-t">
        <div className="max-w-5xl mx-auto px-6 text-center">
          <p className="text-gray-600">
            Designed for retail florists, wedding decorators, and delivery-focused flower businesses across India.
          </p>
        </div>
      </section>


      {/* PROBLEMS IN INDIA */}
      <section className="py-16">
        <div className="max-w-6xl mx-auto px-6 text-center">

          <h2 className="text-3xl font-semibold mb-10">
            Common Problems Indian Florists Face
          </h2>

          <div className="grid md:grid-cols-3 gap-8">

            <div className="bg-white p-8 rounded-2xl shadow-sm">
              <h3 className="font-semibold mb-4">Manual GST Billing</h3>
              <p className="text-gray-600">
                Separate GST software or manual invoice generation.
              </p>
            </div>

            <div className="bg-white p-8 rounded-2xl shadow-sm">
              <h3 className="font-semibold mb-4">Stock Wastage</h3>
              <p className="text-gray-600">
                No FIFO tracking for perishable flowers and fillers.
              </p>
            </div>

            <div className="bg-white p-8 rounded-2xl shadow-sm">
              <h3 className="font-semibold mb-4">Delivery Confusion</h3>
              <p className="text-gray-600">
                WhatsApp orders without structured routing system.
              </p>
            </div>

          </div>

          <p className="text-gray-600 mt-8">
            Designed by florists to support florists across India — from metro cities to growing regional markets.
          </p>

        </div>
      </section>


      {/* MINI SOCIAL PROOF */}
      <section className="py-14 bg-[#f8f8f6] text-center">
        <h2 className="text-2xl font-semibold mb-6">
          Built for Modern Indian Florists
        </h2>
        <p className="text-gray-600">
          Whether you process 20 orders or 200 per day —
          Floraprise scales with your growth.
        </p>
      </section>


      {/* SOLUTION */}
      <section className="py-16 bg-[#f8f8f6]">
        <div className="max-w-5xl mx-auto px-6 text-center">

          <h2 className="text-3xl font-semibold mb-10">
            Floraprise Solves It All
          </h2>

          <ul className="space-y-4 text-gray-700 text-lg">
            <li>✔ GST-Ready Professional Billing</li>
            <li>✔ Perishable Inventory with FIFO Logic</li>
            <li>✔ Bouquet Recipe & Production Tracking</li>
            <li>✔ Delivery & Route Management</li>
            <li>✔ Tally Integration Support</li>
            <li>✔ Staff & Shift Monitoring</li>
            <li>✔ Wedding & Event Order Management</li>
          </ul>

        </div>
      </section>


      {/* SEASONAL RUSH SECTION */}
      <section className="py-16">
        <div className="max-w-5xl mx-auto px-6 text-center">

          <h2 className="text-3xl font-semibold mb-6">
            Built for India’s Peak Floral Seasons
          </h2>

          <p className="text-gray-600 mb-8">
            Valentine’s Day, Mother’s Day, Wedding Season, Rakhi,
            Diwali, Corporate Gifting — manage high-volume orders
            without operational chaos.
          </p>

        </div>
      </section>


      {/* FINAL CTA */}
      <section className="py-20 text-center bg-green-700 text-white">
        <h2 className="text-3xl font-semibold mb-6">
          Ready to Digitize Your Flower Shop?
        </h2>

        <a
          href="/demo"
          className="bg-orange-500 text-white px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
        >
          Schedule Free Demo
        </a>
      </section>

    </div>
  );
}