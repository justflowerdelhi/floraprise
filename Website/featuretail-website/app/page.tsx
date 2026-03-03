import Image from "next/image";
import CategoryGrid from "../src/components/CategoryGrid";
import BestSellers from "../src/components/BestSellers";
import NewArrivals from "../src/components/NewArrivals";

export default function Home() {
  return (
    <main>

      {/* Hero Image Only */}
      <section className="w-full h-[220px] md:h-auto object-contain bg-white">
        <Image
          src="/hero.jpg"
          alt="3A Featuretail Banner"
          width={1920}
          height={600}
          priority
          className="w-full h-auto object-cover"
        />
      </section>

      {/* Tagline Section Below Hero */}
      <section className="py-12 bg-white text-center px-4">
        <h1 className="text-2xl md:text-4xl font-bold text-gray-800 mb-4">
          Craft Your Creativity. Celebrate Every Moment.
        </h1>

        <p className="text-gray-600 mb-6 max-w-2xl mx-auto">
          Premium art & craft supplies, festive decor, birthday decorations,
          gift packaging and creative materials delivered across India.
        </p>

        <button className="bg-pink-600 hover:bg-pink-700 text-white px-8 py-3 rounded-md font-semibold transition">
          Shop Now
        </button>
      </section>

      {/* Category Grid Section */}
      <CategoryGrid />
      <BestSellers />
      <NewArrivals />

    </main>
  );
}