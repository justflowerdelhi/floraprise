import { products } from "../data/products";
import ProductCard from "./ProductCard";

export default function HomeSection() {

  const homeProducts = products
    .filter((p) => p.tags?.includes("home") && p.stock > 0)
    .slice(0, 8);

  if (homeProducts.length === 0) return null;

  return (
    <section className="py-6">
      <div className="max-w-7xl mx-auto px-4">

      <h2 className="text-3xl font-bold mb-4">
          Featured Products
        </h2>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {homeProducts.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>

      </div>
    </section>
  );
}
