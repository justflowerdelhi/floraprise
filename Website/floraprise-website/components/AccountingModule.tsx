export default function AccountingModule() {
  return (
    <section className="py-20 bg-white">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h2 className="text-3xl md:text-4xl font-semibold mb-6">
          Built-In Financial Control for Florists
        </h2>

        <p className="text-gray-600 max-w-3xl mx-auto mb-12">
          Floraprise now includes a powerful accounting module designed
          specifically for flower businesses, giving owners full financial
          visibility without needing external accounting software.
        </p>

        <div className="grid md:grid-cols-3 gap-10 text-left">

          <div>
            <h3 className="font-semibold mb-3">
              Sales & Purchase Ledger
            </h3>
            <p className="text-gray-600">
              Automatically record transactions from POS sales
              and supplier invoices in real time.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-3">
              Expense & Profit Tracking
            </h3>
            <p className="text-gray-600">
              Monitor operational costs and track true profit
              margins for your flower shop.
            </p>
          </div>

          <div>
            <h3 className="font-semibold mb-3">
              Real-Time Financial Reports
            </h3>
            <p className="text-gray-600">
              Get instant insights into revenue, expenses,
              and business performance.
            </p>
          </div>

        </div>

      </div>
    </section>
  )
}
