import Image from "next/image";
import Link from "next/link";

const columns = [
  { title: "Products", links: [["Floraprise ERP", "/features"], ["Floraprise App", "/features"], ["Flora Assist", "/contact"]] },
  { title: "Platform", links: [["Local", "/features"], ["Cloud", "/features"], ["Desktop", "/features"], ["Web", "/features"], ["Android", "/features"], ["iOS", "/features"]] },
  { title: "Company", links: [["About", "/contact"], ["Contact", "/contact"], ["Partners", "/integrations"]] },
  { title: "Explore", links: [["Features", "/features"], ["Pricing", "/pricing"], ["Integrations", "/integrations"], ["Book a demo", "/demo"]] },
];

export default function Footer() {
  return <footer className="site-footer"><div className="footer-grid"><div className="footer-brand"><Link href="/" className="brand"><Image src="/logo.png" alt="Floraprise" width={34} height={34} /><span>Flora<span className="brand-mark">Prise</span></span></Link><p>The digital platform for florist businesses.</p></div>{columns.map((column) => <div className="footer-column" key={column.title}><strong>{column.title}</strong>{column.links.map(([label, href]) => <Link href={href} key={label}>{label}</Link>)}</div>)}</div><div className="footer-bottom">© {new Date().getFullYear()} Floraprise. Built for the business of flowers.</div></footer>;
}
