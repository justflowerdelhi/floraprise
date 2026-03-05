import { prisma } from "@/lib/prisma"
import { NextResponse } from "next/server"

export async function POST(req: Request) {

  try {

    const body = await req.json()

    const message = await prisma.contactMessage.create({
      data: {
        name: body.name,
        email: body.email,
        subject: body.subject,
        message: body.message
      }
    })

    return NextResponse.json(message)

  } catch (error) {

    console.error("CONTACT ERROR:", error)

    return NextResponse.json(
      { error: "Server error" },
      { status: 500 }
    )

  }

}