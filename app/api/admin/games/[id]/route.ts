import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";

import { NextResponse } from "next/server";
import { z } from "zod";
import { withAdminAuth } from "@/lib/withAdminAuth";
import { writeAuditForAdmin } from "@/lib/audit";
import { revalidateAdminChange } from "@/lib/adminRevalidate";

const imagePath = z
  .string()
  .min(1)
  .refine((v) => /^https?:\/\//i.test(v) || v.startsWith("/uploads/") || v.startsWith("/"), {
    message: "Must be a URL or uploaded file path",
  });

const updateSchema = z.object({
  slug: z.string().min(2).regex(/^[a-z0-9-]+$/).optional(),
  name: z.string().min(1).optional(),
  publisher: z.string().min(1).optional(),
  description: z.string().optional().nullable(),
  imageUrl: imagePath.optional(),
  bannerUrl: imagePath.optional().or(z.literal("")),
  currencyName: z.string().min(1).optional(),
  uidLabel: z.string().optional(),
  uidExample: z.string().optional().nullable(),
  requiresServer: z.boolean().optional(),
  servers: z.string().optional(),
  featured: z.boolean().optional(),
  active: z.boolean().optional(),
  sortOrder: z.number().int().optional(),
  seoTitle: z.string().optional().nullable(),
  seoDescription: z.string().optional().nullable(),
});

export const GET = withAdminAuth(
  async (_req, { params }: { params: Promise<{ id: string }> }) => {
    const { id } = await params;
    const game = await prisma.game.findUnique({
      where: { id },
      include: {
        products: { orderBy: { sortOrder: "asc" } },
        _count: { select: { orders: true, products: true } },
      },
    });
    if (!game) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json(game);
  },
  { permission: "games.read" }
);

export const PATCH = withAdminAuth(
  async (req, { params }: { params: Promise<{ id: string }> }, admin) => {
    const { id } = await params;
    const body = await req.json().catch(() => ({}));
    const parsed = updateSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid", details: parsed.error.flatten() },
        { status: 400 }
      );
    }

    const existing = await prisma.game.findUnique({ where: { id } });
    if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

    try {
      const game = await prisma.game.update({
        where: { id },
        data: parsed.data,
      });
      await writeAuditForAdmin(admin, req, {
        action: "game.update",
        targetType: "game",
        targetId: id,
        details: { beforeSlug: existing.slug, changes: parsed.data },
      });
      revalidateAdminChange("games", { gameSlug: existing.slug });
      if (game.slug !== existing.slug) revalidateAdminChange("games", { gameSlug: game.slug });
      return NextResponse.json(game);
    } catch (err: any) {
      if (err.code === "P2002") return NextResponse.json({ error: "Slug already exists" }, { status: 409 });
      throw err;
    }
  },
  { permission: "games.write" }
);

export const DELETE = withAdminAuth(
  async (req, { params }: { params: Promise<{ id: string }> }, admin) => {
    const { id } = await params;
    const game = await prisma.game.findUnique({
      where: { id },
      include: { _count: { select: { orders: true, products: true } } },
    });
    if (!game) return NextResponse.json({ error: "Not found" }, { status: 404 });

    if (game._count.orders > 0 || game._count.products > 0) {
      const disabled = await prisma.game.update({ where: { id }, data: { active: false } });
      await writeAuditForAdmin(admin, req, {
        action: "game.disable.safe_delete",
        targetType: "game",
        targetId: id,
        details: "Game has products/orders, so it was disabled instead of deleted.",
      });
      revalidateAdminChange("games", { gameSlug: game.slug });
      return NextResponse.json({ ok: true, deleted: false, disabled });
    }

    await prisma.game.delete({ where: { id } });
    await writeAuditForAdmin(admin, req, { action: "game.delete", targetType: "game", targetId: id });
    revalidateAdminChange("games", { gameSlug: game.slug });
    return NextResponse.json({ ok: true, deleted: true });
  },
  { permission: "games.write" }
);
