import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export async function GET() {
  try {
    const products = await prisma.product.findMany({
      include: {
        category: true,
      },
      orderBy: { createdAt: "desc" },
    });
    return NextResponse.json(products);
  } catch (error) {
    console.error("Error fetching products", error);
    return NextResponse.json({ error: "Failed to fetch products" }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const {
      name,
      slug,
      description = "",
      price,
      stock,
      category = "",
      tags = [],
      images = [],
      status = "draft",
      featured = false,
    } = body;

    if (!name || !slug || price === undefined || stock === undefined) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    const tagsArray = Array.isArray(tags)
      ? tags
      : typeof tags === "string"
        ? tags.split(",").map((t: string) => t.trim()).filter(Boolean)
        : [];

    const imagesArray = Array.isArray(images) ? images : [];

    const product = await prisma.product.create({
      data: {
        name,
        slug,
        description,
        price: Number(price),
        stock: Number(stock),
        categoryId: category,
        status,
        featured: Boolean(featured),
        tags: tagsArray.length
          ? {
              create: tagsArray.map((tagName: string) => ({
                tag: {
                  connectOrCreate: {
                    where: { name: tagName },
                    create: { name: tagName },
                  },
                },
              })),
            }
          : undefined,
        images: imagesArray.length
          ? {
              create: imagesArray.map((url: string) => ({ url })),
            }
          : undefined,
      },
    });

    return NextResponse.json(product, { status: 201 });
  } catch (error) {
    console.error("Error creating product", error);
    return NextResponse.json({ error: "Failed to create product" }, { status: 500 });
  }
}
