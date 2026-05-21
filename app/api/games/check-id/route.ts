import { NextRequest, NextResponse } from "next/server";
export const dynamic = "force-dynamic";
export const runtime = "nodejs";

import { z } from "zod";

const schema = z.object({
  slug: z.enum(["mobile-legends", "honor-of-kings", "free-fire", "pubg-mobile", "ro-blox"]),
  uid: z.string().min(1).max(30),
  serverId: z.string().optional(),
});

const RAPIDAPI_KEY = process.env.RAPIDAPI_KEY || "fe5c7f553fmsh0f3d273f04f84dap1f1dcdjsn7d45d7b4bd30";
const RAPIDAPI_HOST = "id-game-checker.p.rapidapi.com";
const BASE = `https://${RAPIDAPI_HOST}`;

function buildUrl(slug: string, uid: string, serverId?: string): string | null {
  switch (slug) {
    case "free-fire":
      // URL: /dfm-garena/{uid}
      return `${BASE}/dfm-garena/${encodeURIComponent(uid)}`;

    case "mobile-legends":
      // URL: /mobile-legends/{uid}/{zone}
      if (!serverId) return null;
      return `${BASE}/mobile-legends/${encodeURIComponent(uid)}/${encodeURIComponent(serverId)}`;

    case "pubg-mobile":
      // URL: /pubgm-global/{uid}
      return `${BASE}/pubgm-global/${encodeURIComponent(uid)}`;

    case "honor-of-kings":
      return `${BASE}/honor-of-kings/${encodeURIComponent(uid)}`;

    case "ro-blox":
      return `${BASE}/roblox/${encodeURIComponent(uid)}`;

    default:
      return null;
  }
}

export async function POST(req: NextRequest) {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ success: false, error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { success: false, error: parsed.error.issues[0]?.message || "Invalid input" },
      { status: 400 }
    );
  }

  const { slug, uid, serverId } = parsed.data;

  // Mobile Legends requires serverId/zone
  if (slug === "mobile-legends" && !serverId) {
    return NextResponse.json(
      { success: false, error: "Zone ID is required for Mobile Legends" },
      { status: 400 }
    );
  }

  const url = buildUrl(slug, uid, serverId);
  if (!url) {
    return NextResponse.json(
      { success: false, error: "Unsupported game" },
      { status: 400 }
    );
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 10000);

    const res = await fetch(url, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
        "x-rapidapi-host": RAPIDAPI_HOST,
        "x-rapidapi-key": RAPIDAPI_KEY,
      },
      cache: "no-store",
      signal: controller.signal,
    });
    clearTimeout(timeout);

    const data: unknown = await res.json().catch(() => null);

    if (!data || typeof data !== "object") {
      return NextResponse.json({ success: false, error: "Lookup failed" }, { status: 502 });
    }

    const d = data as Record<string, unknown>;

    // API returns different shapes — normalize them
    // Success shape: { nickname: "...", ... } or { name: "...", ... } or { username: "..." }
    const nickname =
      (d.nickname as string) ||
      (d.name as string) ||
      (d.username as string) ||
      (d.playerName as string) ||
      null;

    if (!nickname) {
      const errMsg =
        (d.message as string) ||
        (d.error as string) ||
        "Player not found — check your ID";
      return NextResponse.json({ success: false, error: errMsg }, { status: 404 });
    }

    return NextResponse.json({
      success: true,
      name: nickname,
      uid,
      serverId: serverId ?? null,
    });

  } catch (err) {
    const aborted = err instanceof Error && err.name === "AbortError";
    return NextResponse.json(
      { success: false, error: aborted ? "Lookup timed out" : "Network error" },
      { status: 504 }
    );
  }
}