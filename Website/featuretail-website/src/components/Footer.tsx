import Link from "next/link";

export default function Footer() {
  return (
    <footer className="bg-gray-100 mt-4">
      <div className="max-w-7xl mx-auto px-4 py-6 grid md:grid-cols-4 gap-8">
        
        <div>
          <h2 className="text-xl font-bold text-pink-600 mb-3">
            3A Featuretail
          </h2>
          <p className="text-sm text-gray-600">
            Craft Your Creativity. Celebrate Every Moment.
          </p>
        </div>

        <div>
          <h3 className="font-semibold mb-2">Quick Links</h3>
              <ul className="space-y-1 text-sm text-gray-600">
                <li>
                  <Link href="/shop" className="hover:underline">Shop</Link>
                </li>
                <li>
                  <Link href="/about" className="hover:underline">About</Link>
                </li>
                <li>
                  <Link href="/contact" className="hover:underline">Contact</Link>
                </li>
              </ul>
        </div>

        <div>
          <h3 className="font-semibold mb-2">Customer Support</h3>
              <ul className="space-y-1 text-sm text-gray-600">
                <li>
                  <Link href="/shipping-policy" className="hover:underline">Shipping Policy</Link>
                </li>
                <li>
                  <Link href="/return-refund" className="hover:underline">Return & Refund</Link>
                </li>
                <li>
                  <Link href="/privacy-policy" className="hover:underline">Privacy Policy</Link>
                </li>
                <li>
                  <Link href="/terms" className="hover:underline">Terms & Conditions</Link>
                </li>
              </ul>
        </div>

        <div>
          <h3 className="font-semibold mb-2">Contact</h3>
          <p className="text-sm text-gray-600">
            3a@featuretail.com
          </p>
        </div>

      </div>

      <div className="text-center text-sm text-gray-500 py-4 border-t">
        © {new Date().getFullYear()} 3A Featuretail. All rights reserved.
      </div>
    </footer>
  );
}