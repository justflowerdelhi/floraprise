import "./globals.css";
import Navbar from "../src/components/Navbar";
import Footer from "../src/components/Footer";
import WhatsAppButton from "../src/components/WhatsAppButton";
import { CartProvider } from "../src/context/CartContext";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "3A Featuretail | Craft & Celebration Supplies",
  description:
    "Shop premium art & craft supplies, birthday decorations, gift packaging and festive decor online in India.",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="bg-white text-gray-800">
        <CartProvider>
          <Navbar />
          {children}
          <Footer />
          <WhatsAppButton />
        </CartProvider>
      </body>
    </html>
  );
}