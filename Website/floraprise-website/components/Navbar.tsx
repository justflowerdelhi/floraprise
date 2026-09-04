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
          <Image src="/logo.png" alt="Floraprise" width={34} height={34} />
          <span>Flora<span className="brand-mark">Prise</span></span>
        </Link>
        <nav className="desktop-nav" aria-label="Primary navigation">
          <div className="product-menu">
            <Link href="#products">Products <span>⌄</span></Link>
            <div className="product-menu-panel">
              <Link href="#erp"><small>01</small><span><b>Floraprise ERP</b>Run the business</span></Link>
              <Link href="#app"><small>02</small><span><b>Floraprise App</b>Run it anywhere</span></Link>
              <Link href="#assist"><small>03</small><span><b>Flora Assist</b>Respond faster</span></Link>
            </div>
          </div>
          <Link href="#platform">Platform</Link>
          <Link href="/features">Features</Link>
          <Link href="/integrations">Integrations</Link>
          <Link href="/pricing">Pricing</Link>
          <Link href="/login" className="nav-login">Login</Link>
          <Link href="/demo" className="nav-cta">Book a demo</Link>
        </nav>
        <button className="menu-button" type="button" aria-label="Open menu" aria-expanded={menuOpen} onClick={() => setMenuOpen(!menuOpen)}>{menuOpen ? "×" : "☰"}</button>
      </div>
      <nav className={`mobile-nav ${menuOpen ? "open" : ""}`} aria-label="Mobile navigation">
        <Link href="#erp" onClick={close}>Floraprise ERP</Link>
        <Link href="#app" onClick={close}>Floraprise App</Link>
        <Link href="#assist" onClick={close}>Flora Assist</Link>
        <Link href="#platform" onClick={close}>Platform</Link>
        <Link href="/features" onClick={close}>Features</Link>
        <Link href="/integrations" onClick={close}>Integrations</Link>
        <Link href="/pricing" onClick={close}>Pricing</Link>
        <Link href="/login" onClick={close}>Login</Link>
        <Link href="/demo" className="nav-cta" onClick={close}>Book a demo</Link>
      </nav>
    </header>
  );
}
