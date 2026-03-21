import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // ✅ allow login page
  if (pathname === "/admin/login") {
    return NextResponse.next();
  }

  // 🔐 get token properly
  const token = request.cookies.get("token")?.value;

  console.log("MIDDLEWARE TOKEN:", token); // 👈 DEBUG

  // protect admin routes
  if (
    (pathname.startsWith("/admin") || pathname.startsWith("/api/admin")) &&
    !token
  ) {
    return NextResponse.redirect(new URL("/admin/login", request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/api/admin/:path*"],
};