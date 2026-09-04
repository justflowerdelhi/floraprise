
import "./globals.css";
import Header from "../components/Navbar";
import Footer from "../components/Footer";

export const metadata = {
title: "Floraprise | The Digital Platform for Florist Businesses",
description: "Floraprise brings florist business management, mobile access and AI-powered customer assistance together in one platform.",
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
