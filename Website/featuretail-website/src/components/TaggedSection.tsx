import { products } from "../data/products";
import ProductCard from "./ProductCard";

interface Props {
  tag: string;
  title: string;
  bg?: string;
}

export default function TaggedSection({ tag, title, bg }: Props) {

  const sectionProducts = products
    .filter((p) => p.tags?.includes(tag) && p.stock > 0)
    .slice(0, 8);

  if (sectionProducts.length === 0) return null;

  return (
    <section className={`py-12 ${bg || "bg-white"}`}>
      <div className="max-w-7xl mx-auto px-4">

        <h2 className="text-3xl font-bold text-center mb-10">
          {title}
        </h2>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {sectionProducts.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>

      </div>
    </section>
  );
}
