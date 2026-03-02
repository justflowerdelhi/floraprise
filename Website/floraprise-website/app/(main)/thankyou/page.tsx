export default function ThankYouPage() {
  return (
    <section className="py-28 bg-white text-center">
      <div className="max-w-3xl mx-auto px-6">

        <h1 className="text-4xl font-semibold mb-6">
          Your Request Has Been Received
        </h1>

        <p className="text-gray-600 mb-8">
          Thank you for your interest in Floraprise.  
          A member of our team will contact you within 24 business hours.
        </p>

        <div className="flex justify-center gap-4 mt-10 flex-wrap">

          <a
            href="/"
            className="bg-[var(--brand-green)] text-white px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
          >
            Return to Homepage
          </a>

          <a
            href="/demo"
            className="bg-[var(--brand-orange)] text-white px-8 py-4 rounded-lg font-semibold hover:opacity-90 transition"
          >
            Book Another Demo
          </a>

        </div>

      </div>
    </section>
  );
}