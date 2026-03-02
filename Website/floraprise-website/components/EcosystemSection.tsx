import Image from "next/image";

export default function EcosystemSection() {
  return (
    <section className="py-28 bg-[#f9f8f5] text-center">
      <div className="max-w-6xl mx-auto px-6">

        <h2 className="text-3xl md:text-4xl font-semibold tracking-tight">
          A Complete Ecosystem for Your Florist
        </h2>

        <p className="mt-6 text-gray-600 max-w-3xl mx-auto">
          Floraprise connects inventory, production, retail,
          delivery, staff, and analytics into one intelligent
          operational platform.
        </p>

        <div className="mt-16 flex justify-center">
          <Image
            src="/floraprise-ecosystem.jpg"
            alt="Floraprise Ecosystem"
            width={700}
            height={700}
            className="rounded-3xl shadow-[0_30px_60px_-15px_rgba(0,0,0,0.15)]"
          />
        </div>

      </div>
    </section>
  );
}