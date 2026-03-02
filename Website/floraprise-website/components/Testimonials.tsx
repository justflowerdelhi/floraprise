export default function Testimonials() {
  return (
    <section className="py-20 bg-[#f8f8f6]">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h2 className="text-3xl font-semibold mb-12">
          Trusted by Operationally Focused Florists
        </h2>

        <div className="grid md:grid-cols-3 gap-8 text-left">

          <div className="bg-white p-8 rounded-2xl shadow-sm">
            <p className="leading-7 text-gray-700">
              “Floraprise gave us operational clarity across inventory,
              production, and delivery. We finally manage the business
              as a system.”
            </p>
            <p className="mt-6 font-medium text-sm">
              — Owner
            </p>
          </div>

          <div className="bg-white p-8 rounded-2xl shadow-sm">
            <p className="leading-7 text-gray-700">
              “Production and delivery are no longer reactive.
              Workflows are structured and controlled.”
            </p>
            <p className="mt-6 font-medium text-sm">
              — Event Florist
            </p>
          </div>

          <div className="bg-white p-8 rounded-2xl shadow-sm">
            <p className="leading-7 text-gray-700">
              “The inventory-first approach matches how real
              flower businesses operate.”
            </p>
            <p className="mt-6 font-medium text-sm">
              — Retail Chain Director
            </p>
          </div>

        </div>

      </div>
    </section>
  );
}