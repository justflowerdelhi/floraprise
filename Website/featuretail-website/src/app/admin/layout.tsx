"use client";

import Link from "next/link";

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen flex bg-gray-100">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r hidden md:block">
        <div className="p-6 font-bold text-xl border-b">Admin Panel</div>

        <nav className="p-4 space-y-3 text-sm">
          <Link href="/admin/dashboard" className="block hover:text-pink-600">
            Dashboard
          </Link>
          <Link href="/admin/catalogue" className="block hover:text-pink-600">
            Catalogue
          </Link>
          <Link
            href="/admin/catalogue/categories"
            className="block hover:text-pink-600"
          >
            Categories
          </Link>
          <Link href="/admin/inventory" className="block hover:text-pink-600">
            Inventory
          </Link>
          <Link href="/admin/orders" className="block hover:text-pink-600">
            Orders
          </Link>
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
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1 p-6">{children}</main>
    </div>
  );
}
