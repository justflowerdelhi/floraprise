import Footer from "@/components/Footer";

export default function ShippingPolicyPage() {
  return (
    <>
      <div className="max-w-4xl mx-auto px-4 py-10 text-gray-700">
      
      {/* Title */}
      <h1 className="text-3xl font-bold mb-6 text-center">
        Shipping Policy
      </h1>

      {/* Intro */}
      <p className="mb-6 text-sm text-gray-500 text-center">
        Last updated: {new Date().toLocaleDateString()}
      </p>

      {/* Sections */}
      <div className="space-y-8">

        {/* Section */}
        <Section title="1. Shipping Locations">
          <p>We currently ship across:</p>
          <ul className="list-disc pl-5 mt-2 space-y-1">
            <li>All major cities and towns in India</li>
            <li>International locations (if applicable)</li>
          </ul>
          <p className="mt-2">
            If your location is not serviceable, you will be notified during checkout or after placing your order.
          </p>
        </Section>

        <Section title="2. Shipping Methods & Delivery Time">
          <Table
            rows={[
              ["Standard Shipping", "3–7 business days"],
              ["Express Shipping", "1–3 business days"],
              ["Same-Day Delivery", "Available in select cities"],
            ]}
          />
          <p className="text-sm text-gray-500 mt-2">
            *Same-day delivery is available only for eligible products and locations.
          </p>
        </Section>

        <Section title="3. Shipping Charges">
          <ul className="list-disc pl-5 space-y-1">
            <li>Free shipping on orders above ₹[Insert Amount]</li>
            <li>Orders below this amount will incur shipping charges</li>
            <li>Express or priority shipping may cost extra</li>
          </ul>
        </Section>

        <Section title="4. Order Tracking">
          <p>
            Once your order is shipped, you will receive a tracking link via email/SMS.
            You can also track orders from your account dashboard.
          </p>
        </Section>

        <Section title="5. Delivery Delays">
          <p>Delays may occur due to:</p>
          <ul className="list-disc pl-5 mt-2 space-y-1">
            <li>Weather conditions</li>
            <li>Logistics disruptions</li>
            <li>High order volumes</li>
            <li>Remote delivery locations</li>
          </ul>
          <p className="mt-2">
            We are not liable for courier delays but will assist in resolving issues.
          </p>
        </Section>

        <Section title="6. Failed Delivery Attempts">
          <p>
            Our courier partners will attempt delivery <strong>2–3 times</strong>.
          </p>
          <p className="mt-2">
            If unsuccessful, the order may be returned. Re-shipping charges may apply.
          </p>
        </Section>

        <Section title="7. Damaged or Lost Shipments">
          <ul className="list-disc pl-5 space-y-1">
            <li>Report within <strong>48 hours</strong> of delivery</li>
            <li>Provide order ID and photos</li>
          </ul>
          <p className="mt-2">
            We will arrange a replacement or refund after verification.
          </p>
        </Section>

        <Section title="8. Incorrect Shipping Information">
          <p>
            Customers are responsible for providing accurate shipping details.
            We are not responsible for delivery failures due to incorrect addresses.
          </p>
        </Section>

        <Section title="9. Contact Us">
          <div className="bg-gray-50 p-4 rounded-lg text-sm">
            <p><strong>Email:</strong> support@featuretail.com</p>
            <p><strong>Phone:</strong> +91-9971060931</p>
            <p><strong>Hours:</strong> Mon–Sat, 10 AM – 6 PM IST</p>
          </div>
        </Section>

        <Section title="10. Policy Updates">
          <p>
            We reserve the right to update this policy at any time.
            Changes will be reflected on this page.
          </p>
        </Section>

      </div>
    </div>
    <Footer />
    </>
  );
}

/* Reusable Section Component */
function Section({ title, children }: any) {
  return (
    <div className="border-b pb-6">
      <h2 className="text-xl font-semibold mb-3">{title}</h2>
      <div className="text-sm leading-relaxed">{children}</div>
    </div>
  );
}

/* Table Component */
function Table({ rows }: { rows: string[][] }) {
  return (
    <div className="overflow-x-auto">
      <table className="w-full border text-sm">
        <tbody>
          {rows.map((row, i) => (
            <tr key={i} className="border-t">
              <td className="p-2 font-medium bg-gray-50">{row[0]}</td>
              <td className="p-2">{row[1]}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}