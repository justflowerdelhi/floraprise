"use client";

import { useCart } from "@/context/CartContext";
import { useState } from "react";
import Footer from "@/components/Footer";

export default function CheckoutPage() {
  const {
    cart,
    subtotal,
    shipping,
    discount,
    couponDiscount,
    total,
    paymentMethod,
    clearCart,
  } = useCart();

  const isValidGST = (gst: string) => {
    const gstRegex =
      /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/;
    return gst === "" || gstRegex.test(gst);
  };

  const [formData, setFormData] = useState({
    shipping: {
      name: "",
      phone: "",
      email: "",
      address: "",
      city: "",
      state: "",
      pincode: "",
    },
    billing: {
      name: "",
      phone: "",
      email: "",
      address: "",
      city: "",
      state: "",
      pincode: "",
      companyName: "",
      gstNumber: "",
    },
  });

  const [sameAsShipping, setSameAsShipping] = useState(true);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);

  /* ---------------- GST ---------------- */
  const GST_RATE = 18;
  const taxableAmount = subtotal - discount - couponDiscount;
  const gstAmount = (taxableAmount * GST_RATE) / (100 + GST_RATE);
  const cgst = gstAmount / 2;
  const sgst = gstAmount / 2;

  /* ---------------- FINAL TOTAL ---------------- */
  const finalTotal =
    subtotal + shipping - discount - couponDiscount;

  if (cart.length === 0) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-4 text-center">
        <h1 className="text-2xl font-bold">
          Your cart is empty
        </h1>
      </div>
    );
  }

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>,
    type: "shipping" | "billing"
  ) => {
    setFormData((prev) => ({
      ...prev,
      [type]: {
        ...prev[type],
        [e.target.name]: e.target.value,
      },
    }));
  };

  const validateForm = () => {
    const newErrors: Record<string, string> = {};
    const s = formData.shipping;

    if (!s.name.trim()) newErrors.name = "Full Name is required";
    if (!s.address.trim()) newErrors.address = "Address is required";
    if (!s.city.trim()) newErrors.city = "City is required";
    if (!s.state.trim()) newErrors.state = "State is required";
    if (!s.pincode.trim()) newErrors.pincode = "Pincode is required";
    if (!s.phone.trim()) newErrors.phone = "Phone is required";
    if (!s.email.trim()) newErrors.email = "Email is required";

    if (s.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.email)) {
      newErrors.email = "Invalid email";
    }

    if (s.phone && !/^[6-9]\d{9}$/.test(s.phone)) {
      newErrors.phone = "Invalid mobile";
    }

    if (s.pincode && !/^\d{6}$/.test(s.pincode)) {
      newErrors.pincode = "Invalid pincode";
    }

    if (!sameAsShipping) {
      const b = formData.billing;
      if (b.gstNumber && !isValidGST(b.gstNumber)) {
        newErrors.billingGstNumber = "Invalid GST";
      }
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleCheckout = async () => {
    if (!validateForm()) return;

    setLoading(true);

    try {
      const payload = {
        paymentMethod,
        subtotal,
        shippingAmount: shipping,
        discount,
        couponDiscount,
        total: finalTotal,
        gstAmount,
        shipping: formData.shipping,
        billing: sameAsShipping
          ? {
              ...formData.shipping,
              companyName: "",
              gstNumber: "",
            }
          : formData.billing,
        items: cart.map((item) => ({
          productId: item.id,
          variantId: item.variantId,
          name: item.name,
          variantName: item.variantName,
          price: item.price,
          qty: item.quantity,
        })),
      };

      const res = await fetch("/api/orders", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(payload),
      });

      const data = await res.json();

      if (res.ok) {
        alert("Order placed: " + data.orderNumber);
        clearCart();
      } else {
        alert(data.error || "Something went wrong");
      }
    } catch {
      alert("Checkout failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="max-w-6xl mx-auto px-4 py-10">
        <h1 className="text-3xl font-bold mb-8">Checkout</h1>

        <div className="grid md:grid-cols-2 gap-10">
          
          {/* ✅ SHIPPING FORM */}
          <div className="space-y-4">
            <h2 className="text-xl font-semibold mb-4">
              Shipping Details
            </h2>

            <input name="name" placeholder="Full Name"
              className="w-full border p-3 rounded"
              onChange={(e) => handleChange(e, "shipping")} />

            <input name="phone" placeholder="Mobile Number"
              className="w-full border p-3 rounded"
              onChange={(e) => handleChange(e, "shipping")} />

            <input name="email" placeholder="Email"
              className="w-full border p-3 rounded"
              onChange={(e) => handleChange(e, "shipping")} />

            <textarea name="address" placeholder="Address"
              className="w-full border p-3 rounded"
              onChange={(e) => handleChange(e, "shipping")} />

            <input name="city" placeholder="City"
              className="w-full border p-3 rounded"
              onChange={(e) => handleChange(e, "shipping")} />

            <input name="state" placeholder="State"
              className="w-full border p-3 rounded"
              onChange={(e) => handleChange(e, "shipping")} />

            <input name="pincode" placeholder="Pincode"
              className="w-full border p-3 rounded"
              onChange={(e) => handleChange(e, "shipping")} />

            {/* Billing Toggle */}
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={sameAsShipping}
                onChange={() => setSameAsShipping(!sameAsShipping)}
              />
              <span>Billing same as shipping</span>
            </div>
          </div>

          {/* ORDER SUMMARY */}
          <div className="border p-6 rounded-lg h-fit">
            <h2 className="text-xl font-semibold mb-4">
              Order Summary
            </h2>

            <div className="flex justify-between">
              <span>Subtotal</span>
              <span>₹{subtotal.toFixed(2)}</span>
            </div>

            <div className="flex justify-between">
              <span>Shipping</span>
              <span>{shipping === 0 ? "Free" : `₹${shipping}`}</span>
            </div>

            <div className="flex justify-between">
              <span>CGST</span>
              <span>₹{cgst.toFixed(2)}</span>
            </div>

            <div className="flex justify-between">
              <span>SGST</span>
              <span>₹{sgst.toFixed(2)}</span>
            </div>

            <div className="border-t pt-3 flex justify-between font-bold">
              <span>Total</span>
              <span>₹{finalTotal.toFixed(2)}</span>
            </div>

            <button
              onClick={handleCheckout}
              className="w-full mt-6 bg-pink-600 text-white py-3 rounded"
            >
              Place Order
            </button>
          </div>

        </div>
      </div>

      <Footer />
    </>
  );
}