"use client";
import ProductCard from "./ProductCard";
import { useEffect, useState } from "react";

export default function NewArrivals() {
  const [products, setProducts] = useState<any[]>([]);
  useEffect(() => {
    fetch("/api/products")
      .then((res) => res.json())
      .then((data) => setProducts(data));
  }, []);
  const newProducts = products
    .filter((p) => p.stock > 0)
    .sort(
      (a, b) =>
        new Date(b.createdAt).getTime() -
        new Date(a.createdAt).getTime()
    )
    .slice(0, 4);
  return (
    <section className="py-12 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4">
        <h2 className="text-3xl font-bold text-center mb-10">
          🆕 New Arrivals
        </h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {newProducts.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      </div>
    </section>
  );
}
