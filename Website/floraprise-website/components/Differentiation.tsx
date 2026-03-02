export default function Differentiation() {
  return (
    <section className="py-28 bg-white">
      <div className="max-w-6xl mx-auto px-6">

        <h2 className="text-3xl md:text-4xl font-semibold text-center">
          Not Just Another Florist POS
        </h2>

        <p className="text-center text-gray-600 mt-6 max-w-3xl mx-auto">
          Most florist software was built as a basic cash register.
          Floraprise was engineered as an operational backbone —
          starting from inventory intelligence.
        </p>

        <div className="grid md:grid-cols-2 gap-12 mt-20">

          <div>
            <h3 className="text-xl font-semibold">
              Traditional Florist Software
            </h3>
            <ul className="mt-6 space-y-4 text-gray-600">
              <li>• POS first, inventory secondary</li>
              <li>• No batch-level perishables tracking</li>
              <li>• Disconnected delivery tools</li>
              <li>• Limited scalability</li>
            </ul>
          </div>

          <div className="bg-[#f9f8f5] p-10 rounded-2xl shadow-sm">
            <h3 className="text-xl font-semibold text-green-800">
              Floraprise Approach
            </h3>
            <ul className="mt-6 space-y-4 text-gray-700">
              <li>• Inventory-first architecture</li>
              <li>• Batch & perishables intelligence</li>
              <li>• Integrated delivery routing</li>
              <li>• Multi-location enterprise ready</li>
            </ul>
          </div>

        </div>
      </div>
    </section>
  );
}