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
        <section className="w-full bg-white mb-2 md:mb-4">
          <Image
            src="/hero.jpg"
            alt="3A Featuretail Banner"
            width={1920}
            height={600}
            priority
            className="w-full h-auto object-cover"
          />
        </section>

      <section className="py-3 md:py-4">
        <FeatureHighlights />
      </section>

      <section className="py-3 md:py-4 bg-gray-50">
        <MarketplaceLogos />
      </section>

      <section className="py-3 md:py-4">
        <FeaturedCollections />
      </section>

      <section className="py-3 md:py-4 bg-gray-50">
        <TrustBar />
      </section>

      {/* About / Trust Section */}
      <section className="py-3 md:py-4 bg-white text-center px-2">
        <h1 className="text-xl md:text-3xl font-bold text-gray-800 mb-3">
          Craft Your Creativity. Celebrate Every Moment.
        </h1>
        <p className="text-gray-600 max-w-2xl mx-auto text-sm md:text-base leading-relaxed">
          3A Featuretail is a premium craft and celebration supplies brand proudly
          serving customers across India since 2016. As a trusted top-rated seller
          on Amazon, we are known for quality, consistency, and customer satisfaction.
          We are also a reliable business partner for many corporates and institutions,
          supplying curated art, decor, gift packaging, and festive solutions with
          professional service and timely delivery.
        </p>
        <div className="mt-3 text-pink-600 font-semibold text-base">
          ⭐ Trusted by 10,000+ Happy Customers Across India
        </div>
        <div className="mt-4">
          <a href="/shop">
            <button className="bg-pink-600 hover:bg-pink-700 text-white px-8 py-3 rounded-md font-semibold transition">
              Shop Now
            </button>
          </a>
        </div>
      </section>

      <section className="py-3 md:py-4">
        <BestSellers />
      </section>

      <section className="py-3 md:py-4">
        <Newsletter />
      </section>

      <section className="py-3 md:py-4">
        <NewArrivals />
      </section>

      <section className="py-3 md:py-4">
        <CustomerReviews />
      </section>
      <Footer />
    </>
  );
}