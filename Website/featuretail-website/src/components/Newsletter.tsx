export default function Newsletter() {
  return (
    <section className="py-14 bg-pink-50 text-center">
      <h2 className="text-2xl font-bold mb-4">
        Join Our Creative Community
      </h2>
      <p className="text-gray-600 mb-6">
        Get new craft ideas, product launches and special offers.
      </p>
      <div className="flex justify-center gap-2">
        <input
          type="email"
          placeholder="Enter your email"
          className="border px-4 py-2 rounded w-64"
        />
        <button className="bg-pink-600 text-white px-5 py-2 rounded">
          Subscribe
        </button>
      </div>
    </section>
  );
}
