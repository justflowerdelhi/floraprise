export default function ComparisonSection() {
return ( <section className="py-24 bg-white"> <div className="max-w-6xl mx-auto px-6 text-center">

    <h2 className="text-3xl md:text-4xl font-semibold mb-6">
      Why Floraprise is Different
    </h2>

    <p className="text-gray-600 max-w-3xl mx-auto mb-16">
      Generic POS systems were built for retail transactions.
      Floraprise is designed specifically for florist operations.
    </p>

    <div className="overflow-x-auto">
      <table className="w-full border rounded-xl overflow-hidden">

        <thead className="bg-gray-100 text-left">
          <tr>
            <th className="p-4">Feature</th>
            <th className="p-4 text-center">Generic POS</th>
            <th className="p-4 text-center">Floraprise</th>
          </tr>
        </thead>

        <tbody className="text-gray-700">

          <tr className="border-t">
            <td className="p-4">Bouquet Recipes</td>
            <td className="text-center">❌</td>
            <td className="text-center">✅</td>
          </tr>

          <tr className="border-t">
            <td className="p-4">Flower Batch Tracking</td>
            <td className="text-center">❌</td>
            <td className="text-center">✅</td>
          </tr>

          <tr className="border-t">
            <td className="p-4">Delivery Routing</td>
            <td className="text-center">❌</td>
            <td className="text-center">✅</td>
          </tr>

          <tr className="border-t">
            <td className="p-4">Bouquet Production Workflow</td>
            <td className="text-center">❌</td>
            <td className="text-center">✅</td>
          </tr>

          <tr className="border-t">
            <td className="p-4">Florist-Specific Inventory</td>
            <td className="text-center">❌</td>
            <td className="text-center">✅</td>
          </tr>

          <tr className="border-t">
            <td className="p-4">Built-in Accounting</td>
            <td className="text-center">❌</td>
            <td className="text-center font-semibold text-green-700">✅</td>
          </tr>

        </tbody>

      </table>
    </div>

  </div>
</section>

)
}
