import Image from "next/image";
import Link from "next/link";

const workflow = ["Enquiry", "Quotation", "Order", "Production", "Delivery", "Payment"];
const operations = ["Customer", "Stock", "Craft", "Production", "Delivery", "Payments", "Profitability", "Teams"];
const audiences = ["Retail florists", "Wedding studios", "Event designers", "Flower shops", "Online flower businesses", "Growing teams", "Multi-location businesses"];
const integrations = ["bloomnation", "doordash", "dunzo", "ftd", "porter", "quickbooks", "stripe", "tally", "uc"];

function Status({ children, future = false }: { children: React.ReactNode; future?: boolean }) {
  return <span className={`product-status ${future ? "is-future" : ""}`}><i />{children}</span>;
}

function Eyebrow({ children }: { children: React.ReactNode }) {
  return <span className="product-eyebrow">{children}</span>;
}

export default function RedesignedHome() {
  return (
    <main className="product-home">
      <section className="product-hero">
        <div className="hero-message">
          <Eyebrow>Complete technology for florist businesses</Eyebrow>
          <h1>Run your florist<br />business. <em>Your way.</em></h1>
          <p>One platform to manage orders, inventory, customers, staff, production and deliveries — built specifically for florist businesses.</p>
          <div className="action-row">
            <Link href="/demo" className="primary-action">Book a demo <span>↗</span></Link>
            <Link href="#products" className="secondary-action">Explore Floraprise <span>↓</span></Link>
          </div>
          <div className="hero-proof">
            <span><b>ERP</b> Run the business</span><span><b>APP</b> Run it anywhere</span><span><b>ASSIST</b> Respond faster</span>
          </div>
        </div>
        <div className="hero-photo">
          <Image
            src="/floraprise-real.png"
            alt="Florist using FloraPrise at a flower shop counter"
            width={1376}
            height={768}
            sizes="(max-width: 1050px) 100vw, 55vw"
            priority
          />
        </div>
      </section>

      <section className="product-ribbon"><strong>Purpose-built for the business of flowers</strong><span>Retail</span><span>Weddings & events</span><span>Perishable inventory</span><span>Production</span><span>Delivery</span></section>

      <section className="products-section" id="products">
        <header className="section-heading centered"><Eyebrow>The Floraprise platform</Eyebrow><h2>One florist platform. Three powerful ways to work.</h2><p>The operating system at the centre, mobile access for the day in motion, and customer assistance at the first conversation.</p></header>
        <article className="erp-product" id="erp">
          <div className="product-copy"><span className="product-number">Product 01 / Flagship</span><Eyebrow>Floraprise ERP</Eyebrow><h3>Run the business.</h3><p>Manage orders, inventory, production, delivery, accounts and reports from one connected system.</p><div className="capability-strip">{["Sales", "Inventory", "Production", "Delivery", "Accounts", "Reports"].map(item => <span key={item}>{item}</span>)}</div><Link href="/features" className="text-action">Explore Floraprise ERP <span>→</span></Link></div>
          <div className="erp-product-visual"><div className="screen-label"><span>8 operational layers</span><b>One connected florist operation</b></div><Image src="/Screens/command.png" alt="Floraprise ERP command center interface" width={1400} height={900} /></div>
        </article>
        <div className="extension-grid">
          <article className="extension-card app-product" id="app">
            <div className="extension-copy"><span className="product-number">Product 02 / Mobile extension</span><Eyebrow>Floraprise App</Eyebrow><h3>Your business in your pocket.</h3><p>See sales, orders, expenses, pending deliveries and today&apos;s work wherever the day takes you.</p><div className="status-row"><Status>Android · Available</Status><Status future>iOS · Coming soon</Status></div><Link href="/features" className="text-action">Explore Floraprise App <span>→</span></Link></div>
            <div className="phone-stage"><div className="app-evidence"><span>Today&apos;s Sales</span><span>Today&apos;s Orders</span><span>Today&apos;s Expenses</span><span>Pending Deliveries</span><span>Today&apos;s Work</span></div><div className="real-phone"><span className="phone-speaker" /><Image src="/images/products/floraprise-app-real.jpeg" alt="Floraprise App real business snapshot" width={720} height={1600} /></div></div>
          </article>
          <article className="extension-card assist-product" id="assist">
            <div className="extension-copy"><span className="product-number">Product 03 / Customer intelligence</span><Eyebrow>Flora Assist</Eyebrow><h3>Your customers ask. Flora Assist answers.</h3><p>A florist-aware customer assistant that helps qualify enquiries, understand occasion and budget, and keep conversations moving.</p><div className="assist-tags"><span>Customer enquiry</span><span>Occasion</span><span>Product</span><span>Budget</span><span>Follow-up</span></div><Link href="/contact" className="text-action">Explore Flora Assist <span>→</span></Link></div>
            <div className="chat-stage"><div className="chat-window"><div><i />Live customer conversation <b>Flora Assist</b></div><Image src="/images/products/flora-assist-real.jpeg" alt="Real Flora Assist WhatsApp customer conversation" width={720} height={1600} /></div></div>
          </article>
        </div>
      </section>

      <section className="mode-section" id="platform">
        <header className="section-heading"><Eyebrow>Your business, your choice</Eyebrow><h2>Choose how your business runs.</h2><p>Start simple. Connect when you&apos;re ready.</p></header>
        <div className="mode-grid">
          <article className="mode-card local-mode"><div className="mode-top"><span>01</span><Status>Available</Status></div><div className="device-cue single-device"><i /><b /></div><Eyebrow>Local</Eyebrow><h3>Simple. Private. Independent.</h3><p>For a focused single-user operation that prefers local control and a local database.</p><ul><li>One focused workspace</li><li>Business data stays local</li><li>Independent day-to-day operation</li></ul></article>
          <article className="mode-card cloud-mode"><div className="mode-top"><span>02</span><Status>Available</Status></div><div className="device-cue connected-devices"><i /><i /><i /><b /></div><Eyebrow>Cloud</Eyebrow><h3>Connected. Flexible. Ready to grow.</h3><p>For businesses that need access across devices, connected users and cloud-based business data.</p><ul><li>Connected team access</li><li>Business data across devices</li><li>Ready for multi-user operation</li></ul></article>
        </div>
      </section>

      <section className="platform-section"><div className="section-heading"><Eyebrow>Work anywhere</Eyebrow><h2>Work wherever your business takes you.</h2></div><div className="platform-app-glimpse"><Image src="/images/products/floraprise-app-real.jpeg" alt="Floraprise App across the working day" width={720} height={1600} /></div><div className="platform-grid"><div><span className="platform-icon desktop-icon" /><strong>Desktop</strong><Status>Available</Status></div><div><span className="platform-icon android-icon" /><strong>Android</strong><Status>Available</Status></div><div><span className="platform-icon web-icon" /><strong>Web</strong><Status future>Coming soon</Status></div><div><span className="platform-icon ios-icon" /><strong>iOS</strong><Status future>Coming soon</Status></div></div></section>

      <section className="workflow-section-new"><div className="workflow-copy"><Eyebrow>One connected operation</Eyebrow><h2>From the first enquiry to the final delivery.</h2><p>Every handoff has a place.</p></div><div className="workflow-track">{workflow.map((step, index) => <div className={index === 0 ? "assist-step" : "erp-step"} key={step}><span>0{index + 1}</span><i /><strong>{step}</strong><small>{index === 0 ? "Flora Assist" : "Floraprise ERP"}</small></div>)}</div></section>

      <section className="difference-section">
        <div className="difference-visual"><div className="inventory-shot"><Image src="/Screens/inventory.png" alt="Floraprise inventory batch dashboard" width={1400} height={900} /></div><div className="depth-stat"><strong>8</strong><span>operational layers<br />around every order</span></div></div>
        <div className="difference-copy"><Eyebrow>Why Floraprise</Eyebrow><h2>More than a POS. Built for the work behind every order.</h2><p>Generic POS systems generally focus on the transaction. Floraprise follows the complete operation around it.</p><div className="operation-grid">{operations.map((item, index) => <span key={item}><i>0{index + 1}</i>{item}</span>)}</div><Link href="/features" className="text-action">See the complete platform <span>→</span></Link></div>
      </section>

      <section className="ai-section-new"><div className="ai-intro"><Eyebrow>Floraprise Smart AI</Eyebrow><h2>AI for the work behind the flowers.</h2></div><div className="ai-body"><div className="ai-cases"><article><span>01</span><h3>See the shape</h3><p>Recognise bouquet styles and forms from an image.</p></article><article><span>02</span><h3>Build the recipe</h3><p>Turn a visual idea into a considered product and recipe.</p></article><article><span>03</span><h3>Know the cost</h3><p>Understand material cost before a design becomes a promise.</p></article></div><div className="assist-distinction"><Eyebrow>Flora Assist</Eyebrow><strong>AI for the conversation in front of the business.</strong><span>Customer enquiry · Recommendation · Budget · Follow-up</span></div></div></section>
      <section className="audience-section-new"><Eyebrow>Built for florist businesses</Eyebrow><div className="audience-list">{audiences.map(item => <span key={item}>{item}</span>)}</div></section>
      <section className="integration-section-new"><div><Eyebrow>Works with your world</Eyebrow><h2>Connected where it matters.</h2><p>Supporting the tools and networks florist businesses rely on.</p></div><div className="integration-list">{integrations.map(name => <span key={name}><Image src={`/images/integrations/${name}.png`} alt={`${name} integration`} width={110} height={40} /></span>)}</div></section>
      <section className="final-cta-new"><Eyebrow>Bring the whole business together</Eyebrow><h2>Ready to build a smarter florist business?</h2><p>Bring your operations, mobile access and customer communication together with Floraprise.</p><div className="action-row"><Link href="/demo" className="primary-action light-action">Book a demo <span>↗</span></Link><Link href="/features" className="secondary-action light-secondary">Explore Floraprise <span>→</span></Link></div></section>
    </main>
  );
}
