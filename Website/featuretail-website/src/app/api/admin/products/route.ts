import { prisma } from "@/lib/prisma"
import { NextResponse } from "next/server"

/* ================= GET PRODUCTS ================= */

export async function GET() {

  try {


    const products = await prisma.product.findMany({
      include: {
        category: true,
        subCategory: true,
        images: true,
        variants: {
          include: {
            options: true
          }
        }
      },
      orderBy: {
        createdAt: "desc"
      }
    })

    return NextResponse.json(products)

  } catch (error) {

    console.error("PRODUCT FETCH ERROR:", error)

    return NextResponse.json(
      { error: "Failed to fetch products" },
      { status: 500 }
    )
  }

}

/* ---------------- CREATE PRODUCT ---------------- */

export async function POST(req: Request) {
  try {

    let data: any = {}

    const contentType = req.headers.get("content-type") || ""

    /* ---------- PARSE REQUEST ---------- */

    if (contentType.includes("multipart/form-data")) {

      const formData = await req.formData()

      formData.forEach((value, key) => {
        if (typeof value === "string") {
          data[key] = value
        }
      })

    } else {

      data = await req.json()

    }

    console.log("DATA RECEIVED:", data)

    /* ---------- VALIDATION ---------- */

    if (!data.name || data.name.trim() === "") {

      return NextResponse.json(
        { error: "Product name is required" },
        { status: 400 }
      )

    }

    /* ---------- SLUG ---------- */

    if (!data.slug || data.slug.trim() === "") {

      data.slug = data.name
        .toLowerCase()
        .replace(/[^a-z0-9\s-]/g, "")
        .trim()
        .replace(/\s+/g, "-")

    }

    /* ---------- VARIANTS ---------- */

    let variants: any[] = []

    if (data.variants) {

      try {
        const raw = data.variants;
        if (raw && typeof raw === "string") {
          variants = JSON.parse(raw);
        } else if (raw) {
          variants = raw;
        }
      } catch (err) {
        console.error("VARIANT PARSE ERROR:", err);
        variants = [];
      }

    }

    /* ---------- CREATE PRODUCT ---------- */

    const product = await prisma.product.create({

      data: {

        name: data.name,
        slug: data.slug,
        description: data.description || "",

        price: Number(data.price || 0),
        stock: Number(data.stock || 0),

        categoryId: data.categoryId,
        subCategoryId: data.subCategoryId || null,

        variants: variants.length
          ? {
              create: variants.map((v: any) => ({
                name: v.sku || "Variant",
                image: v.image || null,
                options: {
                  create: (v.options || []).map((o: any) => ({
                    value: o.value,
                    price: Number(v.price || 0),
                    stock: Number(v.stock || 0)
                  }))
                }
              }))
            }
          : undefined

      },

      include: {
        variants: true
      }

    })

    return NextResponse.json(product)

  } catch (error) {

    console.error("PRODUCT CREATE ERROR:", error)

    return NextResponse.json(
      { error: "Product creation failed" },
      { status: 500 }
    )

  }
}