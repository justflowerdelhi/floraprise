"use client";

import Footer from "@/components/Footer";
import toast from "react-hot-toast";
import Image from "next/image";
import { useParams } from "next/navigation";
import { useState, useEffect } from "react";
import { useCart } from "@/context/CartContext";

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
        if (data?.variants?.length > 0) {
          setSelectedVariant(data.variants[0]);
        }
      })
      .catch(() => setProduct(null));
  }, [params?.slug]);

  if (!product) {
    return <div className="p-8 text-center">Loading...</div>;
  }

  const images =
    selectedVariant?.images?.length > 0
      ? selectedVariant.images
      : product.images || [];

  const selectedImage = images?.[currentIndex]?.url || "";

  const price = selectedVariant?.price ?? product.price ?? 0;

  const isOutOfStock =
    (selectedVariant?.stock ?? product.stock ?? 0) <= 0;

  const goNext = () => {
    if (!images.length) return;
    setCurrentIndex((prev) => (prev + 1) % images.length);
  };

  const goPrev = () => {
    if (!images.length) return;
    setCurrentIndex((prev) => (prev - 1 + images.length) % images.length);
  };

  return (
    <div className="max-w-7xl mx-auto px-4 py-6 pb-24">

      <div className="grid md:grid-cols-5 gap-8">

        {/* LEFT - IMAGES */}
        <div className="md:col-span-2">
          <div
            onClick={() => setIsOpen(true)}
            className="relative w-full h-[320px] border rounded mb-4 overflow-hidden cursor-zoom-in"
          >
            {selectedImage ? (
              <div className="relative w-full h-64">
                <Image
                  src={selectedImage}
                  alt={product.name}
                  fill
                  className="object-contain p-4"
                />
              </div>
            ) : (
              <div className="flex items-center justify-center h-full text-gray-400">
                No Image
              </div>
            )}
          </div>

          {/* THUMBNAILS */}
          <div className="flex gap-3">
            {images.map((img: any, index: number) => (
              <div
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`relative w-20 h-20 border rounded cursor-pointer transition ${
                  currentIndex === index
                    ? "border-pink-600"
                    : "border-gray-300 hover:border-gray-500"
                }`}
              >
                {img?.url && (
                  <div className="relative w-full h-64">
                    <Image
                      src={img.url}
                      alt={product.name}
                      fill
                      className="object-contain p-1"
                    />
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>

        {/* CENTER - INFO */}
        <div className="md:col-span-2">
          <h1 className="text-2xl font-semibold mb-2 leading-snug">
            {product.name}
          </h1>

          <hr className="my-4" />

          

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
                      setCurrentIndex(0);
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

          {/* BULLET POINTS */}
          {product.bulletPoints && (
            <ul className="list-disc pl-5 mt-4 space-y-2 text-gray-700">
              {product.bulletPoints
                .split("\n")
                .map((point: string, i: number) => (
                  <li key={i}>{point}</li>
                ))}
            </ul>
          )}

          {/* TRUST */}
          <div className="mt-4 text-sm text-gray-700 space-y-2">
            <p>🚚 Fast Shipping Across India</p>
            <p>💳 Secure Payments via PayU</p>
            <p>🔄 Easy Return Support</p>
            <p>🏆 Trusted Brand Since 2016</p>
          </div>
        </div>

        {/* RIGHT - BUY BOX */}
        <div className="md:col-span-1">
          <div className="border rounded-lg p-4 shadow-sm sticky top-20 bg-white">

            <p className="text-2xl font-bold text-pink-600">
              ₹{price}
            </p>

            <p className="text-green-600 text-sm mt-1">
              {isOutOfStock ? "Out of Stock" : "In Stock"}
            </p>

            <button className="w-full mt-4 bg-yellow-400 hover:bg-yellow-500 text-black py-2 rounded font-medium">
              Buy Now
            </button>

            <button
              onClick={() => {
                addToCart({
                  id: product.id,
                  name: product.name,
                  slug: product.slug,
                  price,
                  images: product.images,
                  category: product.category,
                  stock: selectedVariant?.stock ?? product.stock ?? 0,
                  createdAt: product.createdAt,
                  description: product.description,
                  features: product.features,
                  variantId: selectedVariant?.id,
                  variantName: selectedVariant?.name,
                  quantity: 1,
                });

                toast.success(
                  `${product.name} (${selectedVariant?.name || "Default"}) added 🛒`
                );
              }}
              disabled={isOutOfStock}
              className="w-full mt-2 bg-pink-600 hover:bg-pink-700 text-white py-2 rounded font-medium transition"
            >
              Add to Cart
            </button>

            <div className="mt-4 text-xs text-gray-600 space-y-1">
              <p>🚚 Free Delivery</p>
              <p>🔁 7 Days Return</p>
              <p>💳 COD Available</p>
            </div>
          </div>
        </div>

      </div>

      {/* DESCRIPTION */}
      <div className="mt-10 border-t pt-6">
        <h2 className="text-xl font-semibold mb-4">
          Product Description
        </h2>
        <p className="text-gray-700">{product.description}</p>
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

            <div className="relative w-full h-64">
              <Image
                src={selectedImage}
                alt={product.name}
                fill
                className="object-contain"
              />
            </div>

            <button
              onClick={goNext}
              className="absolute right-4 text-white text-4xl"
            >
              ›
            </button>
          </div>
        </div>
      )}

      <Footer />
    </div>
  );
}