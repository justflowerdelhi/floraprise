"use client";

import { useEffect, useState } from "react";
import React from "react";
import Link from "next/link";

export default function CataloguePage() {
  const [products, setProducts] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [viewProduct, setViewProduct] = useState<any | null>(null);
  const [viewVariant, setViewVariant] = useState<any | null>(null);
  const [editVariant, setEditVariant] = useState<any | null>(null);
  const [deleteVariant, setDeleteVariant] = useState<any | null>(null);

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

    await fetch(`/api/admin/products?id=${id}`, {
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
            {filteredProducts.map((product) => {
              const hasVariants = product.variants && product.variants.length > 0;
              if (!hasVariants) {
                return (
                  <tr key={product.id} className="border-b hover:bg-gray-50">
                    <td className="p-3 align-middle">
                      {product.images?.[0]?.url ? (
                        <img src={product.images[0].url} className="w-10 h-10 rounded" />
                      ) : (
                        <div className="w-10 h-10 rounded bg-gray-200 flex items-center justify-center text-xs text-gray-400">—</div>
                      )}
                    </td>
                    <td className="p-3 align-middle">{product.name}</td>
                    <td className="p-3 align-middle text-gray-400">No variants</td>
                    <td className="p-3 align-middle">{product.category?.name || "-"}</td>
                    <td className="p-3 align-middle">₹{product.price}</td>
                    <td className="p-3 align-middle">{product.stock}</td>
                    <td className="p-3 align-middle">
                      {product.status === "published" ? (
                        <span className="text-green-600">Published</span>
                      ) : (
                        <span className="text-gray-500">Draft</span>
                      )}
                    </td>
                    <td className="p-3 text-right space-x-4 align-middle">
                      <button
                        onClick={() => setViewProduct(product)}
                        className="text-green-600 hover:underline"
                      >
                        View
                      </button>
                      <Link
                        href={`/admin/catalogue/edit/${product.id}`}
                        className="text-blue-600 hover:underline"
                      >
                        Edit
                      </Link>
                      <button
                        onClick={() => deleteProduct(product.id)}
                        className="text-red-600 hover:underline"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                );
              }
              return product.variants.map((v: any, i: number) => (
                <tr key={product.id + "-variant-" + v.id} className="border-b hover:bg-gray-50">
                  <td className="p-3 align-middle">
                    {i === 0 ? (
                      product.images?.[0]?.url ? (
                        <img src={product.images[0].url} className="w-10 h-10 rounded" />
                      ) : (
                        <div className="w-10 h-10 rounded bg-gray-200 flex items-center justify-center text-xs text-gray-400">—</div>
                      )
                    ) : ""}
                  </td>
                  <td className="p-3 align-middle">{i === 0 ? product.name : ""}</td>
                  <td className="p-3 align-middle">
                    <div className="flex items-center gap-2">
                      {v.images?.[0]?.url ? (
                        <img src={v.images[0].url} className="w-6 h-6 rounded" />
                      ) : (
                        <div className="w-6 h-6 rounded bg-gray-200 flex items-center justify-center text-xs text-gray-400">—</div>
                      )}
                      <span className="font-medium">{v.name}</span>
                      <span className="ml-2 flex gap-2">
                        <button className="text-green-600 hover:underline" onClick={() => setViewVariant(v)}>View</button>
                        <button className="text-blue-600 hover:underline" onClick={() => setEditVariant(v)}>Edit</button>
                        <button className="text-red-600 hover:underline" onClick={() => setDeleteVariant(v)}>Delete</button>
                      </span>
                    </div>
                  </td>
                        {/* Variant Details Modal */}
                        {viewVariant && (
                          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40">
                            <div className="bg-white rounded-lg shadow-lg max-w-sm w-full p-6 relative">
                              <button
                                className="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl"
                                onClick={() => setViewVariant(null)}
                              >
                                &times;
                              </button>
                              <h2 className="text-xl font-bold mb-4">Variant Details</h2>
                              <div className="flex gap-4 mb-4">
                                {viewVariant.images?.[0]?.url && (
                                  <img src={viewVariant.images[0].url} className="w-20 h-20 rounded object-cover border" />
                                )}
                                <div>
                                  <div className="font-semibold text-lg">{viewVariant.name}</div>
                                  <div className="text-gray-700 text-sm">Price: ₹{viewVariant.price}</div>
                                  <div className="text-gray-700 text-sm">Stock: {viewVariant.stock}</div>
                                </div>
                              </div>
                            </div>
                          </div>
                        )}

                        {/* Variant Edit Modal (simple example) */}
                        {editVariant && (
                          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40">
                            <div className="bg-white rounded-lg shadow-lg max-w-sm w-full p-6 relative">
                              <button
                                className="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl"
                                onClick={() => setEditVariant(null)}
                              >
                                &times;
                              </button>
                              <h2 className="text-xl font-bold mb-4">Edit Variant</h2>
                              <form
                                onSubmit={e => {
                                  e.preventDefault();
                                  // Implement save logic here
                                  setEditVariant(null);
                                }}
                                className="space-y-4"
                              >
                                <div>
                                  <label className="block text-sm font-medium">Name</label>
                                  <input className="border rounded p-2 w-full" defaultValue={editVariant.name} />
                                </div>
                                <div>
                                  <label className="block text-sm font-medium">Price</label>
                                  <input className="border rounded p-2 w-full" type="number" defaultValue={editVariant.price} />
                                </div>
                                <div>
                                  <label className="block text-sm font-medium">Stock</label>
                                  <input className="border rounded p-2 w-full" type="number" defaultValue={editVariant.stock} />
                                </div>
                                <div className="flex justify-end gap-2">
                                  <button type="button" className="px-4 py-2 rounded bg-gray-200" onClick={() => setEditVariant(null)}>Cancel</button>
                                  <button type="submit" className="px-4 py-2 rounded bg-blue-600 text-white">Save</button>
                                </div>
                              </form>
                            </div>
                          </div>
                        )}

                        {/* Variant Delete Confirmation */}
                        {deleteVariant && (
                          <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40">
                            <div className="bg-white rounded-lg shadow-lg max-w-xs w-full p-6 relative">
                              <button
                                className="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl"
                                onClick={() => setDeleteVariant(null)}
                              >
                                &times;
                              </button>
                              <h2 className="text-lg font-bold mb-4">Delete Variant</h2>
                              <div className="mb-4">Are you sure you want to delete <span className="font-semibold">{deleteVariant.name}</span>?</div>
                              <div className="flex justify-end gap-2">
                                <button className="px-4 py-2 rounded bg-gray-200" onClick={() => setDeleteVariant(null)}>Cancel</button>
                                <button className="px-4 py-2 rounded bg-red-600 text-white" onClick={() => { setDeleteVariant(null); /* Implement delete logic here */ }}>Delete</button>
                              </div>
                            </div>
                          </div>
                        )}
                  <td className="p-3 align-middle">{i === 0 ? (product.category?.name || "-") : ""}</td>
                  <td className="p-3 align-middle">₹{v.price ?? product.price}</td>
                  <td className="p-3 align-middle">{v.stock ?? product.stock}</td>
                  <td className="p-3 align-middle">{i === 0 ? (
                    product.status === "published" ? (
                      <span className="text-green-600">Published</span>
                    ) : (
                      <span className="text-gray-500">Draft</span>
                    )
                  ) : ""}</td>
                  <td className="p-3 text-right space-x-4 align-middle">{i === 0 ? (
                    <>
                      <button
                        onClick={() => setViewProduct(product)}
                        className="text-green-600 hover:underline"
                      >
                        View
                      </button>
                      <Link
                        href={`/admin/catalogue/edit/${product.id}`}
                        className="text-blue-600 hover:underline"
                      >
                        Edit
                      </Link>
                      <button
                        onClick={() => deleteProduct(product.id)}
                        className="text-red-600 hover:underline"
                      >
                        Delete
                      </button>
                    </>
                  ) : ""}</td>
                      {/* Product Details Modal */}
                      {viewProduct && (
                        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40">
                          <div className="bg-white rounded-lg shadow-lg max-w-lg w-full p-6 relative">
                            <button
                              className="absolute top-2 right-2 text-gray-400 hover:text-gray-600 text-xl"
                              onClick={() => setViewProduct(null)}
                            >
                              &times;
                            </button>
                            <h2 className="text-xl font-bold mb-4">Product Details</h2>
                            <div className="flex gap-4 mb-4">
                              {viewProduct.images?.[0]?.url && (
                                <img src={viewProduct.images[0].url} className="w-24 h-24 rounded object-cover border" />
                              )}
                              <div>
                                <div className="font-semibold text-lg">{viewProduct.name}</div>
                                <div className="text-gray-600 text-sm mb-2">{viewProduct.category?.name || "-"}</div>
                                <div className="text-gray-700 text-sm mb-2">{viewProduct.description}</div>
                                <div className="text-gray-700 text-sm">Price: ₹{viewProduct.price}</div>
                                <div className="text-gray-700 text-sm">Stock: {viewProduct.stock}</div>
                                <div className="text-gray-700 text-sm">Status: {viewProduct.status}</div>
                              </div>
                            </div>
                            <div>
                              <div className="font-semibold mb-2">Variants:</div>
                              {viewProduct.variants && viewProduct.variants.length > 0 ? (
                                <ul className="space-y-2">
                                  {viewProduct.variants.map((v: any) => (
                                    <li key={v.id} className="flex items-center gap-2 text-sm">
                                      {v.images?.[0]?.url ? (
                                        <img src={v.images[0].url} className="w-8 h-8 rounded object-cover border" />
                                      ) : (
                                        <div className="w-8 h-8 rounded bg-gray-200 flex items-center justify-center text-xs text-gray-400">—</div>
                                      )}
                                      <span className="font-medium">{v.name}</span>
                                      <span>₹{v.price}</span>
                                      <span>Stock: {v.stock}</span>
                                      <span className="ml-2 flex gap-2">
                                        <button className="text-green-600 hover:underline" onClick={() => alert(`View variant: ${v.name}`)}>View</button>
                                        <button className="text-blue-600 hover:underline" onClick={() => alert(`Edit variant: ${v.name}`)}>Edit</button>
                                        <button className="text-red-600 hover:underline" onClick={() => alert(`Delete variant: ${v.name}`)}>Delete</button>
                                      </span>
                                    </li>
                                  ))}
                                </ul>
                              ) : (
                                <div className="text-gray-400">No variants</div>
                              )}
                            </div>
                          </div>
                        </div>
                      )}
                </tr>
              ));
            })}
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