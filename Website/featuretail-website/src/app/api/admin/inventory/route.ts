import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export async function GET() {
  try {
    const data = await prisma.storeInventory.findMany({
      orderBy: { updatedAt: "desc" },
    });

    return NextResponse.json(data);
  } catch (error) {
    console.error("GET inventory error:", error);
    return NextResponse.json(
      { error: "Failed to fetch inventory" },
      { status: 500 }
    );
  }
}

export async function POST(req: Request) {
  try {
    const body = await req.json();

    const item = await prisma.storeInventory.create({
      data: {
        sku: body.sku,
        productName: body.productName,
        color: body.color,
        size: body.size,
        stock: body.stock ?? 0,
        purchasePrice: body.purchasePrice,
        supplier: body.supplier,
        storageLocation: body.storageLocation,
        lowStockThreshold: body.lowStockThreshold ?? 5,
      },
    });

    return NextResponse.json(item);
  } catch (error) {
    console.error("POST inventory error:", error);
    return NextResponse.json(
      { error: "Failed to create inventory item" },
      { status: 500 }
    );
  }
}