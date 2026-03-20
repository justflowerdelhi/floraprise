import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const data = await req.json();

  const result = await Promise.all(
    data.map((item: any) =>
      prisma.storeInventory.upsert({
        where: { sku: item.sku },
        update: {
          stock: item.stock,
          purchasePrice: item.purchasePrice,
          supplier: item.supplier,
          storageLocation: item.storageLocation,
        },
        create: item,
      })
    )
  );

  return NextResponse.json(result);
}