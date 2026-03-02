import Link from "next/link";

export default function FinalCTA() {
  return (
    <section className="py-24 bg-[var(--brand-green)] text-white text-center">
      <div className="max-w-6xl mx-auto px-6 text-center">
        <h2 className="text-3xl md:text-4xl font-semibold">
          Built for Florists Who Refuse to Operate Average
        </h2>

        <p className="mt-6 text-gray-300 text-lg leading-relaxed">
          Floraprise is not generic software.
          It is a refined operational platform for flower businesses
          that demand control, precision, and growth.
        </p>

        <Link
          href="/demo"
          className="inline-block mt-12 bg-gradient-to-r from-[#c8a34d] to-[#e2c27d] text-black px-10 py-4 rounded-xl text-lg font-semibold hover:opacity-90 transition shadow-xl"
        >
          Schedule Executive Demo
        </Link>
      </div>
    </section>
  );
}