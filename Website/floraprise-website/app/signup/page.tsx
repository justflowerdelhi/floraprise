"use client";
export default function SignupPage() {
  return (
    <section className="py-28 bg-white">
      <div className="max-w-3xl mx-auto px-6">

        <h1 className="text-4xl font-semibold text-center mb-6">
          Start Your Free Trial
        </h1>

        <p className="text-center text-gray-600 mb-12">
          Experience Floraprise’s operational intelligence platform —
          built specifically for professional flower businesses.
        </p>

        <form className="space-y-6" onSubmit={async (e) => {
          e.preventDefault();
          const formData = new FormData(e.currentTarget);

          const res = await fetch("/api/contact", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
              name: formData.get("name"),
              email: formData.get("email"),
              business: formData.get("business"),
              locations: formData.get("locations"),
              message: "Free Trial Request",
            }),
          });

          if (res.ok) {
            window.location.href = "/thankyou";
          } else {
            alert("Something went wrong. Please try again.");
          }
        }}>

          <div>
            <label className="block text-sm font-medium mb-2">
              Full Name
            </label>
            <input
              type="text"
              name="name"
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-600"
              placeholder="Your name"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Business Email
            </label>
            <input
              type="email"
              name="email"
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-600"
              placeholder="you@flowerbusiness.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Business Name
            </label>
            <input
              type="text"
              name="business"
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-600"
              placeholder="Your flower shop"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Number of Locations
            </label>
            <select name="locations" className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-600">
              <option>Single Location</option>
              <option>2–5 Locations</option>
              <option>6+ Locations</option>
            </select>
          </div>

          <button
            type="submit"
            className="w-full bg-[var(--brand-green)] text-white py-4 rounded-lg font-semibold hover:opacity-90 transition"
          >
            Create Free Account
          </button>

        </form>

      </div>
    </section>
  );
}
