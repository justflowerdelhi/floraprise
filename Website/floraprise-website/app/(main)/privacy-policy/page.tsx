import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Privacy Policy | Floraprise",
  description:
    "Privacy Policy for Floraprise florist business management software and mobile applications. Learn how we collect, protect, and manage your business and customer data.",
  alternates: {
    canonical: "/privacy-policy/",
  },
  openGraph: {
    title: "Privacy Policy | Floraprise",
    description:
      "Comprehensive Privacy Policy for Floraprise florist ERP and POS platform.",
    url: "https://floraprise.com/privacy-policy/",
    siteName: "Floraprise",
    type: "website",
  },
};

export default function PrivacyPolicyPage() {
  return (
    <main className="min-h-screen bg-[#f7f8f4] text-[#142219]">
      {/* Header Banner */}
      <section className="border-b border-[#d9dfd7] bg-white py-14 md:py-20">
        <div className="mx-auto max-w-4xl px-6">
          <div className="inline-flex items-center gap-2 rounded-full border border-[#c4d7c8] bg-[#eef5f0] px-3.5 py-1 text-xs font-semibold uppercase tracking-wider text-[#124e2c]">
            <span>Legal & Privacy</span>
          </div>
          <h1 className="mt-4 font-serif text-3xl font-normal tracking-tight text-[#142219] sm:text-4xl md:text-5xl">
            Privacy Policy
          </h1>
          <p className="mt-4 text-base text-[#526158] sm:text-lg">
            This Privacy Policy describes how Floraprise collects, uses, stores, and protects business, user, and customer information across our mobile application, web dashboard, and cloud platform.
          </p>
          <div className="mt-6 flex flex-wrap items-center gap-y-2 gap-x-6 border-t border-[#edf0eb] pt-4 text-xs text-[#627067]">
            <div>
              <strong className="text-[#142219]">Effective Date:</strong> 25 September 2026
            </div>
            <div>
              <strong className="text-[#142219]">Developer:</strong> Anand Kumar Pandey
            </div>
            <div>
              <strong className="text-[#142219]">Application:</strong> Floraprise
            </div>
          </div>
        </div>
      </section>

      {/* Main Content Area */}
      <section className="mx-auto max-w-4xl px-6 py-12 md:py-16">
        <div className="space-y-12 text-sm leading-relaxed text-[#35433a] sm:text-base">
          
          {/* Quick Summary Card */}
          <div className="rounded-2xl border border-[#d2dfd5] bg-[#eef5f0] p-6 text-[#1a3826]">
            <h2 className="text-base font-bold uppercase tracking-wider text-[#124e2c]">
              Key Highlights
            </h2>
            <ul className="mt-3 list-disc space-y-2 pl-5 text-sm">
              <li>
                <strong>Florist-Centric Design:</strong> Floraprise is a specialized business management software (POS, perishable inventory, order tracking, accounts, and deliveries) designed for florists and floral retail businesses.
              </li>
              <li>
                <strong>Local & Cloud Modes:</strong> Offline/Solo mode keeps your operational data locally on your device in SQLite. Cloud mode securely synchronizes your florist profile and operational records with encrypted cloud servers.
              </li>
              <li>
                <strong>No Unauthorized Sharing:</strong> We do not sell, rent, or trade your business or customer records to data brokers or third-party advertisers.
              </li>
              <li>
                <strong>Full Data Ownership:</strong> You retain complete ownership of the data you enter. You may request account and data deletion at any time by contacting us.
              </li>
            </ul>
          </div>

          {/* 1. Introduction & Overview */}
          <div id="introduction" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              1. Introduction & Scope
            </h2>
            <p>
              Floraprise (&quot;we&quot;, &quot;us&quot;, or &quot;our&quot;), developed by <strong>Anand Kumar Pandey</strong>, provides an integrated florist management suite comprising Android mobile applications, web dashboards, and desktop software accessible via{" "}
              <Link href="https://floraprise.com" className="font-medium text-[#124e2c] underline hover:text-[#25784a]">
                https://floraprise.com
              </Link>{" "}
              and associated subdomains.
            </p>
            <p>
              This Privacy Policy applies to all users of the Floraprise application, website, and related services (collectively, the &quot;Service&quot;). By creating an account, accessing, or using Floraprise, you consent to the practices described in this policy.
            </p>
          </div>

          {/* 2. Information We Collect */}
          <div id="information-collected" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              2. Information We Collect
            </h2>
            <p>
              We collect information that is strictly necessary to provide, maintain, and enhance florist management operations:
            </p>

            <div className="mt-4 space-y-4 pl-1">
              <div>
                <h3 className="text-lg font-semibold text-[#142219]">
                  A. Account & Authentication Information
                </h3>
                <p className="mt-1">
                  When you register for a Floraprise account or log in, we collect your full name, business mobile phone number, email address, password/authentication credentials, and verification tokens.
                </p>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-[#142219]">
                  B. Florist & Business Profile Information
                </h3>
                <p className="mt-1">
                  To personalize your invoices, receipts, and order branding, we store business information provided by you, including your shop name, owner name, business logo, physical store address, city, state, postal PIN code, country/region, GSTIN/tax identification numbers, fiscal currency settings, and business contact numbers.
                </p>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-[#142219]">
                  C. Customer, Recipient & Order Data Entered by Users
                </h3>
                <p className="mt-1">
                  As part of operating your flower shop, you may enter details about your retail and corporate customers, recipients, and orders into Floraprise. This includes customer names, contact phone numbers, delivery destination addresses, card greetings/messages, delivery dates/time slots, itemized floral recipes, payment statuses, and notes.
                </p>
                <p className="mt-1 text-xs text-[#627067]">
                  <em>Note:</em> You act as the controller of customer data you input into your shop records, and Floraprise acts as a secure data processor enabling your day-to-day operations.
                </p>
              </div>

              <div>
                <h3 className="text-lg font-semibold text-[#142219]">
                  D. Device & Diagnostic Information
                </h3>
                <p className="mt-1">
                  To ensure application reliability, prevent fraud, and troubleshoot crashes, we may automatically collect limited technical data such as operating system version, device model, app version, network status, and error diagnostic logs.
                </p>
              </div>
            </div>
          </div>

          {/* 3. Device Permissions & Optional Features */}
          <div id="permissions" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              3. Device Permissions (Where Applicable)
            </h2>
            <p>
              Floraprise requests specific device permissions only when required to execute specific in-app features. You may grant or revoke these permissions via your device settings at any time:
            </p>

            <div className="mt-4 grid gap-4 sm:grid-cols-2">
              <div className="rounded-xl border border-[#d9dfd7] bg-white p-5 shadow-xs">
                <div className="flex items-center gap-2 font-semibold text-[#142219]">
                  <span>📷</span> Camera & Photo Gallery
                </div>
                <p className="mt-2 text-xs text-[#526158] sm:text-sm">
                  Used <em>where applicable</em> solely for capturing/uploading your store logo, bouquet recipe reference photos, finished floral arrangement snapshots, proof-of-delivery photos, and scanning product barcodes or QR codes.
                </p>
              </div>

              <div className="rounded-xl border border-[#d9dfd7] bg-white p-5 shadow-xs">
                <div className="flex items-center gap-2 font-semibold text-[#142219]">
                  <span>📍</span> Location Services
                </div>
                <p className="mt-2 text-xs text-[#526158] sm:text-sm">
                  Used <em>where applicable</em> strictly to assist florists with calculating customer delivery distances, optimizing delivery routing, and dispatching orders to local delivery associates. We do not track user location in the background without consent.
                </p>
              </div>

              <div className="rounded-xl border border-[#d9dfd7] bg-white p-5 shadow-xs">
                <div className="flex items-center gap-2 font-semibold text-[#142219]">
                  <span>🔔</span> Notifications
                </div>
                <p className="mt-2 text-xs text-[#526158] sm:text-sm">
                  Used <em>where applicable</em> to deliver urgent operational alerts, scheduled flower delivery reminders, morning delivery preparation notifications, and subscription renewals.
                </p>
              </div>

              <div className="rounded-xl border border-[#d9dfd7] bg-white p-5 shadow-xs">
                <div className="flex items-center gap-2 font-semibold text-[#142219]">
                  <span>💾</span> Local Storage & Filesystem
                </div>
                <p className="mt-2 text-xs text-[#526158] sm:text-sm">
                  Used to maintain your local offline database (SQLite), store generated PDF receipts and sales invoices, export Excel balance sheets, and cache frequently used product catalogs for offline speed.
                </p>
              </div>
            </div>
          </div>

          {/* 4. How We Use Your Information */}
          <div id="how-we-use" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              4. How We Use Your Information
            </h2>
            <p>We process your data strictly for legitimate operational purposes:</p>
            <ul className="list-disc space-y-2 pl-6 text-[#35433a]">
              <li>Creating and managing your Floraprise florist account and authenticating access.</li>
              <li>Processing sales transactions, generating branded tax invoices, delivery challans, and receipts.</li>
              <li>Tracking perishable flower inventory, stems, wastage, and recipe costs.</li>
              <li>Synchronizing records between your mobile devices, web interface, and cloud databases.</li>
              <li>Sending automated WhatsApp/SMS bills or order status notifications directly requested by you.</li>
              <li>Providing responsive customer support, technical assistance, and resolving operational issues.</li>
              <li>Maintaining data security, preventing unauthorized access, and validating subscription licenses.</li>
            </ul>
          </div>

          {/* 5. Cloud Synchronization vs. Local Solo Mode */}
          <div id="cloud-sync" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              5. Cloud Synchronization & Local Storage Modes
            </h2>
            <p>
              Floraprise features a flexible dual-mode architecture:
            </p>
            <div className="space-y-3 pl-1">
              <div className="rounded-lg border border-[#d9dfd7] bg-white p-4">
                <h4 className="font-semibold text-[#142219]">Local / Solo Mode (Offline-First)</h4>
                <p className="mt-1 text-xs text-[#526158] sm:text-sm">
                  Your business operations, inventory, and order entries remain stored locally on your device in an encrypted SQLite database. No store operational records are transmitted to cloud servers in pure Solo offline mode without your explicit action.
                </p>
              </div>
              <div className="rounded-lg border border-[#d9dfd7] bg-white p-4">
                <h4 className="font-semibold text-[#142219]">Cloud / Pro Mode (Multi-Device Sync)</h4>
                <p className="mt-1 text-xs text-[#526158] sm:text-sm">
                  Your company profile, inventory catalogue, customer list, and active orders are securely synchronized over HTTPS/TLS with our dedicated Floraprise cloud infrastructure, allowing seamless real-time access across your counter POS, mobile devices, and web portals.
                </p>
              </div>
            </div>
          </div>

          {/* 6. Payment Processing & Financial Security */}
          <div id="payments" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              6. Payment Processing & Financial Data
            </h2>
            <p>
              When subscribing to Floraprise or processing in-app digital payments, transactions are handled securely by compliant third-party payment gateways (e.g., PayU, Razorpay, or Stripe, where applicable).
            </p>
            <p>
              Floraprise <strong>never</strong> collects, stores, or processes sensitive credit card numbers, debit card PINs, or CVV codes on our servers. All digital payment transactions are tokenized and processed through PCI-DSS certified payment processors. For offline POS payments (Cash, UPI QR, Bank Transfer), Floraprise records only the payment method label, transaction reference ID (if entered), and amount for accounting purposes.
            </p>
          </div>

          {/* 7. Third-Party Services & Integrations */}
          <div id="third-parties" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              7. Third-Party Integrations & Service Providers
            </h2>
            <p>
              We may utilize trusted third-party service providers to facilitate platform operations:
            </p>
            <ul className="list-disc space-y-2 pl-6 text-[#35433a]">
              <li>
                <strong>Cloud Hosting & Database Infrastructure:</strong> Secure servers located in compliant tier-3 data centers with TLS 1.3 encryption and automated backups.
              </li>
              <li>
                <strong>Communication Services:</strong> Authorized SMS gateways and official Meta WhatsApp Business APIs (where configured) to deliver order bills and status updates.
              </li>
              <li>
                <strong>Mapping & Geocoding:</strong> Mapping APIs (such as OpenStreetMap or Google Maps Platform) used strictly to resolve delivery coordinates and routing directions.
              </li>
            </ul>
            <p>
              These service providers are bound by strict contractual confidentiality agreements and are prohibited from using your data for any unauthorized purpose.
            </p>
          </div>

          {/* 8. Data Protection & Security */}
          <div id="security" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              8. Data Protection & Security Practices
            </h2>
            <p>
              We implement industry-standard technical and organizational security measures to protect your data against unauthorized access, alteration, disclosure, or destruction:
            </p>
            <ul className="list-disc space-y-2 pl-6 text-[#35433a]">
              <li><strong>Encryption in Transit:</strong> All data transmitted between user devices and Floraprise Cloud is encrypted using modern TLS (HTTPS) protocols.</li>
              <li><strong>Encrypted Authentication:</strong> Passwords and API tokens are cryptographically hashed and stored securely using industry-proven algorithms.</li>
              <li><strong>Tenant Isolation:</strong> Cloud multi-tenant architectures strictly partition each florist&apos;s data by unique company identifiers to prevent cross-account exposure.</li>
              <li><strong>Access Control:</strong> Administrative access to production databases is strictly restricted, monitored, and guarded by multi-factor authentication.</li>
            </ul>
          </div>

          {/* 9. Data Retention & Deletion Requests */}
          <div id="data-deletion" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              9. Data Retention & Account Deletion
            </h2>
            <p>
              We retain business and account records for as long as your account remains active or as required to deliver services, resolve disputes, and fulfill statutory tax and legal accounting obligations.
            </p>
            <div className="rounded-xl border border-[#d9dfd7] bg-white p-6 shadow-xs">
              <h3 className="text-base font-semibold text-[#142219]">
                How to Request Account & Data Deletion
              </h3>
              <p className="mt-2 text-sm text-[#526158]">
                You have the full right to delete your Floraprise account and permanently erase all associated cloud data at any time. To request deletion:
              </p>
              <ol className="mt-3 list-decimal space-y-2 pl-5 text-sm text-[#35433a]">
                <li>
                  Send an email from your registered business email address to{" "}
                  <a href="mailto:care@justflower.in" className="font-semibold text-[#124e2c] underline">
                    care@justflower.in
                  </a>{" "}
                  or{" "}
                  <a href="mailto:md.justflowers@gmail.com" className="font-semibold text-[#124e2c] underline">
                    md.justflowers@gmail.com
                  </a>.
                </li>
                <li>
                  Include the subject line: <strong>&quot;Account & Data Deletion Request - [Your Shop Name / Mobile Number]&quot;</strong>.
                </li>
                <li>
                  Our team will verify account ownership and permanently purge your store records, customer data, uploaded images, and credentials from active databases within <strong>30 business days</strong>.
                </li>
              </ol>
            </div>
          </div>

          {/* 10. Children's Privacy */}
          <div id="childrens-privacy" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              10. Children&apos;s Privacy
            </h2>
            <p>
              Floraprise is a commercial business-to-business (B2B) enterprise platform intended exclusively for use by business owners, florists, and authorized commercial staff aged 18 and older. We do not knowingly solicit or collect personal information from children under 13 (or under 16 in applicable jurisdictions). If you become aware that a child has provided us with personal information, please contact us immediately, and we will promptly delete such data.
            </p>
          </div>

          {/* 11. Changes to This Policy */}
          <div id="changes" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              11. Changes to This Privacy Policy
            </h2>
            <p>
              We may update this Privacy Policy from time to time to reflect modifications in our software, legal requirements, or operational practices. When updates are published, we will revise the &quot;Effective Date&quot; at the top of this page. We encourage you to review this policy periodically. Continued use of Floraprise following any changes constitutes acceptance of the revised terms.
            </p>
          </div>

          {/* 12. Contact Information */}
          <div id="contact" className="space-y-4">
            <h2 className="font-serif text-2xl font-normal text-[#142219] sm:text-3xl">
              12. Contact Information & Developer Details
            </h2>
            <p>
              If you have any questions, concerns, feedback, or requests regarding this Privacy Policy or our data handling practices, please contact us directly:
            </p>
            <div className="mt-4 rounded-xl border border-[#d9dfd7] bg-white p-6 shadow-xs">
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <div className="text-xs font-bold uppercase tracking-wider text-[#627067]">
                    Developer
                  </div>
                  <div className="mt-1 font-semibold text-[#142219]">Anand Kumar Pandey</div>
                </div>
                <div>
                  <div className="text-xs font-bold uppercase tracking-wider text-[#627067]">
                    Application
                  </div>
                  <div className="mt-1 font-semibold text-[#142219]">Floraprise</div>
                </div>
                <div>
                  <div className="text-xs font-bold uppercase tracking-wider text-[#627067]">
                    Privacy & Support Email
                  </div>
                  <div className="mt-1">
                    <a
                      href="mailto:care@justflower.in"
                      className="font-medium text-[#124e2c] underline hover:text-[#25784a]"
                    >
                      care@justflower.in
                    </a>
                  </div>
                </div>
                <div>
                  <div className="text-xs font-bold uppercase tracking-wider text-[#627067]">
                    Google Play Developer Email
                  </div>
                  <div className="mt-1">
                    <a
                      href="mailto:md.justflowers@gmail.com"
                      className="font-medium text-[#124e2c] underline hover:text-[#25784a]"
                    >
                      md.justflowers@gmail.com
                    </a>
                  </div>
                </div>
                <div>
                  <div className="text-xs font-bold uppercase tracking-wider text-[#627067]">
                    Official Website
                  </div>
                  <div className="mt-1">
                    <Link
                      href="https://floraprise.com"
                      className="font-medium text-[#124e2c] underline hover:text-[#25784a]"
                    >
                      https://floraprise.com
                    </Link>
                  </div>
                </div>
                <div>
                  <div className="text-xs font-bold uppercase tracking-wider text-[#627067]">
                    Support Contact
                  </div>
                  <div className="mt-1 text-sm text-[#526158]">
                    +91-9971060931 / +91-9810392755
                  </div>
                </div>
              </div>
            </div>
          </div>

        </div>
      </section>
    </main>
  );
}
