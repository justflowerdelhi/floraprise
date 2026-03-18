"use client";

import { useEffect, useState } from "react";
import { useRouter, useParams } from "next/navigation";

export default function ProductViewPage() {
  const router = useRouter();
  const params = useParams();
  const id = params.id as string;
  const [product, setProduct] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!id) return;
    fetch(`/api/admin/products/${id}`)
      .then((res) => res.json())
      .then((data) => {
        setProduct(data);
        setLoading(false);
      });
  }, [id]);

  if (loading) return <div className="p-8">Loading...</div>;
  if (!product) return <div className="p-8 text-red-600">Product not found.</div>;

  return (
    <div className="max-w-3xl mx-auto p-6">
      <h1 className="text-2xl font-bold mb-4">{product.name}</h1>
      <div className="flex flex-col sm:flex-row gap-6">
        <div>
          {product.images && product.images.length > 0 ? (
            <img src={product.images[0].url} alt={product.name} className="w-48 h-48 object-cover rounded border" />
          ) : (
            <div className="w-48 h-48 bg-gray-200 flex items-center justify-center rounded border text-xs text-gray-400">No Image</div>
          )}
        </div>
        <div className="flex-1 space-y-2">
          <div><b>Category:</b> {product.category?.name || '-'}</div>
          <div><b>Price:</b> ₹{product.price}</div>
          <div><b>Stock:</b> {product.stock}</div>
          <div><b>Status:</b> {product.status}</div>
          <div><b>Description:</b> {product.description}</div>
        </div>
      </div>
      <button onClick={() => router.back()} className="mt-6 px-4 py-2 bg-gray-200 rounded">Back</button>
    </div>
  );
}
