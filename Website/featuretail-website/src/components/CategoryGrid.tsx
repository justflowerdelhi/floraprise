import Link from "next/link";
import { categories } from "../data/categories";

export default function CategoryGrid() {
  return (
    <section className="py-12 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4">
        <h2 className="text-3xl font-bold text-center mb-10">
          Shop by Category
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
          {categories?.map((category) => (
            <Link
              key={category.id}
              href={`/shop/${category.slug}`}
              className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition text-center"
            >
              <h3 className="font-semibold text-lg mb-2">
                {category.name}
              </h3>
              <p className="text-sm text-gray-500">
                {category.subcategories?.length} Subcategories
              </p>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}