import { products } from "../../../data/products";
import { categories } from "../../../data/categories";
import ProductCard from "../../../components/ProductCard";
import { Metadata } from "next";

interface Props {
  params: { category: string };
}

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const categoryData = categories.find(
    (c) => c.slug === params.category
  );

  if (!categoryData) {
    return {
      title: "Category Not Found | 3A Featuretail",
    };
  }

  return {
    title: `${categoryData.name} Online in India | 3A Featuretail`,
    description: `Shop premium ${categoryData.name.toLowerCase()} supplies online in India. Trusted since 2016. COD available. 5% prepaid discount.`,
  };
}

export default function CategoryPage({ params }: Props) {
  const categoryProducts = products.filter(
    (p) => p.category === params.category && p.stock > 0
  );

  const categoryData = categories.find(
    (c) => c.slug === params.category
  );

  if (!categoryData) {
    return (
      <div className="max-w-6xl mx-auto px-4 py-4 text-center">
        <h1 className="text-2xl font-bold">Category Not Found</h1>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto px-4 py-10">

      <h1 className="text-3xl md:text-4xl font-bold mb-8">
        {categoryData.name}
      </h1>

      {categoryProducts.length === 0 ? (
        <p>No products available in this category.</p>
      ) : (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {categoryProducts.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      )}
    </div>
  );
}