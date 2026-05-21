import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import { prisma } from "@/lib/prisma";
import { applyRateLimit } from "@/lib/rateLimit";
import { logSecurityEvent } from "@/lib/secureLogger";
import { ADMIN_COOKIE_NAME, SESSION_MAX_AGE_SECONDS } from "@/lib/auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const PENDING_2FA_COOKIE = "admin_2fa_pending";
const DEFAULT_2FA_TTL_SECONDS = 5 * 60;

function getAdminJwtSecret() {
  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) throw new Error("ADMIN_JWT_SECRET is not set");
  return secret;
}

function get2FATtlSeconds() {
  const ttl = Number(
    process.env.ADMIN_2FA_TTL_SECONDS || DEFAULT_2FA_TTL_SECONDS
  );
  if (!Number.isFinite(ttl) || ttl <= 0) return DEFAULT_2FA_TTL_SECONDS;
  return Math.floor(ttl);
}

// ── GET: check login lock status ────────────────────────────────────────────
export async function GET(req: NextRequest) {
  const email = req.nextUrl.searchParams.get("email");
  if (!email) return NextResponse.json({ locked: false });

  const identifier = `admin-login:${email.toLowerCase().trim()}`;
  const lock = await prisma.adminAuthLock.findUnique({ where: { identifier } });

  if (!lock) return NextResponse.json({ locked: false });
  if (lock.forever) return NextResponse.json({ locked: true, forever: true });
  if (lock.lockedUntil && lock.lockedUntil > new Date()) {
    return NextResponse.json({
      locked: true,
      forever: false,
      lockedUntil: lock.lockedUntil,
    });
  }

  return NextResponse.json({ locked: false });
}

// ── POST: password login → issues pending-2FA cookie ────────────────────────
export async function POST(req: NextRequest) {
  // Rate limit: 10 attempts per IP per 15 minutes (Issue #4)
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ?? "unknown";
  const rl = await applyRateLimit(`admin-login:${ip}`, 10, 15 * 60 * 1000, ip);
  if (rl) return rl;

  try {
    const body = await req.json().catch(() => ({}));
    const parsed = loginSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid credentials" },
        { status: 400, headers: { "Cache-Control": "no-store" } }
      );
    }

    const email = parsed.data.email.toLowerCase().trim();
    const identifier = `admin-login:${email}`;

    const lock = await prisma.adminAuthLock.findUnique({
      where: { identifier },
    });

    if (lock?.forever) {
      return NextResponse.json(
        { error: "Account locked permanently. Contact the site owner." },
        { status: 403, headers: { "Cache-Control": "no-store" } }
      );
    }
    if (lock?.lockedUntil && lock.lockedUntil > new Date()) {
      return NextResponse.json(
        { error: "Account temporarily locked. Please wait.", lockedUntil: lock.lockedUntil },
        { status: 429, headers: { "Cache-Control": "no-store" } }
      );
    }

    const admin = await prisma.admin.findUnique({ where: { email } });

    if (!admin || !admin.active) {
      // Count fail even for unknown email (prevent enumeration)
      await handleLoginFail(identifier, lock?.failCount ?? 0, ip);
      return NextResponse.json(
        { error: "Invalid email or password" },
        { status: 401, headers: { "Cache-Control": "no-store" } }
      );
    }

    const passwordMatch = await bcrypt.compare(
      parsed.data.password,
      admin.passwordHash
    );

    if (!passwordMatch) {
      const result = await handleLoginFail(
        identifier,
        lock?.failCount ?? 0,
        ip
      );

      if (result.forever) {
        return NextResponse.json(
          { error: "Account locked permanently. Contact the site owner." },
          { status: 403, headers: { "Cache-Control": "no-store" } }
        );
      }
      return NextResponse.json(
        { error: "Invalid email or password. Account locked temporarily.", lockedUntil: result.lockedUntil },
        { status: 429, headers: { "Cache-Control": "no-store" } }
      );
    }

    // ✅ Password correct — clear lock, issue pending-2FA token
    await prisma.adminAuthLock.deleteMany({ where: { identifier } });

    const ttlSeconds = get2FATtlSeconds();
    const pendingToken = jwt.sign(
      {
        type: "admin-2fa-pending",
        adminId: String(admin.id),
        email: admin.email,
      },
      getAdminJwtSecret(),
      { expiresIn: ttlSeconds }
    );

    const res = NextResponse.json(
      {
        ok: true,
        requires2FA: true,
        email: admin.email,
        message: "Password correct. Please confirm 2FA code.",
      },
      { headers: { "Cache-Control": "no-store" } }
    );

    const isProduction = process.env.NODE_ENV === "production";
    res.cookies.set(PENDING_2FA_COOKIE, pendingToken, {
      httpOnly: true,
      secure: isProduction,
      sameSite: "lax",
      path: "/",
      maxAge: ttlSeconds,
    });

    return res;
  } catch (error) {
    console.error("Admin login error:", error);
    return NextResponse.json(
      { error: "Something went wrong" },
      { status: 500, headers: { "Cache-Control": "no-store" } }
    );
  }
}

// ── DELETE: logout — clear both session cookies ──────────────────────────────
export async function DELETE() {
  const isProduction = process.env.NODE_ENV === "production";

  const res = NextResponse.json(
    { ok: true },
    { headers: { "Cache-Control": "no-store" } }
  );

  const cookieOpts = {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax" as const,
    path: "/",
    maxAge: 0,
    expires: new Date(0),
  };

  res.cookies.set(ADMIN_COOKIE_NAME, "", cookieOpts);
  res.cookies.set(PENDING_2FA_COOKIE, "", cookieOpts);

  return res;
}

// ── Helpers ──────────────────────────────────────────────────────────────────
async function handleLoginFail(
  identifier: string,
  currentFailCount: number,
  ip: string
) {
  const nextFail = currentFailCount + 1;

  logSecurityEvent({
    event: "admin_login_fail",
    ip,
    detail: identifier,
    failCount: nextFail,
  });

  if (nextFail >= 2) {
    await prisma.adminAuthLock.upsert({
      where: { identifier },
      update: { failCount: nextFail, lockedUntil: null, forever: true },
      create: {
        identifier,
        failCount: nextFail,
        lockedUntil: null,
        forever: true,
      },
    });
    logSecurityEvent({
      event: "admin_locked_forever",
      ip,
      detail: identifier,
    });
    return { forever: true, lockedUntil: null };
  }

  const lockedUntil = new Date(Date.now() + 5 * 60 * 1000);
  await prisma.adminAuthLock.upsert({
    where: { identifier },
    update: { failCount: nextFail, lockedUntil, forever: false },
    create: {
      identifier,
      failCount: nextFail,
      lockedUntil,
      forever: false,
    },
  });
  return { forever: false, lockedUntil };
}