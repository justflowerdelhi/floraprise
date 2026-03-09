"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

export default function HeroPremium() {
  const [isIndia, setIsIndia] = useState(false);

  useEffect(() => {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  if (timezone && timezone.includes("Asia")) {
    setIsIndia(true);
  }
}, []);

  return (
    <section className="bg-white pt-20 pb-24">

      <div className="max-w-6xl mx-auto px-6 text-center">

        {/* Hero Image (Foreground) */}
        <div className="relative flex justify-center items-center">
  {/* Green Glow */}
  <div className="absolute w-[60%] h-[60%] bg-green-200 blur-[120px] rounded-full opacity-40"></div>

  {/* Orange Glow */}
  <div className="absolute w-[40%] h-[40%] bg-orange-200 blur-[120px] rounded-full opacity-30"></div>

  <Image
    src="/floraprise-real.png"
    alt="Floraprise POS used in real flower shop"
    width={1000}
    height={650}
    priority
    className="relative rounded-2xl shadow-[0_40px_90px_-20px_rgba(0,0,0,0.25)]"
  />
</div>

        {/* Text Below Image */}
        <div className="mt-12 max-w-3xl mx-auto">

          <p className="text-green-700 uppercase tracking-widest text-sm font-medium">
            Enterprise Florist Intelligence
          </p>

          <h1 className="mt-6 text-4xl md:text-5xl font-semibold leading-[1.1] tracking-tight text-gray-900">
            More Than a Florist POS.
            <br />
            A Complete Florist ERP.
          </h1>

          <p className="text-lg text-green-700 mt-4 font-medium">
  आपके फूलों के व्यवसाय का स्मार्ट साथी।
</p>


          <p className="mt-6 text-lg text-gray-600 leading-relaxed text-center">
            Floraprise is the operating system for modern flower shops.
            <br />
            Manage POS, inventory, bouquet production, delivery,
            <br />
            and accounting from one unified platform built specifically
            <br />
            for professional florists.
          </p>

          {/* Conversion credibility line */}
          <div className="mt-8 text-base text-center text-gray-700 font-semibold">
            Trusted by modern florists to manage orders, inventory, and deliveries from one platform.
          </div>
          <div className="mt-10 flex justify-center gap-4 flex-wrap">
  
  {/* Primary - Green */}
  <Link
    href="/signup"
    className="bg-[var(--brand-green)] text-white px-8 py-4 rounded-lg font-medium shadow-md hover:bg-[var(--brand-green-light)] hover:shadow-lg transition duration-200"
  >
    Start Free Trial
  </Link>

  {/* Secondary - Orange */}
  <Link
    href="/demo"
    className="bg-[var(--brand-orange)] text-white px-8 py-4 rounded-lg font-medium shadow-md hover:bg-[var(--brand-orange-dark)] hover:shadow-lg transition duration-200"
  >
    Book Live Demo
  </Link>

  {/* WhatsApp Demo Button */}
  <a
    href="https://wa.me/919810392755"
    target="_blank"
    className="border border-green-600 text-green-700 px-8 py-4 rounded-lg font-medium hover:bg-green-50 transition"
    rel="noopener noreferrer"
  >
    WhatsApp Us
  </a>

</div>

          <div className="mt-8 text-sm text-gray-600 flex justify-center gap-6 flex-wrap font-medium">
            🇮🇳 Made for Indian Florists
            ✔ GST Ready Billing
            ✔ UPI & Card Payments
            ✔ Secure Cloud Platform
          </div>

        </div>

      </div>
    </section>
  );
}