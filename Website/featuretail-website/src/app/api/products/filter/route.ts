import { PrismaClient } from "@prisma/client"
import { NextResponse } from "next/server"

const prisma = new PrismaClient()

export async function GET(req: Request) {

  const { searchParams } = new URL(req.url)

  const category = searchParams.get("category")
  const subCategory = searchParams.get("subcategory")
  const tag = searchParams.get("tag")
  const minPrice = searchParams.get("min")
  const maxPrice = searchParams.get("max")

  const products = await prisma.product.findMany({

    where: {

      categoryId: category || undefined,
      subCategoryId: subCategory || undefined,

      price: {
        gte: minPrice ? Number(minPrice) : undefined,
        lte: maxPrice ? Number(maxPrice) : undefined
      },

      tags: tag
        ? {
            some: {
              tag: {
                name: tag
              }
            }
          }
        : undefined
    },

    include:{
      images:true
    }

  })

  return NextResponse.json(products)
}