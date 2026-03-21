"use client";

import Link from "next/link";
import { useEffect, useState } from "react";

function LogoutButton() {
  const handleLogout = async () => {
    await fetch("/api/auth/logout", { method: "POST" });
    window.location.href = "/admin/login";
  };
  return (
    <button
      type="button"
      onClick={handleLogout}
      className="block w-full text-left text-red-600 hover:text-red-800 mt-6"
    >
      Logout
    </button>
  );
}

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const [stats, setStats] = useState({ messages: 0 });

  useEffect(() => {
    fetch("/api/admin/dashboard")
      .then((res) => res.json())
      .then((data) => setStats(data));
  }, []);

  return (
    <div className="min-h-screen flex bg-gray-100">

      {/* Sidebar */}
      <aside className="w-64 bg-white border-r hidden md:block">
        <div className="p-6 font-bold text-xl border-b">
          Admin Panel
        </div>

        <nav className="p-4 space-y-3 text-sm">
          <Link href="/admin/dashboard" className="block hover:text-pink-600">
            Dashboard
          </Link>

          <span className="block text-gray-700">Catalogue</span>


            <div className="ml-4">
              <Link href="/admin/catalogue/categories" className="block hover:text-pink-600">
                Categories
              </Link>
              <Link
                href="/admin/catalogue/products"
                className="block hover:text-pink-600"
              >
                Products
              </Link>
            </div>

          <Link href="/admin/our-store/inventory" className="block hover:text-pink-600">
            Our Store Inventory
          </Link>

          <Link href="/admin/orders" className="block hover:text-pink-600">
            Orders
          </Link>

          <div className="flex justify-between items-center">
            <a href="/admin/messages" className="hover:text-pink-600">
              Messages {stats.messages > 0 && `(${stats.messages})`}
            </a>
          </div>

          <Link href="/admin/coupons" className="block hover:text-pink-600">
            Coupons
          </Link>

          <Link href="/admin/delivery" className="block hover:text-pink-600">
            Delivery
          </Link>

          <Link href="/admin/content" className="block hover:text-pink-600">
            Content
          </Link>

          <Link href="/admin/settings" className="block hover:text-pink-600">
            Settings
          </Link>
          <LogoutButton />
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-6">
        {children}
      </main>
    </div>
  );
}