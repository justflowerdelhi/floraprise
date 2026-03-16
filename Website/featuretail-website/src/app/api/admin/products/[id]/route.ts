import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {

    const { id } = await context.params;

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
        variants: {
          include: {
            options: true
          }
        },
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
  context: { params: Promise<{ id: string }> }
) {
  try {

    const { id } = await context.params;
    const body = await request.json();


    const updated = await prisma.product.update({
      where: { id },
      data: {
        name: body.name ?? undefined,
        slug: body.slug ?? undefined,
        description: body.description ?? undefined,
        bulletPoints: body.bulletPoints ?? undefined,

        price: body.price ? Number(body.price) : undefined,
        comparePrice: body.comparePrice ? Number(body.comparePrice) : undefined,

        stock: body.stock ? Number(body.stock) : undefined,
        sku: body.sku ?? undefined,

        weight: body.weight ? Number(body.weight) : undefined,
        length: body.length ? Number(body.length) : undefined,
        width: body.width ? Number(body.width) : undefined,
        height: body.height ? Number(body.height) : undefined,

        packageWeight: body.packageWeight ? Number(body.packageWeight) : undefined,
        packageLength: body.packageLength ? Number(body.packageLength) : undefined,
        packageWidth: body.packageWidth ? Number(body.packageWidth) : undefined,
        packageHeight: body.packageHeight ? Number(body.packageHeight) : undefined,

        metaTitle: body.metaTitle ?? undefined,
        metaDescription: body.metaDescription ?? undefined,
        seoKeywords: body.seoKeywords ?? undefined,

        status: body.status ?? undefined,
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