import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { jwtVerify } from "jose";
import { randomBytes } from "crypto";

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

/**
 * Build a nonce-based Content-Security-Policy header.
 *
 * The nonce is a random 16-byte value encoded as base64. It is included in
 * the CSP `script-src` and `style-src` directives so that only scripts and
 * styles carrying the matching `nonce` attribute are allowed to execute.
 * This eliminates the need for `'unsafe-inline'` everywhere.
 *
 * The nonce is also forwarded to the Next.js app via the `x-nonce` response
 * header so that Server Components (e.g. app/layout.tsx) can read it and
 * attach it to any <Script> or <style> tags they render.
 */
function buildCspHeader(nonce: string, isProduction: boolean): string {
  // In development we still allow 'unsafe-eval' because Next.js hot-reload
  // relies on eval(). The nonce covers all legitimate inline scripts in both
  // environments so 'unsafe-inline' is gone everywhere.
  const scriptSrc = isProduction
    ? `'self' 'nonce-${nonce}'`
    : `'self' 'nonce-${nonce}' 'unsafe-eval'`;

  const connectSrc = isProduction
    ? "'self' https:"
    : "'self' http://localhost:* ws://localhost:* wss: https:";

  // FIX #3: Replace 'unsafe-inline' with nonce-based style-src.
  // Any <style> or styled component that needs inline styles must carry
  // the matching nonce attribute (style nonce={nonce}).
  const styleSrc = `'self' 'nonce-${nonce}' https://fonts.googleapis.com`;

  return [
    "default-src 'self'",
    `script-src ${scriptSrc}`,
    `style-src ${styleSrc}`,
    "font-src 'self' data: https://fonts.gstatic.com",
    [
      "img-src",
      "'self'",
      "data:",
      "blob:",
      "https://i.ibb.co",
      "https://api.qrserver.com",
      "https://img.freepik.com",
      "https://res.cloudinary.com",
      "https://*.cloudinary.com",
    ].join(" "),
    `connect-src ${connectSrc}`,
    "frame-src 'none'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "object-src 'none'",
    "manifest-src 'self'",
    "worker-src 'self' blob:",
    isProduction ? "upgrade-insecure-requests" : "",
  ]
    .filter(Boolean)
    .join("; ");
}

export async function middleware(req: NextRequest) {
  const { pathname } = req.nextUrl;

  // Generate a fresh cryptographic nonce for every request.
  const nonce = randomBytes(16).toString("base64");
  const isProduction = process.env.NODE_ENV === "production";

  const token = req.cookies.get(SESSION_COOKIE)?.value;
  const isLoggedIn = await isValidAdminToken(token);

  // FIX #2: Attach CSP nonce + all recommended security headers to every response.
  // X-Frame-Options is redundant with frame-ancestors 'none' in CSP but kept
  // here for legacy browsers (IE 11) that do not understand CSP.
  function withNonce(response: NextResponse): NextResponse {
    response.headers.set("Content-Security-Policy", buildCspHeader(nonce, isProduction));
    response.headers.set("x-nonce", nonce);
    // Prevent MIME-type sniffing
    response.headers.set("X-Content-Type-Options", "nosniff");
    // Clickjacking protection for legacy browsers
    response.headers.set("X-Frame-Options", "DENY");
    // Limit referrer information sent to third parties
    response.headers.set("Referrer-Policy", "strict-origin-when-cross-origin");
    // Disable unnecessary browser features
    response.headers.set(
      "Permissions-Policy",
      "camera=(), microphone=(), geolocation=(), payment=()"
    );
    // HSTS: only set in production (HTTPS required)
    if (isProduction) {
      response.headers.set(
        "Strict-Transport-Security",
        "max-age=31536000; includeSubDomains"
      );
    }
    return response;
  }

  // ✅ Allow admin auth API always
  // Example: /api/admin/auth, /api/admin/auth/2fa, /api/admin/auth/logout
  if (pathname.startsWith("/api/admin/auth")) {
    return withNonce(NextResponse.next());
  }

  // ✅ Login pages
  // If already logged in, go to admin home
  if (LOGIN_PATHS.has(pathname)) {
    if (isLoggedIn) {
      return withNonce(NextResponse.redirect(new URL(ADMIN_HOME_PATH, req.url)));
    }

    return withNonce(NextResponse.next());
  }

  // ✅ Honeypot page
  // If logged in, redirect to real admin page
  // If not logged in, allow honeypot page to show
  if (pathname === HONEY_PATH) {
    if (isLoggedIn) {
      return withNonce(NextResponse.redirect(new URL(ADMIN_HOME_PATH, req.url)));
    }

    return withNonce(NextResponse.next());
  }

  // ✅ Not logged in + exact /admin → redirect to honeypot
  if (!isLoggedIn && pathname === ADMIN_HOME_PATH) {
    return withNonce(NextResponse.redirect(new URL(HONEY_PATH, req.url)));
  }

  // ✅ Not logged in + protected admin API → return 401 JSON
  if (!isLoggedIn && pathname.startsWith("/api/admin")) {
    return withNonce(
      NextResponse.json(
        { error: "Unauthorized" },
        { status: 401 }
      )
    );
  }

  // ✅ Not logged in + protected admin page → redirect to login
  if (!isLoggedIn && pathname.startsWith("/admin")) {
    return withNonce(NextResponse.redirect(new URL(ADMIN_LOGIN_PATH, req.url)));
  }

  // ✅ Logged in → allow access
  return withNonce(NextResponse.next());
}

export const config = {
  matcher: ["/admin/:path*", "/api/admin/:path*"],
};
