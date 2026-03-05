"use client";

import { useCart } from "@/context/CartContext";
import { useState } from "react";

export default function CheckoutPage() {
  const {
    cart,
    subtotal,
    shipping,
    discount,
    couponCode,
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
  const [errors, setErrors] = useState<any>({});

  const GST_RATE = 18;

  const taxableAmount = subtotal - discount;

  const gstAmount = (taxableAmount * GST_RATE) / (100 + GST_RATE);

  const cgst = gstAmount / 2;
  const sgst = gstAmount / 2;

  const finalTotal = subtotal + shipping - discount;

  if (cart.length === 0) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-16 text-center">
        <h1 className="text-2xl font-bold">Your cart is empty</h1>
      </div>
    );
  }

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>,
    type: "shipping" | "billing"
  ) => {
    setFormData({
      ...formData,
      [type]: {
        ...formData[type],
        [e.target.name]: e.target.value,
      },
    });
  };

  const validateForm = () => {
    const newErrors: any = {};

    const shipping = formData.shipping;

    // Required Fields
    if (!shipping.name.trim()) newErrors.name = "Full Name is required";
    if (!shipping.address.trim()) newErrors.address = "Address is required";
    if (!shipping.city.trim()) newErrors.city = "City is required";
    if (!shipping.state.trim()) newErrors.state = "State is required";
    if (!shipping.pincode.trim()) newErrors.pincode = "Pincode is required";
    if (!shipping.phone.trim()) newErrors.phone = "Phone number is required";
    if (!shipping.email.trim()) newErrors.email = "Email is required";

    // Email format
    if (
      shipping.email &&
      !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(shipping.email)
    ) {
      newErrors.email = "Invalid email format";
    }

    // Indian Phone validation (10 digits)
    if (
      shipping.phone &&
      !/^[6-9]\d{9}$/.test(shipping.phone)
    ) {
      newErrors.phone = "Invalid 10-digit mobile number";
    }

    // Indian Pincode validation (6 digits)
    if (
      shipping.pincode &&
      !/^\d{6}$/.test(shipping.pincode)
    ) {
      newErrors.pincode = "Invalid 6-digit pincode";
    }

    // Billing validation when not same as shipping
    if (!sameAsShipping) {
      const billing = formData.billing;

      if (!billing.name.trim()) newErrors.billingName = "Full Name is required";
      if (!billing.address.trim()) newErrors.billingAddress = "Address is required";
      if (!billing.city.trim()) newErrors.billingCity = "City is required";
      if (!billing.state.trim()) newErrors.billingState = "State is required";
      if (!billing.pincode.trim()) newErrors.billingPincode = "Pincode is required";
      if (!billing.phone.trim()) newErrors.billingPhone = "Phone number is required";
      if (!billing.email.trim()) newErrors.billingEmail = "Email is required";

      if (
        billing.email &&
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(billing.email)
      ) {
        newErrors.billingEmail = "Invalid email format";
      }

      if (
        billing.phone &&
        !/^[6-9]\d{9}$/.test(billing.phone)
      ) {
        newErrors.billingPhone = "Invalid 10-digit mobile number";
      }

      if (
        billing.pincode &&
        !/^\d{6}$/.test(billing.pincode)
      ) {
        newErrors.billingPincode = "Invalid 6-digit pincode";
      }

      if (billing.gstNumber && !isValidGST(billing.gstNumber)) {
        newErrors.billingGstNumber = "Invalid GST Number format";
      }
    }

    setErrors(newErrors);

    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async () => {
    if (!validateForm()) {
      window.scrollTo({ top: 0, behavior: "smooth" });
      return;
    }

    const billingData = sameAsShipping
      ? formData.shipping
      : formData.billing;

    const totalDiscount = discount + couponDiscount;

    const response = await fetch("/api/orders", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        paymentMethod,
        subtotal,
        shippingAmount: shipping,
        discount: totalDiscount,
        gstAmount,
        total: finalTotal,
        couponCode: couponCode ? couponCode.toUpperCase() : undefined,
        shipping: formData.shipping,
        billing: billingData,
        items: cart,
      }),
    });

    const result = await response.json();
    const orderNumber = result.orderNumber || result.order?.orderNumber;

    if (result.success && orderNumber) {
      clearCart();
      window.location.href = `/thank-you?order=${orderNumber}`;
    } else {
      alert("Something went wrong.");
    }
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
            className={`w-full border p-3 rounded ${
              errors.name ? "border-red-500" : ""
            }`}
            onChange={(e) => handleChange(e, "shipping")}
          />
          {errors.name && (
            <p className="text-red-500 text-sm mt-1">
              {errors.name}
            </p>
          )}

          <input
            type="text"
            name="phone"
            placeholder="Mobile Number"
            className={`w-full border p-3 rounded ${
              errors.phone ? "border-red-500" : ""
            }`}
            onChange={(e) => handleChange(e, "shipping")}
          />
          {errors.phone && (
            <p className="text-red-500 text-sm mt-1">{errors.phone}</p>
          )}

          <input
            type="email"
            name="email"
            placeholder="Email Address"
            className={`w-full border p-3 rounded ${
              errors.email ? "border-red-500" : ""
            }`}
            onChange={(e) => handleChange(e, "shipping")}
          />
          {errors.email && (
            <p className="text-red-500 text-sm mt-1">{errors.email}</p>
          )}

          <textarea
            name="address"
            placeholder="Full Address"
            className={`w-full border p-3 rounded ${
              errors.address ? "border-red-500" : ""
            }`}
            onChange={(e) => handleChange(e, "shipping")}
          />
          {errors.address && (
            <p className="text-red-500 text-sm mt-1">{errors.address}</p>
          )}

          <div className="grid grid-cols-2 gap-4">
            <input
              type="text"
              name="city"
              placeholder="City"
              className={`border p-3 rounded ${
                errors.city ? "border-red-500" : ""
              }`}
              onChange={(e) => handleChange(e, "shipping")}
            />
            {errors.city && (
              <p className="text-red-500 text-sm mt-1 col-span-2">
                {errors.city}
              </p>
            )}
            <input
              type="text"
              name="state"
              placeholder="State"
              className={`border p-3 rounded ${
                errors.state ? "border-red-500" : ""
              }`}
              onChange={(e) => handleChange(e, "shipping")}
            />
            {errors.state && (
              <p className="text-red-500 text-sm mt-1 col-span-2">
                {errors.state}
              </p>
            )}
          </div>

          <input
            type="text"
            name="pincode"
            placeholder="Pincode"
            className={`w-full border p-3 rounded ${
              errors.pincode ? "border-red-500" : ""
            }`}
            onChange={(e) => handleChange(e, "shipping")}
          />
          {errors.pincode && (
            <p className="text-red-500 text-sm mt-1">{errors.pincode}</p>
          )}

          <div className="mt-6 flex items-center space-x-2">
            <input
              type="checkbox"
              checked={sameAsShipping}
              onChange={() => setSameAsShipping(!sameAsShipping)}
            />
            <label className="text-sm font-medium">
              Billing address same as Shipping
            </label>
          </div>

          {!sameAsShipping && (
            <div className="mt-8 space-y-4">
              <h2 className="text-xl font-semibold mb-4">
                Billing Details
              </h2>

              <input
                type="text"
                name="companyName"
                placeholder="Company Name (Optional)"
                className="w-full border p-3 rounded"
                onChange={(e) => handleChange(e, "billing")}
              />

              <input
                type="text"
                name="gstNumber"
                placeholder="GST Number (Optional)"
                className={`w-full border p-3 rounded ${
                  errors.billingGstNumber ? "border-red-500" : ""
                }`}
                onChange={(e) => handleChange(e, "billing")}
              />
              {errors.billingGstNumber && (
                <p className="text-red-500 text-sm mt-1">
                  {errors.billingGstNumber}
                </p>
              )}

              <input
                type="text"
                name="name"
                placeholder="Full Name"
                className={`w-full border p-3 rounded ${
                  errors.billingName ? "border-red-500" : ""
                }`}
                onChange={(e) => handleChange(e, "billing")}
              />
              {errors.billingName && (
                <p className="text-red-500 text-sm mt-1">{errors.billingName}</p>
              )}

              <input
                type="text"
                name="phone"
                placeholder="Mobile Number"
                className={`w-full border p-3 rounded ${
                  errors.billingPhone ? "border-red-500" : ""
                }`}
                onChange={(e) => handleChange(e, "billing")}
              />
              {errors.billingPhone && (
                <p className="text-red-500 text-sm mt-1">{errors.billingPhone}</p>
              )}

              <input
                type="email"
                name="email"
                placeholder="Email Address"
                className={`w-full border p-3 rounded ${
                  errors.billingEmail ? "border-red-500" : ""
                }`}
                onChange={(e) => handleChange(e, "billing")}
              />
              {errors.billingEmail && (
                <p className="text-red-500 text-sm mt-1">{errors.billingEmail}</p>
              )}

              <textarea
                name="address"
                placeholder="Full Address"
                className={`w-full border p-3 rounded ${
                  errors.billingAddress ? "border-red-500" : ""
                }`}
                onChange={(e) => handleChange(e, "billing")}
              />
              {errors.billingAddress && (
                <p className="text-red-500 text-sm mt-1">{errors.billingAddress}</p>
              )}

              <div className="grid grid-cols-2 gap-4">
                <input
                  type="text"
                  name="city"
                  placeholder="City"
                  className={`border p-3 rounded ${
                    errors.billingCity ? "border-red-500" : ""
                  }`}
                  onChange={(e) => handleChange(e, "billing")}
                />
                {errors.billingCity && (
                  <p className="text-red-500 text-sm mt-1 col-span-2">
                    {errors.billingCity}
                  </p>
                )}
                <input
                  type="text"
                  name="state"
                  placeholder="State"
                  className={`border p-3 rounded ${
                    errors.billingState ? "border-red-500" : ""
                  }`}
                  onChange={(e) => handleChange(e, "billing")}
                />
                {errors.billingState && (
                  <p className="text-red-500 text-sm mt-1 col-span-2">
                    {errors.billingState}
                  </p>
                )}
              </div>

              <input
                type="text"
                name="pincode"
                placeholder="Pincode"
                className={`w-full border p-3 rounded ${
                  errors.billingPincode ? "border-red-500" : ""
                }`}
                onChange={(e) => handleChange(e, "billing")}
              />
              {errors.billingPincode && (
                <p className="text-red-500 text-sm mt-1">{errors.billingPincode}</p>
              )}
            </div>
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

            {discount > 0 && (
              <div className="flex justify-between text-green-600">
                <span>Prepaid Discount</span>
                <span>- ₹{discount.toFixed(2)}</span>
              </div>
            )}

            {gstAmount > 0 && (
              <>
                <div className="flex justify-between">
                  <span>CGST (9%)</span>
                  <span>₹{cgst.toFixed(2)}</span>
                </div>

                <div className="flex justify-between">
                  <span>SGST (9%)</span>
                  <span>₹{sgst.toFixed(2)}</span>
                </div>
              </>
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