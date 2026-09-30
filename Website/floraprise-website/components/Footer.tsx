import Image from "next/image";
import Link from "next/link";

const columns = [
  {
    title: "Products",
    links: [
      ["Floraprise Solo", "/#solo"],
      ["Floraprise Pro", "/#pro"],
      ["Floraprise ERP", "/#erp"],
      ["Pricing & Plans", "/pricing"],
    ],
  },
  {
    title: "Features",
    links: [
      ["Florist POS", "/features#pos"],
      ["Perishable Inventory", "/features#inventory"],
      ["Order Management", "/features#orders"],
      ["Delivery Tracking", "/features#delivery"],
      ["Cash Book & Accounts", "/features#accounts"],
      ["Staff & Attendance", "/features#staff"],
    ],
  },
  {
    title: "Explore",
    links: [
      ["All Features", "/features"],
      ["Pricing", "/pricing"],
      ["Book a Live Demo", "/demo"],
      ["Integrations", "/integrations"],
      ["Florist POS (India)", "/florist-pos"],
    ],
  },
  {
    title: "Company",
    links: [
      ["About Floraprise", "/contact"],
      ["Contact & Support", "/contact"],
      ["Privacy Policy", "/privacy-policy"],
      ["Login to Web", "/login"],
    ],
  },
];

export default function Footer() {
  return (
    <footer className="site-footer">
      <div className="footer-grid">
        <div className="footer-brand">
          <Link href="/" className="brand">
            <Image src="/logo.png" alt="Floraprise" width={34} height={34} />
            <span>
              Flora<span className="brand-mark">Prise</span>
            </span>
          </Link>
          <p>
            The everyday business management platform built specifically for florists. Run POS, inventory, orders, deliveries, and accounts from one place.
          </p>
        </div>
        {columns.map((column) => (
          <div className="footer-column" key={column.title}>
            <strong>{column.title}</strong>
            {column.links.map(([label, href]) => (
              <Link href={href} key={label}>
                {label}
              </Link>
            ))}
          </div>
        ))}
      </div>
      <div className="footer-bottom">
        © {new Date().getFullYear()} Floraprise. Built for the business of flowers.
      </div>
    </footer>
  );
}
