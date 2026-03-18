import Link from "next/link"

export default function HomeCategories(){


const categories = [
  { name: "Art & Craft", slug: "Arts & Craft", image: "/craft.png", shop: true },
  { name: "Home & Festive Decor", slug: "home-decor", image: "/decor.png" },
  { name: "Gift Packaging", slug: "gift-packaging", image: "/gift.png" },
  { name: "Paper Craft", slug: "paper-craft", image: "/paper.png" },
  { name: "Birthday Supplies", slug: "birthday-supplies", image: "/birthday.png" },
  { name: "Pipe Cleaners", slug: "pipe-cleaners", image: "/pipe.png" }
];

return(

<section className="max-w-7xl mx-auto py-12">
	<h2 className="text-2xl font-bold mb-8 text-center">
		🛍 Shop by Category
	</h2>
	<div className="grid grid-cols-3 gap-6">
		{categories.map(cat => (
			<Link
				href={cat.name === "Art & Craft" ? `/shop/Arts & Craft` : `/category/${cat.slug}`}
				key={cat.slug}
			>
				<div className="border rounded-lg overflow-hidden hover:shadow-lg hover:scale-105 transition cursor-pointer">
					<img
						src={cat.image}
						className="w-full h-44 object-cover"
						alt={cat.name}
					/>
					<div className="p-4 text-center font-medium">
						{cat.name}
					</div>
				</div>
			</Link>
		))}
	</div>
</section>

)

}