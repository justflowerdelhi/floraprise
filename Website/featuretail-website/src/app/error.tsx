"use client";

export default function Error({ error, reset }: { error: Error; reset: () => void }) {
  return (
    <div className="p-6">
      <h1 className="text-xl font-bold mb-3">Something went wrong</h1>
      <p className="mb-4 text-sm text-gray-600">{error.message}</p>
      <button
        className="px-4 py-2 bg-pink-600 text-white rounded"
        onClick={() => reset()}
      >
        Try again
      </button>
    </div>
  );
}
