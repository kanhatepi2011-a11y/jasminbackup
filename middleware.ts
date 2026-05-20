import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";

const SESSION_COOKIE = "admin_token";

const ALLOWED_IP       = process.env.ADMIN_ALLOWED_IP ?? "";
const ADMIN_LOGIN_PATH = process.env.ADMIN_LOGIN_PATH ?? "/admin/login";

function getSecret() {
  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) return null;
  return new TextEncoder().encode(secret);
}

function getClientIP(req: NextRequest): string {
  // Vercel puts the real client IP in x-forwarded-for as the LAST entry
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) {
    const parts = forwarded.split(",").map(s => s.trim());
    // Last IP is the real client on Vercel
    return parts[parts.length - 1];
  }
  return req.headers.get("x-real-ip") ?? "unknown";
}

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;
  const ip = getClientIP(req);

  // 1. Block everyone except allowed IP (applies to ALL /admin pages including login)
  if (ALLOWED_IP && ip !== ALLOWED_IP) {
    return new NextResponse("404 Not Found", { status: 404 });
  }

  // 2. Always allow auth API
  if (pathname.startsWith("/api/admin/auth")) {
    return NextResponse.next();
  }

  // 3. Allow the login page (only reachable if IP passed step 1)
  if (pathname === ADMIN_LOGIN_PATH) {
    return NextResponse.next();
  }

  // 4. Hide default /admin/login if custom path is set
  if (ADMIN_LOGIN_PATH !== "/admin/login" && pathname === "/admin/login") {
    return new NextResponse("404 Not Found", { status: 404 });
  }

  // 5. Verify JWT
  const token  = req.cookies.get(SESSION_COOKIE)?.value;
  const secret = getSecret();

  if (!token || !secret) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    return NextResponse.redirect(new URL(ADMIN_LOGIN_PATH, req.url));
  }

  try {
    await jwtVerify(token, secret);
    return NextResponse.next();
  } catch {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    return NextResponse.redirect(new URL(ADMIN_LOGIN_PATH, req.url));
  }
}

export const config = {
  matcher: ["/admin/:path*", "/api/admin/:path*"],
};