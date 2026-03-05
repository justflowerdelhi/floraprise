import { prisma } from "@/lib/prisma";
import { NextResponse } from "next/server";

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const query = searchParams.get("q") || "";
  const sort = searchParams.get("sort") || "new";

  let orderBy: any = { createdAt: "desc" };
  if (sort === "price-low") {
    orderBy = { price: "asc" };
  }
  if (sort === "price-high") {
    orderBy = { price: "desc" };
  }

  const products = await prisma.product.findMany({
    where: {
      name: {
        contains: query,
        mode: "insensitive",
      },
    },
    include: {
      images: true,
    },
    orderBy,
    take: 40,
  });

  return NextResponse.json(products);
}