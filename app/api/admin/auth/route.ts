import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { getClientIp } from "@/lib/getIp";

import { prisma } from "@/lib/prisma";
import { applyRateLimit } from "@/lib/rateLimit";
import { logSecurityEvent } from "@/lib/secureLogger";
import { ADMIN_COOKIE_NAME, SESSION_MAX_AGE_SECONDS } from "@/lib/auth";
import { getLockDurationMs, formatLockDuration } from "@/lib/lockPolicy";

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

// ── GET: check login lock status ─────────────────────────────────────────────
export async function GET(req: NextRequest) {
  const email = req.nextUrl.searchParams.get("email");
  if (!email) return NextResponse.json({ locked: false });

  const identifier = `admin-login:${email.toLowerCase().trim()}`;
  const lock = await prisma.adminAuthLock.findUnique({ where: { identifier } });

  if (!lock) return NextResponse.json({ locked: false });

  // Backward-compat: respect legacy forever locks already in the DB.
  if (lock.forever) return NextResponse.json({ locked: true, forever: true });

  if (lock.lockedUntil && lock.lockedUntil > new Date()) {
    const remainingMs = lock.lockedUntil.getTime() - Date.now();
    return NextResponse.json({
      locked: true,
      forever: false,
      lockedUntil: lock.lockedUntil,
      retryAfter: formatLockDuration(remainingMs),
    });
  }

  return NextResponse.json({ locked: false });
}

// ── POST: password login → issues pending-2FA cookie ─────────────────────────
export async function POST(req: NextRequest) {
  // Rate limit: 10 attempts per IP per 15 minutes
  const ip =
    getClientIp(req);
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

    // Backward-compat: respect legacy forever locks already in DB.
    if (lock?.forever) {
      return NextResponse.json(
        { error: "Account is disabled. Contact the site owner." },
        { status: 403, headers: { "Cache-Control": "no-store" } }
      );
    }

    if (lock?.lockedUntil && lock.lockedUntil > new Date()) {
      const remainingMs = lock.lockedUntil.getTime() - Date.now();
      return NextResponse.json(
        {
          error: `Too many failed attempts. Please try again in ${formatLockDuration(remainingMs)}.`,
          lockedUntil: lock.lockedUntil,
          retryAfter: formatLockDuration(remainingMs),
        },
        { status: 429, headers: { "Cache-Control": "no-store" } }
      );
    }

    const admin = await prisma.admin.findUnique({ where: { email } });

    // Always run bcrypt even for unknown email to prevent timing attacks.
    const DUMMY_HASH =
      "$2b$10$abcdefghijklmnopqrstuuABCDEFGHIJKLMNOPQRSTUVWXYZ012345";
    const candidateHash = admin?.passwordHash ?? DUMMY_HASH;
    const passwordMatch = await bcrypt.compare(
      parsed.data.password,
      candidateHash
    );

    if (!admin || !admin.active || !passwordMatch) {
      // Use the existing failCount if there's a lock record, else 0.
      const result = await handleLoginFail(
        identifier,
        lock?.failCount ?? 0,
        ip
      );
      const remainingMs = result.lockedUntil.getTime() - Date.now();
      return NextResponse.json(
        {
          error: `Invalid credentials. Please try again in ${formatLockDuration(remainingMs)}.`,
          lockedUntil: result.lockedUntil,
          retryAfter: formatLockDuration(remainingMs),
        },
        { status: 401, headers: { "Cache-Control": "no-store" } }
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
      sameSite: "strict",
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

// ── DELETE: logout — clear both session cookies ───────────────────────────────
export async function DELETE() {
  const isProduction = process.env.NODE_ENV === "production";

  const res = NextResponse.json(
    { ok: true },
    { headers: { "Cache-Control": "no-store" } }
  );

  const cookieOpts = {
    httpOnly: true,
    secure: isProduction,
    sameSite: "strict" as const,
    path: "/",
    maxAge: 0,
    expires: new Date(0),
  };

  res.cookies.set(ADMIN_COOKIE_NAME, "", cookieOpts);
  res.cookies.set(PENDING_2FA_COOKIE, "", cookieOpts);

  return res;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/**
 * Increments the fail counter and applies a progressive temporary lock.
 * Never sets forever=true — manual disable is done via Admin.active field.
 */
async function handleLoginFail(
  identifier: string,
  currentFailCount: number,
  ip: string
) {
  const nextFail    = currentFailCount + 1;
  const durationMs  = getLockDurationMs(nextFail);
  const lockedUntil = new Date(Date.now() + durationMs);

  logSecurityEvent({
    event: "admin_login_fail",
    ip,
    detail: identifier,
    failCount: nextFail,
    lockDuration: formatLockDuration(durationMs),
  });

  await prisma.adminAuthLock.upsert({
    where: { identifier },
    update: { failCount: nextFail, lockedUntil, forever: false },
    create: { identifier, failCount: nextFail, lockedUntil, forever: false },
  });

  return { lockedUntil };
}
