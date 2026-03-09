export default function Integrations() {
  return (
    <section className="py-8 bg-white border-t border-gray-100">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h3 className="text-sm tracking-widest text-green-700 font-semibold mb-4">
          SEAMLESS INTEGRATIONS
        </h3>

        <h2 className="text-3xl md:text-4xl font-semibold mb-6">
          Connect Your Entire Business Ecosystem
        </h2>

        <p className="text-gray-600 max-w-2xl mx-auto mb-6">
          Floraprise integrates with leading accounting, payment,
          delivery, and marketplace platforms — ensuring your
          operations stay synchronized across every channel.
        </p>

        <div className="grid grid-cols-3 md:grid-cols-6 gap-10 items-center justify-center grayscale op">
           <img src="/images/integrations/quickbooks.png" alt="QuickBooks Integration" width="60" height="60" />
           <img src="/images/integrations/stripe.png" alt="Stripe Integration" width="60" height="60" />
           <img src="/images/integrations/doordash.png" alt="DoorDash Integration" width="60" height="60" />
           <img src="/images/integrations/ftd.png" alt="FTD Integration" width="60" height="60" />
           <img src="/images/integrations/bloomnation.png" alt="BloomNation Integration" width="60" height="60" />
           <img src="/images/integrations/tally.png" alt="Tally Integration" width="60" height="60" />
           <img src="/images/integrations/uc.png" alt="Uncle Delivery Integration" width="60" height="60" />
           <img src="/images/integrations/dunzo.png" alt="Dunzo Integration" width="60" height="60" />
           <img src="/images/integrations/porter.png" alt="Porter Integration" width="60" height="60" />
        </div>

        {/* API Ready Line */}

        <div className="border-t border-gray-100 pt-8">
          <p className="text-sm tracking-wide text-gray-600 font-medium">
            Developer-Friendly APIs · Real-Time Webhooks · ERP-Level Data Architecture
          </p>
        </div>

      </div>
    </section>
  );
}