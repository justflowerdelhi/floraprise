import Footer from "@/components/Footer";

export default function AboutPage() {
  return (
    <>
      <div className="max-w-6xl mx-auto px-6 py-12 space-y-12">

      <h1 className="text-3xl font-bold text-center">
        About 3A Featuretail
      </h1>

      <p className="text-lg text-gray-700 leading-relaxed">
        Established in 2016, <b>3A Featuretail</b> is an innovation-driven
        organization dedicated to enhancing the lifestyles of our customers
        through thoughtful design and premium quality. We pride ourselves on
        being a forward-thinking brand that bridges the gap between
        contemporary trends and practical utility.
      </p>

      <p className="text-lg text-gray-700 leading-relaxed">
        Through our signature brands, <b>"3A Featuretail"</b> and
        <b> "Pandeji"</b>, we have rapidly emerged as a trusted name in the
        e-commerce landscape, recognized for delivering export-quality
        products that combine aesthetic appeal with affordability.
      </p>

      {/* Philosophy */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Our Philosophy</h2>

        <p className="text-gray-700 leading-relaxed">
          At the core of our business is a commitment to continuous research
          and development. We believe that every product should make our
          customers' lives easier. By staying ahead of global design trends,
          we ensure that our catalog remains fresh, functional, and superior
          in quality.
        </p>
      </section>

      {/* Product Portfolio */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Our Product Portfolio</h2>

        <p className="text-gray-700">
          We offer an unrivalled range of products across several lifestyle
          and creative categories:
        </p>

        <ul className="list-disc pl-6 space-y-2 text-gray-700">
          <li>
            <b>Arts & Crafts:</b> Specialized supplies including our popular
            Pipe Cleaner Craft range.
          </li>

          <li>
            <b>Home & Festive Decor:</b> Unique pieces designed to elevate
            living spaces and celebrate traditions.
          </li>

          <li>
            <b>Gift Packaging:</b> Premium solutions to make every gesture
            memorable.
          </li>

          <li>
            <b>Birthday & Party Supplies:</b> Comprehensive essentials for
            seamless celebrations.
          </li>
        </ul>
      </section>

      {/* Trusted Excellence */}
      <section className="space-y-4">
        <h2 className="text-2xl font-semibold">Trusted Excellence</h2>

        <p className="text-gray-700">
          We have solidified our reputation as a leading supplier by
          maintaining rigorous quality standards.
        </p>

        <ul className="list-disc pl-6 space-y-2 text-gray-700">
          <li>
            <b>Premium Level Seller Status:</b> A testament to our service and
            quality on Amazon.in.
          </li>

          <li>
            <b>Multi-Platform Availability:</b> Proudly serving customers
            across Flipkart and Meesho.
          </li>

          <li>
            <b>Regulatory Compliance:</b> Fully registered and compliant with
            food safety standards where applicable (FSSAI No.
            23322005001716).
          </li>
        </ul>
      </section>

      {/* Why Featuretail */}
      <section className="space-y-4">

        <h2 className="text-2xl font-semibold">
          Why Choose 3A Featuretail?
        </h2>

        <div className="grid md:grid-cols-2 gap-6">

          <div className="border p-5 rounded-lg">
            <h3 className="font-semibold">Innovation-First</h3>
            <p className="text-gray-600">
              Access to the latest global designs and trends.
            </p>
          </div>

          <div className="border p-5 rounded-lg">
            <h3 className="font-semibold">Premium Quality</h3>
            <p className="text-gray-600">
              Export-grade materials used across all product lines.
            </p>
          </div>

          <div className="border p-5 rounded-lg">
            <h3 className="font-semibold">Affordability</h3>
            <p className="text-gray-600">
              High-end aesthetics at accessible price points.
            </p>
          </div>

          <div className="border p-5 rounded-lg">
            <h3 className="font-semibold">Customer Centric</h3>
            <p className="text-gray-600">
              Products designed specifically to simplify daily life.
            </p>
          </div>

        </div>

      </section>

      {/* Mission */}
      <section className="text-center bg-gray-100 p-8 rounded-lg">
        <p className="text-xl italic text-gray-700">
          "Our mission is to bring joy and convenience to every household
          through creativity and quality craftsmanship."
        </p>
      </section>
      </div>
      <Footer />
    </>
  )
}
