
"use client";

import SearchBar from "./SearchBar";
import { useCart } from "@/context/CartContext";
import { useState, useEffect, useRef } from "react";
import Link from "next/link";

export default function Header() {
  const { cart, subtotal } = useCart();
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    const handler = (e: any) => {
      if (ref.current && !(ref.current as HTMLElement).contains(e.target)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  return (
    <header className="sticky top-0 z-50 bg-white border-b">
      <div className="max-w-7xl mx-auto flex items-center justify-between py-4">
        {/* Logo */}
        <div className="flex items-center gap-2">
          <img src="/logo.png" className="h-10" />
          <span className="font-bold text-lg">3A Featuretail</span>
        </div>
        {/* Search */}
        <div className="flex-1 mx-10">
          <SearchBar />
        </div>
        {/* Cart */}
        <div className="relative" ref={ref}>
          <button
            onClick={() => setOpen(!open)}
            className="flex items-center gap-2 px-3 py-2 rounded hover:bg-gray-100"
          >
            🛒 Cart ({cart.length})
          </button>

          {open && (
            <div className="absolute right-0 mt-2 w-72 bg-white border rounded-lg shadow-lg p-4 z-50">
              {cart.length === 0 ? (
                <p className="text-sm text-gray-500">Cart is empty</p>
              ) : (
                <>
                  {cart.map((item) => (
                    <div
                      key={`${item.id}-${item.variantId || "default"}`}
                      className="flex justify-between text-sm mb-2"
                    >
                      <span>{item.name}</span>
                      <span>₹{item.price} × {item.quantity}</span>
                    </div>
                  ))}

                  <div className="border-t pt-2 mt-2 font-semibold">
                    Subtotal: ₹{subtotal}
                  </div>

                  <div className="flex gap-2 mt-3">
                    <Link
                      href="/cart"
                      className="flex-1 text-center bg-gray-200 py-2 rounded"
                    >
                      View Cart
                    </Link>

                    <Link
                      href="/checkout"
                      className="flex-1 text-center bg-pink-600 text-white py-2 rounded"
                    >
                      Checkout
                    </Link>
                  </div>
                </>
              )}
            </div>
          )}
        </div>
      </div>
      {/* Navigation */}
      <nav className="border-t">
        <div className="max-w-7xl mx-auto flex gap-6 py-3 text-sm">
          <a href="/">Home</a>
          <a href="/shop">Shop</a>
          <a href="/about">About</a>
          <a href="/contact">Contact</a>
        </div>
      </nav>
    </header>
  );
}
