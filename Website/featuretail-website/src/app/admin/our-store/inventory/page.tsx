"use client";

import { useEffect, useMemo, useState } from "react";
import InventoryStats from "@/components/InventoryStats";

// SKU Generator
function generateSKU(name: string, color: string, size: string) {
  const n = name.toUpperCase().replace(/[^A-Z0-9 ]/g, "").split(" ").slice(0, 3).join("");
  const c = color?.toUpperCase().slice(0, 3) || "";
  const s = size?.toUpperCase().replace(/[^A-Z0-9]/g, "") || "";
  return [n, c, s].filter(Boolean).join("-");
}

export default function InventoryPage() {

  // ✅ STATES
  const [data, setData] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [suggestions, setSuggestions] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);

  const [form, setForm] = useState({
    sku: "",
    productName: "",
    color: "",
    size: "",
    stock: "0",
    purchasePrice: "",
    supplier: "",
    storageLocation: "",
    lowStockThreshold: "5",
  });

  // ✅ LOAD DATA
  useEffect(() => {
    fetch("/api/admin/inventory")
      .then((res) => res.json())
      .then(setData);
  }, []);

  // ✅ AUTO SKU
  useEffect(() => {
    const sku = generateSKU(form.productName, form.color, form.size);
    setForm((prev) => ({ ...prev, sku }));
  }, [form.productName, form.color, form.size]);

  // ✅ SEARCH + SUGGESTIONS
  useEffect(() => {
    if (!search) return setSuggestions([]);

    const q = search.toLowerCase();

    const result = data.filter((item) =>
      item.sku.toLowerCase().includes(q) ||
      item.productName.toLowerCase().includes(q) ||
      (item.storageLocation || "").toLowerCase().includes(q)
    );

    setSuggestions(result.slice(0, 5));
  }, [search, data]);

  // ✅ UPDATE FIELD
  const updateField = async (id: string, field: string, value: any) => {
    await fetch(`/api/admin/inventory/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ [field]: value }),
    });

    setData((prev) =>
      prev.map((i) => (i.id === id ? { ...i, [field]: value } : i))
    );
  };

  // ✅ CREATE ITEM
  const handleCreate = async (e: any) => {
    e.preventDefault();

    await fetch("/api/admin/inventory", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ...form,
        stock: Number(form.stock),
        purchasePrice: form.purchasePrice ? Number(form.purchasePrice) : null,
        lowStockThreshold: Number(form.lowStockThreshold),
      }),
    });

    // Reset
    setForm({
      sku: "",
      productName: "",
      color: "",
      size: "",
      stock: "0",
      purchasePrice: "",
      supplier: "",
      storageLocation: "",
      lowStockThreshold: "5",
    });

    const updated = await fetch("/api/admin/inventory").then((r) => r.json());
    setData(updated);
    setShowForm(false);
  };

  // ✅ FILTER
  const filtered = data.filter((item) => {
    const q = search.toLowerCase();
    return (
      item.sku.toLowerCase().includes(q) ||
      item.productName.toLowerCase().includes(q) ||
      (item.storageLocation || "").toLowerCase().includes(q)
    );
  });

  // ✅ AUTOSUGGEST OPTIONS
  const supplierOptions = useMemo(
    () => [...new Set(data.map((i) => i.supplier).filter(Boolean))],
    [data]
  );

  const locationOptions = useMemo(
    () => [...new Set(data.map((i) => i.storageLocation).filter(Boolean))],
    [data]
  );

  return (
    <div className="p-6 bg-gray-50 min-h-screen">

      {/* HEADER */}
      <div className="flex justify-between mb-6">
        <h1 className="text-2xl font-bold">📦 Inventory</h1>
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-black text-white px-4 py-2 rounded"
        >
          + Add Item
        </button>
      </div>

      <InventoryStats data={data} />

      {/* FORM */}
      {showForm && (
        <form onSubmit={handleCreate} className="bg-white p-4 rounded mb-6 shadow">

          <input value={form.sku} readOnly className="border p-2 w-full mb-2 bg-gray-100" />

          <input placeholder="Product Name" className="border p-2 w-full mb-2"
            value={form.productName}
            onChange={(e) => setForm({ ...form, productName: e.target.value })}
          />

          <input placeholder="Color" className="border p-2 w-full mb-2"
            value={form.color}
            onChange={(e) => setForm({ ...form, color: e.target.value })}
          />

          <input placeholder="Size" className="border p-2 w-full mb-2"
            value={form.size}
            onChange={(e) => setForm({ ...form, size: e.target.value })}
          />

          <input type="number" placeholder="Stock" className="border p-2 w-full mb-2"
            value={form.stock}
            onChange={(e) => setForm({ ...form, stock: e.target.value })}
          />

          <input type="number" placeholder="Purchase Price" className="border p-2 w-full mb-2"
            value={form.purchasePrice}
            onChange={(e) => setForm({ ...form, purchasePrice: e.target.value })}
          />

          <input list="supplier-list" placeholder="Supplier" className="border p-2 w-full mb-2"
            value={form.supplier}
            onChange={(e) => setForm({ ...form, supplier: e.target.value })}
          />
          <datalist id="supplier-list">
            {supplierOptions.map((s, i) => (
              <option key={i} value={s} />
            ))}
          </datalist>

          <input list="location-list" placeholder="Location" className="border p-2 w-full mb-2"
            value={form.storageLocation}
            onChange={(e) => setForm({ ...form, storageLocation: e.target.value })}
          />
          <datalist id="location-list">
            {locationOptions.map((l, i) => (
              <option key={i} value={l} />
            ))}
          </datalist>

          <input type="number" placeholder="Low Stock Alert" className="border p-2 w-full mb-2"
            value={form.lowStockThreshold}
            onChange={(e) => setForm({ ...form, lowStockThreshold: e.target.value })}
          />

          <button className="bg-black text-white px-4 py-2 rounded">
            Save
          </button>
        </form>
      )}

      {/* SEARCH */}
      <div className="relative mb-4 w-80">
        <input
          className="w-full border rounded px-3 py-2"
          placeholder="Search SKU / Product / Location"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />

        {suggestions.length > 0 && (
          <div className="absolute bg-white border w-full mt-1 rounded shadow z-10">
            {suggestions.map((item) => (
              <div
                key={item.id}
                className="p-2 hover:bg-gray-100 cursor-pointer"
                onClick={() => {
                  setSearch(item.sku);
                  setSuggestions([]);
                }}
              >
                {item.productName}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* TABLE */}
      <table className="w-full bg-white border rounded">
        <thead>
          <tr className="bg-gray-100">
            <th className="p-2">SKU</th>
            <th className="p-2">Product</th>
            <th className="p-2">Location</th>
            <th className="p-2">Price</th>
            <th className="p-2">Stock</th>
            <th className="p-2">Value</th>
          </tr>
        </thead>

        <tbody>
          {filtered.map((item) => {
            const value = item.stock * (item.purchasePrice || 0);

            return (
              <tr key={item.id} className="border-t">
                <td className="p-2">{item.sku}</td>

                <td className="p-2">
                  <input defaultValue={item.productName}
                    onBlur={(e) => updateField(item.id, "productName", e.target.value)}
                  />
                </td>

                <td className="p-2">
                  <input defaultValue={item.storageLocation || ""}
                    onBlur={(e) => updateField(item.id, "storageLocation", e.target.value)}
                  />
                </td>

                <td className="p-2">
                  <input type="number" defaultValue={item.purchasePrice || 0}
                    onBlur={(e) => updateField(item.id, "purchasePrice", Number(e.target.value))}
                  />
                </td>

                <td className="p-2">
                  <input type="number" defaultValue={item.stock}
                    onBlur={(e) => updateField(item.id, "stock", Number(e.target.value))}
                  />
                </td>

                <td className="p-2 text-green-600 font-medium">
                  ₹ {value.toLocaleString()}
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}