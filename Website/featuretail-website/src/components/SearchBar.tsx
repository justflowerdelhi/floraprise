"use client"

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";


export default function SearchBar() {
	const router = useRouter();
	const [query, setQuery] = useState("");
	type Product = {
		id: string;
		name: string;
		images?: { url: string }[];
		price?: number;
		[key: string]: any;
	};

	const [results, setResults] = useState<Product[]>([]);

	useEffect(() => {
		if (query.length < 2) {
			setResults([]);
			return;
		}
		const fetchSearch = async () => {
			const res = await fetch(`/api/products/search?q=${query}`);
			const data = await res.json();
			setResults(data);
		};
		fetchSearch();
	}, [query]);

	return (
		<div className="relative w-full">
			<input
				className="border border-gray-300 p-3 w-full rounded-md"
				placeholder="Search craft supplies..."
				value={query}
				onChange={(e) => setQuery(e.target.value)}
				onKeyDown={(e) => {
					if (e.key === "Enter") {
						router.push(`/search?q=${query}`);
					}
				}}
			/>
			{results.length > 0 && (
				<div className="absolute bg-white border w-full mt-1 rounded shadow-lg z-50">
					{results.map((p) => (
						<div
							key={p.id}
							className="flex items-center gap-3 p-3 hover:bg-gray-100 cursor-pointer"
						>
							<img
								src={p.images?.[0]?.url || "/noimage.png"}
								className="w-10 h-10 object-cover rounded"
							/>
							<div className="flex-1">
								<p className="text-sm font-medium">{p.name}</p>
								<p className="text-pink-600 text-sm">₹{p.price}</p>
							</div>
						</div>
					))}
					<div
						className="p-3 text-center text-pink-600 cursor-pointer hover:bg-gray-100"
						onClick={() => router.push(`/search?q=${query}`)}
					>
						View all results for "{query}"
					</div>
				</div>
			)}
		</div>
	);
}