import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

// Get a single variant (optional)
export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    if (!id) {
      return NextResponse.json({ error: "Missing variant id" }, { status: 400 });
    }
    const variant = await prisma.productVariant.findUnique({
      where: { id },
      include: { images: true }
    });
    if (!variant) {
      return NextResponse.json({ error: "Variant not found" }, { status: 404 });
    }
    return NextResponse.json(variant);
  } catch (error) {
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
}

// Update a variant
export async function PUT(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    const body = await request.json();
    const updated = await prisma.productVariant.update({
      where: { id },
      data: {
        name: body.name ?? undefined,
        price: body.price !== undefined ? Number(body.price) : undefined,
        stock: body.stock !== undefined ? Number(body.stock) : undefined
        // Add more fields as needed
      }
    });
    return NextResponse.json(updated);
  } catch (error) {
    return NextResponse.json({ error: "Update failed" }, { status: 500 });
  }
}

// Delete a variant
export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await context.params;
    await prisma.productVariant.delete({ where: { id } });
    return NextResponse.json({ success: true });
  } catch (error) {
    return NextResponse.json({ error: "Delete failed" }, { status: 500 });
  }
}
