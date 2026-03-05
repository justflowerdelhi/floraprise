"use client";

import { useEffect, useState } from "react";
import Link from "next/link";

export default function OrdersListPage() {
  const [orders, setOrders] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchOrders() {
      const res = await fetch("/api/orders");
      if (res.ok) {
        const text = await res.text();
        const data = text ? JSON.parse(text) : [];
        setOrders(data);
      }
      setLoading(false);
    }
    fetchOrders();
  }, []);

  if (loading) return <div>Loading orders...</div>;

  return (
    <div className="max-w-3xl mx-auto p-6 bg-white rounded shadow">
      <h1 className="text-xl font-bold mb-4">Orders</h1>
      {orders.length === 0 ? (
        <div>No orders found.</div>
      ) : (
        <table className="w-full border">
          <thead>
            <tr>
              <th className="border px-2 py-1">Order ID</th>
              <th className="border px-2 py-1">Customer</th>
              <th className="border px-2 py-1">Status</th>
              <th className="border px-2 py-1">Total</th>
              <th className="border px-2 py-1">Actions</th>
            </tr>
          </thead>
          <tbody>
            {orders.map((order: any) => (
              <tr key={order.id}>
                <td className="border px-2 py-1">{order.id}</td>
                <td className="border px-2 py-1">{order.shippingName}</td>
                <td className="border px-2 py-1">{order.orderStatus}</td>
                <td className="border px-2 py-1">₹{order.total}</td>
                <td className="border px-2 py-1">
                  <Link
                    href={`/admin/orders/${order.id}`}
                    className="text-blue-600 hover:underline"
                  >
                    View
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
