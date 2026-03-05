"use client";

import { products } from "@/data/products";
import { categories } from "@/data/categories";
import Image from "next/image";
import { notFound, useParams } from "next/navigation";
import { useState, useEffect } from "react";
import Link from "next/link";
import { useCart } from "@/context/CartContext";

export default function ProductPage() {
  const params = useParams<{ category: string; slug: string }>();
  const { addToCart } = useCart();

  const product = products.find(
    (p) =>
      p.slug === params?.slug &&
      p.category === params?.category
  );

  if (!product) return notFound();

  const [currentIndex, setCurrentIndex] = useState(0);
  const selectedImage = product.images[currentIndex];
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    const handleKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") setIsOpen(false);
      if (event.key === "ArrowRight") goNext();
      if (event.key === "ArrowLeft") goPrev();
    };

    if (isOpen) {
      document.addEventListener("keydown", handleKey);
    }

    return () => {
      document.removeEventListener("keydown", handleKey);
    };
  }, [isOpen]);

  const goNext = () => {
    setCurrentIndex((prev) =>
      prev === product.images.length - 1 ? 0 : prev + 1
    );
  };

  const goPrev = () => {
    setCurrentIndex((prev) =>
      prev === 0 ? product.images.length - 1 : prev - 1
    );
  };

  const categoryData = categories.find(
    (c) => c.slug === product.category
  );

  const isOutOfStock = product.stock <= 0;

  return (
    <div className="max-w-6xl mx-auto px-4 py-10 pb-24">

      {/* Breadcrumb */}
      <div className="text-sm text-gray-500 mb-6">
        <Link href="/">Home</Link> |{" "}
        <Link href={`/shop/${product.category}`}>
          {categoryData?.name}
        </Link>{" "}
        | {product.name}
      </div>

      <div className="grid md:grid-cols-2 gap-12">

        {/* Image Section */}
        <div>
          {/* Main Image */}
          <div
            onClick={() => setIsOpen(true)}
            className="relative w-full h-[400px] border rounded mb-4 overflow-hidden group cursor-zoom-in"
          >
            <Image
              src={selectedImage}
              alt={product.name}
              fill
              className="object-contain p-4 transition-transform duration-300 ease-in-out group-hover:scale-110"
            />
          </div>

          {/* Thumbnails */}
          <div className="flex gap-3">
            {product.images.map((img, index) => (
              <div
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`relative w-20 h-20 border rounded cursor-pointer ${
                  currentIndex === index
                    ? "border-pink-600"
                    : "border-gray-300"
                }`}
              >
                <Image
                  src={img}
                  alt={product.name}
                  fill
                  className="object-contain p-1"
                />
              </div>
            ))}
          </div>
        </div>

        {/* Product Details */}
        <div>
          <h1 className="text-3xl font-bold mb-4">
            {product.name}
          </h1>

          <p className="text-2xl text-pink-600 font-semibold mb-4">
            ₹{product.price}
          </p>

          <p className="text-gray-600 mb-6">
            {product.description}
          </p>

          {product.features && (
            <ul className="list-disc pl-5 space-y-2 mb-6 text-gray-700">
              {product.features.map((feature, index) => (
                <li key={index}>{feature}</li>
              ))}
            </ul>
          )}

          <button
            onClick={() => addToCart(product)}
            disabled={isOutOfStock}
            className="w-full md:w-auto bg-pink-600 hover:bg-pink-700 disabled:bg-gray-300 disabled:text-gray-600 text-white px-8 py-3 rounded font-semibold transition"
            aria-label={isOutOfStock ? `${product.name} is sold out` : `Add ${product.name} to cart`}
          >
            {isOutOfStock ? "Back Soon" : "Add to Cart"}
          </button>

          <div className="mt-4 text-sm text-gray-500">
            {product.stock > 0 ? "In Stock" : "Out of Stock"}
          </div>

          {/* Trust Badges */}
          <div className="mt-6 grid grid-cols-2 gap-4 text-sm text-gray-700">
            <div className="flex items-center gap-2">
              <span>🚚</span>
              <span>Fast Shipping Across India</span>
            </div>

            <div className="flex items-center gap-2">
              <span>💳</span>
              <span>Secure Payments via PayU</span>
            </div>

            <div className="flex items-center gap-2">
              <span>🔄</span>
              <span>Easy Return Support</span>
            </div>

            <div className="flex items-center gap-2">
              <span>🏆</span>
              <span>Trusted Brand Since 2016</span>
            </div>
          </div>
        </div>
      </div>

      {/* Lightbox Modal */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black/80 flex items-center justify-center z-50"
          onClick={() => setIsOpen(false)}
        >
          {/* Stop closing when clicking image */}
          <div
            className="relative w-[90%] md:w-[70%] h-[70%] flex items-center justify-center"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Close Button */}
            <button
              onClick={() => setIsOpen(false)}
              className="absolute top-4 right-6 text-white text-3xl"
            >
              ✕
            </button>

            {/* Left Arrow */}
            <button
              onClick={goPrev}
              className="absolute left-4 text-white text-4xl"
            >
              ‹
            </button>

            {/* Image */}
            <Image
              src={selectedImage}
              alt={product.name}
              fill
              className="object-contain"
            />

            {/* Right Arrow */}
            <button
              onClick={goNext}
              className="absolute right-4 text-white text-4xl"
            >
              ›
            </button>
          </div>
        </div>
      )}

      {/* Sticky Mobile Add to Cart */}
      <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t shadow-lg p-4 flex justify-between items-center z-40">
        <div>
          <p className="text-sm text-gray-500">Price</p>
          <p className="text-lg font-bold text-pink-600">
            ₹{product.price}
          </p>
        </div>

        <button
          onClick={() => addToCart(product)}
          disabled={isOutOfStock}
          className="bg-pink-600 hover:bg-pink-700 disabled:bg-gray-300 disabled:text-gray-600 text-white px-6 py-2 rounded font-semibold"
          aria-label={isOutOfStock ? `${product.name} is sold out` : `Add ${product.name} to cart`}
        >
          {isOutOfStock ? "Back Soon" : "Add to Cart"}
        </button>
      </div>
    </div>
  );
}