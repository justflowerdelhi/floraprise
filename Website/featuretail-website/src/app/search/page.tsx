"use client"

import {useEffect,useState,Suspense} from "react"

type Product = {
	id: string;
	name: string;
	images?: { url: string }[];
	price?: number;
	[key: string]: any;
};
import {useSearchParams} from "next/navigation"


export default function SearchPage() {
	return (
		<Suspense>
			<SearchPageContent />
		</Suspense>
	);
}

function SearchPageContent() {
	const searchParams = useSearchParams();
	const query = searchParams.get("q");
	const [products, setProducts] = useState<Product[]>([]);
	const [sort, setSort] = useState("new");

	useEffect(() => {
		const fetchProducts = async () => {
			const res = await fetch(`/api/products/search?q=${query}&sort=${sort}`);
			const data = await res.json();
			setProducts(data);
		};
		if (query) {
			fetchProducts();
		}
	}, [query, sort]);

	return (
		<div className="max-w-7xl mx-auto p-6">
			<div className="flex justify-between items-center mb-6">
				<h1 className="text-2xl font-bold">
					Search results for "{query}"
				</h1>
				<select
					className="border p-2 rounded"
					value={sort}
					onChange={(e) => setSort(e.target.value)}
				>
					<option value="new">Newest</option>
					<option value="price-low">Price Low → High</option>
					<option value="price-high">Price High → Low</option>
				</select>
			</div>
			<div className="grid grid-cols-4 gap-6">
				{products.map((p) => (
					<div
						key={p.id}
						className="border rounded p-3 hover:shadow-md"
					>
						<img
							src={p.images?.[0]?.url || "/noimage.png"}
							className="w-full h-40 object-cover rounded"
						/>
						<h3 className="mt-2 text-sm font-medium">{p.name}</h3>
						<p className="text-pink-600 font-semibold">₹{p.price}</p>
					</div>
				))}
			</div>
		</div>
	);
}

// ...existing code...