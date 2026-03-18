"use client";

import { useEffect, useState } from "react";
import React from "react";

export default function ProductsPage() {

  const [products, setProducts] = useState<any[]>([]);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    const res = await fetch("/api/admin/products");
    const data = await res.json();

    console.log("PRODUCT DATA:", data);

    setProducts(data);
  };

  const deleteProduct = async (id: string) => {

    if (!confirm("Delete product?")) return;

    await fetch(`/api/admin/products?id=${id}`, {
      method: "DELETE",
    });

    fetchProducts();
  };

  return (

    <div className="max-w-6xl mx-auto space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-center gap-4">
        <h1 className="text-2xl font-bold">Products</h1>
        <a
          href="/admin/catalogue/new"
          className="bg-pink-600 text-white px-4 py-2 rounded"
        >
          + Add Product
        </a>
      </div>
      <div className="bg-white border rounded-xl overflow-x-auto">
        <table className="w-full min-w-[700px]">
          <thead className="bg-gray-100">
            <tr>
              <th className="p-3 text-left">Image</th>
              <th className="p-3 text-left">Product</th>
              <th className="p-3 text-left">Variant</th>
              <th className="p-3 text-left">Category</th>
              <th className="p-3 text-left">Price</th>
              <th className="p-3 text-left">Stock</th>
              <th className="p-3 text-left">Status</th>
              <th className="p-3 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {products.map((p) => (
              <React.Fragment key={p.id}>
                {/* PRODUCT ROW */}
                <tr className="font-semibold bg-gray-50 hover:bg-gray-100 transition">
                  <td className="p-2 w-20">
                    {p.images && p.images.length > 0 ? (
                      <img src={p.images[0].url} alt={p.name} className="w-14 h-14 object-cover rounded border" />
                    ) : (
                      <div className="w-14 h-14 bg-gray-200 flex items-center justify-center rounded border text-xs text-gray-400">No Image</div>
                    )}
                  </td>
                  <td className="p-2">{p.name}</td>
                  <td className="p-2 text-gray-400 italic">—</td>
                  <td className="p-2">{p.category?.name || <span className='text-gray-400'>-</span>}</td>
                  <td className="p-2">₹{p.price}</td>
                  <td className="p-2">{p.stock}</td>
                  <td className="p-2">{p.status}</td>
                  <td className="p-2 flex flex-wrap gap-2">
                    <a href={`/admin/catalogue/products/${p.id}`} className="text-blue-600 text-xs underline">View</a>
                    <a href={`/admin/catalogue/products/${p.id}/edit`} className="text-green-600 text-xs underline">Edit</a>
                    <button
                      onClick={() => deleteProduct(p.id)}
                      className="text-red-600 text-xs underline"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
                {/* VARIANT ROWS */}
                {p.variants && p.variants.length > 0 && p.variants.map((v:any) => {
                  const price =
                    v.options?.find((o:any)=>o.price !== null)?.price ?? "-";
                  const stock =
                    v.options?.find((o:any)=>o.stock !== null)?.stock ?? "-";
                  const optionValues =
                    v.options?.map((o:any)=>o.value).join(" / ") ?? "Variant";
                  return (
                    <tr key={v.id} className="text-sm text-gray-600 bg-gray-50">
                      <td></td>
                      <td></td>
                      <td className="pl-4">{optionValues}</td>
                      <td>-</td>
                      <td>₹{price}</td>
                      <td>{stock}</td>
                      <td>-</td>
                      <td></td>
                    </tr>
                  );
                })}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>

  );
}