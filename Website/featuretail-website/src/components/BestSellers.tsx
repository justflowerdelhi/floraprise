"use client";
import ProductCard from "./ProductCard";
import { useEffect, useState } from "react";

export default function BestSellers() {
	const [products, setProducts] = useState<any[]>([]);
	useEffect(() => {
		fetch("/api/products")
			.then((res) => res.json())
			.then((data) => setProducts(data));
	}, []);
	const bestProducts = products
		.filter((p) => p.tags?.includes("best-seller") && p.stock > 0)
		.slice(0, 4);
	if (bestProducts.length === 0) return null;
	return (
		<section className="py-12 bg-white">
			<div className="max-w-7xl mx-auto px-4">
				<h2 className="text-3xl font-bold text-center mb-10">
					⭐ Best Sellers
				</h2>
				<div className="grid grid-cols-2 md:grid-cols-4 gap-6">
					{bestProducts.map((product) => (
						<ProductCard key={product.id} product={product} />
					))}
				</div>
			</div>
		</section>
	);
}
