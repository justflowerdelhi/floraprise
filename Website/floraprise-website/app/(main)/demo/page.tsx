"use client";

import { useState } from "react";

export function isValidIndianPhone(phone: string): boolean {
  if (!phone || typeof phone !== "string") return false;
  const trimmed = phone.trim();
  if (!trimmed) return false;

  // Strip spaces, hyphens, dots, parentheses, and plus sign
  const cleaned = trimmed.replace(/[\s\-\.\(\)\+]/g, "");

  // +91 or 91 country code followed by 10 digits
  if (cleaned.length === 12 && cleaned.startsWith("91")) {
    return /^[6-9]\d{9}$/.test(cleaned.slice(2));
  }

  // Leading 0 (trunk code) followed by 10 digits
  if (cleaned.length === 11 && cleaned.startsWith("0")) {
    return /^[6-9]\d{9}$/.test(cleaned.slice(1));
  }

  // Standard 10-digit mobile number
  if (cleaned.length === 10) {
    return /^[6-9]\d{9}$/.test(cleaned);
  }

  return false;
}

export default function DemoPage() {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [phone, setPhone] = useState("");
  const [phoneError, setPhoneError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (isSubmitting) return;

    setErrorMessage(null);
    setPhoneError(null);
    setIsSubmitting(true);

    const formData = new FormData(e.currentTarget);
    const fullName = formData.get("name")?.toString().trim();
    const businessEmail = formData.get("email")?.toString().trim();
    const phoneInput = (formData.get("phone")?.toString() || phone).trim();
    const businessType = formData.get("businessType")?.toString().trim();
    const currentSoftware = formData.get("currentSoftware")?.toString().trim();
    const notes = formData.get("notes")?.toString().trim();

    if (!fullName || !businessEmail) {
      setErrorMessage("Please enter both your full name and business email.");
      setIsSubmitting(false);
      return;
    }

    if (!phoneInput || !isValidIndianPhone(phoneInput)) {
      setPhoneError("Please enter a valid WhatsApp/phone number.");
      setErrorMessage("Please enter a valid WhatsApp/phone number.");
      setIsSubmitting(false);
      return;
    }

    try {
      const res = await fetch("/api/marketing/demo-request", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          fullName,
          businessEmail,
          phone: phoneInput,
          phoneNumber: phoneInput,
          businessType,
          currentSoftware,
          notes,
          submittedAt: new Date().toISOString(),
        }),
      });

      if (res.ok) {
        window.location.href = "/thankyou";
      } else {
        const errorData = await res.json().catch(() => null);
        setErrorMessage(
          errorData?.message || "Something went wrong. Please try again."
        );
        setIsSubmitting(false);
      }
    } catch {
      setErrorMessage(
        "Unable to connect. Please check your connection and try again."
      );
      setIsSubmitting(false);
    }
  };

  return (
    <section className="py-28 bg-[#f8f8f6]">
      <div className="max-w-4xl mx-auto px-6">
        <h1 className="text-4xl font-semibold text-center mb-6">
          Book a Live Demo
        </h1>

        <p className="text-center text-gray-600 mb-12">
          See how Floraprise streamlines inventory, production,
          delivery, and multi-location management in one platform.
        </p>

        <form
          className="space-y-6 bg-white p-10 rounded-2xl shadow-sm"
          onSubmit={handleSubmit}
        >
          {errorMessage && (
            <div className="p-4 rounded-lg bg-red-50 border border-red-200 text-red-700 text-sm">
              {errorMessage}
            </div>
          )}

          <div className="grid md:grid-cols-2 gap-6">
            <div>
              <label htmlFor="name" className="block text-sm font-medium mb-2">
                Full Name
              </label>
              <input
                id="name"
                type="text"
                name="name"
                required
                disabled={isSubmitting}
                className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#124e2c] disabled:bg-gray-100"
                placeholder="Your full name"
              />
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium mb-2">
                Business Email
              </label>
              <input
                id="email"
                type="email"
                name="email"
                required
                disabled={isSubmitting}
                className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#124e2c] disabled:bg-gray-100"
                placeholder="you@flowerbusiness.com"
              />
            </div>
          </div>

          <div>
            <label htmlFor="phone" className="block text-sm font-medium mb-2">
              Phone / WhatsApp Number <span className="text-red-500">*</span>
            </label>
            <input
              id="phone"
              type="tel"
              name="phone"
              required
              disabled={isSubmitting}
              value={phone}
              onChange={(e) => {
                setPhone(e.target.value);
                if (phoneError) setPhoneError(null);
              }}
              className={`w-full border rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#124e2c] disabled:bg-gray-100 ${
                phoneError ? "border-red-500" : "border-gray-300"
              }`}
              placeholder="+91 99900 44406"
            />
            {phoneError && (
              <p className="mt-1 text-sm text-red-600">
                {phoneError}
              </p>
            )}
          </div>

          <div>
            <label htmlFor="businessType" className="block text-sm font-medium mb-2">
              Business Type
            </label>
            <select
              id="businessType"
              name="businessType"
              disabled={isSubmitting}
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#124e2c] disabled:bg-gray-100"
            >
              <option>Retail Flower Shop</option>
              <option>Wedding & Events Florist</option>
              <option>Multi-Location Chain</option>
              <option>Online + In-Store Hybrid</option>
            </select>
          </div>

          <div>
            <label htmlFor="currentSoftware" className="block text-sm font-medium mb-2">
              Current Software (if any)
            </label>
            <input
              id="currentSoftware"
              type="text"
              name="currentSoftware"
              disabled={isSubmitting}
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#124e2c] disabled:bg-gray-100"
              placeholder="QuickFlora, Floranext, Excel, etc."
            />
          </div>

          <div>
            <label htmlFor="notes" className="block text-sm font-medium mb-2">
              Additional Notes
            </label>
            <textarea
              id="notes"
              rows={4}
              name="notes"
              disabled={isSubmitting}
              className="w-full border border-gray-300 rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-[#124e2c] disabled:bg-gray-100"
              placeholder="Tell us about your requirements or any specific questions..."
            />
          </div>

          <button
            type="submit"
            disabled={isSubmitting}
            className="w-full !bg-[#124e2c] hover:!bg-[#0b3c20] !text-white py-4 px-6 rounded-lg font-semibold transition shadow-sm disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2 text-base cursor-pointer"
          >
            {isSubmitting ? (
              <>
                <svg
                  className="animate-spin h-5 w-5 text-white"
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                >
                  <circle
                    className="opacity-25"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    strokeWidth="4"
                  />
                  <path
                    className="opacity-75"
                    fill="currentColor"
                    d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                  />
                </svg>
                <span>Submitting...</span>
              </>
            ) : (
              "Request a Demo"
            )}
          </button>
        </form>
      </div>
    </section>
  );
}