import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

const PENDING_2FA_COOKIE = "admin_2fa_pending";
const ADMIN_COOKIE_NAME = "admin_token";
const DEFAULT_2FA_TTL_SECONDS = 5 * 60;

function getAdminJwtSecret() {
  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) throw new Error("ADMIN_JWT_SECRET is not set");
  return secret;
}

function get2FATtlSeconds() {
  const ttl = Number(process.env.ADMIN_2FA_TTL_SECONDS || DEFAULT_2FA_TTL_SECONDS);
  if (!Number.isFinite(ttl) || ttl <= 0) return DEFAULT_2FA_TTL_SECONDS;
  return Math.floor(ttl);
}

// ✅ GET — check login lock status (used by frontend on page refresh)
export async function GET(req: NextRequest) {
  const email = req.nextUrl.searchParams.get("email");

  if (!email) {
    return NextResponse.json({ locked: false });
  }

  const identifier = `admin-login:${email.toLowerCase().trim()}`;

  const lock = await prisma.adminAuthLock.findUnique({
    where: { identifier },
  });

  if (!lock) return NextResponse.json({ locked: false });

  if (lock.forever) {
    return NextResponse.json({ locked: true, forever: true });
  }

  if (lock.lockedUntil && lock.lockedUntil > new Date()) {
    return NextResponse.json({
      locked: true,
      forever: false,
      lockedUntil: lock.lockedUntil,
    });
  }

  return NextResponse.json({ locked: false });
}

export async function POST(req: NextRequest) {
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

    // ✅ ពិនិត្យ lock មុន
    const lock = await prisma.adminAuthLock.findUnique({ where: { identifier } });

    if (lock?.forever) {
      return NextResponse.json(
        { error: "គណនីត្រូវបាន lock ជាអចិន្ត្រៃយ៍។ សូមទាក់ទង owner។" },
        { status: 403, headers: { "Cache-Control": "no-store" } }
      );
    }

    if (lock?.lockedUntil && lock.lockedUntil > new Date()) {
      return NextResponse.json(
        {
          error: "លើកទី១ password ខុស Lock 5 នាទី សូមរង់ចាំ។",
          lockedUntil: lock.lockedUntil,
        },
        { status: 429, headers: { "Cache-Control": "no-store" } }
      );
    }

    const admin = await prisma.admin.findUnique({ where: { email } });

    if (!admin || !admin.active) {
      // ✅ count fail even for unknown email (prevent enumeration)
      await handleLoginFail(identifier, lock?.failCount ?? 0);
      return NextResponse.json(
        { error: "Invalid email or password" },
        { status: 401, headers: { "Cache-Control": "no-store" } }
      );
    }

    const passwordMatch = await bcrypt.compare(parsed.data.password, admin.passwordHash);

    if (!passwordMatch) {
      const result = await handleLoginFail(identifier, lock?.failCount ?? 0);

      if (result.forever) {
        return NextResponse.json(
          { error: "password ខុស ២ លើក Lock ជាអចិន្ត្រៃយ៍ សូមទាក់ទង owner។" },
          { status: 403, headers: { "Cache-Control": "no-store" } }
        );
      }

      return NextResponse.json(
        {
          error: "password ខុស លើកទី១ Lock 5 នាទី សូមរង់ចាំ។",
          lockedUntil: result.lockedUntil,
        },
        { status: 429, headers: { "Cache-Control": "no-store" } }
      );
    }

    // ✅ Login ជោគជ័យ → Clear lock
    await prisma.adminAuthLock.deleteMany({ where: { identifier } });

    const ttlSeconds = get2FATtlSeconds();
    const pendingToken = jwt.sign(
      { type: "admin-2fa-pending", adminId: String(admin.id), email: admin.email },
      getAdminJwtSecret(),
      { expiresIn: ttlSeconds }
    );

    const res = NextResponse.json(
      { ok: true, requires2FA: true, email: admin.email, message: "Password correct. Please confirm 2FA code." },
      { headers: { "Cache-Control": "no-store" } }
    );

    const isProduction = process.env.NODE_ENV === "production";
    res.cookies.set(PENDING_2FA_COOKIE, pendingToken, {
      httpOnly: true,
      secure: isProduction,
      sameSite: "lax",
      path: "/",
      maxAge: ttlSeconds,
      expires: new Date(Date.now() + ttlSeconds * 1000),
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

async function handleLoginFail(identifier: string, currentFailCount: number) {
  const nextFail = currentFailCount + 1;

  // ✅ លើកទី១ → Lock 5 នាទី | លើកទី២+ → Lock ជាអចិន្ត្រៃយ៍
  if (nextFail >= 2) {
    await prisma.adminAuthLock.upsert({
      where: { identifier },
      update: { failCount: nextFail, lockedUntil: null, forever: true },
      create: { identifier, failCount: nextFail, lockedUntil: null, forever: true },
    });
    return { forever: true, lockedUntil: null };
  }

  const lockedUntil = new Date(Date.now() + 5 * 60 * 1000); // 5 នាទី
  await prisma.adminAuthLock.upsert({
    where: { identifier },
    update: { failCount: nextFail, lockedUntil, forever: false },
    create: { identifier, failCount: nextFail, lockedUntil, forever: false },
  });
  return { forever: false, lockedUntil };
}

export async function DELETE() {
  const isProduction = process.env.NODE_ENV === "production";

  const res = NextResponse.json(
    { ok: true },
    { headers: { "Cache-Control": "no-store" } }
  );

  res.cookies.set(ADMIN_COOKIE_NAME, "", {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    path: "/",
    maxAge: 0,
    expires: new Date(0),
  });

  res.cookies.set(PENDING_2FA_COOKIE, "", {
    httpOnly: true,
    secure: isProduction,
    sameSite: "lax",
    path: "/",
    maxAge: 0,
    expires: new Date(0),
  });

  return res;
}