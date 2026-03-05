"use client";

import { useState } from "react";

type Product = {
  id: string;
  name: string;
  images?: { url: string }[];
  price?: number;
  [key: string]: any;
};
import ProductFilters from "@/components/ProductFilters";

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);

  const fetchFiltered = async (filters: Record<string, string>) => {
    const params = new URLSearchParams(filters);
    const res = await fetch(`/api/products/filter?${params}`);
    const data = await res.json();
    setProducts(data);
  };

  return (
    <div className="flex gap-10">
      <ProductFilters onFilter={fetchFiltered} />
      <div className="grid grid-cols-4 gap-6">
        {products.map((p) => (
          <div key={p.id}>
            <img
              src={p.images?.[0]?.url}
              className="w-full h-40 object-cover"
              alt={p.name}
            />
            <h3>{p.name}</h3>
            <p>₹{p.price}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
