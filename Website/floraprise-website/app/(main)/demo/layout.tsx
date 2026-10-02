import { pageMetadata } from "@/lib/seo";

export const metadata = pageMetadata({
  title: "Book a Floraprise Demo | Florist Business Software",
  description:
    "Book a live demo of Floraprise and see how it streamlines florist inventory, production, delivery, and multi-location management in one platform.",
  path: "/demo/",
});

export default function DemoLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
