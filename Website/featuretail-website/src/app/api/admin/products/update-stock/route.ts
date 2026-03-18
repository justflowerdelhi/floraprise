import { PrismaClient } from "@prisma/client";
import { NextResponse } from "next/server";

const prisma = new PrismaClient();

export async function POST(req: Request) {
  try {
    const { id, stock, price, isVariant } = await req.json();

    if (isVariant) {
      const updated = await prisma.productVariant.update({
        where: { id },
        data: {
          ...(stock !== undefined && { stock: Number(stock) }),
          ...(price !== undefined && { price: Number(price) }),
        },
      });

      return NextResponse.json(updated);
    } else {
      const updated = await prisma.product.update({
        where: { id },
        data: {
          ...(stock !== undefined && { stock: Number(stock) }),
          ...(price !== undefined && { price: Number(price) }),
        },
      });

      return NextResponse.json(updated);
    }
  } catch (err: any) {
    return NextResponse.json(
      { error: err.message },
      { status: 500 }
    );
  }
}
