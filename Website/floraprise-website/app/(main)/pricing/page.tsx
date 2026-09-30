"use client";

import { useState } from "react";
import Link from "next/link";

type CountryCode = "IN" | "US" | "AE";
type BillingDuration = "quarterly" | "halfYearly" | "annual";

interface CountryPricing {
  name: string;
  flag: string;
  currency: string;
  symbol: string;
  gateway: string;
  pricing: {
    quarterly: {
      total: number;
      monthlyEquivalent: number;
      label: string;
    };
    halfYearly: {
      total: number;
      monthlyEquivalent: number;
      savings: number;
      label: string;
    };
    annual: {
      total: number;
      monthlyEquivalent: number;
      savings: number;
      label: string;
    };
  };
}

const PRICING_DATA: Record<CountryCode, CountryPricing> = {
  IN: {
    name: "India",
    flag: "🇮🇳",
    currency: "INR",
    symbol: "₹",
    gateway: "PayU (UPI, Cards, Net Banking)",
    pricing: {
      quarterly: {
        total: 4999,
        monthlyEquivalent: 1666,
        label: "3 Months",
      },
      halfYearly: {
        total: 8999,
        monthlyEquivalent: 1500,
        savings: 999, // (4999 * 2) - 8999
        label: "6 Months",
      },
      annual: {
        total: 14999,
        monthlyEquivalent: 1250,
        savings: 4997, // (4999 * 4) - 14999
        label: "12 Months",
      },
    },
  },
  US: {
    name: "United States",
    flag: "🇺🇸",
    currency: "USD",
    symbol: "$",
    gateway: "PayPal (Cards & PayPal Balance)",
    pricing: {
      quarterly: {
        total: 179,
        monthlyEquivalent: 60,
        label: "3 Months",
      },
      halfYearly: {
        total: 329,
        monthlyEquivalent: 55,
        savings: 29, // (179 * 2) - 329
        label: "6 Months",
      },
      annual: {
        total: 599,
        monthlyEquivalent: 50,
        savings: 117, // (179 * 4) - 599
        label: "12 Months",
      },
    },
  },
  AE: {
    name: "United Arab Emirates",
    flag: "🇦🇪",
    currency: "AED",
    symbol: "AED ",
    gateway: "PayPal (Cards & PayPal Balance)",
    pricing: {
      quarterly: {
        total: 649,
        monthlyEquivalent: 216,
        label: "3 Months",
      },
      halfYearly: {
        total: 1199,
        monthlyEquivalent: 200,
        savings: 99, // (649 * 2) - 1199
        label: "6 Months",
      },
      annual: {
        total: 2199,
        monthlyEquivalent: 183,
        savings: 397, // (649 * 4) - 2199
        label: "12 Months",
      },
    },
  },
};

const FAQ_DATA = [
  {
    q: "Which Floraprise edition is right for my flower business?",
    a: "Floraprise Solo and Floraprise Pro provide the same complete everyday florist business capabilities at the exact same subscription pricing. If you operate on a single Android phone or tablet and prefer 100% local device storage without cloud dependencies, choose Floraprise Solo. If you want real-time cloud backup, multi-device synchronization, and full web browser access from your laptop or PC, choose Floraprise Pro. If you manage multiple shop locations, central warehouses, or need store-to-store stock transfers, Floraprise ERP is built for you.",
  },
  {
    q: "What payment methods are supported for Solo and Pro subscriptions?",
    a: "For India, we support PayU with instant activation via UPI, RuPay, Visa, MasterCard, and Net Banking. For international florists in the USA, UAE, and worldwide, we support secure PayPal checkout with debit/credit cards and PayPal accounts in native USD and AED.",
  },
  {
    q: "What happens if the internet goes down during counter rush?",
    a: "Floraprise POS is offline-first. In Floraprise Solo, all operations are saved locally on your device. In Floraprise Pro, counter billing, receipt printing, and cash transactions continue seamlessly without internet; once reconnected, transactions automatically synchronize with the cloud.",
  },
  {
    q: "Can I switch or upgrade my plan later?",
    a: "Yes. You can transition from Solo to Pro or from Pro to ERP at any time without losing product catalogues, customer records, recipe data, or transaction history.",
  },
  {
    q: "Do you offer onboarding and data migration assistance?",
    a: "Yes. Our team helps you import your existing flower list, stem rates, bouquet designs, customer databases, and supplier records so your team can start taking orders immediately.",
  },
  {
    q: "Is there any hidden transaction fee on our floral sales?",
    a: "No. Floraprise charges zero commission or transaction fees on your sales. You only pay your transparent software subscription.",
  },
];

export default function PricingPage() {
  const [selectedCountry, setSelectedCountry] = useState<CountryCode>("IN");
  const [duration, setDuration] = useState<BillingDuration>("annual");
  const [openFaq, setOpenFaq] = useState<number | null>(0);

  const countryData = PRICING_DATA[selectedCountry];
  const activePlan = countryData.pricing[duration];

  const formatPrice = (amount: number) => {
    if (selectedCountry === "AE") {
      return `AED ${amount.toLocaleString()}`;
    }
    return `${countryData.symbol}${amount.toLocaleString()}`;
  };

  const faqSchema = {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: FAQ_DATA.map((item) => ({
      "@type": "Question",
      name: item.q,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.a,
      },
    })),
  };

  return (
    <div className="bg-[#f5f6f1] text-[#142219]">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqSchema) }}
      />

      {/* ================= HERO ================= */}
      <section className="pt-16 pb-12 text-center">
        <div className="max-w-4xl mx-auto px-6">
          <span className="inline-block text-[#25784a] text-xs font-extrabold uppercase tracking-widest mb-3 bg-[#e6ede5] px-3.5 py-1 rounded-full border border-[#c4d6c2]">
            Transparent Florist Pricing
          </span>

          <h1 className="text-4xl md:text-5xl lg:text-6xl font-serif font-normal mb-4 text-[#142219] leading-tight">
            Simple, Honest Plans for Florists
          </h1>

          <p className="text-xl md:text-2xl text-[#25784a] font-serif mb-4">
            From single-phone kiosks to multi-store floral brands.
          </p>

          <p className="text-gray-600 max-w-2xl mx-auto text-base sm:text-lg mb-8 leading-relaxed">
            No per-transaction cuts. No hidden charges. Select your country to view local pricing and payment options.
          </p>

          {/* Country Selector */}
          <div className="mb-6 inline-flex items-center gap-2 p-1.5 bg-white rounded-2xl border border-[#d9dfd7] shadow-xs">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-400 pl-3 pr-1">
              Select Region:
            </span>
            {(["IN", "US", "AE"] as CountryCode[]).map((code) => {
              const c = PRICING_DATA[code];
              const isSelected = selectedCountry === code;
              return (
                <button
                  key={code}
                  type="button"
                  onClick={() => setSelectedCountry(code)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition cursor-pointer ${
                    isSelected
                      ? "bg-[#124e2c] text-white shadow-xs"
                      : "text-gray-700 hover:text-black hover:bg-gray-100"
                  }`}
                >
                  <span className="text-base">{c.flag}</span>
                  <span>{c.name}</span>
                  <span className={`text-xs ${isSelected ? "text-green-200" : "text-gray-500"}`}>
                    ({c.currency})
                  </span>
                </button>
              );
            })}
          </div>

          {/* Billing Duration Selector */}
          <div className="flex justify-center">
            <div className="inline-flex flex-wrap justify-center items-center p-1.5 bg-white border border-[#d9dfd7] rounded-xl shadow-xs gap-1">
              <button
                type="button"
                onClick={() => setDuration("quarterly")}
                className={`px-4 py-2 text-sm font-semibold rounded-lg transition cursor-pointer ${
                  duration === "quarterly"
                    ? "bg-[#124e2c] text-white shadow-xs"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                Quarterly (3 Months)
              </button>
              <button
                type="button"
                onClick={() => setDuration("halfYearly")}
                className={`px-4 py-2 text-sm font-semibold rounded-lg transition cursor-pointer flex items-center gap-1.5 ${
                  duration === "halfYearly"
                    ? "bg-[#124e2c] text-white shadow-xs"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                <span>Half-Yearly (6 Months)</span>
                {countryData.pricing.halfYearly.savings > 0 && (
                  <span className="text-[10px] bg-[#25784a] text-white px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">
                    Save {formatPrice(countryData.pricing.halfYearly.savings)}
                  </span>
                )}
              </button>
              <button
                type="button"
                onClick={() => setDuration("annual")}
                className={`px-4 py-2 text-sm font-semibold rounded-lg transition cursor-pointer flex items-center gap-1.5 ${
                  duration === "annual"
                    ? "bg-[#124e2c] text-white shadow-xs"
                    : "text-gray-600 hover:text-gray-900"
                }`}
              >
                <span>Annual (12 Months)</span>
                <span className="text-[10px] bg-[#e48a24] text-white px-2 py-0.5 rounded-full font-bold uppercase tracking-wider">
                  Save {formatPrice(countryData.pricing.annual.savings)}
                </span>
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* ================= 3 TIERS CARDS ================= */}
      <section className="pb-24 px-6">
        <div className="max-w-7xl mx-auto grid lg:grid-cols-3 gap-8 items-stretch">
          
          {/* ================= TIER 1: SOLO ================= */}
          <div className="bg-white rounded-3xl border border-[#d9dfd7] p-8 shadow-xs flex flex-col justify-between hover:border-[#25784a] transition">
            <div>
              <div className="text-xs font-extrabold uppercase tracking-widest text-gray-500 mb-2">
                Single Android Device • Local Storage
              </div>
              <h2 className="text-3xl font-serif font-normal text-[#142219] mb-2">
                Floraprise Solo
              </h2>
              <p className="text-gray-600 text-sm mb-6 min-h-[42px] leading-relaxed">
                Everything you need to run your florist business on one Android device, even when you&apos;re offline.
              </p>

              {/* Price Display */}
              <div className="mb-6 p-5 bg-[#f5f6f1] rounded-2xl border border-gray-200">
                <div className="flex items-baseline gap-2">
                  <span className="text-4xl font-extrabold text-[#124e2c]">
                    {formatPrice(activePlan.total)}
                  </span>
                  <span className="text-gray-700 text-sm font-medium">
                    / {activePlan.label}
                  </span>
                </div>
                <div className="text-xs text-[#124e2c] font-bold mt-2 flex items-center justify-between">
                  <span>~{formatPrice(activePlan.monthlyEquivalent)} / month</span>
                  {duration === "annual" && (
                    <span className="bg-[#e48a24] text-white text-[10px] px-2 py-0.5 rounded-md uppercase font-bold">
                      Save {formatPrice(countryData.pricing.annual.savings)}
                    </span>
                  )}
                  {duration === "halfYearly" && (
                    <span className="bg-[#25784a] text-white text-[10px] px-2 py-0.5 rounded-md uppercase font-bold">
                      Save {formatPrice(countryData.pricing.halfYearly.savings)}
                    </span>
                  )}
                </div>

                {/* Duration pills */}
                <div className="mt-3 pt-3 border-t border-gray-200 text-xs flex gap-1.5 justify-between">
                  <span className={`px-2 py-0.5 rounded ${duration === "quarterly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border text-gray-700"}`}>
                    {formatPrice(countryData.pricing.quarterly.total)} / 3m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${duration === "halfYearly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border text-gray-700"}`}>
                    {formatPrice(countryData.pricing.halfYearly.total)} / 6m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${duration === "annual" ? "bg-[#124e2c] text-white font-bold" : "bg-white border text-gray-700"}`}>
                    {formatPrice(countryData.pricing.annual.total)} / 12m
                  </span>
                </div>
              </div>

              {/* Gateway Callout */}
              <div className="mb-6 p-3 bg-gray-100 rounded-xl text-xs text-gray-600 font-medium">
                <strong>Accepted Gateway:</strong> {countryData.gateway}
              </div>

              {/* Operating Mode Callout */}
              <div className="mb-6 p-3 bg-gray-100 rounded-xl text-xs text-gray-700 font-medium">
                <strong>Operating Model:</strong> Single Android device (100% offline-first local database)
              </div>

              {/* Feature List */}
              <div className="mb-8">
                <p className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-3">
                  Everyday Florist Capabilities Included:
                </p>
                <ul className="space-y-3 text-sm text-gray-700">
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Florist POS</strong> (Take Away, Pickup & Delivery)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Perishable Flower Inventory</strong> (Batches, stems & wastage)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Order Management</strong> & order preparation</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Payments & Split Tender</strong> (Cash, Cards, UPI, Advance)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Customer Contacts</strong> & order history lookup</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Delivery Management</strong> & address notes</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Cash Book & Day Close</strong> cash reconciliation</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Visual Product Catalogue</strong> & WhatsApp digital receipts</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>100% Offline Local Database</strong> on device</span>
                  </li>
                </ul>
              </div>
            </div>

            <Link
              href="/demo"
              className="block w-full text-center py-3.5 px-6 rounded-xl font-bold bg-[#142219] text-white hover:bg-black transition shadow-xs"
            >
              Get Floraprise Solo
            </Link>
          </div>

          {/* ================= TIER 2: PRO (HIGHLIGHTED) ================= */}
          <div className="bg-white rounded-3xl border-2 border-[#124e2c] p-8 shadow-xl flex flex-col justify-between relative scale-100 lg:scale-[1.03]">
            {/* Top Badge */}
            <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-[#124e2c] text-white text-xs font-extrabold uppercase tracking-widest px-4 py-1 rounded-full shadow-md flex items-center gap-1.5 whitespace-nowrap">
              <span>⭐</span> RECOMMENDED • CONNECTED CLOUD
            </div>

            <div>
              <div className="text-xs font-extrabold uppercase tracking-widest text-[#25784a] mb-2 pt-1">
                Connected Everyday Florist Cloud
              </div>
              <h2 className="text-3xl font-serif font-normal text-[#142219] mb-2">
                Floraprise Pro
              </h2>
              <p className="text-gray-600 text-sm mb-6 min-h-[42px] leading-relaxed">
                Everything in Solo, with cloud storage, multi-device synchronization and web access.
              </p>

              {/* Price Display */}
              <div className="mb-6 p-5 bg-[#e6ede5] rounded-2xl border border-[#c4d6c2]">
                <div className="flex items-baseline gap-2">
                  <span className="text-4xl font-extrabold text-[#124e2c]">
                    {formatPrice(activePlan.total)}
                  </span>
                  <span className="text-gray-700 text-sm font-medium">
                    / {activePlan.label}
                  </span>
                </div>
                <div className="text-xs text-[#124e2c] font-bold mt-2 flex items-center justify-between">
                  <span>~{formatPrice(activePlan.monthlyEquivalent)} / month</span>
                  {duration === "annual" && (
                    <span className="bg-[#e48a24] text-white text-[10px] px-2 py-0.5 rounded-md uppercase font-bold">
                      Save {formatPrice(countryData.pricing.annual.savings)}
                    </span>
                  )}
                  {duration === "halfYearly" && (
                    <span className="bg-[#25784a] text-white text-[10px] px-2 py-0.5 rounded-md uppercase font-bold">
                      Save {formatPrice(countryData.pricing.halfYearly.savings)}
                    </span>
                  )}
                </div>

                {/* Duration pills */}
                <div className="mt-3 pt-3 border-t border-[#c4d6c2] text-xs flex gap-1.5 justify-between">
                  <span className={`px-2 py-0.5 rounded ${duration === "quarterly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border text-gray-700"}`}>
                    {formatPrice(countryData.pricing.quarterly.total)} / 3m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${duration === "halfYearly" ? "bg-[#124e2c] text-white font-bold" : "bg-white border text-gray-700"}`}>
                    {formatPrice(countryData.pricing.halfYearly.total)} / 6m
                  </span>
                  <span className={`px-2 py-0.5 rounded ${duration === "annual" ? "bg-[#124e2c] text-white font-bold" : "bg-white border text-gray-700"}`}>
                    {formatPrice(countryData.pricing.annual.total)} / 12m
                  </span>
                </div>
              </div>

              {/* Gateway Callout */}
              <div className="mb-6 p-3 bg-[#f5f6f1] rounded-xl text-xs text-gray-600 font-medium">
                <strong>Accepted Gateway:</strong> {countryData.gateway}
              </div>

              {/* Operating Mode Callout */}
              <div className="mb-6 p-3 bg-[#f5f6f1] rounded-xl text-xs text-gray-700 font-medium">
                <strong>Operating Model:</strong> Cloud storage + Multi-device sync + Android & Web
              </div>

              {/* Feature List */}
              <div className="mb-8">
                <p className="text-xs font-bold uppercase tracking-wider text-[#124e2c] mb-3">
                  Everything in Solo, Plus Cloud & Web Connected Power:
                </p>
                <ul className="space-y-3 text-sm text-gray-700">
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Everything in Solo</strong> included</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Cloud Storage & Automatic Backup</strong></span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Multi-Device Real-Time Sync</strong> (Phone + Tablet + Web)</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Full Web / Browser Workspace</strong> for PC & laptop</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Delivery Management</strong> with live rider tracking</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Staff Attendance & Shift Tracking</strong></span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Cash Variance & Shift Audit</strong> reporting</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Offline POS Resilience</strong> with automatic cloud sync</span>
                  </li>
                </ul>
              </div>
            </div>

            <Link
              href="/demo"
              className="block w-full text-center py-4 px-6 rounded-xl font-bold bg-[#124e2c] text-white hover:bg-[#0b3c20] transition shadow-md"
            >
              Get Floraprise Pro
            </Link>
          </div>

          {/* ================= TIER 3: ERP ================= */}
          <div className="bg-white rounded-3xl border border-[#d9dfd7] p-8 shadow-xs flex flex-col justify-between hover:border-[#25784a] transition">
            <div>
              <div className="text-xs font-extrabold uppercase tracking-widest text-[#25784a] mb-2">
                Multi-Store & Floral Chains
              </div>
              <h2 className="text-3xl font-serif font-normal text-[#142219] mb-2">
                Floraprise ERP
              </h2>
              <p className="text-gray-600 text-sm mb-6 min-h-[42px] leading-relaxed">
                Advanced florist ERP for growing and multi-location businesses. Multi-store inventory, central warehouse, and corporate management.
              </p>

              {/* Price */}
              <div className="mb-6 p-5 bg-[#f5f6f1] rounded-2xl border border-gray-200">
                <div className="text-3xl font-extrabold text-[#124e2c]">Custom Quote</div>
                <div className="text-xs text-gray-600 mt-1">
                  Tailored to your store count, warehouses & staff roles
                </div>
              </div>

              {/* Operating Mode Callout */}
              <div className="mb-6 p-3 bg-gray-100 rounded-xl text-xs text-gray-700 font-medium">
                <strong>Deployment:</strong> Multi-store web ERP + multiple mobile devices
              </div>

              {/* Feature List */}
              <div className="mb-8">
                <p className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-3">
                  Advanced Floral ERP Capabilities:
                </p>
                <ul className="space-y-3 text-sm text-gray-700">
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Everything in Pro</strong> included</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Multi-Location Inventory</strong> & store-to-store transfers</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Central Warehouse</strong> & replenishment dispatch</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Recipe Management</strong> & production workflows</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Multi-Location Reporting</strong> & business analytics</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Custom Role Hierarchy</strong> & multi-branch permissions</span>
                  </li>
                  <li className="flex items-start gap-2.5">
                    <span className="text-[#25784a] font-bold">✓</span>
                    <span><strong>Dedicated Onboarding Specialist</strong> & team training</span>
                  </li>
                </ul>
              </div>
            </div>

            <Link
              href="/demo"
              className="block w-full text-center py-3.5 px-6 rounded-xl font-bold bg-[#142219] text-white hover:bg-black transition shadow-xs"
            >
              Book Multi-Store Demo
            </Link>
          </div>

        </div>
      </section>

      {/* ================= DETAILED COMPARISON TABLE ================= */}
      <section className="py-20 bg-white border-t border-[#d9dfd7]">
        <div className="max-w-6xl mx-auto px-6">
          <div className="text-center mb-16">
            <span className="text-[#25784a] text-xs font-extrabold uppercase tracking-widest block mb-2">
              Feature Matrix
            </span>
            <h2 className="text-3xl sm:text-4xl font-serif font-normal text-[#142219]">
              Compare Floraprise Editions
            </h2>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm border-collapse">
              <thead>
                <tr className="border-b-2 border-gray-200">
                  <th className="py-4 px-4 font-bold text-gray-900 w-1/3">Feature Category</th>
                  <th className="py-4 px-4 font-bold text-[#142219] text-center w-1/5">
                    Solo<br /><span className="text-xs font-normal text-gray-500">Local / Single Device</span>
                  </th>
                  <th className="py-4 px-4 font-bold text-[#124e2c] text-center w-1/4 bg-[#e6ede5] rounded-t-xl">
                    Pro ⭐<br /><span className="text-xs font-normal text-[#124e2c]">Everyday Cloud</span>
                  </th>
                  <th className="py-4 px-4 font-bold text-[#142219] text-center w-1/5">
                    ERP<br /><span className="text-xs font-normal text-gray-500">Multi-Store</span>
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {/* Point of Sale & Billing */}
                <tr className="bg-gray-50/50">
                  <td colSpan={4} className="py-3 px-4 font-bold text-xs uppercase tracking-wider text-[#25784a]">
                    Florist POS & Orders
                  </td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Order Intent Workflows (Take Away, Pickup & Delivery)</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Multi-Counter</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">WhatsApp Digital Invoicing & Receipts</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Automated Notifications</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Advance Bookings & Split Tender Deposits</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Milestone & Contracts</td>
                </tr>

                {/* Inventory & Perishables */}
                <tr className="bg-gray-50/50">
                  <td colSpan={4} className="py-3 px-4 font-bold text-xs uppercase tracking-wider text-[#25784a]">
                    Perishable Flower Inventory
                  </td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Perishable Flower Batches, Stems & Spoilage</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Multi-Warehouse Batches</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Bouquet Recipes, Stem Deductions & Materials</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Central Recipe Matrix</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Store-to-Store Stock Transfers</td>
                  <td className="py-3.5 px-4 text-center text-gray-400">—</td>
                  <td className="py-3.5 px-4 text-center text-gray-400 bg-[#e6ede5]/40">—</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c]">✓ Inter-Branch Dispatch</td>
                </tr>

                {/* Logistics & Workstations */}
                <tr className="bg-gray-50/50">
                  <td colSpan={4} className="py-3 px-4 font-bold text-xs uppercase tracking-wider text-[#25784a]">
                    Designer & Delivery Logistics
                  </td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Designer Preparation & Greeting Card Printing</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Centralized Workflow</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Delivery Logistics & Driver Coordination</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓ Local Dispatch</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓ Live Rider Tracking</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Multi-Location Delivery</td>
                </tr>

                {/* Financials & Day Close */}
                <tr className="bg-gray-50/50">
                  <td colSpan={4} className="py-3 px-4 font-bold text-xs uppercase tracking-wider text-[#25784a]">
                    Accounts & Cash Control
                  </td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Cash Book, Daily Expenses & Day Close Variance</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Multi-Location Reports</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Everyday Business Reports</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Multi-Branch Analytics</td>
                </tr>

                {/* Operating & Storage Architecture */}
                <tr className="bg-gray-50/50">
                  <td colSpan={4} className="py-3 px-4 font-bold text-xs uppercase tracking-wider text-[#25784a]">
                    Operating & Storage Model
                  </td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Offline-First Operation</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓ Full Offline</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold bg-[#e6ede5]/40">✓ Offline + Auto Sync</td>
                  <td className="py-3.5 px-4 text-center text-[#25784a] font-bold">✓ Offline + Central Sync</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Storage Architecture</td>
                  <td className="py-3.5 px-4 text-center text-gray-700 font-medium">Local Device Database</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">Cloud Storage</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">Cloud Storage</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Supported Devices & Terminals</td>
                  <td className="py-3.5 px-4 text-center text-gray-700 font-medium">Single Android Device</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">Multi-Device (Phone, Tablet, Web)</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">Multi-Store & Multiple Devices</td>
                </tr>
                <tr>
                  <td className="py-3.5 px-4 font-medium text-gray-800">Web / Browser Access</td>
                  <td className="py-3.5 px-4 text-center text-gray-400">—</td>
                  <td className="py-3.5 px-4 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">✓ Full Web Workspace</td>
                  <td className="py-3.5 px-4 text-center text-gray-700">✓ Central Web ERP</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* ================= MIGRATION & REASSURANCE ================= */}
      <section className="py-20 bg-[#f5f6f1]">
        <div className="max-w-5xl mx-auto px-6 grid md:grid-cols-2 gap-12 items-center">
          <div>
            <span className="text-[#25784a] text-xs font-extrabold uppercase tracking-widest block mb-2">
              Smooth Transition
            </span>
            <h2 className="text-3xl font-serif font-normal text-[#142219] mb-4">
              Moving to Floraprise is Fast and Painless
            </h2>
            <p className="text-gray-600 mb-6 leading-relaxed">
              Whether you are currently managing orders on paper notebooks, WhatsApp chats, generic retail POS, or spreadsheets, we help you transition smoothly.
            </p>
            <ul className="space-y-2.5 text-sm text-gray-700 font-medium">
              <li className="flex items-center gap-2">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Import existing flower & accessory catalogues</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Transfer existing customer contact history</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Staff and counter operator training sessions</span>
              </li>
              <li className="flex items-center gap-2">
                <span className="text-[#25784a] font-bold">✓</span>
                <span>Go-live assistance before peak floral dates</span>
              </li>
            </ul>
          </div>

          <div className="bg-white p-8 rounded-3xl border border-[#d9dfd7] shadow-xs">
            <h3 className="text-xl font-serif font-normal text-[#142219] mb-4">
              Typical Onboarding Timeline
            </h3>
            <div className="space-y-4 text-sm text-gray-700">
              <div className="flex justify-between items-center border-b border-gray-100 pb-3">
                <span className="font-bold text-[#124e2c]">Day 1</span>
                <span>Store setup, payment modes & receipt templates</span>
              </div>
              <div className="flex justify-between items-center border-b border-gray-100 pb-3">
                <span className="font-bold text-[#124e2c]">Day 2–3</span>
                <span>Catalogue import & perishable stem stock entry</span>
              </div>
              <div className="flex justify-between items-center border-b border-gray-100 pb-3">
                <span className="font-bold text-[#124e2c]">Day 4–5</span>
                <span>Staff dry-run training & receipt printer pairing</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="font-bold text-[#124e2c]">Week 2</span>
                <span className="font-medium text-gray-900">100% Live Operations</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ================= FAQ SECTION ================= */}
      <section className="py-20 bg-white border-t border-[#d9dfd7]">
        <div className="max-w-4xl mx-auto px-6">
          <div className="text-center mb-12">
            <span className="text-[#25784a] text-xs font-extrabold uppercase tracking-widest block mb-2">
              Got Questions?
            </span>
            <h2 className="text-3xl font-serif font-normal text-[#142219]">
              Pricing & Subscription FAQs
            </h2>
          </div>

          <div className="space-y-4">
            {FAQ_DATA.map((faq, idx) => {
              const isOpen = openFaq === idx;
              return (
                <div key={idx} className="border border-gray-200 rounded-2xl overflow-hidden transition">
                  <button
                    type="button"
                    onClick={() => setOpenFaq(isOpen ? null : idx)}
                    className="w-full text-left font-semibold text-lg bg-white p-5 focus:outline-none flex justify-between items-center transition hover:text-[#124e2c] cursor-pointer"
                  >
                    <span>{faq.q}</span>
                    <span className="text-[#25784a] font-bold text-xl ml-4">
                      {isOpen ? "−" : "+"}
                    </span>
                  </button>
                  {isOpen && (
                    <div className="px-5 pb-5 text-gray-600 bg-white text-base leading-relaxed border-t border-gray-100 pt-3">
                      {faq.a}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* ================= FINAL CTA ================= */}
      <section className="py-20 bg-[#124e2c] text-white text-center">
        <div className="max-w-3xl mx-auto px-6">
          <h2 className="text-3xl sm:text-4xl font-serif font-normal mb-4">
            Ready to Streamline Your Flower Shop?
          </h2>
          <p className="text-green-100 text-base sm:text-lg mb-8 leading-relaxed max-w-xl mx-auto">
            Book a quick 15-minute live walkthrough or start with Floraprise today.
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              href="/demo"
              className="bg-white text-[#124e2c] px-8 py-4 rounded-xl font-bold hover:bg-green-50 transition shadow-md"
              style={{ color: "#124e2c" }}
            >
              Book a Live Demo
            </Link>
            <a
              href="https://wa.me/919971060931"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-[#25784a] text-white px-8 py-4 rounded-xl font-bold hover:bg-[#1a5b36] transition border border-green-400/30"
            >
              Chat on WhatsApp
            </a>
          </div>
        </div>
      </section>
    </div>
  );
}
