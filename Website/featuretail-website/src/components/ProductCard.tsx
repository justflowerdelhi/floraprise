"use client";

import Image from "next/image";
import { Product } from "../data/products";
import { useCart } from "../context/CartContext";

interface Props {
  product: Product;
}

const currencyFormatter = new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
  maximumFractionDigits: 0,
});

export default function ProductCard({ product }: Props) {
  const { addToCart } = useCart();
  const isOutOfStock = product.stock <= 0;
  const isNewArrival = Date.now() - new Date(product.createdAt).getTime() <= 1000 * 60 * 60 * 24 * 14; // 14 days

  return (
    <div className="bg-white rounded-xl shadow-sm hover:shadow-md transition p-4 border border-gray-100 flex flex-col">
      <div className="relative w-full h-48 mb-4">
        {product.isBestSeller && (
          <span className="absolute top-3 left-3 bg-pink-600 text-white text-xs font-semibold px-3 py-1 rounded-full z-10">
            Best Seller
          </span>
        )}
        {isNewArrival && (
          <span className="absolute top-3 right-3 bg-emerald-600 text-white text-xs font-semibold px-3 py-1 rounded-full z-10">
            New
          </span>
        )}
        <Image
          src={product.image}
          alt={product.name}
          fill
          sizes="(max-width: 768px) 100vw, 25vw"
          className="object-cover rounded-lg"
          priority={false}
        />
      </div>

      <h3 className="font-semibold text-base mb-1 line-clamp-2 flex-1">
        {product.name}
      </h3>

      <p className="text-sm text-gray-500 mb-2">
        Stock: {isOutOfStock ? "Sold out" : `${product.stock} left`}
      </p>

      <p className="text-pink-600 font-bold text-lg mb-3">
        {currencyFormatter.format(product.price)}
      </p>

      <button
        onClick={() => addToCart(product)}
        className="w-full bg-pink-600 hover:bg-pink-700 disabled:bg-gray-300 disabled:text-gray-500 text-white py-2 rounded font-medium transition"
        disabled={isOutOfStock}
        aria-label={isOutOfStock ? `${product.name} is sold out` : `Add ${product.name} to cart`}
      >
        {isOutOfStock ? "Back Soon" : "Add to Cart"}
      </button>
    </div>
  );
}