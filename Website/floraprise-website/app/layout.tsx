import "./globals.css";
import Header from "../components/Navbar";
import Footer from "../components/Footer";

export const metadata = {
title: "Floraprise",
description: "Floraprise Florist POS & ERP Platform",
};

export default function RootLayout({
children,
}: {
children: React.ReactNode;
}) {
return ( <html lang="en"> <body className="antialiased bg-white text-gray-900"> <Header />

    {children}

    <Footer />
  </body>
</html>

);
}
