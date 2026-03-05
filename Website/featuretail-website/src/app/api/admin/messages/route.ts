import { prisma } from "@/lib/prisma"
import { NextResponse } from "next/server"

export async function GET(){
  const messages = await prisma.contactMessage.findMany({
    orderBy:{
      createdAt:"desc"
    }
  })
  return NextResponse.json(messages)
}
