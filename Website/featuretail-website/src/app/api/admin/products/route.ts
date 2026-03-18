export async function GET() {
  try {
    const products = await prisma.product.findMany({
      include: {
        images: true,
        variants: true,
        category: true,
      },
      orderBy: { createdAt: "desc" },
    });
    return NextResponse.json(products);
  } catch (error: any) {
    return NextResponse.json(
      { error: error.message || "Failed to fetch products" },
      { status: 500 }
    );
  }
}
import { PrismaClient } from "@prisma/client";
import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";

const prisma = new PrismaClient();

export async function POST(req: Request) {
  try {
    const formData = await req.formData();

    // BASIC FIELDS
    const name = formData.get("name") as string;
    const slug = formData.get("slug") as string;
    const description = formData.get("description") as string;

    const price = Number(formData.get("price") || 0);
    const stock = Number(formData.get("stock") || 0);

    const categoryId = formData.get("categoryId") as string;
    const subCategoryId = formData.get("subCategoryId") as string;
    const status = formData.get("status") as string;

    // FILES
    const productFiles = formData.getAll("images") as File[];

    // VARIANTS
    let variants: any[] = [];
    try {
      variants = JSON.parse(formData.get("variants") as string);
    } catch {
      variants = [];
    }

    // =========================
    // PRODUCT IMAGES
    // =========================
    const productImages: any[] = [];

    for (let i = 0; i < productFiles.length; i++) {
      const file = productFiles[i];

      if (!(file instanceof File)) continue;

      const buffer = Buffer.from(await file.arrayBuffer());
      const fileName = Date.now() + "-" + file.name;

      const filePath = path.join(process.cwd(), "public/uploads", fileName);
      fs.writeFileSync(filePath, buffer);

      productImages.push({
        url: "/uploads/" + fileName,
        order: i,
      });
    }

    // =========================
    // VARIANTS
    // =========================
    const variantData = variants.map((v: any) => ({
      name: v.name,
      price: Number(v.price || 0),
      stock: Number(v.stock || 0),
      images: { create: [] },
    }));

    // =========================
    // CREATE PRODUCT
    // =========================
    const product = await prisma.product.create({
      data: {
        name,
        slug,
        description,
        price,
        stock,
        status,
        categoryId,
        subCategoryId,

        images: {
          create: productImages,
        },

        variants: {
          create: variantData,
        },
      },
    });

    return NextResponse.json(product);
  } catch (error: any) {
    console.error("PRODUCT CREATE ERROR:", error);

    return NextResponse.json(
      { error: error.message || "Failed" },
      { status: 500 }
    );
  }
}