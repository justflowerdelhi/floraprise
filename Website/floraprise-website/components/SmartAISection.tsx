export default function SmartAISection() {
return ( <section className="py-24 bg-[#f7f7f5]"> <div className="max-w-6xl mx-auto px-6 text-center">

    <h2 className="text-3xl md:text-4xl font-semibold mb-6">
      Floraprise Smart AI
    </h2>

    <p className="text-gray-600 max-w-3xl mx-auto mb-16">
      Turn bouquet photos into ready-to-sell products in seconds.
      Floraprise Smart AI analyzes bouquet designs and converts them
      into structured recipes, inventory requirements, and POS-ready
      products automatically.
    </p>

    <div className="grid md:grid-cols-3 gap-10 text-left">

      <div className="bg-white p-6 rounded-xl border shadow-sm">
        <div className="text-xl mb-2">📸</div>
        <div className="font-semibold mb-2">Bouquet Image Scanner</div>
        <p className="text-gray-600 text-sm">
          Detect flowers, colors, and stem counts from any bouquet photo.
        </p>
      </div>

      <div className="bg-white p-6 rounded-xl border shadow-sm">
        <div className="text-xl mb-2">🌸</div>
        <div className="font-semibold mb-2">Style & Shape Recognition</div>
        <p className="text-gray-600 text-sm">
          Identify bouquet style, shape, and floral structure automatically.
        </p>
      </div>

      <div className="bg-white p-6 rounded-xl border shadow-sm">
        <div className="text-xl mb-2">🧾</div>
        <div className="font-semibold mb-2">Auto Recipe Generator</div>
        <p className="text-gray-600 text-sm">
          Convert bouquet designs into standardized production recipes.
        </p>
      </div>

      <div className="bg-white p-6 rounded-xl border shadow-sm">
        <div className="text-xl mb-2">💰</div>
        <div className="font-semibold mb-2">Smart Cost Calculator</div>
        <p className="text-gray-600 text-sm">
          Automatically estimate flower cost, labor cost, and retail pricing.
        </p>
      </div>

      <div className="bg-white p-6 rounded-xl border shadow-sm">
        <div className="text-xl mb-2">📦</div>
        <div className="font-semibold mb-2">AI Catalog Creation</div>
        <p className="text-gray-600 text-sm">
          Create POS-ready catalog products directly from bouquet scans.
        </p>
      </div>

      <div className="bg-white p-6 rounded-xl border shadow-sm">
        <div className="text-xl mb-2">⚙️</div>
        <div className="font-semibold mb-2">Production Intelligence</div>
        <p className="text-gray-600 text-sm">
          Standardize floral recipes and streamline bouquet production.
        </p>
      </div>

    </div>

  </div>
</section>

)
}
