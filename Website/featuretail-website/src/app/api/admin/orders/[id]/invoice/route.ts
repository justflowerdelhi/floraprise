import { prisma } from "@/lib/prisma"
import PDFDocument from "pdfkit"
import { NextResponse } from "next/server"

export async function GET(
  req: Request,
  { params }: { params: { id: string } }
){
  const order = await prisma.order.findUnique({
    where:{ id: params.id },
    include:{ items:true }
  })
  if(!order){
    return NextResponse.json({error:"Order not found"})
  }
  const doc = new PDFDocument()
  let buffers:any[] = []
  doc.on("data", buffers.push.bind(buffers))
  doc.on("end", ()=>{})
  doc.fontSize(20).text("Tax Invoice", {align:"center"})
  doc.moveDown()
  doc.fontSize(12).text(`Order Number: ${order.orderNumber}`)
  doc.text(`Customer: ${order.shippingName}`)
  doc.text(`Phone: ${order.shippingPhone}`)
  doc.text(`Email: ${order.shippingEmail}`)
  doc.moveDown()
  doc.text("Items")
  order.items.forEach(item=>{
    doc.text(
      `${item.name} - Qty: ${item.quantity} - ₹${item.price}`
    )
  })
  doc.moveDown()
  doc.text(`Subtotal: ₹${order.subtotal}`)
  doc.text(`Shipping: ₹${order.shipping}`)
  doc.text(`Total: ₹${order.total}`)
  doc.end()
  const pdfBuffer = await new Promise((resolve)=>{
    doc.on("end",()=>{
      resolve(Buffer.concat(buffers))
    })
  })
  return new NextResponse(pdfBuffer as any,{
    headers:{
      "Content-Type":"application/pdf",
      "Content-Disposition":`attachment; filename=invoice-${order.orderNumber}.pdf`
    }
  })
}
