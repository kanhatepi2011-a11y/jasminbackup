import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";

import { NextResponse } from "next/server";
import { withAdminAuth } from "@/lib/withAdminAuth";

export const PATCH = withAdminAuth(async (req, { params }: { params: Promise<{ id: string }> }) => {
  const { id } = await params;
  try {
    const body = await req.json();
    const promo = await prisma.promoCode.update({
      where: { id: id },
      data: {
        ...(typeof body.active === "boolean" ? { active: body.active } : {}),
        ...(typeof body.maxUses === "number" ? { maxUses: body.maxUses } : {}),
        ...(body.expiresAt !== undefined
          ? { expiresAt: body.expiresAt ? new Date(body.expiresAt) : null }
          : {}),
      },
    });
    return NextResponse.json(promo);
  } catch {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
});

export const DELETE = withAdminAuth(async (_req, { params }: { params: Promise<{ id: string }> }) => {
  const { id } = await params;
  try {
    await prisma.promoCode.delete({ where: { id: id } });
    return NextResponse.json({ success: true });
  } catch {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }
});
