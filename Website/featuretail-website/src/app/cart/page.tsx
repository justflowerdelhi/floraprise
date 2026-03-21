"use client";

import Link from "next/link";
import Footer from "@/components/Footer";
import Image from "next/image";
import { useCart } from "@/context/CartContext";
import { useState } from "react";

export default function CartPage() {
  const {
    cart,
    removeFromCart,
    increaseQty,
    decreaseQty,
    subtotal,
    shipping,
    discount,
    total,
    paymentMethod,
    setPaymentMethod,
    couponCode,
    setCouponCode,
    couponDiscount,
    setCouponDiscount,
  } = useCart();

  const [couponError, setCouponError] = useState("");

  /* ---------------- GST CALCULATION ---------------- */
  const gstRate = 0.18;
  const gstAmount = subtotal * gstRate;
  const cgst = gstAmount / 2;
  const sgst = gstAmount / 2;

  /* ---------------- FINAL TOTAL ---------------- */
  const finalTotal = total - couponDiscount;

  /* ---------------- APPLY COUPON ---------------- */
  const applyCoupon = () => {
    if (!couponCode) {
      setCouponError("Please enter a coupon code");
      return;
    }

    // Example logic (you can connect API later)
    if (couponCode === "SAVE10") {
      const discountAmount = subtotal * 0.1;
      setCouponDiscount(discountAmount);
      setCouponError("");
    } else {
      setCouponDiscount(0);
      setCouponError("Invalid coupon code");
    }
  };

  return (
    <>
      <div className="max-w-6xl mx-auto px-4 py-10">
        <h1 className="text-3xl font-bold mb-8">Shopping Cart</h1>

        <div className="grid md:grid-cols-2 gap-10">
          {/* Cart Items */}
          <div className="space-y-4">
            {cart.length === 0 ? (
              <p>Your cart is empty.</p>
            ) : (
              cart.map((item) => (
                <div
                  key={item.id + item.variantId}
                  className="flex items-center gap-4 border-b pb-4"
                >
                  {(() => {
                    const firstImage = item.images?.[0];
                    let imageUrl = "/placeholder.png";
                    if (firstImage) {
                      if (typeof firstImage === "string") {
                        imageUrl = firstImage;
                      } else if (typeof firstImage === "object" && "url" in firstImage) {
                        imageUrl = (firstImage as any).url;
                      }
                    }
                    return (
                      <Image
                        src={imageUrl}
                        alt={item.name}
                        width={80}
                        height={80}
                        className="rounded object-cover"
                      />
                    );
                  })()}

                  <div className="flex-1">
                    <h2 className="font-semibold">{item.name}</h2>

                    {item.variantName && (
                      <p className="text-sm text-gray-500">
                        {item.variantName}
                      </p>
                    )}

                    <div className="flex items-center gap-2 mt-2">
                      <button
                        onClick={() =>
                          decreaseQty(item.id, item.variantId)
                        }
                        className="border px-2 rounded"
                      >
                        -
                      </button>

                      <span>{item.quantity}</span>

                      <button
                        onClick={() =>
                          increaseQty(item.id, item.variantId)
                        }
                        className="border px-2 rounded"
                      >
                        +
                      </button>
                    </div>

                    <button
                      onClick={() =>
                        removeFromCart(item.id, item.variantId)
                      }
                      className="text-red-500 text-sm mt-2"
                    >
                      Remove
                    </button>
                  </div>

                  <div className="font-semibold">
                    ₹{item.price.toFixed(2)}
                  </div>
                </div>
              ))
            )}
          </div>

          {/* Order Summary */}
          <div className="border p-6 rounded-lg h-fit">
            <h2 className="text-xl font-semibold mb-4">
              Order Summary
            </h2>

            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Subtotal</span>
                <span>₹{subtotal.toFixed(2)}</span>
              </div>

              <div className="flex justify-between">
                <span>Shipping</span>
                <span>
                  {shipping === 0 ? "Free" : `₹${shipping}`}
                </span>
              </div>

              {/* GST */}
              {gstAmount > 0 && (
                <>
                  <div className="flex justify-between">
                    <span>Included CGST (9%)</span>
                    <span>₹{cgst.toFixed(2)}</span>
                  </div>

                  <div className="flex justify-between">
                    <span>Included SGST (9%)</span>
                    <span>₹{sgst.toFixed(2)}</span>
                  </div>
                </>
              )}

              {/* Prepaid Discount */}
              {discount > 0 && (
                <div className="flex justify-between text-green-600">
                  <span>Prepaid Discount (5%)</span>
                  <span>- ₹{discount.toFixed(2)}</span>
                </div>
              )}

              {/* Coupon Discount */}
              {couponDiscount > 0 && (
                <div className="flex justify-between text-green-600">
                  <span>Coupon Discount</span>
                  <span>- ₹{couponDiscount.toFixed(2)}</span>
                </div>
              )}

              <div className="flex justify-between font-bold text-lg border-t pt-3">
                <span>Total</span>
                <span>₹{finalTotal.toFixed(2)}</span>
              </div>
            </div>

            {/* Coupon */}
            <div className="bg-white border rounded-lg p-4 mt-6">
              <h3 className="font-semibold mb-3">Apply Coupon</h3>

              <div className="flex gap-2">
                <input
                  type="text"
                  value={couponCode}
                  onChange={(e) =>
                    setCouponCode(e.target.value)
                  }
                  placeholder="Enter coupon code"
                  className="flex-1 border p-2 rounded"
                />

                <button
                  onClick={applyCoupon}
                  className="bg-pink-600 text-white px-4 rounded"
                >
                  Apply
                </button>
              </div>

              {couponError && (
                <p className="text-red-500 text-sm mt-2">
                  {couponError}
                </p>
              )}
            </div>

            {/* Payment */}
            <div className="mt-6">
              <h3 className="font-semibold mb-2">
                Select Payment Method
              </h3>

              <div className="space-y-2">
                <label className="flex items-center space-x-2">
                  <input
                    type="radio"
                    value="cod"
                    checked={paymentMethod === "cod"}
                    onChange={() =>
                      setPaymentMethod("cod")
                    }
                  />
                  <span>Cash on Delivery</span>
                </label>

                <label className="flex items-center space-x-2">
                  <input
                    type="radio"
                    value="prepaid"
                    checked={paymentMethod === "prepaid"}
                    onChange={() =>
                      setPaymentMethod("prepaid")
                    }
                  />
                  <span>
                    Prepaid (Get 5% Discount)
                  </span>
                </label>
              </div>
            </div>

            <Link
              href="/checkout"
              className="inline-block w-full mt-6 bg-pink-600 hover:bg-pink-700 text-white text-center py-3 rounded font-semibold"
            >
              Proceed to Checkout
            </Link>
          </div>
        </div>
      </div>

      <Footer />
    </>
  );
}