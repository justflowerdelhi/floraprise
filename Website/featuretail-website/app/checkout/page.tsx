"use client";

import { useCart } from "../../src/context/CartContext";
import { useState } from "react";

export default function CheckoutPage() {
  const { cart, subtotal, shipping, discount, total, paymentMethod } = useCart();

  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    email: "",
    address: "",
    city: "",
    state: "",
    pincode: "",
  });

  if (cart.length === 0) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-16 text-center">
        <h1 className="text-2xl font-bold">Your cart is empty</h1>
      </div>
    );
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  const handleSubmit = () => {
    alert("Proceeding to payment (Next step: PayU integration)");
  };

  return (
    <div className="max-w-6xl mx-auto px-4 py-10">
      <h1 className="text-3xl font-bold mb-8">Checkout</h1>

      <div className="grid md:grid-cols-2 gap-10">
        
        {/* Customer Form */}
        <div className="space-y-4">
          <h2 className="text-xl font-semibold mb-4">
            Shipping Details
          </h2>

          <input
            type="text"
            name="name"
            placeholder="Full Name"
            className="w-full border p-3 rounded"
            onChange={handleChange}
          />

          <input
            type="text"
            name="phone"
            placeholder="Mobile Number"
            className="w-full border p-3 rounded"
            onChange={handleChange}
          />

          <input
            type="email"
            name="email"
            placeholder="Email Address"
            className="w-full border p-3 rounded"
            onChange={handleChange}
          />

          <textarea
            name="address"
            placeholder="Full Address"
            className="w-full border p-3 rounded"
            onChange={handleChange}
          />

          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              name="city"
              placeholder="City"
              className="border p-3 rounded"
              onChange={handleChange}
            />
            <input
              type="text"
              name="state"
              placeholder="State"
              className="border p-3 rounded"
              onChange={handleChange}
            />
          </div>

          <input
            type="text"
            name="pincode"
            placeholder="Pincode"
            className="w-full border p-3 rounded"
            onChange={handleChange}
          />
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

            {discount > 0 && (
              <div className="flex justify-between text-green-600">
                <span>Prepaid Discount</span>
                <span>- ₹{discount.toFixed(2)}</span>
              </div>
            )}

            <div className="border-t pt-3 flex justify-between font-bold text-lg">
              <span>Total</span>
              <span>₹{total.toFixed(2)}</span>
            </div>

            <div className="mt-4 text-sm text-gray-600">
              Payment Method:{" "}
              <strong>
                {paymentMethod === "cod" ? "Cash on Delivery" : "Prepaid"}
              </strong>
            </div>
          </div>

          <button
            onClick={handleSubmit}
            className="w-full mt-6 bg-pink-600 hover:bg-pink-700 text-white py-3 rounded font-semibold"
          >
            {paymentMethod === "prepaid"
              ? "Proceed to Pay"
              : "Place Order"}
          </button>
        </div>
      </div>
    </div>
  );
}