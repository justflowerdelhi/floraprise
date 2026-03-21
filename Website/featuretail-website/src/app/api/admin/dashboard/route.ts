import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { prisma } from "@/lib/prisma";

export async function GET() {
  try {
    const token = cookies().get("token");

    if (!token) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const revenue = await prisma.order.aggregate({
      _sum: { total: true },
    });

    const orders = await prisma.order.count();
    const products = await prisma.product.count();
    const customers = await prisma.order.groupBy({
      by: ["shippingEmail"],
    });

    return NextResponse.json({
      revenue: revenue._sum.total || 0,
      orders,
      products,
      customers: customers.length,
      messages: 0,
    });

  } catch (error) {
    console.error("DASHBOARD ERROR:", error);
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}