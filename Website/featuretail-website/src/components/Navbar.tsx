"use client";

import Link from "next/link";
import { useState } from "react";
import Image from "next/image";
import { useCart } from "../context/CartContext";

export default function Navbar() {
  const [menuOpen, setMenuOpen] = useState(false);
  const { cart } = useCart();

  return (
    <>
      <div className="bg-pink-600 text-white text-center text-sm py-2 px-4">
        🚚 Free Shipping on Orders Above ₹200 | 💳 Get 5% Extra Off on Prepaid Orders
      </div>
      <nav className="bg-white shadow-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-3 flex justify-between items-center">
          
          {/* Logo */}
          <Link href="/" className="flex items-center">
            <Image
              src="/logo.png"
              alt="3A Featuretail"
              width={120}
              height={50}
              priority
            />
          </Link>
          {/* Desktop Menu */}
          <div className="hidden md:flex space-x-6 font-medium">
            <Link href="/" className="hover:text-pink-600">Home</Link>
            <Link href="/shop" className="hover:text-pink-600">Shop</Link>
            <Link href="/about" className="hover:text-pink-600">About</Link>
            <Link href="/contact" className="hover:text-pink-600">Contact</Link>
          </div>
          <div className="hidden md:flex items-center gap-6">
            <Link href="/cart" className="relative text-2xl">
              <span role="img" aria-label="Cart">🛒</span>
              {cart.length > 0 && (
                <span className="absolute -top-2 -right-3 bg-pink-600 text-white text-xs px-2 rounded-full">
                  {cart.length}
                </span>
              )}
            </Link>
          </div>
          {/* Mobile Menu Button */}
          <button 
            className="md:hidden text-2xl"
            onClick={() => setMenuOpen(!menuOpen)}
          >
            ☰
          </button>
        </div>
      </nav>
    </>
  );
}