import { prisma } from "@/lib/prisma"
import { NextResponse } from "next/server"

export async function GET() {
  const revenue = await prisma.order.aggregate({
    _sum: { total: true }
  })
  const totalOrders = await prisma.order.count()
  const totalProducts = await prisma.product.count()
  const customers = await prisma.order.groupBy({
    by: ["shippingEmail"]
  })
  const unreadMessages = await prisma.contactMessage.count({
    where: { isRead: false }
  })
  return NextResponse.json({
    revenue: revenue._sum.total || 0,
    orders: totalOrders,
    products: totalProducts,
    customers: customers.length,
    messages: unreadMessages
  })
}
