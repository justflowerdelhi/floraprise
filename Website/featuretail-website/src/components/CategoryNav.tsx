import Link from "next/link";
import { categories } from "../data/categories";

export default function CategoryNav() {
  return (
    <section className="bg-gray-50 border-y">
      <div className="max-w-7xl mx-auto px-4 py-4 overflow-x-auto whitespace-nowrap text-center">
        {categories.map((category, index) => (
          <span key={category.id}>
            <Link
              href={`/shop/${category.slug}`}
              className="text-sm md:text-base font-medium hover:text-pink-600 transition"
            >
              {category.name}
            </Link>

            {index < categories.length - 1 && (
              <span className="mx-3 text-gray-400">|</span>
            )}
          </span>
        ))}
      </div>
    </section>
  );
}
