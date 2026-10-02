import { pageMetadata } from "@/lib/seo";

export const metadata = pageMetadata({
  title: "Floraprise Pricing | Florist POS & ERP Plans",
  description:
    "Simple, honest pricing for Floraprise Solo, Pro and ERP. Compare quarterly, half-yearly and annual florist software plans for India, the USA and the UAE.",
  path: "/pricing/",
});

export default function PricingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
