"use client";

import { Suspense } from "react";
import { useSearchParams } from "next/navigation";
import Link from "next/link";

function ThankYouContent() {
  const searchParams = useSearchParams();
  const orderNumber = searchParams.get("order");

  return (
    <div className="max-w-4xl mx-auto px-4 py-4 text-center">
      <h1 className="text-3xl font-bold mb-4">
        🎉 Order Placed Successfully!
      </h1>

      {orderNumber && (
        <p className="text-lg mb-6">
          Your Order Number:{" "}
          <span className="font-semibold text-pink-600">
            {orderNumber}
          </span>
        </p>
      )}

      <p className="text-gray-600 mb-8">
        Thank you for shopping with 3A Featuretail.
        We will notify you once your order is shipped.
      </p>

      <Link
        href="/"
        className="bg-pink-600 hover:bg-pink-700 text-white px-6 py-3 rounded font-semibold"
      >
        Continue Shopping
      </Link>
    </div>
  );
}

export default function ThankYouPage() {
  return (
    <Suspense fallback={<div className="max-w-4xl mx-auto px-4 py-4 text-center">Loading...</div>}>
      <ThankYouContent />
    </Suspense>
  );
}
