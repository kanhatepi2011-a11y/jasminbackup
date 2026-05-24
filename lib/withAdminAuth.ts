/**
 * lib/withAdminAuth.ts — DB-layer auth wrapper for admin API routes
 *
 * WHY THIS EXISTS:
 * middleware.ts verifies the JWT cryptographically (fast, edge-compatible),
 * but does NOT check the database. That means a disabled admin's token
 * remains valid for up to 8 hours across all routes that skip this check.
 *
 * This wrapper adds the second layer: it calls getCurrentAdmin() which
 * verifies admin.active and admin.role in the DB on every request.
 *
 * USAGE — replace your bare handler:
 *
 *   // Before
 *   export async function GET(req: NextRequest) { ... }
 *
 *   // After
 *   export const GET = withAdminAuth(async (req, _ctx, admin) => { ... });
 *
 * The third argument `admin` is the verified Admin object from the DB.
 * You no longer need to call getCurrentAdmin() inside the handler.
 */

import { NextRequest, NextResponse } from "next/server";
import { getCurrentAdmin } from "@/lib/auth";
import type { Admin } from "@prisma/client";

type RouteContext = { params?: Promise<Record<string, string>> };

type AuthedHandler = (
  req: NextRequest,
  ctx: RouteContext,
  admin: Admin
) => Promise<NextResponse> | NextResponse;

export function withAdminAuth(handler: AuthedHandler) {
  return async function (req: NextRequest, ctx: RouteContext): Promise<NextResponse> {
    const admin = await getCurrentAdmin();
    if (!admin) {
      return NextResponse.json(
        { error: "Unauthorized" },
        { status: 401, headers: { "Cache-Control": "no-store" } }
      );
    }
    return handler(req, ctx, admin);
  };
}
