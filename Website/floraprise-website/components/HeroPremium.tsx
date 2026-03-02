"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";

export default function HeroPremium() {
  const [isIndia, setIsIndia] = useState(false);

  useEffect(() => {
    const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (timezone.includes("Asia/Kolkata")) {
      setIsIndia(true);
    }
  }, []);

  return (
    <section className="bg-white pt-20 pb-24">

      <div className="max-w-6xl mx-auto px-6 text-center">

        {/* Hero Image (Foreground) */}
        <div className="relative flex justify-center">
  <div className="absolute -z-10 w-[65%] h-[65%] bg-green-100 blur-3xl rounded-full opacity-40"></div>

  <Image
    src="/floraprise-real.png"
    alt="Floraprise POS used in real flower shop"
    width={1000}
    height={650}
    priority
    className="rounded-2xl shadow-[0_40px_80px_-20px_rgba(0,0,0,0.25)]"
  />
</div>

        {/* Text Below Image */}
        <div className="mt-16 max-w-4xl mx-auto">

          <p className="text-green-700 uppercase tracking-widest text-sm font-medium">
            Enterprise Florist Intelligence
          </p>

          <h1 className="mt-6 text-4xl md:text-5xl font-semibold leading-[1.1] tracking-tight text-gray-900">
            More Than a Florist POS.
            <br />
            A Complete Florist ERP.
          </h1>

          {isIndia && (
            <p className="text-lg text-green-800 mt-4 font-bold">
              आपके फूलों के व्यवसाय का स्मार्ट साथी।
            </p>
          )}

          <p className="mt-6 text-lg text-gray-600 leading-relaxed text-justify">
  Floraprise is an advanced florist POS and ERP software designed for modern flower shops and multi-location floral businesses. From real-time inventory management and perishable batch tracking to bouquet production workflows, delivery routing, staff scheduling, and profit analytics, Floraprise centralizes every operational process into one intelligent, cloud-based platform built specifically for professional florists.
</p>

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

</div>

          <div className="mt-6 text-sm text-gray-500 flex justify-center gap-4 flex-wrap">
            ✔ Inventory-first
            ✔ Production-ready
            ✔ Multi-location SaaS
          </div>

        </div>

      </div>
    </section>
  );
}