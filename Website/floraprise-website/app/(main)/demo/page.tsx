"use client";
export default function DemoPage() {
  return (
    <section className="py-28 bg-[#f8f8f6]">
      <div className="max-w-4xl mx-auto px-6">

        <h1 className="text-4xl font-semibold text-center mb-6">
          Book a Live Demo
        </h1>

        <p className="text-center text-gray-600 mb-12">
          See how Floraprise streamlines inventory, production,
          delivery, and multi-location management in one platform.
        </p>

        <form className="space-y-6 bg-white p-10 rounded-2xl shadow-sm" onSubmit={async (e) => {
          e.preventDefault();
          const formData = new FormData(e.currentTarget);

          const res = await fetch(`${process.env.NEXT_PUBLIC_ERP_API_URL}/api/marketing/demo-request`, {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-Website-Key": process.env.NEXT_PUBLIC_WEBSITE_API_KEY || "",
            },
            body: JSON.stringify({
              fullName: formData.get("name"),
              businessEmail: formData.get("email"),
              businessType: formData.get("businessType"),
              currentSoftware: formData.get("currentSoftware"),
              notes: formData.get("notes"),
              submittedAt: new Date().toISOString(),
            }),
          });

          if (res.ok) {
            window.location.href = "/thankyou";
          } else {
            alert("Something went wrong. Please try again.");
          }
        }}>

          <div className="grid md:grid-cols-2 gap-6">

            <div>
              <label className="block text-sm font-medium mb-2">
                Full Name
              </label>
              <input
                type="text"
                name="name"
                className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-green-600"
              />
            </div>

            <div>
              <label className="block text-sm font-medium mb-2">
                Business Email
              </label>
              <input
                type="email"
                name="email"
                className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-green-600"
              />
            </div>

          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Business Type
            </label>
            <select name="businessType" className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-green-600">
              <option>Retail Flower Shop</option>
              <option>Wedding & Events Florist</option>
              <option>Multi-Location Chain</option>
              <option>Online + In-Store Hybrid</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Current Software (if any)
            </label>
            <input
              type="text"
              name="currentSoftware"
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-green-600"
              placeholder="QuickFlora, Floranext, Excel, etc."
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Additional Notes
            </label>
            <textarea
              rows={4}
              name="notes"
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:ring-2 focus:ring-green-600"
            />
          </div>

          <button
            type="submit"
            className="w-full bg-[var(--brand-orange)] text-white py-4 rounded-lg font-semibold hover:opacity-90 transition"
          >
            Schedule Demo
          </button>

        </form>

      </div>
    </section>
  );
}