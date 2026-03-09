import Integrations from "@/components/Integrations";

export default function IntegrationsPage() {
  return (
    <>
      <section className="py-12 text-center">
        <h1 className="text-3xl font-bold mb-4">Floraprise Integrations</h1>
        <p className="text-gray-600 max-w-2xl mx-auto">
          Floraprise connects with accounting systems, delivery platforms,
          marketplaces, and payment providers to power modern florist operations.
        </p>
      </section>
      <Integrations />
      <div className="mt-16 bg-gray-50 p-8 rounded-xl">
        <h3 className="text-xl font-semibold mb-3">
          Developer Friendly APIs
        </h3>
        <p className="text-gray-600">
          Floraprise provides REST APIs and real-time webhooks
          for seamless integration with external systems,
          marketplaces, and custom applications.
        </p>
      </div>
      <div className="mt-12">
        <p className="text-gray-600 mb-4">
          Need an integration not listed here?
        </p>
        <a
          href="/contact"
          className="inline-block bg-green-700 text-white px-6 py-3 rounded-lg"
        >
          Request Integration
        </a>
      </div>
    </>
  );
}
