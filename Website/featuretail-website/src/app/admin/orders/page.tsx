"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

export default function OrdersPage() {
  const [orders, setOrders] = useState<any[]>([]);

  useEffect(() => {
    fetchOrders();
  }, []);

  const fetchOrders = async () => {
    const res = await fetch("/api/admin/orders");
    const data = await res.json();
    setOrders(data || []);
  };

  /* ---------------- DELETE ---------------- */

  const deleteOrder = async (id: string) => {
    if (!confirm("Delete order?")) return;

    await fetch(`/api/admin/orders?id=${id}`, {
      method: "DELETE",
    });

    fetchOrders();
  };

  /* ---------------- STATUS ---------------- */

  const updateStatus = async (id: string, status: string) => {
    await fetch("/api/admin/orders/update-status", {
      method: "POST",
      body: JSON.stringify({ id, status }),
    });

    fetchOrders();
  };

  /* ---------------- DISPATCH ---------------- */

  const dispatchOrder = async (id: string) => {
    alert("Dispatch API (NimbusPost) will trigger here");
    // future: call shipping API
  };

  return (
    <div className="space-y-6">

      <div className="flex justify-between">
        <h1 className="text-2xl font-bold">Orders</h1>

        <Link
          href="/admin/orders/new"
          className="bg-pink-600 text-white px-4 py-2 rounded"
        >
          + Create Order
        </Link>
      </div>

      <div className="bg-white border rounded shadow overflow-x-auto">
        <table className="w-full text-sm">

          <thead className="bg-gray-50 border-b">
            <tr>
              <th className="p-3 text-left">Order ID</th>
              <th className="p-3 text-left">Customer</th>
              <th className="p-3 text-left">Total</th>
              <th className="p-3 text-left">Status</th>
              <th className="p-3 text-left">Date</th>
              <th className="p-3 text-right">Actions</th>
            </tr>
          </thead>

          <tbody>
            {orders.map((o) => (
              <tr key={o.id} className="border-b hover:bg-gray-50">

                <td className="p-3">#{o.id.slice(-6)}</td>

                <td className="p-3">
                  {o.shippingName || "-"}
                </td>

                <td className="p-3">₹{o.total}</td>

                <td className="p-3">
                  <select
                    value={o.status}
                    onChange={(e) =>
                      updateStatus(o.id, e.target.value)
                    }
                    className="border p-1"
                  >
                    <option value="pending">Pending</option>
                    <option value="confirmed">Confirmed</option>
                    <option value="shipped">Shipped</option>
                    <option value="delivered">Delivered</option>
                  </select>
                </td>

                <td className="p-3">
                  {new Date(o.createdAt).toLocaleDateString()}
                </td>

                <td className="p-3 text-right space-x-3">

                  <Link
                    href={`/admin/orders/${o.id}`}
                    className="text-blue-600"
                  >
                    View
                  </Link>

                  <button
                    onClick={() => deleteOrder(o.id)}
                    className="text-red-600"
                  >
                    Delete
                  </button>

                  <button
                    onClick={() => dispatchOrder(o.id)}
                    className="text-purple-600"
                  >
                    Dispatch
                  </button>

                  <button
                    className="text-green-600"
                    onClick={() =>
                      window.open(`/api/admin/orders/${o.id}/invoice`)
                    }
                  >
                    Invoice
                  </button>

                </td>
              </tr>
            ))}
          </tbody>

        </table>

        {orders.length === 0 && (
          <div className="p-6 text-center text-gray-500">
            No orders found
          </div>
        )}
      </div>
    </div>
  );
}