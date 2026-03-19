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

    await fetch(`/api/admin/products/${id}`, {
      method: "DELETE",
    });

    fetchProducts();
  };

  return (

    <div className="max-w-6xl mx-auto space-y-6">

      <div className="flex justify-between items-center">

        <h1 className="text-2xl font-bold">
          Products
        </h1>

        <a
          href="/admin/catalogue/new"
          className="bg-pink-600 text-white px-4 py-2 rounded"
        >
          + Add Product
        </a>

      </div>

      <div className="bg-white border rounded-xl overflow-hidden">

        <table className="w-full">

          <thead className="bg-gray-100">
            <tr>
              <th className="p-3 text-left">Image</th>
              <th className="p-3 text-left">Product</th>
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

                <tr className="font-semibold bg-gray-50 border-t">
                  <td className="p-2">
                    <img
                      src={p.images?.[0]?.url || "/no-image.png"}
                      className="w-12 h-12 object-cover rounded"
                    />
                  </td>
                  <td className="p-3">{p.name}</td>
                  <td className="p-3">{p.category?.name}</td>
                  <td className="p-3">₹{p.price}</td>
                  <td className="p-3">{p.stock}</td>
                  <td className="p-3">{p.status}</td>
                  <td className="p-3">
                    <button
                      onClick={() => deleteProduct(p.id)}
                      className="text-red-600 text-sm"
                    >
                      Delete
                    </button>
                  </td>
                </tr>

                {/* VARIANTS */}

                {p.variants?.map((v:any) => {
                  const optionValues =
                    v.options?.map((o:any)=>o.value).join(" / ") || "-";
                  const price =
                    v.options?.find((o:any)=>o.price !== null)?.price ?? "-";
                  const stock =
                    v.options?.find((o:any)=>o.stock !== null)?.stock ?? "-";
                  const image =
                    v.image || p.images?.[0]?.url || "/no-image.png";
                  return (
                    <tr key={v.id} className="bg-gray-50 text-sm">
                      <td className="p-2">
                        <img
                          src={image}
                          className="w-10 h-10 object-cover rounded"
                        />
                      </td>
                      <td className="pl-6 text-gray-700">
                        {p.name} ({optionValues})
                      </td>
                      <td></td>
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