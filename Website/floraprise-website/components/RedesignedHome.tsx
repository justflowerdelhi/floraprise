"use client";

import Image from "next/image";
import Link from "next/link";
import { useState } from "react";

function Eyebrow({ children }: { children: React.ReactNode }) {
  return <span className="product-eyebrow">{children}</span>;
}

function Status({ children, future = false }: { children: React.ReactNode; future?: boolean }) {
  return (
    <span className={`product-status ${future ? "is-future" : ""}`}>
      <i />
      {children}
    </span>
  );
}

const problems = [
  {
    icon: "📱",
    title: "Orders scattered across apps",
    description: "Customer requests mixed between WhatsApp chats, phone calls, and paper notebooks with no central place.",
  },
  {
    icon: "🥀",
    title: "Flower wastage & stock confusion",
    description: "Perishable stems arriving and wilting without real-time tracking of what came in, what was used, or what was lost.",
  },
  {
    icon: "🛵",
    title: "Lost delivery details & timings",
    description: "Delicate arrangements delayed or misrouted because rider details, delivery slots, and addresses are tracked manually.",
  },
  {
    icon: "🧾",
    title: "Slow billing & manual cash tally",
    description: "Calculating prices, custom discounts, and end-of-day cash registers by hand after an exhausting day in the shop.",
  },
  {
    icon: "👥",
    title: "Staff & shift coordination",
    description: "Difficulty keeping track of who is working, marking attendance, and assigning design preparation to team members.",
  },
  {
    icon: "📈",
    title: "Growing business becoming chaotic",
    description: "Opening a second counter or expanding online while struggling to see total sales, profits, and customer history.",
  },
];

const features = [
  {
    tag: "Florist POS",
    title: "Fast, intent-based checkout",
    desc: "Create walk-in, pickup, and delivery orders quickly. Handle products, customer details, custom discounts, taxes, and split payments in one smooth flow.",
    icon: "💐",
  },
  {
    tag: "Perishable Inventory",
    title: "Know every stem & material",
    desc: "Know exactly what flowers, fillers, packaging, and accessories you have in stock. Track what came in, what was crafted, and what was wasted.",
    icon: "📦",
  },
  {
    tag: "Order Management",
    title: "From enquiry to delivery",
    desc: "Keep every order organized from initial creation to floral preparation, rider assignment, live tracking, and successful completion.",
    icon: "📋",
  },
  {
    tag: "Delivery Tracking",
    title: "Scheduled florist logistics",
    desc: "Plan and manage flower deliveries without losing track of venue addresses, recipient timings, or rider coordination.",
    icon: "🛵",
  },
  {
    tag: "Customer History",
    title: "Build lasting relationships",
    desc: "Keep customer contacts, past order records, delivery preferences, and credit balances together for personalized service.",
    icon: "👥",
  },
  {
    tag: "Accounts & Day Close",
    title: "Clean daily financial control",
    desc: "Track cash drawers, card payments, expenses, and daily registers without maintaining complicated manual ledgers.",
    icon: "💰",
  },
  {
    tag: "Staff & Attendance",
    title: "Shift & team accountability",
    desc: "Manage florists, assistants, and delivery drivers with daily attendance, role access, and assigned order responsibilities.",
    icon: "⏱️",
  },
  {
    tag: "Catalogue & MyDesign",
    title: "Showcase floral designs",
    desc: "Organize your bouquet catalogue, seasonal collections, and walk-in design album directly on your tablet or phone.",
    icon: "🎨",
  },
  {
    tag: "Business Reports",
    title: "Clear sales & margin insights",
    desc: "Understand your best-selling flowers, busiest delivery days, revenue trends, and inventory movement with clear reports.",
    icon: "📊",
  },
  {
    tag: "Floraprise ERP",
    title: "Advanced multi-store power",
    desc: "Move beyond everyday shop management with multi-location stock transfers, recipe production, full accounting, CRM, and analytics.",
    icon: "🏢",
  },
];

const comparisonRows = [
  { feature: "Florist POS (Take Away, Pickup & Delivery)", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Multi-Counter)" },
  { feature: "Products & Stem-Level Inventory", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Multi-Location & Batches)" },
  { feature: "Orders & Order Preparation", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Production Management)" },
  { feature: "Payments & Split Tender", solo: "✓", pro: "✓", proHighlight: true, erp: "✓" },
  { feature: "Customer Contacts & Order History", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Advanced Florist CRM)" },
  { feature: "Delivery Management & Logistics", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Multi-Store Delivery)" },
  { feature: "Cash Book, Expenses & Day Close", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Multi-Store Accounting)" },
  { feature: "Product Catalogue & Lookbook", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Central Catalogue)" },
  { feature: "Everyday Business Reports", solo: "✓", pro: "✓", proHighlight: true, erp: "✓ (Multi-Branch Analytics)" },
  { feature: "Offline-First Operation", solo: "✓ (Full Offline)", pro: "✓ (Offline + Cloud Sync)", proHighlight: true, erp: "✓ (Offline + Cloud Sync)" },
  { feature: "Local Storage (On Device)", solo: "✓", pro: "—", erp: "—" },
  { feature: "Cloud Storage & Automatic Backup", solo: "—", pro: "✓", proHighlight: true, erp: "✓" },
  { feature: "Single Android Device Operation", solo: "✓", pro: "—", erp: "—" },
  { feature: "Multi-Device Connected Operation", solo: "—", pro: "✓", proHighlight: true, erp: "✓" },
  { feature: "Web / Browser Workspace Access", solo: "—", pro: "✓", proHighlight: true, erp: "✓" },
  { feature: "Multi-Store & Warehouse Stock Transfers", solo: "—", pro: "—", erp: "✓" },
];

const faqs = [
  {
    q: "Is Floraprise made specifically for florists?",
    a: "Yes. Unlike generic retail software, Floraprise is designed around the unique rhythm of florist businesses. It natively handles perishable flower inventory, stem wastage, bouquet customisation, scheduled pickup and delivery slots, split advance payments, and customer occasion reminders.",
  },
  {
    q: "What is the difference between Floraprise Solo, Pro, and ERP?",
    a: "Floraprise Solo and Pro provide the same complete everyday florist business capabilities at the exact same subscription pricing. Floraprise Solo is designed for a florist operating on a single Android device with local data storage and offline-first operation. Floraprise Pro adds cloud storage, multi-device synchronization, and full web browser access. Floraprise ERP is the advanced edition for growing and multi-location floral businesses managing multiple stores, central warehouses, and workshop production.",
  },
  {
    q: "Can I use Floraprise on my Android phone and computer simultaneously?",
    a: "Yes. With Floraprise Pro and Floraprise ERP, your business data synchronizes seamlessly across Android phones, tablets, and modern web browsers on your computer or laptop.",
  },
  {
    q: "What happens if our shop internet connection goes down?",
    a: "Floraprise includes offline POS capabilities. In Floraprise Solo, all operations run locally on the device without requiring internet. In Floraprise Pro, you can continue ringing up sales, taking pickup orders, and printing receipts offline; when your connection returns, all data automatically synchronizes to the cloud.",
  },
  {
    q: "Where is my business data stored?",
    a: "In Floraprise Solo, your business data is stored locally and securely on your own Android device. In Floraprise Pro and Floraprise ERP, your data is securely stored in the cloud with encrypted daily backups and multi-device access.",
  },
  {
    q: "Can I transition between Floraprise editions as my business expands?",
    a: "Absolutely. You can start on Floraprise Solo or Pro today and seamlessly scale to Floraprise ERP when you open additional locations or require central warehouse management. All your customer history, product catalogues, and sales records carry over cleanly.",
  },
];

export default function RedesignedHome() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  const toggleFaq = (index: number) => {
    setOpenFaq(openFaq === index ? null : index);
  };

  return (
    <main className="product-home">
      {/* ================= HERO SECTION ================= */}
      <section className="product-hero">
        <div className="hero-message">
          <Eyebrow>Built specifically for the business of flowers</Eyebrow>
          <h1>
            Run Your Flower Business. <em>Simply.</em>
          </h1>
          <p>
            POS, perishable inventory, orders, deliveries, customers, staff, and accounts — all in one florist-first platform.
          </p>
          <div className="action-row">
            <Link href="/pricing" className="primary-action">
              Start with Floraprise Pro <span>→</span>
            </Link>
            <Link href="/pricing" className="secondary-action">
              Explore Plans <span>↓</span>
            </Link>
          </div>
          <div className="hero-proof">
            <span>
              <b>SOLO</b> One Android Device
            </span>
            <span>
              <b>PRO</b> Everyday Cloud & Web
            </span>
            <span>
              <b>ERP</b> Multi-Store Scale
            </span>
          </div>
        </div>
        <div className="hero-photo">
          <Image
            src="/floraprise-real.png"
            alt="Florist managing counter sales and floral orders with Floraprise"
            width={1376}
            height={768}
            sizes="(max-width: 1050px) 100vw, 55vw"
            priority
          />
        </div>
      </section>

      {/* ================= RIBBON ================= */}
      <section className="product-ribbon">
        <strong>The Everyday Florist Platform</strong>
        <span>Retail Flower Shops</span>
        <span>Studio Florists</span>
        <span>Perishable Inventory</span>
        <span>Delivery & Route Tracking</span>
        <span>Multi-Device Sync</span>
      </section>

      {/* ================= PROBLEM → SOLUTION STORY ================= */}
      <section className="py-20 px-6 bg-white border-b border-[#d9dfd7]">
        <div className="max-w-6xl mx-auto">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <Eyebrow>The Everyday Florist Reality</Eyebrow>
            <h2 className="text-3xl md:text-5xl font-serif font-normal text-[#142219] mt-3 mb-5 leading-tight">
              Running a flower shop shouldn&apos;t mean wrestling with disconnected tools.
            </h2>
            <p className="text-gray-600 text-lg leading-relaxed">
              Flowers are delicate and perishable. Orders have strict delivery deadlines. When your sales, stock, and deliveries are scattered across notebooks and WhatsApp, mistakes happen.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-14">
            {problems.map((p, idx) => (
              <div
                key={idx}
                className="p-6 rounded-2xl bg-[#f5f6f1] border border-[#d9dfd7] flex flex-col justify-start hover:border-[#25784a] transition"
              >
                <div className="text-3xl mb-4">{p.icon}</div>
                <h3 className="font-bold text-lg text-[#142219] mb-2">{p.title}</h3>
                <p className="text-gray-600 text-sm leading-relaxed">{p.description}</p>
              </div>
            ))}
          </div>

          {/* Solution Banner */}
          <div className="p-8 sm:p-10 rounded-2xl bg-[#124e2c] text-white flex flex-col md:flex-row items-center justify-between gap-6 shadow-md">
            <div className="max-w-2xl">
              <span className="text-[#8fd2a5] text-xs font-extrabold uppercase tracking-widest block mb-2">
                The Floraprise Solution
              </span>
              <h3 className="text-2xl sm:text-3xl font-serif font-normal leading-snug">
                Floraprise brings your entire florist business together in one place.
              </h3>
              <p className="text-[#cfe0d4] text-base mt-2">
                From morning flower market arrivals to counter sales, custom bouquet assembly, rider tracking, and daily cash closing.
              </p>
            </div>
            <Link
              href="/pricing"
              className="bg-white text-[#124e2c] px-6 py-3.5 rounded-xl font-bold text-sm hover:bg-[#e6ede5] transition whitespace-nowrap inline-flex items-center gap-1.5"
              style={{ color: "#124e2c" }}
            >
              <span>See How It Works</span> <span>→</span>
            </Link>
          </div>
        </div>
      </section>

      {/* ================= COMPACT PROMO & DELIVERY SECTIONS ================= */}
      <section className="py-20 lg:py-24 px-6 bg-[#f5f6f1] border-b border-[#d9dfd7]">
        <div className="max-w-6xl mx-auto grid lg:grid-cols-12 gap-10 lg:gap-12 items-center">
          <div className="lg:col-span-6">
            <Eyebrow>Simple Counter Setup</Eyebrow>
            <h2 className="text-3xl md:text-4xl lg:text-5xl font-serif font-normal text-[#142219] mt-3 mb-4 leading-tight">
              Compact Size. Big Possibilities.
            </h2>
            <p className="text-gray-600 text-base md:text-lg leading-relaxed mb-6">
              Run your entire florist shop from a single Android phone and Bluetooth printer. Complete florist POS, digital inventory, billing, and simple digital operations with zero bulky hardware.
            </p>
            <div className="grid grid-cols-2 gap-3 mb-8">
              <span className="p-3 bg-white rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">📱</span> Android Phone / Tablet
              </span>
              <span className="p-3 bg-white rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">🖨️</span> Bluetooth Thermal Printer
              </span>
              <span className="p-3 bg-white rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">💐</span> Purpose-Built Florist POS
              </span>
              <span className="p-3 bg-white rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">✨</span> Zero Clutter Countertop
              </span>
            </div>
            <Link
              href="/pricing"
              className="inline-flex items-center gap-2 font-bold text-[#124e2c] text-sm hover:underline"
            >
              Explore Floraprise Pro <span>→</span>
            </Link>
          </div>
          <div className="lg:col-span-6">
            <div className="rounded-2xl overflow-hidden border border-[#d9dfd7] bg-white shadow-md">
              <Image
                src="/compact.png"
                alt="Floraprise Compact Setup - Android Phone, Bluetooth Printer & Florist POS"
                width={1672}
                height={941}
                sizes="(max-width: 1050px) 100vw, 50vw"
                className="w-full h-auto block"
              />
            </div>
          </div>
        </div>
      </section>

      <section className="py-20 lg:py-24 px-6 bg-white border-b border-[#d9dfd7]">
        <div className="max-w-6xl mx-auto grid lg:grid-cols-12 gap-10 lg:gap-12 items-center">
          <div className="lg:col-span-6 lg:order-2">
            <Eyebrow>Integrated Florist Logistics</Eyebrow>
            <h2 className="text-3xl md:text-4xl lg:text-5xl font-serif font-normal text-[#142219] mt-3 mb-4 leading-tight">
              Delivery Tracking Built for Florists.
            </h2>
            <p className="text-gray-600 text-base md:text-lg leading-relaxed mb-6">
              Give your customers peace of mind with real-time rider tracking designed specifically for delicate floral arrangements, event venues, and scheduled delivery times.
            </p>
            <div className="grid grid-cols-2 gap-3 mb-8">
              <span className="p-3 bg-[#f5f6f1] rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">📍</span> Live Rider Location
              </span>
              <span className="p-3 bg-[#f5f6f1] rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">⏱️</span> Timed Delivery Slots
              </span>
              <span className="p-3 bg-[#f5f6f1] rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">📲</span> Customer Status Notifications
              </span>
              <span className="p-3 bg-[#f5f6f1] rounded-xl border border-[#d9dfd7] text-xs font-semibold text-gray-800 flex items-center gap-2">
                <span className="text-base">📋</span> Complete Delivery History
              </span>
            </div>
            <Link
              href="/features#delivery"
              className="inline-flex items-center gap-2 font-bold text-[#124e2c] text-sm hover:underline"
            >
              See How Delivery Works <span>→</span>
            </Link>
          </div>
          <div className="lg:col-span-6 lg:order-1">
            <div className="rounded-2xl overflow-hidden border border-[#d9dfd7] bg-white shadow-md">
              <Image
                src="/delivery-tracking.png"
                alt="Floraprise Delivery Tracking - Live Rider Location & Notifications"
                width={1672}
                height={941}
                sizes="(max-width: 1050px) 100vw, 50vw"
                className="w-full h-auto block"
              />
            </div>
          </div>
        </div>
      </section>

      {/* ================= 3 PRODUCT EDITIONS (SOLO, PRO, ERP) ================= */}
      <section className="py-24 px-6 bg-[#f5f6f1]" id="products">
        <div className="max-w-6xl mx-auto">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <Eyebrow>Product Editions</Eyebrow>
            <h2 className="text-3xl md:text-5xl font-serif font-normal text-[#142219] mt-3 mb-4 leading-tight">
              One florist platform. Three clear ways to work.
            </h2>
            <p className="text-gray-600 text-lg leading-relaxed">
              Choose the edition that matches how your flower business operates today, with an easy path to grow tomorrow.
            </p>
          </div>

          <div className="grid lg:grid-cols-3 gap-8 items-stretch">
            {/* 1. SOLO */}
            <div id="solo" className="bg-white rounded-2xl border border-[#d9dfd7] p-8 shadow-xs flex flex-col justify-between hover:border-[#25784a] transition">
              <div>
                <div className="flex justify-between items-center mb-3">
                  <span className="text-xs font-extrabold uppercase tracking-widest text-gray-500">Edition 01</span>
                  <Status>Single Android Device</Status>
                </div>
                <h3 className="text-2xl font-serif font-normal text-[#142219] mb-2">Floraprise Solo</h3>
                <p className="text-[#25784a] font-medium text-sm mb-4">
                  Complete florist business management on one device.
                </p>
                <p className="text-gray-600 text-sm leading-relaxed mb-6">
                  Everything you need to run your florist business on one Android device, even when you&apos;re offline. Complete everyday florist capabilities with local storage and offline reliability.
                </p>

                <div className="p-4 bg-[#f5f6f1] rounded-xl mb-6 text-xs text-gray-700 space-y-2">
                  <div className="font-bold text-[#142219] uppercase tracking-wider text-[11px]">Included Capabilities:</div>
                  <div>• Single Android device with local database storage</div>
                  <div>• 100% offline-first operation (no continuous internet required)</div>
                  <div>• Florist POS (Take Away, Pickup & Delivery) & split payments</div>
                  <div>• Perishable flower batch inventory, stems & wastage</div>
                  <div>• Order management, order preparation & delivery coordination</div>
                  <div>• Cash book, daily expenses & day close reconciliation</div>
                  <div>• Visual product catalogue & WhatsApp digital receipts</div>
                </div>
              </div>

              <Link
                href="/pricing"
                className="block w-full text-center py-3.5 px-4 rounded-xl font-bold bg-[#f5f6f1] text-[#142219] border border-[#d9dfd7] hover:border-[#25784a] transition text-sm"
              >
                View Solo Plans & Pricing <span>→</span>
              </Link>
            </div>

            {/* 2. PRO (PRIMARY HIGHLIGHT) */}
            <div id="pro" className="bg-white rounded-2xl border-2 border-[#124e2c] p-8 shadow-xl flex flex-col justify-between relative scale-100 lg:scale-[1.03]">
              <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 bg-[#124e2c] text-white text-xs font-extrabold uppercase tracking-widest px-4 py-1 rounded-full shadow-md flex items-center gap-1.5">
                <span>⭐</span> RECOMMENDED • CONNECTED CLOUD
              </div>
              <div>
                <div className="flex justify-between items-center mb-3 pt-1">
                  <span className="text-xs font-extrabold uppercase tracking-widest text-[#25784a]">Edition 02</span>
                  <Status>Everyday Cloud</Status>
                </div>
                <h3 className="text-2xl font-serif font-normal text-[#142219] mb-2">Floraprise Pro</h3>
                <p className="text-[#124e2c] font-bold text-sm mb-4">
                  Your florist business, connected everywhere.
                </p>
                <p className="text-gray-600 text-sm leading-relaxed mb-6">
                  Everything in Solo, with cloud storage, multi-device synchronization and web access. Connect multiple devices, manage deliveries with live rider tracking, and manage your shop from Android and Web.
                </p>

                <div className="p-4 bg-[#e6ede5] rounded-xl mb-6 text-xs text-[#124e2c] space-y-2">
                  <div className="font-bold uppercase tracking-wider text-[11px]">Included Capabilities:</div>
                  <div>• Everything in Solo, plus connected cloud power</div>
                  <div>• Cloud storage & automated secure backups</div>
                  <div>• Multi-device real-time synchronization</div>
                  <div>• Android App + Full Web/Chrome browser workspace</div>
                  <div>• Delivery management with live rider tracking</div>
                  <div>• Staff attendance, shifts & cash variance audit</div>
                  <div>• Multi-device counter & workstation access</div>
                </div>
              </div>

              <Link
                href="/pricing"
                className="block w-full text-center py-3.5 px-6 rounded-xl font-bold bg-[#124e2c] text-white hover:bg-[#0b3c20] transition shadow-xs text-sm"
              >
                View Pro Plans & Pricing <span>→</span>
              </Link>
            </div>

            {/* 3. ERP */}
            <div id="erp" className="bg-white rounded-2xl border border-[#d9dfd7] p-8 shadow-xs flex flex-col justify-between hover:border-[#25784a] transition">
              <div>
                <div className="flex justify-between items-center mb-3">
                  <span className="text-xs font-extrabold uppercase tracking-widest text-gray-500">Edition 03</span>
                  <Status>Advanced Operations</Status>
                </div>
                <h3 className="text-2xl font-serif font-normal text-[#142219] mb-2">Floraprise ERP</h3>
                <p className="text-[#25784a] font-medium text-sm mb-4">
                  Advanced florist ERP for growing and multi-location businesses.
                </p>
                <p className="text-gray-600 text-sm leading-relaxed mb-6">
                  For larger floral operations requiring multi-store stock transfers, recipe-based workshop production, full double-entry accounting, CRM, and branch analytics.
                </p>

                <div className="p-4 bg-[#f5f6f1] rounded-xl mb-6 text-xs text-gray-700 space-y-2">
                  <div className="font-bold text-[#142219] uppercase tracking-wider text-[11px]">Enterprise Layers:</div>
                  <div>• Multi-location inventory & store-to-store transfers</div>
                  <div>• Recipe management & production workflows</div>
                  <div>• Multi-location delivery coordination</div>
                  <div>• Comprehensive florist CRM & B2B corporate accounts</div>
                  <div>• Advanced reporting & multi-location business analytics</div>
                </div>
              </div>

              <Link
                href="/demo"
                className="block w-full text-center py-3 px-4 rounded-xl font-bold bg-[#142219] text-white hover:bg-black transition text-sm"
              >
                Book an ERP Demo
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ================= FLORIST-SPECIFIC FEATURES ================= */}
      <section className="py-24 px-6 bg-white border-y border-[#d9dfd7]" id="features">
        <div className="max-w-6xl mx-auto">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <Eyebrow>Florist-First Capabilities</Eyebrow>
            <h2 className="text-3xl md:text-5xl font-serif font-normal text-[#142219] mt-3 mb-4 leading-tight">
              Designed around how florists actually work.
            </h2>
            <p className="text-gray-600 text-lg leading-relaxed">
              Every feature in Floraprise is built for the unique demands of floral retail, perishables, and event execution.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((f, idx) => (
              <div
                key={idx}
                className="p-6 rounded-2xl bg-[#f5f6f1] border border-[#d9dfd7] hover:border-[#25784a] transition flex flex-col justify-between"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <span className="text-2xl">{f.icon}</span>
                    <span className="text-[11px] font-bold uppercase tracking-wider text-[#25784a] bg-white px-2.5 py-1 rounded-md border border-[#d9dfd7]">
                      {f.tag}
                    </span>
                  </div>
                  <h3 className="text-xl font-serif font-normal text-[#142219] mb-2">{f.title}</h3>
                  <p className="text-gray-600 text-sm leading-relaxed">{f.desc}</p>
                </div>
              </div>
            ))}
          </div>

          <div className="text-center mt-12">
            <Link href="/features" className="inline-flex items-center gap-2 font-bold text-[#124e2c] text-base hover:underline">
              Explore the detailed features breakdown <span>→</span>
            </Link>
          </div>
        </div>
      </section>

      {/* ================= SOLO / PRO / ERP COMPARISON MATRIX ================= */}
      <section className="py-24 px-6 bg-[#f5f6f1]" id="comparison">
        <div className="max-w-6xl mx-auto">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <Eyebrow>Edition Comparison</Eyebrow>
            <h2 className="text-3xl md:text-5xl font-serif font-normal text-[#142219] mt-3 mb-4 leading-tight">
              Find the right match for your shop.
            </h2>
            <p className="text-gray-600 text-lg leading-relaxed">
              Transparent feature availability across Floraprise Solo, Pro, and ERP.
            </p>
          </div>

          <div className="overflow-x-auto bg-white rounded-2xl border border-[#d9dfd7] shadow-xs">
            <table className="w-full text-left text-sm border-collapse min-w-[650px]">
              <thead>
                <tr className="bg-[#e6ede5] text-[#142219] border-b border-[#d9dfd7]">
                  <th className="py-4 px-6 font-bold text-base">Feature / Capability</th>
                  <th className="py-4 px-6 font-bold text-center w-1/4">Solo</th>
                  <th className="py-4 px-6 font-bold text-center w-1/4 bg-[#124e2c] text-white">
                    Pro (Everyday Cloud)
                  </th>
                  <th className="py-4 px-6 font-bold text-center w-1/4">ERP (Advanced)</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#d9dfd7] text-gray-700">
                {comparisonRows.map((row, index) => (
                  <tr key={index} className="hover:bg-[#f9faf8] transition">
                    <td className="py-3.5 px-6 font-medium text-[#142219]">{row.feature}</td>
                    <td className="py-3.5 px-6 text-center text-gray-600">{row.solo}</td>
                    <td className="py-3.5 px-6 text-center font-bold text-[#124e2c] bg-[#e6ede5]/40">
                      {row.pro}
                    </td>
                    <td className="py-3.5 px-6 text-center text-gray-800">{row.erp}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex flex-col sm:flex-row justify-center items-center gap-4 mt-10">
            <Link
              href="/pricing"
              className="bg-[#124e2c] text-white px-8 py-3.5 rounded-xl font-bold text-sm hover:bg-[#0b3c20] transition shadow-xs"
            >
              View Floraprise Pro Pricing <span>→</span>
            </Link>
            <Link
              href="/demo"
              className="bg-white text-[#142219] border border-[#d9dfd7] px-8 py-3.5 rounded-xl font-bold text-sm hover:border-[#25784a] transition"
            >
              Book an ERP Demo
            </Link>
          </div>
        </div>
      </section>

      {/* ================= FAQ SECTION ================= */}
      <section className="py-24 px-6 bg-white border-b border-[#d9dfd7]" id="faq">
        <div className="max-w-4xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-16">
            <Eyebrow>Got Questions?</Eyebrow>
            <h2 className="text-3xl md:text-4xl font-serif font-normal text-[#142219] mt-3 mb-4">
              Frequently Asked Questions
            </h2>
            <p className="text-gray-600">
              Clear answers about Floraprise editions, devices, and operations.
            </p>
          </div>

          <div className="space-y-4">
            {faqs.map((faq, idx) => {
              const isOpen = openFaq === idx;
              return (
                <div
                  key={idx}
                  className="border border-[#d9dfd7] rounded-2xl bg-[#f5f6f1] overflow-hidden transition hover:border-[#25784a]"
                >
                  <button
                    type="button"
                    onClick={() => toggleFaq(idx)}
                    className="w-full text-left py-4 px-6 font-bold text-base text-[#142219] flex justify-between items-center focus:outline-hidden"
                  >
                    <span>{faq.q}</span>
                    <span className="text-[#124e2c] text-xl font-extrabold ml-4">
                      {isOpen ? "−" : "+"}
                    </span>
                  </button>
                  {isOpen && (
                    <div className="px-6 pb-5 pt-1 text-gray-600 text-sm leading-relaxed border-t border-[#d9dfd7]/60">
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
      <section className="py-20 lg:py-24 px-6 bg-[#103721] text-white text-center">
        <div className="max-w-4xl mx-auto">
          <span className="text-[#88c29d] text-xs font-extrabold uppercase tracking-widest block mb-3">
            Bring your whole flower business together
          </span>
          <h2 className="text-3xl sm:text-4xl md:text-5xl font-serif font-normal mb-4 max-w-2xl mx-auto leading-tight">
            Ready to run a simpler, smarter florist business?
          </h2>
          <p className="text-[#bfd0c4] text-base md:text-lg max-w-xl mx-auto mb-8 leading-relaxed">
            Join florists who manage their counter sales, perishables, orders, and deliveries seamlessly with Floraprise.
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              href="/pricing"
              className="bg-white text-[#124e2c] px-8 py-4 rounded-xl font-bold hover:bg-[#e6ede5] transition shadow-md text-sm inline-flex items-center gap-2"
              style={{ color: "#124e2c" }}
            >
              <span>Explore Pro Pricing</span> <span>→</span>
            </Link>
            <Link
              href="/demo"
              className="border border-[#607d69] bg-transparent text-white px-8 py-4 rounded-xl font-bold hover:bg-white/10 transition text-sm inline-flex items-center gap-2"
            >
              <span>Book a Live Demo</span> <span>↗</span>
            </Link>
          </div>
        </div>
      </section>
    </main>
  );
}
