export async function POST(req: Request) {
  try {
    const body = await req.json();
    if (!body.items || body.items.length === 0) {
      return NextResponse.json(
        { error: "No items provided" },
        { status: 400 }
      );
    }
    const shipping = body.shipping;
    const billing = body.billing;

    // Generate a unique order number
    const orderNumber = "ORD-" + Date.now();

    const order = await prisma.order.create({
      data: {
        orderNumber,
        paymentMethod: body.paymentMethod,
        subtotal: body.subtotal,
        shipping: body.shippingAmount,
        discount: body.discount,
        total: body.total,
        gstAmount: body.gstAmount ?? 0,
        // Shipping fields
        shippingName: shipping.name,
        shippingPhone: shipping.phone,
        shippingEmail: shipping.email,
        shippingAddress: shipping.address,
        shippingCity: shipping.city,
        shippingState: shipping.state,
        shippingPincode: shipping.pincode,
        // Billing fields
        billingName: billing.name,
        billingPhone: billing.phone,
        billingEmail: billing.email,
        billingAddress: billing.address,
        billingCity: billing.city,
        billingState: billing.state,
        billingPincode: billing.pincode,
        companyName: billing.companyName,
        gstNumber: billing.gstNumber,
        // Items
        items: {
          create: body.items?.map((item: any) => ({
            productId: item.productId,
            variantId: item.variantId,
            name: item.name, // snapshot
            variantName: item.variantName, // snapshot
            price: item.price,
            quantity: item.qty,
          })) || [],
        },
      },
      include: { items: true },
    });

    // Deduct inventory for each item
    for (const item of body.items || []) {
      if (item.qty <= 0) continue;
      if (item.variantId) {
        const variant = await prisma.productVariant.findUnique({
          where: { id: item.variantId },
        });
        if (!variant || variant.stock == null || variant.stock < item.qty) {
          throw new Error("Insufficient stock for variant");
        }
        await prisma.productVariant.update({
          where: { id: item.variantId },
          data: { stock: { decrement: item.qty } },
        });
      } else if (item.productId) {
        await prisma.product.update({
          where: { id: item.productId },
          data: { stock: { decrement: item.qty } },
        });
      }
    }

    return NextResponse.json({ success: true, orderNumber, order });
  } catch (error: any) {
    console.error(error);
    return NextResponse.json({ error: error.message || "Order creation failed" }, { status: 500 });
  }
}
import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export async function GET() {
  try {
    const orders = await prisma.order.findMany({
      orderBy: {
        createdAt: "desc",
      },
    });

    return NextResponse.json(orders);
  } catch (error) {
    console.error(error);
    return NextResponse.json({ error: "Failed to fetch orders" }, { status: 500 });
  }
}