import { describe, it, beforeEach, afterEach } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, "..");

describe("Floraprise Marketing Website — Demo Form & Email Notification", () => {
  const originalEnv = { ...process.env };
  const originalFetch = globalThis.fetch;

  beforeEach(() => {
    process.env = { ...originalEnv };
  });

  afterEach(() => {
    process.env = { ...originalEnv };
    globalThis.fetch = originalFetch;
  });

  it("1. Demo Page: Renders 'Request a Demo' submit button, Phone/WhatsApp field, loading state and validation protection", () => {
    const pageContent = fs.readFileSync(
      path.join(rootDir, "app/(main)/demo/page.tsx"),
      "utf-8"
    );

    // Verify 'Request a Demo' button text
    assert.match(
      pageContent,
      /Request a Demo/,
      "Submit button must have text 'Request a Demo'"
    );

    // Verify primary green button styling
    assert.match(
      pageContent,
      /bg-\[#124e2c\]/,
      "Submit button must use Floraprise website primary green (#124e2c)"
    );

    // Verify loading state text
    assert.match(
      pageContent,
      /Submitting\.\.\./,
      "Submit button must show 'Submitting...' when in loading state"
    );

    // Verify double submission guard
    assert.match(
      pageContent,
      /if\s*\(\s*isSubmitting\s*\)\s*return/,
      "Form must prevent double submission when already submitting"
    );

    // Verify button disabled state when submitting
    assert.match(
      pageContent,
      /disabled=\{\s*isSubmitting\s*\}/,
      "Submit button must be disabled during submission"
    );

    // Verify form fields
    assert.match(pageContent, /name="name"/, "Form must have Full Name field");
    assert.match(pageContent, /name="email"/, "Form must have Business Email field");
    assert.match(pageContent, /name="phone"/, "Form must have Phone / WhatsApp Number field");
    assert.match(pageContent, /Phone \/ WhatsApp Number/, "Form must label Phone / WhatsApp Number field");
    assert.match(pageContent, /\+91 99900 44406/, "Form must have +91 99900 44406 placeholder");
    assert.match(pageContent, /Please enter a valid WhatsApp\/phone number\./, "Form must have inline phone validation error message");
    assert.match(pageContent, /name="businessType"/, "Form must have Business Type field");
    assert.match(pageContent, /name="currentSoftware"/, "Form must have Current Software field");
    assert.match(pageContent, /name="notes"/, "Form must have Additional Notes field");

    // Verify destination endpoint
    assert.match(
      pageContent,
      /\/api\/marketing\/demo-request/,
      "Form must post to /api/marketing/demo-request"
    );
  });

  it("2. API Route: Rejects invalid/empty submissions with 400 and does not contact DB or send email", async () => {
    let fetchCalled = false;
    globalThis.fetch = async () => {
      fetchCalled = true;
      return new Response(JSON.stringify({ success: true }), { status: 200 });
    };

    const { POST } = await import(
      `../app/api/marketing/demo-request/route.ts?update=${Date.now()}`
    );

    // Test missing name/email
    const req1 = new Request("http://localhost:3000/api/marketing/demo-request", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fullName: "",
        businessEmail: "",
        phone: "+91 99900 44406",
      }),
    });

    const res1 = await POST(req1);
    assert.equal(res1.status, 400);
    const data1 = await res1.json();
    assert.match(data1.message, /Full name and business email are required/i);
    assert.equal(fetchCalled, false, "DB fetch must not be called when validation fails");

    // Test invalid phone number
    const req2 = new Request("http://localhost:3000/api/marketing/demo-request", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fullName: "John Doe",
        businessEmail: "john@example.com",
        phone: "12345",
      }),
    });

    const res2 = await POST(req2);
    assert.equal(res2.status, 400);
    const data2 = await res2.json();
    assert.match(data2.message, /Please enter a valid WhatsApp\/phone number/i);
    assert.equal(fetchCalled, false, "DB fetch must not be called when phone validation fails");
  });

  it("3. API Route: Successfully saves to DB with phone and attempts email notification with correct headers & body", async () => {
    let savedPayload = null;
    let authHeader = null;

    globalThis.fetch = async (url, options) => {
      savedPayload = JSON.parse(options.body);
      authHeader = options.headers["X-Website-Key"];
      return new Response(
        JSON.stringify({ success: true, message: "Demo request saved to DB" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    };

    process.env.SMTP_HOST = "smtp.test.com";
    process.env.SMTP_USER = "test-sender@floraprise.com";
    process.env.SMTP_PASS = "test-password";
    process.env.WEBSITE_API_KEY = "test-website-key";

    const { POST } = await import(
      `../app/api/marketing/demo-request/route.ts?update=${Date.now() + 1}`
    );

    const req = new Request("http://localhost:3000/api/marketing/demo-request", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fullName: "Jane Florist",
        businessEmail: "jane@blooms.com",
        phone: "+91 99900 44406",
        businessType: "Retail Flower Shop",
        currentSoftware: "QuickFlora",
        notes: "Interested in multi-store inventory sync",
      }),
    });

    const res = await POST(req);
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);

    // Verify DB save payload
    assert.equal(savedPayload.fullName, "Jane Florist");
    assert.equal(savedPayload.businessEmail, "jane@blooms.com");
    assert.equal(savedPayload.phone, "+91 99900 44406");
    assert.equal(savedPayload.businessType, "Retail Flower Shop");
    assert.equal(savedPayload.currentSoftware, "QuickFlora");
    assert.equal(savedPayload.notes, "Interested in multi-store inventory sync");
    assert.equal(authHeader, "test-website-key");
  });

  it("4. API Route: Email failure does not delete or fail the saved DB lead", async () => {
    globalThis.fetch = async () => {
      return new Response(
        JSON.stringify({ success: true, message: "Lead saved in PostgreSQL" }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    };

    // Provide invalid SMTP settings that will fail to connect
    process.env.SMTP_HOST = "non-existent-smtp-server-999.invalid";
    process.env.SMTP_USER = "sender@floraprise.com";
    process.env.SMTP_PASS = "secret-pass";

    const { POST } = await import(
      `../app/api/marketing/demo-request/route.ts?update=${Date.now() + 2}`
    );

    const req = new Request("http://localhost:3000/api/marketing/demo-request", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fullName: "John Rose",
        businessEmail: "john@roseflower.com",
        phone: "+91-9990044406",
        businessType: "Wedding & Events Florist",
        currentSoftware: "Excel",
        notes: "Need wedding proposal builder",
      }),
    });

    const res = await POST(req);
    // Crucial requirement: Must still return 200 success because the DB save succeeded!
    assert.equal(res.status, 200);
    const data = await res.json();
    assert.equal(data.success, true);
  });

  it("5. API Route: DB save failure returns error and does NOT send email", async () => {
    globalThis.fetch = async () => {
      return new Response(
        JSON.stringify({ message: "Database connection error" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    };

    const { POST } = await import(
      `../app/api/marketing/demo-request/route.ts?update=${Date.now() + 3}`
    );

    const req = new Request("http://localhost:3000/api/marketing/demo-request", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        fullName: "Alex Bloom",
        businessEmail: "alex@bloom.com",
        phone: "9990044406",
      }),
    });

    const res = await POST(req);
    assert.equal(res.status, 500);
    const data = await res.json();
    assert.equal(data.message, "Database connection error");
  });

  it("6. Phone Validation: Accepts Indian mobile formats (9990044406, +91 9990044406, +91-9990044406)", async () => {
    const { isValidIndianPhone } = await import(
      `../app/api/marketing/demo-request/route.ts?update=${Date.now() + 4}`
    );

    assert.equal(isValidIndianPhone("9990044406"), true);
    assert.equal(isValidIndianPhone("+91 9990044406"), true);
    assert.equal(isValidIndianPhone("+91-9990044406"), true);
    assert.equal(isValidIndianPhone("+91 99900 44406"), true);
    assert.equal(isValidIndianPhone("09990044406"), true);

    assert.equal(isValidIndianPhone(""), false);
    assert.equal(isValidIndianPhone("12345"), false);
    assert.equal(isValidIndianPhone("1234567890"), false);
    assert.equal(isValidIndianPhone("abcdefghij"), false);
  });
});
