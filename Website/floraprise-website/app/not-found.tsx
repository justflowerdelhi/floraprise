import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: { absolute: "Page Not Found | Floraprise" },
  robots: null,
};

export default function NotFound() {
  return (
    <section className="py-24 px-6 text-center">
      <h1 className="text-3xl font-bold mb-4">Page not found</h1>
      <p className="text-gray-600 mb-8">
        The page you are looking for does not exist or has moved.
      </p>
      <Link
        href="/"
        className="inline-block bg-green-700 text-white px-6 py-3 rounded-lg"
      >
        Back to Floraprise
      </Link>
    </section>
  );
}
