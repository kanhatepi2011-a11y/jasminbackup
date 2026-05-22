import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";

const SESSION_COOKIE = "admin_token";

const ADMIN_HOME_PATH = "/admin";
const ADMIN_LOGIN_PATH = process.env.ADMIN_LOGIN_PATH || "/admin/sophallogin";
const HONEY_PATH = "/admin/fuckyou";

const LOGIN_PATHS = new Set([
  ADMIN_LOGIN_PATH,
  "/admin/login",
  "/admin/sophallogin",
]);

function getSecret() {
  const secret = process.env.ADMIN_JWT_SECRET;

  if (!secret) {
    return null;
  }

  return new TextEncoder().encode(secret);
}

async function isValidAdminToken(token?: string) {
  const secret = getSecret();

  if (!token || !secret) {
    return false;
  }

  try {
    await jwtVerify(token, secret);
    return true;
  } catch {
    return false;
  }
}

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  const token = req.cookies.get(SESSION_COOKIE)?.value;
  const isLoggedIn = await isValidAdminToken(token);

  // ✅ Allow admin auth API always
  // Example: /api/admin/auth, /api/admin/auth/2fa, /api/admin/auth/logout
  if (pathname.startsWith("/api/admin/auth")) {
    return NextResponse.next();
  }

  // ✅ Login pages
  // If already logged in, go to admin home
  if (LOGIN_PATHS.has(pathname)) {
    if (isLoggedIn) {
      return NextResponse.redirect(new URL(ADMIN_HOME_PATH, req.url));
    }

    return NextResponse.next();
  }

  // ✅ Honeypot page
  // If logged in, redirect to real admin page
  // If not logged in, allow honeypot page to show
  if (pathname === HONEY_PATH) {
    if (isLoggedIn) {
      return NextResponse.redirect(new URL(ADMIN_HOME_PATH, req.url));
    }

    return NextResponse.next();
  }

  // ✅ Not logged in + exact /admin → redirect to honeypot
  if (!isLoggedIn && pathname === ADMIN_HOME_PATH) {
    return NextResponse.redirect(new URL(HONEY_PATH, req.url));
  }

  // ✅ Not logged in + protected admin API → return 401 JSON
  if (!isLoggedIn && pathname.startsWith("/api/admin")) {
    return NextResponse.json(
      { error: "Unauthorized" },
      { status: 401 }
    );
  }

  // ✅ Not logged in + protected admin page → redirect to login
  if (!isLoggedIn && pathname.startsWith("/admin")) {
    return NextResponse.redirect(new URL(ADMIN_LOGIN_PATH, req.url));
  }

  // ✅ Logged in → allow access
  return NextResponse.next();
}

export const config = {
  matcher: ["/admin/:path*", "/api/admin/:path*"],
};