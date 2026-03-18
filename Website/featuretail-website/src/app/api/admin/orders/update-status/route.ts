import { PrismaClient } from "@prisma/client";
import { NextResponse } from "next/server";

const prisma = new PrismaClient();

export async function POST(req: Request) {
  const { id, status } = await req.json();

  await prisma.order.update({
    where: { id },
    data: { orderStatus: status },
  });

  return NextResponse.json({ success: true });
}
