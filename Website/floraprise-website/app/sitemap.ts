import type { MetadataRoute } from "next";
import { SITE_URL } from "@/lib/seo";

export const dynamic = "force-static";

const routes: { path: string; priority: number }[] = [
  { path: "/", priority: 1 },
  { path: "/features/", priority: 0.9 },
  { path: "/pricing/", priority: 0.9 },
  { path: "/florist-pos/", priority: 0.8 },
  { path: "/integrations/", priority: 0.6 },
  { path: "/demo/", priority: 0.7 },
  { path: "/contact/", priority: 0.6 },
  { path: "/privacy-policy/", priority: 0.3 },
];

export default function sitemap(): MetadataRoute.Sitemap {
  return routes.map(({ path, priority }) => ({
    url: `${SITE_URL}${path}`,
    priority,
  }));
}
