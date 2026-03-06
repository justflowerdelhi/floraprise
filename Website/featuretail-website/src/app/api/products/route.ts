import { NextResponse } from "next/server";

export async function GET() {
  const products = [];
  return NextResponse.json(products);
}
