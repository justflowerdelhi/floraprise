import type { Metadata } from "next";
import "./globals.css";
import Header from "../components/Navbar";
import Footer from "../components/Footer";
import { DEFAULT_OG_IMAGE, SITE_URL } from "@/lib/seo";

export const metadata: Metadata = {
  metadataBase: new URL(SITE_URL),
  title: {
    default: "Floraprise | Florist POS & Business Management Software",
    template: "%s | Floraprise",
  },
  description:
    "Floraprise is florist business management software with POS, perishable inventory, orders, deliveries, accounting and customer management for flower shops.",
  keywords: [
    "florist software",
    "florist business software",
    "florist POS",
    "florist POS software",
    "florist inventory management",
    "flower shop software",
    "flower shop POS",
    "flower shop management software",
    "florist order management",
    "florist delivery management",
    "florist ERP",
    "florist business management software",
    "flower shop inventory software",
  ],
  authors: [{ name: "Floraprise" }],
  creator: "Floraprise",
  publisher: "Floraprise",
  formatDetection: {
    email: false,
    address: false,
    telephone: false,
  },
  openGraph: {
    title: "Floraprise | Florist POS & Business Management Software",
    description:
      "Floraprise is florist business management software with POS, perishable inventory, orders, deliveries, accounting and customer management for flower shops.",
    siteName: "Floraprise",
    images: [DEFAULT_OG_IMAGE],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Floraprise | Florist POS & Business Management Software",
    description:
      "Floraprise is florist business management software with POS, perishable inventory, orders, deliveries, accounting and customer management for flower shops.",
    images: [DEFAULT_OG_IMAGE.url],
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
    apple: "/apple-icon.png",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <Header />
        {children}
        <Footer />
      </body>
    </html>
  );
}
