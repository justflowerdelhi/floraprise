import Link from "next/link";
import { products } from "../data/products";
import ProductCard from "./ProductCard";

interface Props {
  categorySlug: string;
  categoryName: string;
}

export default function CategorySection({
  categorySlug,
  categoryName,
}: Props) {
  const categoryProducts = products
    .filter((p) => p.category === categorySlug && p.stock > 0)
    .slice(0, 8);

  if (categoryProducts.length === 0) return null;

  return (
    <section className="py-12">
      <div className="max-w-7xl mx-auto px-4">

        {/* Heading */}
        <div className="flex justify-between items-center mb-8">
          <h2 className="text-2xl md:text-3xl font-bold">
            {categoryName}
          </h2>

          <Link
            href={`/shop/${categorySlug}`}
            className="text-pink-600 font-semibold hover:underline"
          >
            View More →
          </Link>
        </div>

        {/* Product Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {categoryProducts.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>

      </div>
    </section>
  );
}
