export default function CustomerReviews() {
  return (
    <section className="py-12 bg-white">
      <div className="max-w-7xl mx-auto px-4">
        <h2 className="text-3xl font-bold text-center mb-10">🧾 Customer Reviews</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-gray-50 p-6 rounded-lg shadow">
            <p className="text-gray-700 mb-4">“Great quality and fast delivery. My go-to for craft supplies!”</p>
            <p className="text-sm text-gray-500">— Priya S.</p>
          </div>
          <div className="bg-gray-50 p-6 rounded-lg shadow">
            <p className="text-gray-700 mb-4">“Excellent customer service and unique products.”</p>
            <p className="text-sm text-gray-500">— Rahul M.</p>
          </div>
          <div className="bg-gray-50 p-6 rounded-lg shadow">
            <p className="text-gray-700 mb-4">“Always reliable for bulk orders and festive needs.”</p>
            <p className="text-sm text-gray-500">— Anjali T.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
