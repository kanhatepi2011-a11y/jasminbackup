import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";

const SESSION_COOKIE = "admin_token";
const ADMIN_LOGIN_PATH = process.env.ADMIN_LOGIN_PATH ?? "/admin/sophallogin";
const EXTRA_LOGIN_PATHS = new Set(["/admin/login", "/admin/sophallogin"]);
const HONEY_PATH = "/admin/fuckyou";

function getSecret() {
  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) return null;
  return new TextEncoder().encode(secret);
}

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // ✅ API auth routes → allow always
  if (pathname.startsWith("/api/admin/auth")) {
    return NextResponse.next();
  }

  // ✅ Login pages → allow always
  if (EXTRA_LOGIN_PATHS.has(pathname)) {
    return NextResponse.next();
  }

  const token = req.cookies.get(SESSION_COOKIE)?.value;
  const secret = getSecret();

  // ✅ ពិនិត្យ Token មុន
  const isLoggedIn = token && secret
    ? await jwtVerify(token, secret).then(() => true).catch(() => false)
    : false;

  // ✅ Admin login រួចហើយ + ចូល /admin/fuckyou → redirect ទៅ /admin/dashboard
  if (isLoggedIn && pathname === HONEY_PATH) {
    return NextResponse.redirect(new URL("/admin/dashboard", req.url));
  }

  // ✅ User មិន Login + ចូល /admin (exact) → redirect ទៅ /admin/fuckyou
  if (!isLoggedIn && pathname === "/admin") {
    return NextResponse.redirect(new URL(HONEY_PATH, req.url));
  }

  // ✅ Honeypot page → allow (for non-logged-in users)
  if (pathname === HONEY_PATH) {
    return NextResponse.next();
  }

  // ✅ មិន Login + ចូល /admin/* ផ្សេងទៀត → redirect ទៅ login
  if (!isLoggedIn) {
    if (pathname.startsWith("/api/")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    return NextResponse.redirect(new URL(ADMIN_LOGIN_PATH, req.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/api/admin/:path*"],
};