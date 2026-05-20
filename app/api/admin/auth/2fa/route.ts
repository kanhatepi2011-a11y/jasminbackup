import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import jwt from "jsonwebtoken";
import { timingSafeEqual } from "crypto";

import { prisma } from "@/lib/prisma";
import { signAdminToken, buildAuthCookie } from "@/lib/auth";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

const PENDING_2FA_COOKIE = "admin_2fa_pending";

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

  if (!secret) {
    throw new Error("ADMIN_JWT_SECRET is not set");
  }

  return secret;
}

function safeEqual(a: string, b: string) {
  const aBuffer = Buffer.from(a);
  const bBuffer = Buffer.from(b);

  if (aBuffer.length !== bBuffer.length) {
    return false;
  }

  return timingSafeEqual(aBuffer, bBuffer);
}

function getLockMs(failCount: number) {
  if (failCount === 1) return 15 * 1000;
  if (failCount === 2) return 5 * 60 * 1000;

  return null;
}

function getLockMessage(failCount: number) {
  if (failCount === 1) return "Wrong 2FA code. Locked for 15 seconds.";
  if (failCount === 2) return "Wrong 2FA code. Locked for 5 minutes.";

  return "Wrong 2FA code too many times. Account locked forever.";
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const parsed = verifySchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid 2FA code" },
        { status: 400 }
      );
    }

    const correctCode = process.env.ADMIN_2FA_CODE;

    if (!correctCode) {
      return NextResponse.json(
        { error: "ADMIN_2FA_CODE is not set" },
        { status: 500 }
      );
    }

    const pendingToken = req.cookies.get(PENDING_2FA_COOKIE)?.value;

    if (!pendingToken) {
      return NextResponse.json(
        { error: "2FA session expired. Please login again." },
        { status: 401 }
      );
    }

    let payload: Pending2FAPayload;

    try {
      payload = jwt.verify(pendingToken, getAdminJwtSecret()) as Pending2FAPayload;
    } catch {
      return NextResponse.json(
        { error: "2FA session expired. Please login again." },
        { status: 401 }
      );
    }

    if (payload.type !== "admin-2fa-pending" || !payload.adminId || !payload.email) {
      return NextResponse.json(
        { error: "Invalid 2FA session. Please login again." },
        { status: 401 }
      );
    }

    const identifier = `admin-2fa:${payload.adminId}`;

    const lock = await prisma.adminAuthLock.findUnique({
      where: { identifier },
    });

    if (lock?.forever) {
      return NextResponse.json(
        { error: "Account locked forever. Contact owner to unlock." },
        { status: 403 }
      );
    }

    if (lock?.lockedUntil && lock.lockedUntil > new Date()) {
      return NextResponse.json(
        {
          error: "2FA is temporarily locked. Please try again later.",
          lockedUntil: lock.lockedUntil,
        },
        { status: 429 }
      );
    }

    const inputCode = parsed.data.code.trim();

    if (!safeEqual(inputCode, correctCode)) {
      const nextFailCount = (lock?.failCount || 0) + 1;
      const lockMs = getLockMs(nextFailCount);

      if (lockMs === null) {
        await prisma.adminAuthLock.upsert({
          where: { identifier },
          update: {
            failCount: nextFailCount,
            lockedUntil: null,
            forever: true,
          },
          create: {
            identifier,
            failCount: nextFailCount,
            lockedUntil: null,
            forever: true,
          },
        });

        return NextResponse.json(
          { error: getLockMessage(nextFailCount) },
          { status: 403 }
        );
      }

      const lockedUntil = new Date(Date.now() + lockMs);

      await prisma.adminAuthLock.upsert({
        where: { identifier },
        update: {
          failCount: nextFailCount,
          lockedUntil,
          forever: false,
        },
        create: {
          identifier,
          failCount: nextFailCount,
          lockedUntil,
          forever: false,
        },
      });

      return NextResponse.json(
        {
          error: getLockMessage(nextFailCount),
          lockedUntil,
        },
        { status: 401 }
      );
    }

    await prisma.adminAuthLock.deleteMany({
      where: { identifier },
    });

    await prisma.admin.update({
      where: { id: payload.adminId },
      data: { lastLoginAt: new Date() },
    });

    const adminToken = signAdminToken(payload.adminId);
    const authCookie = buildAuthCookie(adminToken);

    const res = NextResponse.json({
      ok: true,
      email: payload.email,
      message: "2FA confirmed",
    });

    res.headers.append("Set-Cookie", authCookie);
    res.cookies.delete(PENDING_2FA_COOKIE);

    return res;
  } catch (error) {
    console.error("Admin 2FA error:", error);

    return NextResponse.json(
      { error: "Something went wrong" },
      { status: 500 }
    );
  }
}
