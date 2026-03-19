"use client";

import { useEffect, useState } from "react";
import React from "react";
import Link from "next/link";

export default function CataloguePage() {
    // 🔥 ADD THIS FUNCTION
    const [saving, setSaving] = useState<string | null>(null);

    // 🔥 UPDATE FUNCTION
    const updateField = async (
      id: string,
      field: "stock" | "price",
      value: number,
      isVariant = false
    ) => {
      setSaving(id);
      await fetch("/api/admin/products/update-stock", {
        method: "POST",
        body: JSON.stringify({
          id,
          [field]: value,
          isVariant,
        }),
      });
      setSaving(null);
    };

    // Fix: Provide updateStock for inline stock editing
    const updateStock = (id: string, value: number, isVariant = false) =>
      updateField(id, "stock", value, isVariant);
  const [products, setProducts] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [expanded, setExpanded] = useState<string | null>(null);

  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    const res = await fetch("/api/admin/products", {
      cache: "no-store",
    });
    const data = await res.json();
    setProducts(Array.isArray(data) ? data : []);
  };

  const deleteProduct = async (id: string) => {
    if (!confirm("Delete this product?")) return;

    await fetch(`/api/admin/products/${id}`, {
      method: "DELETE",
    });

    fetchProducts();
  };

  const filteredProducts = products.filter((product) =>
    product.name.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">Catalogue</h1>

        <Link
          href="/admin/catalogue/new"
          className="bg-pink-600 text-white px-4 py-2 rounded"
        >
          + Add Product
        </Link>
      </div>

      {/* Search */}
      <input
        type="text"
        placeholder="Search product..."
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        className="w-full border p-2 rounded"
      />

      {/* Product Table */}
      <div className="bg-white rounded-xl shadow border overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="p-3 text-left">Image</th>
              <th className="p-3 text-left">Product</th>
              <th className="p-3 text-left">Variant</th>
              <th className="p-3 text-left">Category</th>
              <th className="p-3 text-left">Price</th>
              <th className="p-3 text-left">Stock</th>
              <th className="p-3 text-left">Status</th>
              <th className="p-3 text-right">Actions</th>
            </tr>
          </thead>

          <tbody>
            {filteredProducts.map((product) => (
              <React.Fragment key={product.id}>
                {/* PRODUCT ROW */}
                <tr
                  className="border-b bg-white hover:bg-gray-50 cursor-pointer"
                  onClick={() => setExpanded(expanded === product.id ? null : product.id)}
                >
                  <td className="p-3">
                    {product.images?.[0]?.url ? (
                      <img
                        src={product.images[0].url}
                        className="w-10 h-10 object-cover rounded"
                      />
                    ) : (
                      "—"
                    )}
                  </td>
                  <td className="p-3 font-medium">
                    {expanded === product.id ? "▼ " : "▶ "}
                    {product.name}
                  </td>
                  <td className="p-3">
                    {product.variants?.length || 0} variants
                  </td>
                  <td className="p-3">
                    {product.category?.name || "-"}
                  </td>
                  {/* 🔥 REPLACE PRODUCT PRICE CELL */}
                  <td className="p-3">
                    ₹
                    <input
                      type="number"
                      defaultValue={product.price}
                      className="w-20 border px-1 rounded ml-1"
                      onBlur={(e) =>
                        updateField(product.id, "price", Number(e.target.value))
                      }
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          (e.target as HTMLInputElement).blur();
                        }
                      }}
                    />
                  </td>
                  {/* 🔥 REPLACE PRODUCT STOCK CELL */}
                  <td className="p-3">
                    <input
                      type="number"
                      defaultValue={product.stock}
                      className="w-16 border px-1 rounded"
                      onBlur={(e) =>
                        updateStock(product.id, Number(e.target.value))
                      }
                      onKeyDown={(e) => {
                        if (e.key === "Enter") {
                          (e.target as HTMLInputElement).blur();
                        }
                      }}
                    />
                  </td>
                  <td className="p-3">
                    {product.status === "published" ? (
                      <span className="text-green-600">Published</span>
                    ) : (
                      <span className="text-gray-500">Draft</span>
                    )}
                  </td>
                  <td className="p-3 text-right space-x-3">
                    <Link href={`/admin/catalogue/edit/${product.id}`} className="text-blue-600">
                      Edit
                    </Link>
                    <button
                      onClick={e => {
                        e.stopPropagation();
                        deleteProduct(product.id);
                      }}
                      className="text-red-600"
                    >
                      Delete
                    </button>
                  </td>
                </tr>

                {/* VARIANT ROWS */}
                {expanded === product.id &&
                  product.variants?.map((v: any) => (
                    <tr key={v.id} className="bg-gray-50 border-b">
                      <td></td>
                      <td className="p-3 pl-10 flex items-center gap-2">
                        {v.images?.[0]?.url ? (
                          <img
                            src={v.images[0].url}
                            className="w-8 h-8 rounded"
                          />
                        ) : (
                          <div className="w-8 h-8 bg-gray-200 rounded" />
                        )}
                        {v.name}
                      </td>
                      <td></td>
                      <td></td>
                      {/* 🔥 REPLACE VARIANT PRICE CELL */}
                      <td className="p-3">
                        ₹
                        <input
                          type="number"
                          defaultValue={v.price ?? product.price}
                          className="w-20 border px-1 rounded ml-1"
                          onBlur={(e) =>
                            updateField(v.id, "price", Number(e.target.value), true)
                          }
                          onKeyDown={(e) => {
                            if (e.key === "Enter") {
                              (e.target as HTMLInputElement).blur();
                            }
                          }}
                        />
                      </td>
                      <td className="p-3">
                        <input
                          type="number"
                          defaultValue={v.stock}
                          className="w-16 border px-1 rounded"
                          onBlur={(e) =>
                            updateStock(v.id, Number(e.target.value), true)
                          }
                          onKeyDown={(e) => {
                            if (e.key === "Enter") {
                              (e.target as HTMLInputElement).blur();
                            }
                          }}
                        />
                        {saving === v.id && <span className="text-xs text-gray-400 ml-2">Saving...</span>}
                      </td>
                      <td></td>
                      <td className="p-3 text-right space-x-2">
                        <span className="text-blue-600 text-xs">Edit</span>
                        <span className="text-red-600 text-xs">Delete</span>
                      </td>
                    </tr>
                  ))}
              </React.Fragment>
            ))}
          </tbody>
        </table>

        {filteredProducts.length === 0 && (
          <div className="p-6 text-center text-gray-500">
            No products found.
          </div>
        )}
      </div>
    </div>
  );
}