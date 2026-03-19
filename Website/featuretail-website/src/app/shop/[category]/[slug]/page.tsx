"use client";

import Image from "next/image";
import { useParams } from "next/navigation";
import { useState, useEffect } from "react";
import Link from "next/link";
import { useCart } from "@/context/CartContext";
import { categories } from "@/data/categories";

export default function ProductPage() {
  const params = useParams<{ category: string; slug: string }>();
  const { addToCart } = useCart();

  const [product, setProduct] = useState<any>(null);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [isOpen, setIsOpen] = useState(false);
  const [selectedVariant, setSelectedVariant] = useState<any>(null);

  // ✅ FETCH PRODUCT
  useEffect(() => {
    if (!params?.slug) return;

    fetch(`/api/products/${params.slug}`)
      .then((res) => res.json())
      .then((data) => {
        setProduct(data);

        // ✅ AUTO SELECT FIRST VARIANT
        if (data?.variants?.length > 0) {
          setSelectedVariant(data.variants[0]);
        }
      })
      .catch(() => setProduct(null));
  }, [params?.slug]);

  // ✅ KEYBOARD NAV
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

  // ✅ LOADING STATE
  if (!product) return <div className="p-10 text-center">Loading...</div>;

  // ✅ SAFE IMAGES (CRITICAL FIX)
  const images =
    selectedVariant?.images?.length > 0
      ? selectedVariant.images
      : product.images || [];

  const selectedImage = images[currentIndex]?.url;

  // ✅ FIXED NAVIGATION
  const goNext = () => {
    setCurrentIndex((prev) =>
      prev === images.length - 1 ? 0 : prev + 1
    );
  };

  const goPrev = () => {
    setCurrentIndex((prev) =>
      prev === 0 ? images.length - 1 : prev - 1
    );
  };

  const categoryData = categories.find(
    (c: any) => c.slug === product.category?.slug
  );

  const price = selectedVariant?.price || product.price;
  const isOutOfStock = product.stock <= 0;

  return (
    <div className="max-w-6xl mx-auto px-4 py-10 pb-24">

      {/* Breadcrumb */}
      <div className="text-sm text-gray-500 mb-6">
        <Link href="/">Home</Link> |{" "}
        <Link href={`/shop/${product.category?.slug || "all"}`}>
          {categoryData?.name || product.category?.name || "All"}
        </Link>{" "}
        | {product.name}
      </div>

      <div className="grid md:grid-cols-2 gap-12">

        {/* IMAGE SECTION */}
        <div>
          <div
            onClick={() => setIsOpen(true)}
            className="relative w-full h-[400px] border rounded mb-4 overflow-hidden cursor-zoom-in"
          >
            {selectedImage && (
              <Image
                src={selectedImage}
                alt={product.name}
                fill
                className="object-contain p-4"
              />
            )}
          </div>

          {/* THUMBNAILS */}
          <div className="flex gap-3">
            {images.map((img: any, index: number) => (
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
                  src={img.url}
                  alt={product.name}
                  fill
                  className="object-contain p-1"
                />
              </div>
            ))}
          </div>
        </div>

        {/* DETAILS */}
        <div>
          <h1 className="text-3xl font-bold mb-4">{product.name}</h1>

          <p className="text-2xl text-pink-600 font-semibold mb-4">
            ₹{price}
          </p>

          {/* VARIANTS */}
          {product.variants?.length > 0 && (
            <div className="mb-6">
              <h3 className="font-semibold mb-2">Options</h3>

              <div className="flex gap-2 flex-wrap">
                {product.variants.map((v: any) => (
                  <button
                    key={v.id}
                    onClick={() => {
                      setSelectedVariant(v);
                      setCurrentIndex(0); // ✅ IMPORTANT FIX
                    }}
                    className={`px-3 py-1 border rounded ${
                      selectedVariant?.id === v.id
                        ? "border-pink-600 bg-pink-50"
                        : "border-gray-300"
                    }`}
                  >
                    {v.name}
                  </button>
                ))}
              </div>
            </div>
          )}

          <p className="text-gray-600 mb-6">
            {product.description}
          </p>

          {/* ADD TO CART */}
          <button
            onClick={() =>
              addToCart({
                ...product,
                variantId: selectedVariant?.id,
                variantName: selectedVariant?.name,
                price,
              })
            }
            disabled={isOutOfStock}
            className="w-full md:w-auto bg-pink-600 hover:bg-pink-700 disabled:bg-gray-300 text-white px-8 py-3 rounded font-semibold"
          >
            {isOutOfStock ? "Back Soon" : "Add to Cart"}
          </button>
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

          <div className="mt-4 text-sm text-gray-500">
            {product.stock > 0 ? "In Stock" : "Out of Stock"}
          </div>
        </div>
      </div>

      {/* LIGHTBOX */}
      {isOpen && selectedImage && (
        <div
          className="fixed inset-0 bg-black/80 flex items-center justify-center z-50"
          onClick={() => setIsOpen(false)}
        >
          <div
            className="relative w-[90%] md:w-[70%] h-[70%]"
            onClick={(e) => e.stopPropagation()}
          >
            <button
              onClick={() => setIsOpen(false)}
              className="absolute top-4 right-6 text-white text-3xl"
            >
              ✕
            </button>

            <button
              onClick={goPrev}
              className="absolute left-4 text-white text-4xl"
            >
              ‹
            </button>

            <Image
              src={selectedImage}
              alt={product.name}
              fill
              className="object-contain"
            />

            <button
              onClick={goNext}
              className="absolute right-4 text-white text-4xl"
            >
              ›
            </button>
          </div>
        </div>
      )}
    </div>
  );
}