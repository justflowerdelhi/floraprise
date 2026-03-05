"use client"

import { useState } from "react"

interface ProductFiltersProps {
	onFilter: (filters: Record<string, string>) => void;
}

export default function ProductFilters({ onFilter }: ProductFiltersProps) {
	const [query, setQuery] = useState("");

const [category,setCategory] = useState("")
const [min,setMin] = useState("")
const [max,setMax] = useState("")

const applyFilters = ()=>{

onFilter({
category,
min,
max
})

}

return(

<div className="w-64 space-y-6">

<h3 className="font-semibold">Filters</h3>

<div>

<label>Category</label>

<select
className="border p-2 w-full"
value={category}
onChange={(e)=>setCategory(e.target.value)}
>

<option value="">All</option>
<option value="artcraft">Art & Craft</option>
<option value="decor">Home Decor</option>

</select>

</div>

<div>

<label>Price Range</label>

				<div className="relative w-[600px]">
					<input
						className="border border-gray-300 p-3 pl-4 pr-12 w-full rounded-md focus:outline-none focus:ring-2 focus:ring-pink-500"
						placeholder="Search craft supplies, pipe cleaners, balloons..."
						value={query}
						onChange={(e)=>setQuery(e.target.value)}
					/>
					<button
						className="absolute right-2 top-1/2 -translate-y-1/2 bg-pink-600 text-white px-3 py-1 rounded"
					>
						🔍
					</button>
				</div>

<input
	className="border p-2 w-full"
	placeholder="Max"
	value={max}
	onChange={(e)=>setMax(e.target.value)}
/>

</div>

<button
className="bg-pink-600 text-white px-4 py-2 rounded"
onClick={applyFilters}
>

Apply Filters

</button>

</div>

)

}