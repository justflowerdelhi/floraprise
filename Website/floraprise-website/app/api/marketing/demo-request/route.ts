import { NextResponse } from "next/server";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const {
      fullName,
      businessEmail,
      businessType,
      currentSoftware,
      notes,
      submittedAt,
    } = body || {};

    if (!fullName || !businessEmail) {
      return NextResponse.json(
        { message: "Full name and business email are required." },
        { status: 400 }
      );
    }

    const apiUrl = (
      process.env.NEXT_PUBLIC_ERP_API_URL || "https://api.floraprise.com"
    ).replace(/\/$/, "");
    const apiKey =
      process.env.NEXT_PUBLIC_WEBSITE_API_KEY ||
      "CHANGE-ME-floraprise-website-key-2026";

    const response = await fetch(`${apiUrl}/api/marketing/demo-request`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-Website-Key": apiKey,
        "User-Agent":
          "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Floraprise-DevProxy/1.0",
      },
      body: JSON.stringify({
        fullName,
        businessEmail,
        businessType,
        currentSoftware,
        notes,
        submittedAt: submittedAt || new Date().toISOString(),
      }),
    });

    const data = await response.json().catch(() => null);

    if (response.ok) {
      return NextResponse.json(
        data || {
          success: true,
          message: "Demo request submitted successfully",
        },
        { status: 200 }
      );
    }

    return NextResponse.json(
      data || { message: "Failed to submit demo request" },
      { status: response.status || 500 }
    );
  } catch (error) {
    console.error("Error proxying demo request:", error);
    return NextResponse.json(
      {
        message:
          "Unable to reach demo request service. Please try again later.",
      },
      { status: 500 }
    );
  }
}
