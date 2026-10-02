import { pageMetadata } from "@/lib/seo";
import Integrations from "@/components/Integrations";

export const metadata = pageMetadata({
  title: "Floraprise Integrations | Online Payments & Courier Deliveries",
  description:
    "See how Floraprise connects florist orders with Stripe online payments, automatic payment confirmation, and third-party courier bookings such as Porter or Dunzo.",
  path: "/integrations/",
});

export default function IntegrationsPage() {
  return (
    <>
      <section className="py-12 text-center">
        <h1 className="text-3xl font-bold mb-4">Floraprise Integrations</h1>
        <p className="text-gray-600 max-w-2xl mx-auto">
          Floraprise connects your orders with online payments and keeps
          third-party courier deliveries on record alongside your own riders.
        </p>
      </section>
      <Integrations />
      <div className="mt-16 bg-gray-50 p-8 rounded-xl">
        <h3 className="text-xl font-semibold mb-3">
          Automatic Payment Confirmation
        </h3>
        <p className="text-gray-600">
          When a customer pays online through a connected payment gateway,
          the gateway confirms the payment to Floraprise and the order&apos;s
          payment status is updated automatically.
        </p>
      </div>
      <div className="mt-8 bg-gray-50 p-8 rounded-xl">
        <h3 className="text-xl font-semibold mb-3">
          Third-Party Courier Deliveries
        </h3>
        <p className="text-gray-600">
          Booked a courier such as Porter or Dunzo? Record the delivery
          partner and booking reference on the order in the Floraprise app
          so your team can track who is delivering it.
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
