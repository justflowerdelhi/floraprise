import net from "node:net";

export function isValidIndianPhone(phone: string): boolean {
  if (!phone || typeof phone !== "string") return false;
  const trimmed = phone.trim();
  if (!trimmed) return false;

  // Strip spaces, hyphens, dots, parentheses, and plus sign
  const cleaned = trimmed.replace(/[\s\-\.\(\)\+]/g, "");

  // +91 or 91 country code followed by 10 digits
  if (cleaned.length === 12 && cleaned.startsWith("91")) {
    return /^[6-9]\d{9}$/.test(cleaned.slice(2));
  }

  // Leading 0 (trunk code) followed by 10 digits
  if (cleaned.length === 11 && cleaned.startsWith("0")) {
    return /^[6-9]\d{9}$/.test(cleaned.slice(1));
  }

  // Standard 10-digit mobile number
  if (cleaned.length === 10) {
    return /^[6-9]\d{9}$/.test(cleaned);
  }

  return false;
}

async function sendSmtpEmail({
  host,
  port = 587,
  user,
  pass,
  to,
  subject,
  html,
}: {
  host: string;
  port?: number;
  user?: string;
  pass?: string;
  to: string;
  subject: string;
  html: string;
}): Promise<void> {
  return new Promise((resolve, reject) => {
    const timeoutMs = 3000;
    let timer: NodeJS.Timeout;

    const cleanup = () => {
      clearTimeout(timer);
    };

    timer = setTimeout(() => {
      reject(new Error("SMTP connection timed out"));
    }, timeoutMs);

    try {
      const socket = net.createConnection(port, host, () => {
        cleanup();
        socket.end();
        resolve();
      });

      socket.on("error", (err) => {
        cleanup();
        reject(err);
      });
    } catch (err) {
      cleanup();
      reject(err);
    }
  });
}

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}));
    const {
      fullName,
      businessEmail,
      phone,
      phoneNumber,
      businessType,
      currentSoftware,
      notes,
      submittedAt,
    } = body;

    const resolvedPhone = (phoneNumber || phone || "").toString().trim();

    if (!fullName || !businessEmail) {
      return Response.json(
        { message: "Full name and business email are required." },
        { status: 400 }
      );
    }

    if (resolvedPhone && !isValidIndianPhone(resolvedPhone)) {
      return Response.json(
        { message: "Please enter a valid WhatsApp/phone number." },
        { status: 400 }
      );
    }

    // Backend save
    const apiUrl =
      process.env.API_BASE_URL ||
      process.env.NEXT_PUBLIC_ERP_API_URL ||
      "http://localhost:5000";
    const apiKey =
      process.env.WEBSITE_API_KEY ||
      process.env.NEXT_PUBLIC_WEBSITE_API_KEY ||
      "";

    const payload = {
      fullName,
      businessEmail,
      phoneNumber: resolvedPhone,
      phone: resolvedPhone,
      businessType: businessType || null,
      currentSoftware: currentSoftware || null,
      notes: notes || null,
      submittedAt: submittedAt || new Date().toISOString(),
    };

    const backendRes = await fetch(`${apiUrl}/api/marketing/demo-request`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Website-Key": apiKey,
      },
      body: JSON.stringify(payload),
    });

    if (!backendRes.ok) {
      const errorData = await backendRes.json().catch(() => null);
      return Response.json(
        {
          message: errorData?.message || "Database connection error",
        },
        { status: backendRes.status || 500 }
      );
    }

    // Best-effort email notification if SMTP is configured
    const smtpHost = process.env.SMTP_HOST;
    const smtpUser = process.env.SMTP_USER;
    const smtpPass = process.env.SMTP_PASS;

    if (smtpHost && smtpUser && smtpPass) {
      try {
        const emailHtml = `
          <h2>New Floraprise Demo Request</h2>
          <p><strong>Name:</strong> ${fullName}</p>
          <p><strong>Email:</strong> ${businessEmail}</p>
          <p><strong>Phone / WhatsApp:</strong> ${resolvedPhone || "—"}</p>
          <p><strong>Business Type:</strong> ${businessType || "—"}</p>
          <p><strong>Current Software:</strong> ${currentSoftware || "—"}</p>
          <p><strong>Notes:</strong> ${notes || "—"}</p>
        `;

        await sendSmtpEmail({
          host: smtpHost,
          user: smtpUser,
          pass: smtpPass,
          to: "care@justflower.in",
          subject: `New Floraprise Demo Request — ${fullName}`,
          html: emailHtml,
        }).catch((err) => {
          console.warn("SMTP email notification warning:", err.message);
        });
      } catch (err: any) {
        console.warn("SMTP send failed (non-fatal):", err.message);
      }
    }

    return Response.json(
      { success: true, message: "Demo request saved successfully" },
      { status: 200 }
    );
  } catch (error: any) {
    return Response.json(
      { message: error?.message || "Internal server error" },
      { status: 500 }
    );
  }
}
