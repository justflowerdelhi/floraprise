export default function DashboardShowcase() {
  return (
    <section className="py-20 bg-[#f8f8f6]">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h2 className="text-3xl md:text-4xl font-semibold mb-6">
          Real-Time Operational Intelligence
        </h2>

        <p className="text-gray-600 max-w-3xl mx-auto mb-12">
          From live inventory tracking and perishable batch management to
          delivery coordination and profit analytics, Floraprise gives
          flower shop owners complete visibility across every department
          in one centralized, cloud-based dashboard.
        </p>

        <div className="bg-white p-8 md:p-12 rounded-3xl shadow-lg">
          <img
            src="/floraprise-dashboard.png"
            alt="Floraprise florist ERP dashboard"
            className="rounded-2xl w-full"
          />
        </div>

      </div>
    </section>
  );
}