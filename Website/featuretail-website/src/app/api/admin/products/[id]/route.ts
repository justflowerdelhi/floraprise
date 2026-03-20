import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  try {
    if (!id) {
      return NextResponse.json(
        { error: "Missing product id" },
        { status: 400 }
      );
    }

    const product = await prisma.product.findUnique({
      where: { id },
      include: {
        category: true,
        subCategory: true,
        images: true,
        variants: true,
        tags: true
      }
    });

    if (!product) {
      return NextResponse.json(
        { error: "Product not found" },
        { status: 404 }
      );
    }

    return NextResponse.json(product);

  } catch (error) {
    console.error("GET PRODUCT ERROR:", error);
    return NextResponse.json(
      { error: "Server error" },
      { status: 500 }
    );
  }
}

export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;
  try {
    const body = await request.json();
    const updated = await prisma.product.update({
      where: { id },
      data: {
        name: body.name ?? undefined,
        slug: body.slug ?? undefined,
        description: body.description ?? undefined,
        price: body.price ? Number(body.price) : undefined,
        // width removed, not in Product model
        // height removed, not in Product model
        // packageWeight removed, not in Product model
        // packageLength removed, not in Product model
        // packageWidth removed, not in Product model
        // packageHeight removed, not in Product model
        // metaTitle removed, not in Product model
        // metaDescription removed, not in Product model
        // seoKeywords removed, not in Product model
        // status removed, not in Product model
        categoryId: body.categoryId ?? undefined,
        subCategoryId: body.subCategoryId ?? undefined
      }
    });
    return NextResponse.json(updated);
  } catch (error) {
    console.error("UPDATE PRODUCT ERROR:", error);
    return NextResponse.json(
      { error: "Update failed" },
      { status: 500 }
    );
  }
}

export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;

    console.log("DELETE ID:", id);

    if (!id) {
      return NextResponse.json(
        { error: "Missing product id" },
        { status: 400 }
      );
    }

    // Delete relations
    await prisma.variantImage.deleteMany({
      where: {
        variant: {
          productId: id,
        },
      },
    });

    await prisma.productVariant.deleteMany({
      where: { productId: id },
    });

    await prisma.productImage.deleteMany({
      where: { productId: id },
    });

    await prisma.productTag.deleteMany({
      where: { productId: id },
    });

    // Delete product
    await prisma.product.delete({
      where: { id },
    });

    return NextResponse.json({ success: true });

  } catch (error: any) {
    console.error("DELETE PRODUCT ERROR:", error);

    return NextResponse.json(
      { error: error.message || "Delete failed" },
      { status: 500 }
    );
  }
}