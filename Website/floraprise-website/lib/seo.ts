import type { Metadata } from "next";

export const SITE_URL = "https://floraprise.com";

export const DEFAULT_OG_IMAGE = {
  url: "/floraprise-real.png",
  width: 1376,
  height: 768,
  alt: "Florist managing counter sales and floral orders with Floraprise",
};

type PageMetadataInput = {
  title: string;
  description: string;
  path: string;
  noIndex?: boolean;
};

export function pageMetadata({ title, description, path, noIndex = false }: PageMetadataInput): Metadata {
  return {
    title: { absolute: title },
    description,
    alternates: { canonical: path },
    openGraph: {
      title,
      description,
      url: path,
      siteName: "Floraprise",
      images: [DEFAULT_OG_IMAGE],
      locale: "en_US",
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [DEFAULT_OG_IMAGE.url],
    },
    ...(noIndex ? { robots: { index: false, follow: true } } : {}),
  };
}
