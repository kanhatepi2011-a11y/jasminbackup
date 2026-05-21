import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import jwt from "jsonwebtoken";
import { timingSafeEqual } from "crypto";

import { prisma } from "@/lib/prisma";
import { signAdminToken } from "@/lib/auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const PENDING_2FA_COOKIE = "admin_2fa_pending";
const ADMIN_COOKIE_NAME = "admin_token";

const verifySchema = z.object({
  code: z.string().min(1),
});

type Pending2FAPayload = {
  type?: string;
  adminId?: string;
  email?: string;
};

function getAdminJwtSecret() {
  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) throw new Error("ADMIN_JWT_SECRET is not set");
  return secret;
}

function safeEqual(a: string, b: string) {
  const aBuffer = Buffer.from(a);
  const bBuffer = Buffer.from(b);
  if (aBuffer.length !== bBuffer.length) return false;
  return timingSafeEqual(aBuffer, bBuffer);
}

function decodePendingToken(token: string): Pending2FAPayload | null {
  try {
    return jwt.verify(token, getAdminJwtSecret()) as Pending2FAPayload;
  } catch {
    return null;
  }
}

// ✅ GET — check 2FA lock + session status (used by frontend on page refresh)
export async function GET(req: NextRequest) {
  const pendingToken = req.cookies.get(PENDING_2FA_COOKIE)?.value;

  if (!pendingToken) {
    return NextResponse.json({ step: "login", locked: false });
  }

  const payload = decodePendingToken(pendingToken);

  if (!payload?.adminId || payload.type !== "admin-2fa-pending") {
    return NextResponse.json({ step: "login", locked: false });
  }

  const identifier = `admin-2fa:${payload.adminId}`;
  const lock = await prisma.adminAuthLock.findUnique({ where: { identifier } });

  if (lock?.forever) {
    return NextResponse.json({ step: "2fa", locked: true, forever: true });
  }

  if (lock?.lockedUntil && lock.lockedUntil > new Date()) {
    return NextResponse.json({
      step: "2fa",
      locked: true,
      forever: false,
      lockedUntil: lock.lockedUntil,
    });
  }

  return NextResponse.json({ step: "2fa", locked: false, email: payload.email });
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const parsed = verifySchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json({ error: "Invalid 2FA code" }, { status: 400 });
    }

    const correctCode = process.env.ADMIN_2FA_CODE;
    if (!correctCode) {
      return NextResponse.json({ error: "ADMIN_2FA_CODE is not set" }, { status: 500 });
    }

    const pendingToken = req.cookies.get(PENDING_2FA_COOKIE)?.value;
    if (!pendingToken) {
      return NextResponse.json(
        { error: "2FA session expired. Please login again." },
        { status: 401 }
      );
    }

    const payload = decodePendingToken(pendingToken);

    if (!payload || payload.type !== "admin-2fa-pending" || !payload.adminId || !payload.email) {
      return NextResponse.json(
        { error: "2FA session expired. Please login again." },
        { status: 401 }
      );
    }

    const identifier = `admin-2fa:${payload.adminId}`;
    const lock = await prisma.adminAuthLock.findUnique({ where: { identifier } });

    // ✅ Check lock មុន
    if (lock?.forever) {
      return NextResponse.json(
        { error: "កូដ 2FA ខុស ២ លើក Lock ជាអចិន្ត្រៃយ៍ សូមទាក់ទង owner។" },
        { status: 403 }
      );
    }

    if (lock?.lockedUntil && lock.lockedUntil > new Date()) {
      return NextResponse.json(
        {
          error: "កូដ 2FA ខុស លើកទី១ Lock 5 នាទី សូមរង់ចាំ។",
          lockedUntil: lock.lockedUntil,
        },
        { status: 429 }
      );
    }

    const inputCode = parsed.data.code.trim();

    if (!safeEqual(inputCode, correctCode)) {
      const nextFail = (lock?.failCount || 0) + 1;

      // ✅ លើកទី១ → 5 នាទី | លើកទី២+ → forever
      if (nextFail >= 2) {
        await prisma.adminAuthLock.upsert({
          where: { identifier },
          update: { failCount: nextFail, lockedUntil: null, forever: true },
          create: { identifier, failCount: nextFail, lockedUntil: null, forever: true },
        });
        return NextResponse.json(
          { error: "កូដ 2FA ខុស ២ លើក Lock ជាអចិន្ត្រៃយ៍ សូមទាក់ទង owner។" },
          { status: 403 }
        );
      }

      const lockedUntil = new Date(Date.now() + 5 * 60 * 1000);
      await prisma.adminAuthLock.upsert({
        where: { identifier },
        update: { failCount: nextFail, lockedUntil, forever: false },
        create: { identifier, failCount: nextFail, lockedUntil, forever: false },
      });
      return NextResponse.json(
        {
          error: "កូដ 2FA ខុស លើកទី១ Lock 5 នាទី សូមរង់ចាំ។",
          lockedUntil,
        },
        { status: 429 }
      );
    }

    // ✅ Code ត្រូវ → Clear lock + Login
    await prisma.adminAuthLock.deleteMany({ where: { identifier } });

    await prisma.admin.update({
      where: { id: payload.adminId },
      data: { lastLoginAt: new Date() },
    });

    const adminToken = signAdminToken(payload.adminId);
    const isProduction = process.env.NODE_ENV === "production";

    const res = NextResponse.json({
      ok: true,
      email: payload.email,
      message: "2FA confirmed",
    });

    res.cookies.set(ADMIN_COOKIE_NAME, adminToken, {
      httpOnly: true,
      secure: isProduction,
      sameSite: "lax",
      path: "/",
      maxAge: 60 * 60 * 24 * 7,
    });

    res.cookies.delete(PENDING_2FA_COOKIE);

    return res;
  } catch (error) {
    console.error("Admin 2FA error:", error);
    return NextResponse.json({ error: "Something went wrong" }, { status: 500 });
  }
}