import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export async function GET(
  req: Request,
  context: { params: Promise<{ slug: string }> }
) {
  try {
    // ✅ MUST AWAIT PARAMS (NEW NEXT.JS RULE)
    const { slug } = await context.params;

    console.log("API SLUG:", slug);

    if (!slug) {
      return NextResponse.json(
        { error: "Missing slug" },
        { status: 400 }
      );
    }

    const product = await prisma.product.findUnique({
      where: { slug },
      include: {
        images: true,
        variants: {
          include: {
            images: true,
          },
        },
        category: true,
      },
    });

    if (!product) {
      return NextResponse.json(
        { error: "Product not found" },
        { status: 404 }
      );
    }

    return NextResponse.json(product);
  } catch (error) {
    console.error("PRODUCT FETCH ERROR:", error);
    return NextResponse.json(
      { error: "Server error" },
      { status: 500 }
    );
  }
}