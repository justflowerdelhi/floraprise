export default function FeaturedCollections() {
  const collections = [
    { name: "Arts & Crafts", image: "/collections/craft.png", link: "/shop/craft" },
    { name: "Birthday Supplies", image: "/collections/birthday.png", link: "/shop/birthday" },
    { name: "Gift Packaging", image: "/collections/gift.png", link: "/shop/gift-packaging" },
    { name: "Home Decor", image: "/collections/decor.png", link: "/shop/home-decor" },
  ];

  return (
    <section className="py-12 bg-white">
      <div className="max-w-6xl mx-auto px-4">
        <h2 className="text-2xl font-bold text-center mb-8">
          Featured Collections
        </h2>
        <div className="grid md:grid-cols-4 gap-6">
          {collections.map((c) => (
            <a key={c.name} href={c.link}>
              <div className="rounded-lg overflow-hidden shadow hover:shadow-lg transition">
                <img
                  src={c.image}
                  alt={c.name}
                  className="w-full h-48 object-cover"
                />
                <div className="p-4 text-center font-semibold">
                  {c.name}
                </div>
              </div>
            </a>
          ))}
        </div>
      </div>
    </section>
  );
}
