"use client";

export default function GlobalError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <html>
      <body className="p-6">
        <h1 className="text-xl font-bold mb-3">App crashed</h1>
        <p className="mb-4 text-sm text-gray-600">{error.message}</p>
        <button
          className="px-4 py-2 bg-pink-600 text-white rounded"
          onClick={() => reset()}
        >
          Reload
        </button>
      </body>
    </html>
  );
}
