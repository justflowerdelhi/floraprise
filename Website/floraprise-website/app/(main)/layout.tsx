import { Inter } from "next/font/google";
import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";
import "../globals.css";

const inter = Inter({
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Floraprise | Florist POS & ERP Software",
  description:
    "Floraprise is an inventory-first florist POS and ERP software built for modern flower shops. Manage POS, delivery routing, inventory, and online orders in one system.",
  keywords: [
    "Florist POS",
    "Florist ERP",
    "Flower shop software",
    "Delivery routing software",
    "Florist inventory management",
  ],
  openGraph: {
    title: "Floraprise | Florist POS & ERP",
    description: "The operating system for modern florists.",
    url: "https://www.floraprise.com",
    siteName: "Floraprise",
    type: "website",
  },
};

export default function MainSiteLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className={`${inter.className} bg-white text-gray-900`}>
        <Navbar />
        {children}
        <Footer />
      </body>
    </html>
  );
}
