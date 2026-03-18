"use client"

import { useEffect, useState } from "react"

export default function InventoryPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [qty, setQty] = useState<Record<string, number>>({});
  const [loading, setLoading] = useState("");

  useEffect(() => {
    fetch("/api/admin/products")
      .then(res => res.json())
      .then(data => setProducts(data));
  }, []);

  const handleQtyChange = (id: string, value: string) => {
    setQty(q => ({ ...q, [id]: Number(value) }));
  };

  const updateStock = async (variantId: string, value: number) => {
    setLoading(variantId);
    await fetch(`/api/admin/variants/${variantId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ stock: value })
    });
    setLoading("");
    // Refresh products
    fetch("/api/admin/products")
      .then(res => res.json())
      .then(data => setProducts(data));
  };

  const updateProductStock = async (productId: string, value: number) => {
    setLoading(productId);
    await fetch(`/api/admin/products?id=${productId}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ stock: value })
    });
    setLoading("");
    fetch("/api/admin/products")
      .then(res => res.json())
      .then(data => setProducts(data));
  };

  return (
    <div className="max-w-6xl mx-auto">
      <h1 className="text-2xl font-bold mb-6">Inventory</h1>
      <div className="bg-white border rounded overflow-x-auto">
        <table className="w-full min-w-[700px]">
          <thead className="bg-gray-100">
            <tr>
              <th className="p-3 text-left">Product</th>
              <th className="p-3 text-left">Variant</th>
              <th className="p-3 text-left">Category</th>
              <th className="p-3 text-left">Price</th>
              <th className="p-3 text-left">Stock</th>
              <th className="p-3 text-left">Update Qty</th>
              <th className="p-3 text-left">Status</th>
            </tr>
          </thead>
          <tbody>
            {products.map((p: any) => {
              if (p.variants && p.variants.length > 0) {
                return p.variants.map((v: any, i: number) => (
                  <tr key={p.id + "-" + v.id} className="border-t">
                    <td className="p-3">{i === 0 ? p.name : ""}</td>
                    <td className="p-3">{v.name}</td>
                    <td className="p-3">{i === 0 ? p.category?.name : ""}</td>
                    <td className="p-3">₹{v.price ?? p.price}</td>
                    <td className="p-3">{v.stock}</td>
                    <td className="p-3">
                      <input
                        type="number"
                        className="border rounded p-1 w-20"
                        value={qty[v.id] ?? v.stock}
                        onChange={e => handleQtyChange(v.id, e.target.value)}
                        min={0}
                      />
                      <button
                        className="ml-2 px-2 py-1 bg-blue-600 text-white rounded text-xs"
                        disabled={loading === v.id}
                        onClick={() => updateStock(v.id, qty[v.id] ?? v.stock)}
                      >
                        {loading === v.id ? "Updating..." : "Update"}
                      </button>
                    </td>
                    <td className="p-3">
                      {v.stock < 5 ? (
                        <span className="text-red-500">Low Stock</span>
                      ) : (
                        <span className="text-green-600">In Stock</span>
                      )}
                    </td>
                  </tr>
                ));
              } else {
                return (
                  <tr key={p.id} className="border-t">
                    <td className="p-3">{p.name}</td>
                    <td className="p-3 text-gray-400">—</td>
                    <td className="p-3">{p.category?.name}</td>
                    <td className="p-3">₹{p.price}</td>
                    <td className="p-3">{p.stock}</td>
                    <td className="p-3">
                      <input
                        type="number"
                        className="border rounded p-1 w-20"
                        value={qty[p.id] ?? p.stock}
                        onChange={e => handleQtyChange(p.id, e.target.value)}
                        min={0}
                      />
                      <button
                        className="ml-2 px-2 py-1 bg-blue-600 text-white rounded text-xs"
                        disabled={loading === p.id}
                        onClick={() => updateProductStock(p.id, qty[p.id] ?? p.stock)}
                      >
                        {loading === p.id ? "Updating..." : "Update"}
                      </button>
                    </td>
                    <td className="p-3">
                      {p.stock < 5 ? (
                        <span className="text-red-500">Low Stock</span>
                      ) : (
                        <span className="text-green-600">In Stock</span>
                      )}
                    </td>
                  </tr>
                );
              }
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}