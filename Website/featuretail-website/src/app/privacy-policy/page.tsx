import Footer from "@/components/Footer";

export default function PrivacyPolicyPage() {
  return (
    <>
      <div className="max-w-4xl mx-auto px-4 py-10 text-gray-700">

      {/* Title */}
      <h1 className="text-3xl font-bold mb-6 text-center">
        Privacy Policy
      </h1>

      {/* Last Updated */}
      <p className="mb-6 text-sm text-gray-500 text-center">
        Last updated: {new Date().toLocaleDateString()}
      </p>

      {/* Intro */}
      <p className="text-sm text-center text-gray-600 mb-10">
        Featuretail (“we”, “our”, or “us”) values your privacy and is committed to protecting your personal information.
      </p>

      <div className="space-y-8">

        {/* Section 1 */}
        <Section title="1. Information We Collect">
          <p className="font-medium">Personal Information:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>Name</li>
            <li>Email address</li>
            <li>Phone number</li>
            <li>Shipping & billing address</li>
            <li>Payment details (processed securely via third-party providers)</li>
          </ul>

          <p className="mt-3 font-medium">Non-Personal Information:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>IP address</li>
            <li>Browser and device information</li>
            <li>Pages visited and time spent</li>
            <li>Cookies and usage data</li>
          </ul>
        </Section>

        {/* Section 2 */}
        <Section title="2. How We Use Your Information">
          <ul className="list-disc pl-5 space-y-1">
            <li>Process and fulfill orders</li>
            <li>Provide customer support</li>
            <li>Send order updates</li>
            <li>Improve website performance</li>
            <li>Prevent fraud and enhance security</li>
            <li>Send marketing emails (with consent)</li>
          </ul>
        </Section>

        {/* Section 3 */}
        <Section title="3. Sharing of Information">
          <p>We do not sell your personal data. We may share data with:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>Logistics partners</li>
            <li>Payment gateways</li>
            <li>Service providers (hosting, analytics)</li>
            <li>Legal authorities (if required)</li>
          </ul>
        </Section>

        {/* Section 4 */}
        <Section title="4. Cookies & Tracking Technologies">
          <ul className="list-disc pl-5 space-y-1">
            <li>Enhance functionality</li>
            <li>Remember preferences</li>
            <li>Analyze traffic</li>
          </ul>
          <p className="mt-2">
            You can disable cookies in your browser settings.
          </p>
        </Section>

        {/* Section 5 */}
        <Section title="5. Data Security">
          <ul className="list-disc pl-5 space-y-1">
            <li>HTTPS encrypted connections</li>
            <li>Restricted data access</li>
            <li>Regular security monitoring</li>
          </ul>
          <p className="mt-2 text-sm text-gray-500">
            No method of transmission is 100% secure.
          </p>
        </Section>

        {/* Section 6 */}
        <Section title="6. Data Retention">
          <p>
            We retain your data only as long as necessary for order processing,
            legal compliance, and dispute resolution.
          </p>
        </Section>

        {/* Section 7 */}
        <Section title="7. Your Rights">
          <ul className="list-disc pl-5 space-y-1">
            <li>Access your data</li>
            <li>Request correction or deletion</li>
            <li>Opt-out of marketing</li>
          </ul>
          <p className="mt-2">
            Contact: <strong>3a@featuretail.com</strong>
          </p>
        </Section>

        {/* Section 8 */}
        <Section title="8. Third-Party Links">
          <p>
            We are not responsible for privacy practices of external websites.
          </p>
        </Section>

        {/* Section 9 */}
        <Section title="9. Children’s Privacy">
          <p>
            We do not knowingly collect data from individuals under 18.
          </p>
        </Section>

        {/* Section 10 */}
        <Section title="10. International Users">
          <p>
            Your data may be processed in India or other countries where our service providers operate.
          </p>
        </Section>

        {/* Section 11 */}
        <Section title="11. Policy Updates">
          <p>
            We may update this policy anytime. Changes will be reflected on this page.
          </p>
        </Section>

        {/* Section 12 */}
        <Section title="12. Contact Us">
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

/* Reusable Section Component */
function Section({ title, children }: any) {
  return (
    <div className="border-b pb-6">
      <h2 className="text-xl font-semibold mb-3">{title}</h2>
      <div className="text-sm leading-relaxed">{children}</div>
    </div>
  );
}