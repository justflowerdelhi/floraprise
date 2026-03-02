export default function ContactPage() {
  return (
    <main className="bg-white py-20">
      <section className="max-w-4xl mx-auto px-6 text-center">
        <h1 className="text-4xl font-bold text-gray-900">Contact Floraprise</h1>
        <p className="mt-6 text-lg text-gray-600">
          Reach out for product questions, implementation details, or migration
          support for your flower shop.
        </p>
        {/* ================= PHONE CONTACT ================= */}
        <div className="mt-12 bg-[#f8f8f6] p-8 rounded-2xl shadow-sm">
          <h3 className="text-xl font-semibold mb-4">
            📞 Call Us
          </h3>
          <div className="space-y-3 text-gray-700">
            <p>
              <a
                href="tel:+919990224611"
                className="hover:text-green-700 font-medium"
              >
                +91-9990224611
              </a>
            </p>
            <p>
              <a
                href="tel:+919810392755"
                className="hover:text-green-700 font-medium"
              >
                +91-9810392755
              </a>
            </p>
          </div>
          <p className="text-sm text-gray-500 mt-4">
            Available Monday – Saturday | 10:00 AM – 6:00 PM IST
          </p>
        </div>
      </section>
    </main>
  );
}