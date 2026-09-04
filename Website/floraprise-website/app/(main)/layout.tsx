import type { Metadata } from "next";

import "../globals.css";

export const metadata: Metadata = {
  title: "Floraprise | The Digital Platform for Florist Businesses",
  description: "Floraprise brings florist business management, mobile access and AI-powered customer assistance together in one platform.",
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
  return <>{children}</>;
}
