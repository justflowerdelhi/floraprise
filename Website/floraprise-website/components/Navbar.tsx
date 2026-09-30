"use client";

import Image from "next/image";
import Link from "next/link";
import { useState } from "react";

export default function Header() {
  const [menuOpen, setMenuOpen] = useState(false);
  const close = () => setMenuOpen(false);

  return (
    <header className="site-header">
      <div className="nav-wrap">
        <Link href="/" className="brand" onClick={close}>
          <Image src="/logo.png" alt="" width={34} height={34} />
          <Image
            src="/floraprise-title.png"
            alt="Floraprise"
            width={150}
            height={50}
            priority
            className="brand-wordmark"
          />
        </Link>
        <nav className="desktop-nav" aria-label="Primary navigation">
          <div className="product-menu">
            <Link href="/#products">Products <span>⌄</span></Link>
            <div className="product-menu-panel">
              <Link href="/#solo">
                <small>01</small>
                <span>
                  <b>Floraprise Solo</b>
                  Simple florist app, right on your phone
                </span>
              </Link>
              <Link href="/#pro">
                <small>02</small>
                <span>
                  <b>Floraprise Pro</b>
                  Everyday cloud florist platform
                </span>
              </Link>
              <Link href="/#erp">
                <small>03</small>
                <span>
                  <b>Floraprise ERP</b>
                  Advanced & multi-location ERP
                </span>
              </Link>
            </div>
          </div>
          <Link href="/features">Features</Link>
          <Link href="/pricing">Pricing</Link>
          <Link href="/integrations">Integrations</Link>
          <Link href="/contact">Contact</Link>
          <Link href="/login" className="nav-login">Login</Link>
          <Link href="/demo" className="nav-cta">Book a Demo</Link>
        </nav>
        <button
          className="menu-button"
          type="button"
          aria-label="Open menu"
          aria-expanded={menuOpen}
          onClick={() => setMenuOpen(!menuOpen)}
        >
          {menuOpen ? "×" : "☰"}
        </button>
      </div>
      <nav className={`mobile-nav ${menuOpen ? "open" : ""}`} aria-label="Mobile navigation">
        <Link href="/#solo" onClick={close}>Floraprise Solo (Single Device)</Link>
        <Link href="/#pro" onClick={close}>Floraprise Pro (Everyday Cloud)</Link>
        <Link href="/#erp" onClick={close}>Floraprise ERP (Advanced Operations)</Link>
        <Link href="/features" onClick={close}>Features</Link>
        <Link href="/pricing" onClick={close}>Pricing & Plans</Link>
        <Link href="/integrations" onClick={close}>Integrations</Link>
        <Link href="/contact" onClick={close}>Contact Us</Link>
        <Link href="/login" onClick={close}>Login</Link>
        <Link href="/demo" className="nav-cta" onClick={close}>Book a Demo</Link>
      </nav>
    </header>
  );
}
