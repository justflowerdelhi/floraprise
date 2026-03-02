import "./globals.css";
import type { Metadata } from "next";
import Navbar from "@/components/Navbar";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
    title: "Floraprise | Operational Intelligence Platform for Florists",
    description:
      "Floraprise is an advanced florist POS and ERP platform designed for inventory-first flower shop management, production workflows, delivery routing, and multi-location operations.",
    keywords: [
      "Florist POS",
      "Florist ERP",
      "Flower shop software",
      "Inventory management",
      "Production workflows",
      "Delivery routing",
      "Multi-location florist",
      "Operational intelligence",
      "Florist business platform"
    ],
    openGraph: {
      title: "Floraprise | Operational Intelligence Platform for Florists",
      description:
        "Floraprise is an advanced florist POS and ERP platform designed for inventory-first flower shop management, production workflows, delivery routing, and multi-location operations.",
      url: "https://www.floraprise.com",
      siteName: "Floraprise",
      type: "website",
    },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <link rel="icon" href="/favicon.svg" type="image/svg+xml" />
      </head>
      <body className="bg-white text-gray-900">
        <Navbar />
        {children}
        <Footer />
      </body>
    </html>
  );
}