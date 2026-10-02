export default function Integrations() {
  return (
    <section className="py-8 bg-white border-t border-gray-100">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h3 className="text-sm tracking-widest text-green-700 font-semibold mb-4">
          SEAMLESS INTEGRATIONS
        </h3>

        <h2 className="text-3xl md:text-4xl font-semibold mb-6">
          Payments and Delivery, Connected to Your Orders
        </h2>

        <p className="text-gray-600 max-w-2xl mx-auto mb-6">
          Accept online payments through Stripe and keep every
          delivery on record, whether it goes out with your own
          staff or a third-party courier.
        </p>

        <div className="flex gap-10 items-center justify-center grayscale op">
           <img src="/images/integrations/stripe.png" alt="Stripe" width="60" height="60" />
        </div>

        {/* API Ready Line */}

        <div className="border-t border-gray-100 pt-8">
          <p className="text-sm tracking-wide text-gray-600 font-medium">
            Stripe Payments · Third-Party Courier Bookings · Online Payment Confirmation
          </p>
        </div>

      </div>
    </section>
  );
}