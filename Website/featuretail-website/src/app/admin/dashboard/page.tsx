"use client";
import { useEffect, useState } from "react";
import {
  ShoppingCart,
  Users,
  Package,
  IndianRupee,
  ClipboardList,
  PlusCircle,
} from "lucide-react";
import Link from "next/link";
import SalesChart from "@/components/admin/SalesChart";

export default function AdminDashboard() {
  const [stats, setStats] = useState({
    revenue: 0,
    orders: 0,
    customers: 0,
    products: 0,
    messages: 0,
  });

  useEffect(() => {
    fetch("/api/admin/dashboard")
      .then((res) => res.json())
      .then((data) => setStats(data));
  }, []);

  return (
    <div className="space-y-8">

      <h1 className="text-3xl font-bold">Dashboard Overview</h1>

      {/* Stats Cards */}
      <div className="grid md:grid-cols-4 gap-6">

        <div className="bg-white rounded-xl shadow p-6 border-l-4 border-pink-600">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-sm text-gray-500">Total Revenue</p>
              <h2 className="text-2xl font-bold mt-1">₹{stats.revenue}</h2>
            </div>
            <IndianRupee className="text-pink-600" size={32} />
          </div>
        </div>

        <div className="bg-white rounded-xl shadow p-6 border-l-4 border-blue-600">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-sm text-gray-500">Total Orders</p>
              <h2 className="text-2xl font-bold mt-1">{stats.orders}</h2>
            </div>
            <ShoppingCart className="text-blue-600" size={32} />
          </div>
        </div>

        <div className="bg-white rounded-xl shadow p-6 border-l-4 border-green-600">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-sm text-gray-500">Customers</p>
              <h2 className="text-2xl font-bold mt-1">{stats.customers}</h2>
            </div>
            <Users className="text-green-600" size={32} />
          </div>
        </div>

        <div className="bg-white rounded-xl shadow p-6 border-l-4 border-yellow-600">
          <div className="flex justify-between items-center">
            <div>
              <p className="text-sm text-gray-500">Products</p>
              <h2 className="text-2xl font-bold mt-1">{stats.products}</h2>
            </div>
            <Package className="text-yellow-600" size={32} />
          </div>
        </div>

      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="text-xl font-semibold mb-4">Quick Actions</h2>

        <div className="grid md:grid-cols-3 gap-6">

          <Link
            href="/admin/catalogue"
            className="bg-white p-6 rounded-xl shadow hover:shadow-md transition border"
          >
            <div className="flex items-center gap-3">
              <PlusCircle className="text-pink-600" />
              <div>
                <h3 className="font-semibold">Add New Product</h3>
                <p className="text-sm text-gray-500">
                  Create and publish new products.
                </p>
              </div>
            </div>
          </Link>

          <Link
            href="/admin/orders"
            className="bg-white p-6 rounded-xl shadow hover:shadow-md transition border"
          >
            <div className="flex items-center gap-3">
              <ClipboardList className="text-blue-600" />
              <div>
                <h3 className="font-semibold">Manage Orders</h3>
                <p className="text-sm text-gray-500">
                  View and update order status.
                </p>
              </div>
            </div>
          </Link>

          <Link
            href="/admin/customers"
            className="bg-white p-6 rounded-xl shadow hover:shadow-md transition border"
          >
            <div className="flex items-center gap-3">
              <Users className="text-green-600" />
              <div>
                <h3 className="font-semibold">Customer CRM</h3>
                <p className="text-sm text-gray-500">
                  View customer insights.
                </p>
              </div>
            </div>
          </Link>

        </div>
      </div>

      <SalesChart />

      {/* Recent Activity Placeholder */}
      <div className="bg-white rounded-xl shadow p-6 border">
        <h2 className="text-xl font-semibold mb-4">Recent Orders</h2>
        <p className="text-gray-500 text-sm">
          Latest orders will appear here once your store goes live.
        </p>
      </div>

    </div>
  );
}