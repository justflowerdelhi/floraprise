import Image from "next/image";
import Link from "next/link";

export default function Navbar() {
  return (
    <nav className="w-full bg-[#fafaf8]/90 backdrop-blur-md border-b border-[#eaeaea] sticky top-0 z-50">
      <div className="max-w-7xl mx-auto px-6 py-5 flex justify-between items-center">

        <Link href="/" className="flex items-center gap-3">
          <Image
            src="/floraprise-logo1.png"
            alt="Floraprise Logo"
            width={36}
            height={36}
          />
            <span className="text-lg font-semibold tracking-tight">
              <span style={{ color: '#14532d' }}>Flora</span><span style={{ color: '#ff8800' }}>Prise</span>
            </span>
        </Link>

        <div className="hidden md:flex items-center gap-8 text-sm text-gray-600">
          <Link href="/features" className="text-gray-700 hover:text-[var(--brand-green)] transition font-semibold tracking-wide">
            Features
          </Link>
          <Link href="/pricing" className="text-gray-700 hover:text-[var(--brand-green)] transition font-semibold tracking-wide">
            Pricing
          </Link>
          <Link href="/contact" className="text-gray-700 hover:text-[var(--brand-green)] transition font-semibold tracking-wide">
            Contact
          </Link>
          <Link
            href="/demo"
            className="bg-[var(--brand-orange)] hover:opacity-90 text-white px-4 py-2 rounded-lg font-semibold transition"
          >
            Book Demo
          </Link>
        </div>

      </div>
    </nav>
  );
}