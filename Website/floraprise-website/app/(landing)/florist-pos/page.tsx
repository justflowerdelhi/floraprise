import Link from "next/link";
import { Metadata } from "next";

export const metadata: Metadata = {
  title: "Florist POS Software & Inventory System — Floraprise",
  description:
    "Purpose-built Point of Sale (POS) and inventory software for retail flower shops, studio florists, and floral delivery businesses. Offline-first, WhatsApp billing, and perishable batch tracking.",
  alternates: {
    canonical: "https://floraprise.com/florist-pos",
  },
};

export default function FloristPOSLandingPage() {
  return (
    <div className="bg-[#f5f6f1] text-[#142219]">
      {/* ================= HERO ================= */}
      <section className="pt-24 pb-16 text-center bg-gradient-to-b from-[#e6ede5] to-[#f5f6f1]">
        <div className="max-w-4xl mx-auto px-6">
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-white border border-[#c4d6c2] text-xs font-bold text-[#124e2c] uppercase tracking-wider mb-6 shadow-xs">
            <span>🌸</span> Built Exclusively for Florists
          </div>

          <h1 className="text-4xl md:text-5xl lg:text-6xl font-serif font-normal mb-6 text-[#142219] leading-tight">
            The Point of Sale Built for the Reality of Flowers
          </h1>

          <p className="text-lg md:text-xl text-gray-700 max-w-2xl mx-auto mb-8 leading-relaxed">
            Standard retail POS systems treat bouquets like dry cans on a shelf. Floraprise is built for perishable stems, custom arrangements, advance event bookings, and delivery rush.
          </p>

          <div className="flex flex-wrap justify-center gap-4 mb-12">
            <Link
              href="/pricing"
              className="bg-[#124e2c] text-white px-8 py-4 rounded-xl font-bold hover:bg-[#0b3c20] transition shadow-md"
            >
              View Plans & Pricing
            </Link>
            <Link
              href="/demo"
              className="bg-white text-[#142219] px-8 py-4 rounded-xl font-bold hover:bg-gray-100 transition border border-[#d9dfd7] shadow-xs"
            >
              Book a Live Demo
            </Link>
          </div>

          <div className="text-xs text-gray-500 font-medium">
            Offline POS • WhatsApp Bills • Perishable Batches • Thermal & Card Printing • Multi-Device
          </div>
        </div>
      </section>

      {/* ================= CORE POS PILLARS ================= */}
      <section className="py-20 px-6">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <span className="text-[#25784a] text-xs font-extrabold uppercase tracking-widest block mb-2">
              Why Florists Choose Floraprise
            </span>
            <h2 className="text-3xl sm:text-4xl font-serif font-normal text-[#142219]">
              Designed for Flower Shop Speed and Complexity
            </h2>
          </div>

          <div className="grid md:grid-cols-3 gap-8">
            <div className="bg-white p-8 rounded-3xl border border-[#d9dfd7] shadow-xs">
              <div className="text-2xl mb-4">⚡</div>
              <h3 className="text-xl font-serif font-normal text-[#142219] mb-3">
                Intent-Based Checkout
              </h3>
              <p className="text-gray-600 text-sm leading-relaxed mb-4">
                Instantly tag each sale as Take Away, Delivery, or Pickup. Automatically route card messages and delivery slots to the right team members without confusion.
              </p>
              <ul className="text-xs text-gray-500 space-y-1.5 font-medium">
                <li>• Quick counter cash & split tender</li>
                <li>• Advance deposit collection</li>
                <li>• WhatsApp digital receipts</li>
              </ul>
            </div>

            <div className="bg-white p-8 rounded-3xl border border-[#d9dfd7] shadow-xs">
              <div className="text-2xl mb-4">🌹</div>
              <h3 className="text-xl font-serif font-normal text-[#142219] mb-3">
                Perishable Stem Control
              </h3>
              <p className="text-gray-600 text-sm leading-relaxed mb-4">
                Track flower batches with FIFO rotation. When you sell a 12-rose bouquet, Floraprise automatically deducts stems, greenery, wrapping, and ribbon from live inventory.
              </p>
              <ul className="text-xs text-gray-500 space-y-1.5 font-medium">
                <li>• Batch arrival date tracking</li>
                <li>• Flower spoilage recording</li>
                <li>• Recipe margin protection</li>
              </ul>
            </div>

            <div className="bg-white p-8 rounded-3xl border border-[#d9dfd7] shadow-xs">
              <div className="text-2xl mb-4">📶</div>
              <h3 className="text-xl font-serif font-normal text-[#142219] mb-3">
                Offline-First Reliability
              </h3>
              <p className="text-gray-600 text-sm leading-relaxed mb-4">
                Never lose a sale when your internet fails. Take orders, print thermal receipts, and accept cash offline. Floraprise syncs everything automatically upon reconnection.
              </p>
              <ul className="text-xs text-gray-500 space-y-1.5 font-medium">
                <li>• Android phone/tablet counter POS</li>
                <li>• Zero disruption during festive rush</li>
                <li>• Secure cloud backup sync</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* ================= COMPARISON STRIP ================= */}
      <section className="py-20 bg-white border-t border-[#d9dfd7]">
        <div className="max-w-5xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-serif font-normal text-[#142219] mb-4">
              Generic POS vs Floraprise Florist POS
            </h2>
            <p className="text-gray-600">
              Why generic retail or restaurant software fails in a flower shop.
            </p>
          </div>

          <div className="grid md:grid-cols-2 gap-8">
            <div className="p-6 bg-red-50/60 rounded-2xl border border-red-200">
              <h3 className="font-bold text-red-900 text-lg mb-4 flex items-center gap-2">
                <span>✕</span> Generic Retail POS
              </h3>
              <ul className="space-y-3 text-sm text-red-800/90">
                <li>• Treats flowers as non-perishable barcodes</li>
                <li>• No bouquet recipe breakdown (stems, foliage, ribbons)</li>
                <li>• No card message printing or designer workflow</li>
                <li>• No time-slot delivery dispatch or driver routing</li>
                <li>• Forces workarounds for advance event bookings</li>
              </ul>
            </div>

            <div className="p-6 bg-green-50/60 rounded-2xl border border-green-200">
              <h3 className="font-bold text-green-900 text-lg mb-4 flex items-center gap-2">
                <span>✓</span> Floraprise Florist POS
              </h3>
              <ul className="space-y-3 text-sm text-green-900/90">
                <li>• Perishable batch tracking with FIFO stem rotation</li>
                <li>• Standardized bouquet recipes with live COGS margin</li>
                <li>• Built-in greeting card message capture & thermal printing</li>
                <li>• Dispatch board with driver assignment & delivery proof</li>
                <li>• Native advance deposits & split payment tracking</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* ================= FINAL CTA ================= */}
      <section className="py-20 bg-[#124e2c] text-white text-center">
        <div className="max-w-3xl mx-auto px-6">
          <h2 className="text-3xl sm:text-4xl font-serif font-normal mb-4">
            Try Floraprise for Your Flower Shop
          </h2>
          <p className="text-green-100 text-base sm:text-lg mb-8 leading-relaxed max-w-xl mx-auto">
            Experience why florists trust Floraprise to organize counter sales, protect flower margins, and deliver on time.
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              href="/pricing"
              className="bg-white text-[#124e2c] px-8 py-4 rounded-xl font-bold hover:bg-green-50 transition shadow-md"
              style={{ color: "#124e2c" }}
            >
              View Plans & Pricing
            </Link>
            <Link
              href="/demo"
              className="bg-[#25784a] text-white px-8 py-4 rounded-xl font-bold hover:bg-[#1a5b36] transition border border-green-400/30"
            >
              Book a Live Demo
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}