import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export async function GET() {
  const settings = await prisma.settings.upsert({
    where: { id: 1 },
    update: {},
    create: { id: 1 },
  });

  return NextResponse.json({
    logoUrl:     settings.logoUrl     ?? null,
    logoText:    settings.logoText    ?? null,
    logoTagline: settings.logoTagline ?? null,
  });
}