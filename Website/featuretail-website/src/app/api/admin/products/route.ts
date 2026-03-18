export const dynamic = "force-dynamic";
// Helper to save a file and return its URL
async function saveFile(file: File) {
  const buffer = Buffer.from(await file.arrayBuffer());
  const fileName = Date.now() + '-' + file.name;
  const filePath = path.join(process.cwd(), 'public/uploads', fileName);
  fs.writeFileSync(filePath, buffer);
  return '/uploads/' + fileName;
}
export async function GET() {
  try {
    const products = await prisma.product.findMany({
      include: {
        category: true,
        variants: {
          include: {
            images: true
          }
        },
        images: true
      },
      orderBy: {
        createdAt: "desc"
      }
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
    const rawSubCategoryId = formData.get("subCategoryId") as string;
    const subCategoryId =
      rawSubCategoryId && rawSubCategoryId !== ""
        ? rawSubCategoryId
        : null;
    const status = formData.get("status") as string;

    // FILES
    const productFiles = formData.getAll("images") as File[];

    // VARIANT FILES
    const variantFiles = formData.getAll("variantImages") as File[];

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
    const variantData = await Promise.all(variants.map(async (v: any, i: number) => ({
      name: v.name,
      price: Number(v.price || 0),
      stock: Number(v.stock || 0),
      images: {
        create: variantFiles[i]
          ? [
              {
                url: await saveFile(variantFiles[i]),
                order: 0
              }
            ]
          : []
      },
    })));

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