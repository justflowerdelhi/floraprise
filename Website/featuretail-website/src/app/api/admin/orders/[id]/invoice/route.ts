
import { PrismaClient } from "@prisma/client";
import PDFDocument from "pdfkit";
import path from "path";
import fs from "fs";

const prisma = new PrismaClient();

export const runtime = "nodejs"; // IMPORTANT

export async function GET(
  req: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const order = await prisma.order.findUnique({
      where: { id },
      include: {
        items: true,
      },
    });

    if (!order) {
      return new Response("Order not found", { status: 404 });
    }


    const fontPath = path.join(process.cwd(), "public/fonts/Roboto-Black.ttf");
    const doc = new PDFDocument({
      font: fontPath, // ✅ CRITICAL FIX
    });
    const chunks: Buffer[] = [];
    doc.on("data", (chunk) => chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)));

    /* ---------------- PDF CONTENT ---------------- */
    const logoPath = path.join(process.cwd(), "public/logo.png");

    /* ---------------- HEADER ---------------- */

    // Logo
    if (fs.existsSync(logoPath)) {
      doc.image(logoPath, 50, 40, { width: 100 });
    }

    // Title
    doc
      .fontSize(20)
      .text("INVOICE", 400, 50, { align: "right" });

    doc.moveDown(2);

    /* ---------------- COMPANY INFO ---------------- */

    doc
      .fontSize(10)
      .text("3A Featuretail", 50, 120)
      .text("support@featuretail.com")
      .text("India");

    /* ---------------- ORDER INFO ---------------- */

    const status = order.orderStatus || "pending";
    doc
      .text(`Order ID: ${order.id}`, 350, 120)
      .text(`Date: ${new Date(order.createdAt).toLocaleDateString()}`)
      .text(`Status: ${status}`);

    doc.moveDown(2);

    /* ---------------- CUSTOMER ---------------- */



    doc
      .fontSize(12)
      .text("Bill To:", 50, 180)
      .fontSize(10)
      .text(order.shippingName || "-")
      .text(order.shippingAddress || "-")
      .text(
        [order.shippingCity, order.shippingState, order.shippingPincode]
          .filter(Boolean)
          .join(", ") || "-"
      )
      .text(order.shippingPhone || "-")
      .text(order.shippingEmail || "-");

    doc.moveDown();

    /* ---------------- TABLE HEADER ---------------- */

    const tableTop = 250;

    doc
      .fontSize(10)
      .text("Item", 50, tableTop)
      .text("Price", 300, tableTop)
      .text("Qty", 370, tableTop)
      .text("Total", 430, tableTop);

    doc.moveTo(50, tableTop + 15).lineTo(550, tableTop + 15).stroke();

    /* ---------------- ITEMS ---------------- */

    let y = tableTop + 25;

    order.items.forEach((item: any) => {
      const name =
        item.name ||
        item.variantName ||
        "Item";

      doc
        .text(name, 50, y)
        .text(`₹${item.price}`, 300, y)
        .text(item.quantity, 370, y)
        .text(`₹${item.price * item.quantity}`, 430, y);

      y += 20;
    });

    /* ---------------- TOTAL ---------------- */

    doc.moveTo(300, y + 10).lineTo(550, y + 10).stroke();

    doc
      .fontSize(12)
      .text("Total:", 350, y + 20)
      .text(`₹${order.total}`, 430, y + 20, {
        width: 100,
        align: "right",
      });

    /* ---------------- FOOTER ---------------- */

    doc
      .fontSize(10)
      .text("Thank you for your business!", 50, 700, {
        align: "center",
        width: 500,
      });
    doc.end();

    // Wait for the PDF to finish
    await new Promise<void>((resolve) => doc.on("end", resolve));
    const pdfBuffer = Buffer.concat(chunks);
    return new Response(pdfBuffer, {
      headers: {
        "Content-Type": "application/pdf",
        "Content-Disposition": `inline; filename=invoice-${order.id}.pdf`,
      },
    });
  } catch (err: any) {
    console.error("INVOICE ERROR:", err);
    return new Response("Invoice generation failed", {
      status: 500,
    });
  }
}