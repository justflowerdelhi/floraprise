export default function MarketplaceLogos() {
  return (
    <section className="py-4 bg-gray-50 text-center">
      <h2 className="text-xl font-semibold mb-6">
        Available On Leading Marketplaces
      </h2>
      <div className="flex justify-center items-center gap-10 flex-wrap">
        <img src="/amazon.png" alt="Amazon" className="h-8 opacity-80" />
        <img src="/flipkart.png" alt="Flipkart" className="h-8 opacity-80" />
        <img src="/meesho.png" alt="Meesho" className="h-8 opacity-80" />
      </div>
    </section>
  );
}
