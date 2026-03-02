export default function ProductShowcase() {
  return (
    <section className="py-10 bg-white">
      <div className="max-w-6xl mx-auto px-6 text-center">

        <h2 className="text-3xl font-semibold mb-4">
          Operational Control in Action.
        </h2>

        <p className="text-gray-600 max-w-3xl mx-auto mb-8">
          Floraprise centralizes billing, inventory, production, and payment
          workflows into one structured operational interface built
          specifically for professional flower businesses.
        </p>

        <div className="flex justify-center">
          <img
            src="/images/floraprise-pos.png"
            alt="Floraprise POS system interface"
            className="rounded-2xl shadow-lg w-full max-w-4xl"
          />
        </div>

      </div>
    </section>
  );
}