import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";

import { prisma } from "@/lib/prisma";
import { buildClearCookie } from "@/lib/auth";

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

  if (!secret) {
    throw new Error("ADMIN_JWT_SECRET is not set");
  }

  return secret;
}

function get2FATtlSeconds() {
  const ttl = Number(
    process.env.ADMIN_2FA_TTL_SECONDS || DEFAULT_2FA_TTL_SECONDS
  );

  if (!Number.isFinite(ttl) || ttl <= 0) {
    return DEFAULT_2FA_TTL_SECONDS;
  }

  return Math.floor(ttl);
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json().catch(() => ({}));
    const parsed = loginSchema.safeParse(body);

    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid credentials" },
        {
          status: 400,
          headers: {
            "Cache-Control": "no-store",
          },
        }
      );
    }

    const email = parsed.data.email.toLowerCase().trim();

    const admin = await prisma.admin.findUnique({
      where: { email },
    });

    if (!admin || !admin.active) {
      return NextResponse.json(
        { error: "Invalid email or password" },
        {
          status: 401,
          headers: {
            "Cache-Control": "no-store",
          },
        }
      );
    }

    const passwordMatch = await bcrypt.compare(
      parsed.data.password,
      admin.passwordHash
    );

    if (!passwordMatch) {
      return NextResponse.json(
        { error: "Invalid email or password" },
        {
          status: 401,
          headers: {
            "Cache-Control": "no-store",
          },
        }
      );
    }

    const ttlSeconds = get2FATtlSeconds();

    const pendingToken = jwt.sign(
      {
        type: "admin-2fa-pending",
        adminId: String(admin.id),
        email: admin.email,
      },
      getAdminJwtSecret(),
      {
        expiresIn: ttlSeconds,
      }
    );

    const res = NextResponse.json(
      {
        ok: true,
        requires2FA: true,
        email: admin.email,
        message: "Password correct. Please confirm 2FA code.",
      },
      {
        headers: {
          "Cache-Control": "no-store",
        },
      }
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
      {
        status: 500,
        headers: {
          "Cache-Control": "no-store",
        },
      }
    );
  }
}

export async function DELETE() {
  const res = NextResponse.json(
    { ok: true },
    {
      headers: {
        "Cache-Control": "no-store",
      },
    }
  );

  res.headers.append("Set-Cookie", buildClearCookie());

  res.cookies.set(PENDING_2FA_COOKIE, "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 0,
    expires: new Date(0),
  });

  return res;
}