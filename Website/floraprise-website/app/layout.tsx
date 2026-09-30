import type { Metadata } from "next";
import "./globals.css";
import Header from "../components/Navbar";
import Footer from "../components/Footer";

export const metadata: Metadata = {
  metadataBase: new URL("https://floraprise.com"),
  title: {
    default: "Floraprise – Florist Business Management Software | POS, Inventory & Orders",
    template: "%s | Floraprise",
  },
  description:
    "Floraprise is the everyday business management platform built specifically for florists. Manage POS, perishable inventory, orders, deliveries, customers, staff, and accounts in one place.",
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
  alternates: {
    canonical: "/",
  },
  openGraph: {
    title: "Floraprise – Florist Business Management Software | POS, Inventory & Orders",
    description:
      "Run your flower business simply. Florist POS, perishable inventory, order tracking, delivery management, customers, and accounts in one platform.",
    url: "https://floraprise.com",
    siteName: "Floraprise",
    images: [
      {
        url: "/floraprise-real.png",
        width: 1200,
        height: 630,
        alt: "Floraprise Florist Business Management Platform",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Floraprise – Florist Business Management Software",
    description:
      "Everyday business management platform built specifically for florists. POS, inventory, orders, deliveries, and accounts.",
    images: ["/floraprise-real.png"],
    creator: "@floraprise",
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

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": "https://floraprise.com/#organization",
      "name": "Floraprise",
      "url": "https://floraprise.com",
      "logo": "https://floraprise.com/logo.png",
      "description": "Everyday business management software built specifically for florists.",
      "sameAs": [
        "https://twitter.com/floraprise",
        "https://www.facebook.com/floraprise",
        "https://www.instagram.com/floraprise"
      ]
    },
    {
      "@type": "SoftwareApplication",
      "@id": "https://floraprise.com/#software",
      "name": "Floraprise",
      "operatingSystem": "Android, Web, Windows",
      "applicationCategory": "BusinessApplication",
      "offers": [
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Quarterly - India)",
          "price": "4999",
          "priceCurrency": "INR",
          "billingDuration": "P3M",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Half-Yearly - India)",
          "price": "8999",
          "priceCurrency": "INR",
          "billingDuration": "P6M",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Annual - India)",
          "price": "14999",
          "priceCurrency": "INR",
          "billingDuration": "P1Y",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Quarterly - USA)",
          "price": "179",
          "priceCurrency": "USD",
          "billingDuration": "P3M",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Half-Yearly - USA)",
          "price": "329",
          "priceCurrency": "USD",
          "billingDuration": "P6M",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Annual - USA)",
          "price": "599",
          "priceCurrency": "USD",
          "billingDuration": "P1Y",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Quarterly - UAE)",
          "price": "649",
          "priceCurrency": "AED",
          "billingDuration": "P3M",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Half-Yearly - UAE)",
          "price": "1199",
          "priceCurrency": "AED",
          "billingDuration": "P6M",
          "availability": "https://schema.org/InStock"
        },
        {
          "@type": "Offer",
          "name": "Floraprise Solo / Pro (Annual - UAE)",
          "price": "2199",
          "priceCurrency": "AED",
          "billingDuration": "P1Y",
          "availability": "https://schema.org/InStock"
        }
      ],
      "description": "Everyday florist management software covering POS, perishable inventory, orders, deliveries, customers, staff, and accounts."
    }
  ]
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <head>
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
        />
      </head>
      <body>
        <Header />
        {children}
        <Footer />
      </body>
    </html>
  );
}
