"use client";

export default function CatalogueError({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="p-6 space-y-3">
      <h1 className="text-2xl font-bold">Something went wrong</h1>
      <p className="text-sm text-gray-600">{error?.message || "Unable to load catalogue."}</p>
      <button
        className="px-4 py-2 bg-pink-600 text-white rounded"
        onClick={() => reset()}
      >
        Retry
      </button>
    </div>
  );
}
