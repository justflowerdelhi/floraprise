"use client"

import { useState } from "react"
import Link from "next/link"
import Image from "next/image"

export default function Header() {
  const [menuOpen, setMenuOpen] = useState(false)

  return (
    <header className="sticky top-0 z-50 bg-white border-b">
      <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">

        {/* Logo */}
        <Link href="/" className="flex items-center gap-2">
          <Image
            src="/logo.png"
            alt="Floraprise"
            width={40}
            height={40}
          />
          <span className="text-xl font-semibold">
            Flora<span className="text-green-700">Prise</span>
          </span>
        </Link>

        {/* Desktop Menu */}
        <nav className="hidden md:flex items-center gap-8 text-gray-700 font-medium">

          <Link href="/product" className="hover:text-green-700">
            Product
          </Link>

          <Link href="/features" className="hover:text-green-700">
            Features
          </Link>

          <Link href="/integrations" className="hover:text-green-700">
            Integrations
          </Link>

          <Link href="/pricing" className="hover:text-green-700">
            Pricing
          </Link>

          <Link href="/contact" className="hover:text-green-700">
            Contact
          </Link>

          {/* Login */}
          <Link href="/login" className="hover:text-green-700">
            Login
          </Link>

          {/* CTA */}
          <Link
            href="/demo"
            className="bg-orange-500 text-white px-5 py-2 rounded-lg hover:opacity-90 transition"
          >
            Book Demo
          </Link>

        </nav>

        {/* Mobile Hamburger */}
        <button
          className="md:hidden text-2xl"
          onClick={() => setMenuOpen(!menuOpen)}
        >
          ☰
        </button>
      </div>

      {/* Mobile Menu */}
      {menuOpen && (
        <div className="md:hidden border-t bg-white px-6 py-4 space-y-4">

          <Link href="/product" className="block text-gray-700" onClick={() => setMenuOpen(false)}>
            Product
          </Link>

          <Link href="/features" className="block text-gray-700" onClick={() => setMenuOpen(false)}>
            Features
          </Link>

          <Link href="/integrations" className="block text-gray-700" onClick={() => setMenuOpen(false)}>
            Integrations
          </Link>

          <Link href="/pricing" className="block text-gray-700" onClick={() => setMenuOpen(false)}>
            Pricing
          </Link>

          <Link href="/contact" className="block text-gray-700" onClick={() => setMenuOpen(false)}>
            Contact
          </Link>

          <Link href="/login" className="block text-gray-700" onClick={() => setMenuOpen(false)}>
            Login
          </Link>

          <Link
            href="/demo"
            className="block bg-orange-500 text-white text-center py-2 rounded-lg"
            onClick={() => setMenuOpen(false)}
          >
            Book Demo
          </Link>

        </div>
      )}
    </header>
  )
}