import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const phone = searchParams.get("phone");

  if (!phone) {
    return NextResponse.json(null);
  }

  const customer = await prisma.customer.findFirst({
    where: { phone },
    include: {
      orders: {
        orderBy: { createdAt: "desc" },
        take: 5
      }
    }
  });

  return NextResponse.json(customer);
}
