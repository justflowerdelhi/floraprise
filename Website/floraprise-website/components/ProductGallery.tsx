import Image from "next/image"

export default function ProductGallery() {
return ( <section className="py-24 bg-white"> <div className="max-w-6xl mx-auto px-6 text-center">

    <h2 className="text-3xl md:text-4xl font-semibold mb-6">
      See Floraprise in Action
    </h2>

    <p className="text-gray-600 max-w-3xl mx-auto mb-16">
      From POS billing to inventory control, delivery routing,
      and financial reporting — Floraprise gives florists complete
      operational visibility.
    </p>

    <div className="grid md:grid-cols-2 gap-10">

      <div className="bg-gray-50 p-6 rounded-xl shadow-sm">
        <Image
          src="/screens/pos.png"
          alt="Floraprise POS system"
          width={800}
          height={500}
          className="rounded-lg"
        />
        <div className="mt-4 font-medium">Florist POS</div>
      </div>

      <div className="bg-gray-50 p-6 rounded-xl shadow-sm">
        <Image
          src="/screens/inventory.png"
          alt="Floraprise inventory management"
          width={800}
          height={500}
          className="rounded-lg"
        />
        <div className="mt-4 font-medium">Inventory & Batch Tracking</div>
      </div>

      <div className="bg-gray-50 p-6 rounded-xl shadow-sm">
        <Image
          src="/screens/production.png"
          alt="Bouquet production workflow"
          width={800}
          height={500}
          className="rounded-lg"
        />
        <div className="mt-4 font-medium">Bouquet Production</div>
      </div>

      <div className="bg-gray-50 p-6 rounded-xl shadow-sm">
        <Image
          src="/screens/delivery.png"
          alt="Floraprise delivery routing"
          width={800}
          height={500}
          className="rounded-lg"
        />
        <div className="mt-4 font-medium">Delivery Routing</div>
      </div>

    </div>

  </div>
</section>
)
}
