import Link from "next/link";

export default function FinalPremiumCTA() {
  return (
    <section className="bg-white py-28 text-center border-t border-gray-100">
      <div className="max-w-6xl mx-auto px-6">

        <h2 className="text-3xl md:text-4xl font-semibold">
          For Florists Who Refuse to Operate Average.
        </h2>

        <p className="mt-6 text-gray-600">
          If you are ready to modernize your operations,
          we invite you to experience Floraprise privately.
        </p>

        <Link
          href="/demo"
          className="inline-block mt-10 bg-gradient-to-r from-[#c8a34d] to-[#e2c27d] text-black px-10 py-4 rounded-xl font-semibold shadow-lg"
        >
          Schedule Executive Demo
        </Link>

      </div>
    </section>
  );
}