export default function PlatformSection() {
  return (
    <section className="py-12 bg-[#f8f8f6]">
      <div className="max-w-6xl mx-auto px-6 text-center">
        <h2 className="text-3xl md:text-4xl font-semibold mb-4">
          One Platform. Complete Florist Operations.
        </h2>
        <p className="text-gray-600 max-w-3xl mx-auto mb-16">
          Floraprise brings together every operational layer of a flower
          business — from POS and inventory to production, delivery,
          accounting, and analytics.
        </p>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-8">
          <div className="bg-white p-6 rounded-xl shadow-sm border">
            🧾
            <div className="mt-2 font-medium">POS Billing</div>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border">
            📦
            <div className="mt-2 font-medium">Inventory Management</div>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border">
            🌸
            <div className="mt-2 font-medium">Bouquet Production</div>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border">
            🚚
            <div className="mt-2 font-medium">Delivery Routing</div>
          </div>
          <div className="bg-white p-6 rounded-xl shadow-sm border">
            💰
            <div className="mt-2 font-medium">Accounting</div>
          </div>

      <div className="bg-white p-6 rounded-xl shadow-sm border">
        👥
        <div className="mt-2 font-medium">Staff Management</div>
      </div>

      <div className="bg-white p-6 rounded-xl shadow-sm border">
        🧑‍🤝‍🧑
        <div className="mt-2 font-medium">Customer CRM</div>
      </div>

      <div className="bg-white p-6 rounded-xl shadow-sm border">
        📊
        <div className="mt-2 font-medium">Business Analytics</div>
      </div>

    </div>

  </div>
</section>
  );
}
