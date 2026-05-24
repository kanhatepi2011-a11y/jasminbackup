/**
 * lib/auth.ts — Admin authentication helpers (Issue #7)
 *
 * Changes:
 * - Session lifetime reduced from 7d → 8h
 * - getCurrentAdmin now verifies admin is active + role is ADMIN/SUPERADMIN
 * - Secure cookie cleared properly on logout
 */

import jwt from "jsonwebtoken";
import { cookies } from "next/headers";
import { prisma } from "./prisma";

const ADMIN_COOKIE_NAME = "admin_token";

// Reduced from 7 days to 8 hours (Issue #7)
const SESSION_MAX_AGE_SECONDS = 8 * 60 * 60;

function getAdminJwtSecret() {
  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) {
    throw new Error("ADMIN_JWT_SECRET is not set");
  }
  return secret;
}

export function signAdminToken(adminId: string) {
  return jwt.sign({ adminId }, getAdminJwtSecret(), {
    expiresIn: SESSION_MAX_AGE_SECONDS,
  });
}

export function verifyAdminToken(token: string) {
  try {
    return jwt.verify(token, getAdminJwtSecret()) as {
      adminId: string;
      iat: number;
      exp: number;
    };
  } catch {
    return null;
  }
}

export function buildAuthCookie(token: string) {
  const isProduction = process.env.NODE_ENV === "production";

  return [
    `${ADMIN_COOKIE_NAME}=${token}`,
    "Path=/",
    "HttpOnly",
    "SameSite=Strict",
    `Max-Age=${SESSION_MAX_AGE_SECONDS}`,
    isProduction ? "Secure" : "",
  ]
    .filter(Boolean)
    .join("; ");
}

export function buildClearCookie() {
  const isProduction = process.env.NODE_ENV === "production";

  return [
    `${ADMIN_COOKIE_NAME}=`,
    "Path=/",
    "HttpOnly",
    "SameSite=Strict",
    "Max-Age=0",
    isProduction ? "Secure" : "",
  ]
    .filter(Boolean)
    .join("; ");
}

/**
 * Returns the current admin if:
 * 1. A valid, unexpired JWT cookie exists
 * 2. The admin exists in the database
 * 3. The admin is active
 * 4. The admin role is ADMIN or SUPERADMIN
 *
 * Returns null for any failure — callers must treat null as unauthorized.
 */
export async function getCurrentAdmin() {
  try {
    const cookieStore = await cookies();
    const token = cookieStore.get(ADMIN_COOKIE_NAME)?.value;
    if (!token) return null;

    const payload = verifyAdminToken(token);
    if (!payload) return null;

    const admin = await prisma.admin.findUnique({
      where: { id: payload.adminId },
    });

    if (!admin) return null;
    if (!admin.active) return null;
    if (admin.role !== "ADMIN" && admin.role !== "SUPERADMIN") return null;

    return admin;
  } catch {
    return null;
  }
}

export { ADMIN_COOKIE_NAME, SESSION_MAX_AGE_SECONDS };