import { NextResponse } from "next/server";

export async function GET() {
  const products: any[] = [];
  return NextResponse.json(products);
}
