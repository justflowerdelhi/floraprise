import "./globals.css";
import Header from "@/components/Header";
import PromoBar from "@/components/PromoBar";
import { CartProvider } from "@/context/CartContext";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "3A Featuretail | Craft & Celebration Supplies",
  description:
    "Shop premium art & craft supplies, birthday decorations, gift packaging and festive decor online in India.",
};
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html>
      <body>
        <CartProvider>
          <PromoBar />
          <Header />
          {children}
          <a
            href="https://wa.me/919810329755"
            target="_blank"
            className="fixed bottom-6 right-6 bg-green-500 text-white p-4 rounded-full shadow-lg z-50"
            aria-label="Chat on WhatsApp"
          >
            💬
          </a>
        </CartProvider>
      </body>
    </html>
  );
}