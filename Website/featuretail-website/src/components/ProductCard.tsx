"use client";

import Image from "next/image";
import Link from "next/link";
import { Product } from "../data/products";
import { useCart } from "@/context/CartContext";
import { useState } from "react";
import toast from "react-hot-toast";

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
  const [added, setAdded] = useState(false);
  const isOutOfStock = product.stock <= 0;
  const isBestSeller = product.tags?.includes("best-seller");
  const isNewArrival = Date.now() - new Date(product.createdAt).getTime() <= 1000 * 60 * 60 * 24 * 14; // 14 days
  const primaryImage = product.images?.[0] || "/images/product-placeholder.png";

  return (
    <div className="bg-white rounded-xl shadow-sm hover:shadow-md transition p-4 border border-gray-100 flex flex-col">
      <Link href={`/shop/${product.category?.slug || "all"}/${product.slug}`} className="flex-1">
        <div>
          <div className="relative w-full h-48 mb-4">
            {isBestSeller && (
              <span className="absolute top-3 left-3 bg-pink-600 text-white text-xs font-semibold px-3 py-1 rounded-full z-10">
                Best Seller
              </span>
            )}
            {isNewArrival && (
              <span className="absolute top-3 right-3 bg-emerald-600 text-white text-xs font-semibold px-3 py-1 rounded-full z-10">
                New
              </span>
            )}
            <img
              src={
                product.images && product.images.length > 0
                  ? product.images[0].url
                  : "/placeholder.jpg"
              }
              alt={product.name}
              className="w-full h-48 object-cover rounded"
            />
          </div>

          <h3 className="text-sm font-medium line-clamp-2">
            {product.name}
          </h3>

          <p className="text-sm text-gray-500 mb-2">
            Stock: {isOutOfStock ? "Sold out" : `${product.stock} left`}
          </p>

          <p className="text-pink-600 font-bold text-lg mb-3">
            {currencyFormatter.format(product.price)}
          </p>
        </div>
      </Link>

      <button
        onClick={() => {
          addToCart({
            ...product,
            images: product.images && product.images.length > 0
              ? product.images
              : ["/placeholder.jpg"],
            quantity: 1,
          });
          toast.success("Added to cart 🛒");
          setAdded(true);
          setTimeout(() => {
            setAdded(false);
          }, 2000);
        }}
        className="bg-pink-600 text-white px-4 py-2 rounded"
      >
        Add to Cart
      </button>

      {added && (
        <div className="fixed bottom-6 right-6 bg-white border shadow-lg rounded-lg p-4 z-50">
          <p className="text-green-600 font-semibold">
            ✔ Item added to cart
          </p>
          <p className="text-sm mt-1">{product.name}</p>
          <div className="flex gap-3 mt-3">
            <Link
              href="/cart"
              className="text-sm bg-gray-200 px-3 py-1 rounded"
            >
              View Cart
            </Link>
            <button
              onClick={() => setAdded(false)}
              className="text-sm bg-pink-600 text-white px-3 py-1 rounded"
            >
              Continue
            </button>
          </div>
        </div>
      )}

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{
          __html: JSON.stringify({
            "@context": "https://schema.org/",
            "@type": "Product",
            name: product.name,
            image: product.images,
            description: product.name,
            brand: {
              "@type": "Brand",
              name: "3A Featuretail",
            },
            offers: {
              "@type": "Offer",
              priceCurrency: "INR",
              price: product.price,
              availability:
                product.stock > 0
                  ? "https://schema.org/InStock"
                  : "https://schema.org/OutOfStock",
            },
          }),
        }}
      />
    </div>
  );
}