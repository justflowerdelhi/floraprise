import RedesignedHome from "@/components/RedesignedHome";
import { pageMetadata, SITE_URL } from "@/lib/seo";

export const metadata = pageMetadata({
  title: "Floraprise | Florist POS & Business Management Software",
  description:
    "Floraprise is florist business management software with POS, perishable inventory, orders, deliveries, accounting and customer management for flower shops.",
  path: "/",
});

const offer = (name: string, price: string, priceCurrency: string, billingDuration: string) => ({
  "@type": "Offer",
  name,
  price,
  priceCurrency,
  billingDuration,
  availability: "https://schema.org/InStock",
  url: `${SITE_URL}/pricing/`,
});

const jsonLd = {
  "@context": "https://schema.org",
  "@graph": [
    {
      "@type": "Organization",
      "@id": `${SITE_URL}/#organization`,
      name: "Floraprise",
      url: SITE_URL,
      logo: {
        "@type": "ImageObject",
        url: `${SITE_URL}/logo.png`,
        width: 296,
        height: 319,
      },
      description: "Florist business management software built specifically for flower shops.",
      contactPoint: [
        {
          "@type": "ContactPoint",
          telephone: "+91-9971060931",
          contactType: "customer support",
        },
        {
          "@type": "ContactPoint",
          telephone: "+91-9810392755",
          contactType: "customer support",
        },
      ],
    },
    {
      "@type": "WebSite",
      "@id": `${SITE_URL}/#website`,
      name: "Floraprise",
      url: `${SITE_URL}/`,
      inLanguage: "en",
      publisher: { "@id": `${SITE_URL}/#organization` },
    },
    {
      "@type": "SoftwareApplication",
      "@id": `${SITE_URL}/#software`,
      name: "Floraprise",
      url: `${SITE_URL}/`,
      operatingSystem: "Android, Web",
      applicationCategory: "BusinessApplication",
      publisher: { "@id": `${SITE_URL}/#organization` },
      description:
        "Florist business management software covering POS, perishable inventory, orders, deliveries, customers, staff, and accounts.",
      offers: [
        offer("Floraprise Solo / Pro (Quarterly - India)", "4999", "INR", "P3M"),
        offer("Floraprise Solo / Pro (Half-Yearly - India)", "8999", "INR", "P6M"),
        offer("Floraprise Solo / Pro (Annual - India)", "14999", "INR", "P1Y"),
        offer("Floraprise Solo / Pro (Quarterly - USA)", "179", "USD", "P3M"),
        offer("Floraprise Solo / Pro (Half-Yearly - USA)", "329", "USD", "P6M"),
        offer("Floraprise Solo / Pro (Annual - USA)", "599", "USD", "P1Y"),
        offer("Floraprise Solo / Pro (Quarterly - UAE)", "649", "AED", "P3M"),
        offer("Floraprise Solo / Pro (Half-Yearly - UAE)", "1199", "AED", "P6M"),
        offer("Floraprise Solo / Pro (Annual - UAE)", "2199", "AED", "P1Y"),
      ],
    },
  ],
};

export default function Home() {
  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <RedesignedHome />
    </>
  );
}
