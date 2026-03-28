import React, { useEffect, useState } from "react";
import { getInventoryLedger } from "../../api/inventory.api";
import { searchProducts } from "../../api/product.api";

interface LedgerEntry {
  createdAtUtc: string;
  reference: string;
  referenceType: string;
  quantityChange: number;
  balanceAfter: number;
  notes?: string;
}

interface ProductOption {
  id: string;
  name: string;
  stockQuantity: number;
}

const InventoryLedger = () => {
  const [products, setProducts] = useState<ProductOption[]>([]);
  const [productId, setProductId] = useState("");
  const [data, setData] = useState<LedgerEntry[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [searched, setSearched] = useState(false);

  useEffect(() => {
    searchProducts({ PageSize: 200 })
      .then((res) => {
        const items: ProductOption[] = (res.items ?? res).map((p: any) => ({
          id: p.id,
          name: p.name,
          stockQuantity: p.stockQuantity ?? 0,
        }));
        setProducts(items);
      })
      .catch(() => {
        // products list optional; user can still type ID manually
      });
  }, []);

  const load = async () => {
    if (!productId) return;
    setLoading(true);
    setError(null);
    setSearched(true);
    try {
      const res = await getInventoryLedger(productId);
      setData(Array.isArray(res) ? res : []);
    } catch (err: any) {
      setError(
        err?.response?.data?.message ??
          err?.message ??
          "Failed to load ledger. Make sure the backend is running."
      );
      setData([]);
    } finally {
      setLoading(false);
    }
  };

  const selectedProduct = products.find((p) => p.id === productId);

  return (
    <div className="p-6">
      <h1 className="text-xl font-semibold mb-4">Inventory Ledger</h1>

      <div className="flex gap-2 mb-4 flex-wrap">
        {products.length > 0 ? (
          <select
            value={productId}
            onChange={(e) => setProductId(e.target.value)}
            className="border px-3 py-2 rounded w-80"
          >
            <option value="">— Select a product —</option>
            {products.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name} (stock: {p.stockQuantity})
              </option>
            ))}
          </select>
        ) : (
          <input
            placeholder="Enter Product ID (UUID)"
            value={productId}
            onChange={(e) => setProductId(e.target.value)}
            className="border px-3 py-2 rounded w-80"
          />
        )}

        <button
          onClick={load}
          disabled={!productId || loading}
          className="bg-purple-600 text-white px-4 py-2 rounded disabled:opacity-50"
        >
          {loading ? "Loading…" : "Load"}
        </button>
      </div>

      {error && (
        <div className="mb-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded text-sm">
          {error}
        </div>
      )}

      {searched && !loading && !error && data.length === 0 && (
        <div className="mb-4 p-3 bg-yellow-50 border border-yellow-200 text-yellow-700 rounded text-sm">
          No ledger entries found for{" "}
          {selectedProduct ? `"${selectedProduct.name}"` : "this product"}.
          Ledger entries are created when stock changes through purchases, sales, and adjustments.
        </div>
      )}

      {data.length > 0 && (
        <table className="w-full border text-sm">
          <thead>
            <tr className="bg-gray-100 text-left">
              <th className="p-2">Date</th>
              <th className="p-2">Reference</th>
              <th className="p-2">Type</th>
              <th className="p-2 text-right">Qty Change</th>
              <th className="p-2 text-right">Balance After</th>
              <th className="p-2">Notes</th>
            </tr>
          </thead>
          <tbody>
            {data.map((row, i) => (
              <tr key={i} className="border-t hover:bg-gray-50">
                <td className="p-2 whitespace-nowrap">
                  {new Date(row.createdAtUtc).toLocaleString()}
                </td>
                <td className="p-2">{row.reference}</td>
                <td className="p-2">
                  <span className="px-2 py-0.5 rounded text-xs bg-gray-100">
                    {row.referenceType}
                  </span>
                </td>
                <td
                  className={`p-2 text-right font-medium ${
                    row.quantityChange < 0 ? "text-red-600" : "text-green-600"
                  }`}
                >
                  {row.quantityChange > 0 ? "+" : ""}
                  {row.quantityChange}
                </td>
                <td className="p-2 text-right">{row.balanceAfter}</td>
                <td className="p-2 text-gray-500 text-xs">{row.notes ?? "—"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
};

export default InventoryLedger;
