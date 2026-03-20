import ProductCard from "./ProductCard";

async function getProducts() {
  const res = await fetch(`${process.env.NEXT_PUBLIC_BASE_URL}/api/products`, {
    cache: "no-store",
  });
  return res.json();
}

export default async function BestSellers() {
  const products = await getProducts();
  if (!Array.isArray(products)) {
    return null;
  }
  const bestProducts = products
    .filter((p: any) => p.tags?.includes("best-seller") && p.stock > 0)
    .slice(0, 4);
  if (bestProducts.length === 0) return null;

  return (
    <section className="py-6 md:py-10 bg-white">
      <div className="max-w-7xl mx-auto px-4">
        <h2 className="text-2xl md:text-3xl font-bold text-center mb-6 md:mb-10">
          ⭐ Best Sellers
        </h2>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 md:gap-6">
          {bestProducts.map((product: any) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      </div>
    </section>
  );
}