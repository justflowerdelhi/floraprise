export default function TrustBar() {
  return (
    <section className="bg-gray-50 py-6">
      <div className="max-w-6xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
        <div>
          <div className="text-2xl">🚚</div>
          <p className="text-sm font-medium">Fast Shipping</p>
        </div>
        <div>
          <div className="text-2xl">🔒</div>
          <p className="text-sm font-medium">Secure Payments</p>
        </div>
        <div>
          <div className="text-2xl">📦</div>
          <p className="text-sm font-medium">Easy Returns</p>
        </div>
        <div>
          <div className="text-2xl">⭐</div>
          <p className="text-sm font-medium">Trusted by 10,000+ Customers</p>
        </div>
      </div>
    </section>
  );
}
