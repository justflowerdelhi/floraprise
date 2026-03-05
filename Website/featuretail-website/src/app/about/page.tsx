import Footer from "@/components/Footer";

export default function AboutPage() {
  return (
    <>
      <div className="max-w-6xl mx-auto px-6 py-12 space-y-16">

        {/* Hero */}
        <section className="text-center space-y-6">

          <h1 className="text-4xl font-bold">
            About 3A Featuretail
          </h1>

          <p className="text-lg text-gray-700 max-w-3xl mx-auto">
            Established in 2016, <b>3A Featuretail</b> is an innovation-driven
            organization dedicated to enhancing lifestyles through thoughtful
            design and premium quality products.
          </p>

          <p className="text-gray-600 max-w-3xl mx-auto">
            Through our signature brands <b>3A Featuretail</b> and <b>Pandeji</b>,
            we combine contemporary design trends with practical everyday
            utility to deliver export-quality products at accessible prices.
          </p>

        </section>

        {/* Brand Section */}
        <section className="text-center space-y-6">

          <h2 className="text-2xl font-semibold">
            Our Brands
          </h2>

          <div className="flex justify-center gap-10">

            <div className="border p-6 rounded-lg w-48">
              <p className="font-semibold">3A Featuretail</p>
              <p className="text-sm text-gray-500">
                Lifestyle & Celebration Products
              </p>
            </div>

            <div className="border p-6 rounded-lg w-48">
              <p className="font-semibold">Pandeji</p>
              <p className="text-sm text-gray-500">
                Creative Craft Supplies
              </p>
            </div>

          </div>

        </section>

        {/* Product Portfolio */}
        <section className="space-y-6">

          <h2 className="text-2xl font-semibold">
            Our Product Portfolio
          </h2>

          <div className="grid md:grid-cols-2 gap-6">

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Arts & Crafts</h3>
              <p className="text-gray-600">
                Specialized craft supplies including our popular
                Pipe Cleaner Craft range.
              </p>
            </div>

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Home & Festive Decor</h3>
              <p className="text-gray-600">
                Unique decorative products designed to elevate living spaces
                and celebrations.
              </p>
            </div>

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Gift Packaging</h3>
              <p className="text-gray-600">
                Premium packaging solutions to make every gift memorable.
              </p>
            </div>

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Birthday & Party Supplies</h3>
              <p className="text-gray-600">
                Complete essentials for seamless celebrations.
              </p>
            </div>

          </div>

        </section>

        {/* Marketplace Presence */}
        <section className="space-y-6 text-center">

          <h2 className="text-2xl font-semibold">
            Marketplace Presence
          </h2>

          <p className="text-gray-700">
            We proudly serve customers across India's leading marketplaces.
          </p>

          <div className="flex justify-center gap-8">

            <div className="border p-4 rounded-lg">Amazon</div>
            <div className="border p-4 rounded-lg">Flipkart</div>
            <div className="border p-4 rounded-lg">Meesho</div>

          </div>

        </section>

        {/* Why Featuretail */}
        <section className="space-y-6">

          <h2 className="text-2xl font-semibold text-center">
            Why Choose 3A Featuretail?
          </h2>

          <div className="grid md:grid-cols-2 gap-6">

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Innovation First</h3>
              <p className="text-gray-600">
                Access to the latest global designs and trends.
              </p>
            </div>

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Premium Quality</h3>
              <p className="text-gray-600">
                Export-grade materials used across our product lines.
              </p>
            </div>

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Affordable Excellence</h3>
              <p className="text-gray-600">
                Premium aesthetics at accessible price points.
              </p>
            </div>

            <div className="border p-5 rounded-lg">
              <h3 className="font-semibold">Customer Centric</h3>
              <p className="text-gray-600">
                Products designed to simplify daily life.
              </p>
            </div>

          </div>

        </section>

        {/* Compliance */}
        <section className="text-center space-y-3">

          <h2 className="text-xl font-semibold">
            Regulatory Compliance
          </h2>

          <p className="text-gray-600">
            Fully registered and compliant with applicable food safety
            regulations (FSSAI No. 23322005001716).
          </p>

        </section>

        {/* Mission */}
        <section className="bg-gray-100 p-10 rounded-lg text-center">

          <p className="text-xl italic text-gray-700">
            "Our mission is to bring joy and convenience to every household
            through creativity and quality craftsmanship."
          </p>

        </section>

      </div>
      <Footer />
    </>
  );
}