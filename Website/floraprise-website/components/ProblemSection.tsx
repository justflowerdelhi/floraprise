export default function ProblemSection() {
  return (
    <section className="py-20 bg-white">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h2 className="text-3xl font-semibold mb-4">
          Most Florist Software Was Built for Transactions. Not Operations.
        </h2>

        <p className="text-gray-600 max-w-3xl mx-auto mb-12">
          Flower businesses require structured inventory, coordinated production,
          and controlled delivery workflows — not just billing systems.
        </p>

        <div className="grid md:grid-cols-3 gap-10 text-left">

          <div>
            <h3 className="font-semibold mb-3">Disconnected Systems</h3>
            <p className="text-gray-600">
              POS, inventory, and delivery tools operate separately.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-3">Inventory Blind Spots</h3>
            <p className="text-gray-600">
              Perishable stock lacks structured tracking and control.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-3">
              Unstructured Production & Delivery
            </h3>
            <p className="text-gray-600">
              Workflow coordination is reactive instead of systematic.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-3">
              No Financial Visibility
            </h3>
            <p className="text-gray-600">
              Florists often rely on external accounting tools,
              making it difficult to track real profitability.
            </p>
          </div>

        </div>

      </div>
    </section>
  );
}