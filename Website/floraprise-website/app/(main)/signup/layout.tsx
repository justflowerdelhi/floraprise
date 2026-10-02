import { pageMetadata } from "@/lib/seo";

export const metadata = pageMetadata({
  title: "Start Your Free Trial | Floraprise",
  description:
    "Start your Floraprise free trial.",
  path: "/signup/",
  noIndex: true,
});

export default function SignupLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
