import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";

import { writeAudit } from "@/lib/audit";
import { NextResponse } from "next/server";
import { z } from "zod";
import { withAdminAuth } from "@/lib/withAdminAuth";

const schema = z.object({
  title: z.string().min(1),
  subtitle: z.string().optional().nullable(),
  imageUrl: z.string().min(1),
  linkUrl: z.string().optional().nullable(),
  ctaLabel: z.string().optional().nullable(),
  active: z.boolean().default(true),
  sortOrder: z.number().int().default(0),
});

export const GET = withAdminAuth(async () => {
  const banners = await prisma.heroBanner.findMany({
    orderBy: [{ sortOrder: "asc" }, { createdAt: "desc" }],
  });
  return NextResponse.json(banners);
});

export const POST = withAdminAuth(async (req) => {
  const body = await req.json().catch(() => ({}));
  const parsed = schema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid", details: parsed.error.flatten() },
      { status: 400 }
    );
  }
  const banner = await prisma.heroBanner.create({ data: parsed.data });
  await writeAudit({ action: "banner.create", targetType: "banner", targetId: banner.id });
  return NextResponse.json(banner);
});
