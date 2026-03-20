import Footer from "@/components/Footer";

export default function TermsPage() {
  return (
    <>
      <div className="max-w-4xl mx-auto px-4 py-10 text-gray-700">

      {/* Title */}
      <h1 className="text-3xl font-bold mb-6 text-center">
        Terms & Conditions
      </h1>

      {/* Last Updated */}
      <p className="mb-6 text-sm text-gray-500 text-center">
        Last updated: {new Date().toLocaleDateString()}
      </p>

      {/* Intro */}
      <p className="text-sm text-center text-gray-600 mb-10">
        By using Featuretail.com, you agree to comply with and be bound by these Terms.
      </p>

      <div className="space-y-8">

        {/* Section 1 */}
        <Section title="1. Definitions">
          <ul className="list-disc pl-5 space-y-1">
            <li><strong>Platform:</strong> Featuretail.com</li>
            <li><strong>User:</strong> Anyone accessing or purchasing</li>
            <li><strong>We / Us:</strong> Featuretail</li>
            <li><strong>Products:</strong> Items listed for sale</li>
          </ul>
        </Section>

        {/* Section 2 */}
        <Section title="2. Eligibility">
          <ul className="list-disc pl-5 space-y-1">
            <li>You must be at least 18 years old</li>
            <li>You must be legally capable of entering agreements</li>
          </ul>
        </Section>

        {/* Section 3 */}
        <Section title="3. Account & User Responsibilities">
          <ul className="list-disc pl-5 space-y-1">
            <li>Maintain account confidentiality</li>
            <li>Responsible for all account activity</li>
            <li>Provide accurate information</li>
          </ul>
          <p className="mt-2">
            We may suspend accounts for misuse or false data.
          </p>
        </Section>

        {/* Section 4 */}
        <Section title="4. Products & Pricing">
          <ul className="list-disc pl-5 space-y-1">
            <li>Prices and availability may change</li>
            <li>Errors may occur</li>
            <li>We may cancel orders in case of errors</li>
          </ul>
        </Section>

        {/* Section 5 */}
        <Section title="5. Orders & Payments">
          <ul className="list-disc pl-5 space-y-1">
            <li>Orders confirmed after payment (except COD)</li>
            <li>We may cancel orders at our discretion</li>
            <li>Payments processed via secure gateways</li>
          </ul>
        </Section>

        {/* Section 6 */}
        <Section title="6. Shipping & Delivery">
          <p>
            Delivery timelines are estimates and may vary.
          </p>
          <p className="mt-2">
            Refer to our Shipping Policy for more details.
          </p>
        </Section>

        {/* Section 7 */}
        <Section title="7. Returns, Refunds & Cancellations">
          <p>
            Governed by our Refund Policy. Certain items may not be eligible.
          </p>
        </Section>

        {/* Section 8 */}
        <Section title="8. Intellectual Property">
          <p>
            All content (logos, images, text, software) belongs to Featuretail.
            Unauthorized use is prohibited.
          </p>
        </Section>

        {/* Section 9 */}
        <Section title="9. Prohibited Activities">
          <ul className="list-disc pl-5 space-y-1">
            <li>Illegal or unauthorized use</li>
            <li>System hacking or disruption</li>
            <li>Uploading malicious code</li>
            <li>Violation of laws</li>
          </ul>
        </Section>

        {/* Section 10 */}
        <Section title="10. Limitation of Liability">
          <ul className="list-disc pl-5 space-y-1">
            <li>No liability for indirect damages</li>
            <li>Liability limited to order value</li>
          </ul>
        </Section>

        {/* Section 11 */}
        <Section title="11. Indemnification">
          <p>
            You agree to hold Featuretail harmless from claims arising from misuse.
          </p>
        </Section>

        {/* Section 12 */}
        <Section title="12. Third-Party Services">
          <p>
            We are not responsible for third-party services (payments, logistics).
          </p>
        </Section>

        {/* Section 13 */}
        <Section title="13. Privacy">
          <p>
            Your usage is also governed by our Privacy Policy.
          </p>
        </Section>

        {/* Section 14 */}
        <Section title="14. Termination">
          <p>
            We may suspend or terminate access for violations.
          </p>
        </Section>

        {/* Section 15 */}
        <Section title="15. Governing Law">
          <p>
            Governed by laws of India. Jurisdiction: Delhi.
          </p>
        </Section>

        {/* Section 16 */}
        <Section title="16. Changes to Terms">
          <p>
            Continued use implies acceptance of updated Terms.
          </p>
        </Section>

        {/* Section 17 */}
        <Section title="17. Contact Us">
          <div className="bg-gray-50 p-4 rounded-lg text-sm">
            <p><strong>Email:</strong> 3a@featuretail.com</p>
            <p><strong>Phone:</strong> +91-9971060931</p>
            <p><strong>Hours:</strong> Mon–Sat, 10 AM – 6 PM IST</p>
          </div>
        </Section>

      </div>

      {/* Trust Strip */}
      <div className="text-center text-xs text-gray-500 mt-10">
        🔒 Secure Payments | 🚚 Fast Delivery | 💬 24/7 Support
      </div>

    </div>
    <Footer />
    </>
  );
}

/* Reusable Section */
function Section({ title, children }: any) {
  return (
    <div className="border-b pb-6">
      <h2 className="text-xl font-semibold mb-3">{title}</h2>
      <div className="text-sm leading-relaxed">{children}</div>
    </div>
  );
}