import Image from "next/image";
import Header from "@/components/Header";
import HomeCategories from "@/components/HomeCategories";
import BestSellers from "@/components/BestSellers";
import NewArrivals from "@/components/NewArrivals";
import Newsletter from "@/components/Newsletter";
import MarketplaceLogos from "@/components/MarketplaceLogos";
import CustomerReviews from "@/components/CustomerReviews";
import Footer from "@/components/Footer";
import FeaturedCollections from "@/components/FeaturedCollections";
import TrustBar from "@/components/TrustBar";
import FeatureHighlights from "@/components/FeatureHighlights";

export const metadata = {
  title: "3A Featuretail | Craft & Celebration Supplies",
  description:
    "Shop premium craft supplies, birthday decorations, gift packaging and festive decor online in India.",
};

export default function Home() {
  return (
    <>
      {/* Hero Banner */}
      <section className="w-full h-[220px] md:h-auto object-contain bg-white mb-4 md:mb-6">
        <Image
          src="/hero.jpg"
          alt="3A Featuretail Banner"
          width={1920}
          height={600}
          priority
          className="w-full h-auto object-cover"
        />
      </section>

      <section className="py-4 md:py-6">
        <FeatureHighlights />
      </section>

      <section className="py-4 md:py-6 bg-gray-50">
        <MarketplaceLogos />
      </section>

      <section className="py-4 md:py-6">
        <FeaturedCollections />
      </section>

      <section className="py-4 md:py-6 bg-gray-50">
        <TrustBar />
      </section>

      {/* About / Trust Section */}
      <section className="py-4 md:py-6 bg-white text-center px-4">
        <h1 className="text-2xl md:text-4xl font-bold text-gray-800 mb-4">
          Craft Your Creativity. Celebrate Every Moment.
        </h1>
        <p className="text-gray-600 max-w-3xl mx-auto text-base md:text-lg leading-relaxed">
          3A Featuretail is a premium craft and celebration supplies brand proudly
          serving customers across India since 2016. As a trusted top-rated seller
          on Amazon, we are known for quality, consistency, and customer satisfaction.
          We are also a reliable business partner for many corporates and institutions,
          supplying curated art, decor, gift packaging, and festive solutions with
          professional service and timely delivery.
        </p>
        <div className="mt-4 text-pink-600 font-semibold text-lg">
          ⭐ Trusted by 10,000+ Happy Customers Across India
        </div>
        <div className="mt-5">
          <a href="/shop">
            <button className="bg-pink-600 hover:bg-pink-700 text-white px-8 py-3 rounded-md font-semibold transition">
              Shop Now
            </button>
          </a>
        </div>
      </section>

      <section className="py-4 md:py-6">
        <BestSellers />
      </section>

      <section className="py-4 md:py-6">
        <Newsletter />
      </section>

      <section className="py-4 md:py-6">
        <NewArrivals />
      </section>

      <section className="py-4 md:py-6">
        <CustomerReviews />
      </section>
      <Footer />
    </>
  );
}