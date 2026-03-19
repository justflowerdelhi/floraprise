"use client";

import Link from "next/link";
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

  const GST_RATE = 18;

  const taxableAmount = subtotal - discount - couponDiscount;

  // Extract GST component assuming totals are GST inclusive
  const gstAmount = (taxableAmount * GST_RATE) / (100 + GST_RATE);

  const cgst = gstAmount / 2;
  const sgst = gstAmount / 2;

  const finalTotal = taxableAmount + shipping;

  const applyCoupon = async () => {
    setCouponError("");

    const response = await fetch("/api/coupons", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        code: couponCode,
        subtotal,
      }),
    });

    const result = await response.json();

    if (result.success) {
      setCouponCode(result.code);
      setCouponDiscount(result.discount);
    } else {
      setCouponCode("");
      setCouponDiscount(0);
      setCouponError(result.message);
    }
  };



  if (cart.length === 0) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-4 text-center">
        <h1 className="text-2xl font-bold mb-4">Your Cart is Empty</h1>
        <p className="text-gray-600">Start shopping to add products.</p>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto px-4 py-10">
      <h1 className="text-3xl font-bold mb-8">🛒 Your Cart</h1>

      <div className="grid md:grid-cols-3 gap-8">
        
        {/* Cart Items */}
        <div className="md:col-span-2 space-y-6">
          {cart.map((item) => (
            <div
              key={`${item.id}-${item.variantId || "default"}`}
              className="bg-white rounded-lg shadow-sm border p-4 flex gap-4 items-center"
            >
              <Link href={`/shop/${item.categorySlug}/${item.slug}`}>
                <div className="relative w-24 h-24 border rounded cursor-pointer">
                  {item.image ? (
                    <img
                      src={item.image}
                      alt={item.name}
                      className="w-full h-full object-contain"
                    />
                  ) : null}
                </div>
              </Link>

              <div className="flex-1">
                <h2 className="font-semibold text-base">
                  <Link href={`/shop/${item.categorySlug}/${item.slug}`}>
                    {item.name}
                  </Link>
                </h2>

                <p className="text-sm text-gray-500">
                  ₹{item.price} each
                </p>

                <div className="flex items-center gap-3 mt-3">
                  <button
                    onClick={() => decreaseQty(item.id, item.variantId)}
                    className="w-8 h-8 border rounded flex items-center justify-center"
                  >
                    -
                  </button>

                  <span className="font-semibold">
                    {item.quantity}
                  </span>

                  <button
                    onClick={() => increaseQty(item.id, item.variantId)}
                    className="w-8 h-8 border rounded flex items-center justify-center"
                  >
                    +
                  </button>
                </div>
              </div>

              <div className="text-right">
                <p className="font-bold text-pink-600">
                  ₹{(item.price * item.quantity).toFixed(2)}
                </p>

                <button
                  onClick={() => removeFromCart(item.id)}
                  className="text-red-500 text-sm mt-2"
                >
                  Remove
                </button>
              </div>
            </div>
          ))}
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

            {discount > 0 && (
              <div className="flex justify-between text-green-600">
                <span>Prepaid Discount (5%)</span>
                <span>- ₹{discount.toFixed(2)}</span>
              </div>
            )}

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

          <div className="bg-white border rounded-lg p-4 mt-6">
            <h3 className="font-semibold mb-3">Apply Coupon</h3>

            <div className="flex gap-2">
              <input
                type="text"
                value={couponCode}
                onChange={(e) => setCouponCode(e.target.value)}
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

          {/* Payment Selection */}
          <div className="mt-6">
            <h3 className="font-semibold mb-2">Select Payment Method</h3>

            <div className="space-y-2">
              <label className="flex items-center space-x-2">
                <input
                  type="radio"
                  value="cod"
                  checked={paymentMethod === "cod"}
                  onChange={() => setPaymentMethod("cod")}
                />
                <span>Cash on Delivery</span>
              </label>

              <label className="flex items-center space-x-2">
                <input
                  type="radio"
                  value="prepaid"
                  checked={paymentMethod === "prepaid"}
                  onChange={() => setPaymentMethod("prepaid")}
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
  );
}