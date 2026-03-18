import { PrismaClient } from "@prisma/client";
import { NextResponse } from "next/server";
import fs from "fs";
import path from "path";

const prisma = new PrismaClient();

export async function POST(req: Request) {
  try {
    const formData = await req.formData();

    // 🟢 BASIC
    const name = formData.get("name") as string;
    const slugRaw = formData.get("slug") as string;
    const description = formData.get("description") as string;

    const price = Number(formData.get("price") || 0);
    const stock = Number(formData.get("stock") || 0);

    const categoryId = formData.get("categoryId") as string;
    const subCategoryId = formData.get("subCategoryId") as string;
    const status = formData.get("status") as string;

    // 🟢 SLUG
    const slug =
      slugRaw && slugRaw.trim() !== ""
        ? slugRaw
        : name
            .toLowerCase()
            .replace(/[^a-z0-9\s-]/g, "")
            .trim()
            .replace(/\s+/g, "-");

    // 🟢 FILES
    const productFiles = formData.getAll("images") as File[];
    const variantFiles = formData.getAll("variantImages") as File[];

    // 🟢 VARIANTS
    let variants: any[] = [];
    try {
      variants = JSON.parse(formData.get("variants") as string);
    } catch {}

    // =========================
    // 🖼️ PRODUCT IMAGES
    // =========================
    const productImages = [];

    for (let i = 0; i < productFiles.length; i++) {
      const file = productFiles[i];

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
    // 🎨 VARIANT IMAGES
    // =========================
    let variantIndex = 0;

    const variantData = await Promise.all(
      variants.map(async (variant) => {
        const images = [];

        if (!variant.imageNames || variant.imageNames.length === 0) return; // Skip processing if imageNames is missing or empty
        
        for (let i = 0; i < variant.imageNames.length; i++) {
          const file = variantFiles[variantIndex++];
          const buffer = Buffer.from(await file.arrayBuffer());
          const fileName = Date.now() + "-" + file.name;
          const filePath = path.join(process.cwd(), "public/uploads", fileName);
          fs.writeFileSync(filePath, buffer);
          images.push({
            url: "/uploads/" + fileName,
            order: i,
          });
        }

        return {
          name: variant.name,
          price: variant.price ? Number(variant.price) : null,
          stock: variant.stock ? Number(variant.stock) : null,
          images: {
            create: images,
          },
        };
      })
    );

    // =========================
    // 🧠 CREATE PRODUCT
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
      include: {
        images: true,
        variants: {
          include: { images: true },
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