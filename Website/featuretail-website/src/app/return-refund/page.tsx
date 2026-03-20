import Footer from "@/components/Footer";

export default function ReturnRefundPage() {
  return (
    <>
      <div className="max-w-4xl mx-auto px-4 py-10 text-gray-700">
      
      {/* Title */}
      <h1 className="text-3xl font-bold mb-6 text-center">
        Refund & Return Policy
      </h1>

      {/* Last Updated */}
      <p className="mb-6 text-sm text-gray-500 text-center">
        Last updated: {new Date().toLocaleDateString()}
      </p>

      <div className="space-y-8">

        {/* Section 1 */}
        <Section title="1. Eligibility for Returns">
          <ul className="list-disc pl-5 space-y-1">
            <li>Product is damaged, defective, or incorrect</li>
            <li>Product is unused, in original condition with packaging</li>
            <li>Request raised within <strong>48 hours of delivery</strong></li>
          </ul>

          <p className="mt-3 font-medium">Non-returnable items:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>Perishable goods (flowers, cakes, food items)</li>
            <li>Customized or personalized products</li>
            <li>Digital/downloadable products</li>
          </ul>
        </Section>

        {/* Section 2 */}
        <Section title="2. Return Process">
          <p>To initiate a return:</p>
          <ul className="list-disc pl-5 space-y-1 mt-2">
            <li>Email us at 3a@featuretail.com</li>
            <li>Provide Order ID</li>
            <li>Reason for return</li>
            <li>Photos/videos as proof (if applicable)</li>
          </ul>

          <p className="mt-3">
            Once approved:
          </p>
          <ul className="list-disc pl-5 space-y-1">
            <li>Pickup will be arranged (if available)</li>
            <li>Or you may need to ship to our return address</li>
          </ul>
        </Section>

        {/* Section 3 */}
        <Section title="3. Refund Policy">
          <p className="font-medium">Prepaid Orders:</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>Refund to original payment method</li>
            <li>Processed within 5–7 business days after approval</li>
          </ul>

          <p className="mt-3 font-medium">Cash on Delivery (COD):</p>
          <ul className="list-disc pl-5 space-y-1">
            <li>Refund via bank transfer (NEFT/IMPS)</li>
            <li>UPI (as provided by customer)</li>
          </ul>
        </Section>

        {/* Section 4 */}
        <Section title="4. Replacement Policy">
          <p>
            Eligible items may be replaced instead of refunded based on availability.
          </p>
          <p className="mt-2">
            Replacement will be shipped within <strong>2–5 business days</strong>.
          </p>
        </Section>

        {/* Section 5 */}
        <Section title="5. Cancellation Policy">
          <ul className="list-disc pl-5 space-y-1">
            <li>Orders can be cancelled before shipment</li>
            <li>Once shipped, cancellation is not allowed</li>
            <li>Refunds processed within 5–7 business days</li>
          </ul>
        </Section>

        {/* Section 6 */}
        <Section title="6. Non-Refundable Situations">
          <ul className="list-disc pl-5 space-y-1">
            <li>Return request made after allowed timeframe</li>
            <li>Product damaged by customer</li>
            <li>Missing packaging</li>
            <li>Incorrect address provided</li>
          </ul>
        </Section>

        {/* Section 7 */}
        <Section title="7. Late or Missing Refunds">
          <ul className="list-disc pl-5 space-y-1">
            <li>Check your bank account again</li>
            <li>Contact your bank/payment provider</li>
          </ul>
        </Section>

        {/* Section 8 */}
        <Section title="8. Contact Us">
          <div className="bg-gray-50 p-4 rounded-lg text-sm">
            <p><strong>Email:</strong> 3a@featuretail.com</p>
            <p><strong>Phone:</strong> +91-9971060931</p>
            <p><strong>Hours:</strong> Mon–Sat, 10 AM – 6 PM IST</p>
          </div>
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