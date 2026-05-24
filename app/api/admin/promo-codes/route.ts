import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";

import { NextResponse } from "next/server";
import { z } from "zod";
import { withAdminAuth } from "@/lib/withAdminAuth";

const createSchema = z.object({
  code: z.string().min(2).max(30).transform((v) => v.toUpperCase().trim()),
  discountType: z.enum(["PERCENT", "FIXED"]),
  discountValue: z.number().positive(),
  minOrderUsd: z.number().min(0).default(0),
  maxUses: z.number().int().min(0).default(0),
  expiresAt: z.string().nullable().optional(),
  active: z.boolean().default(true),
});

export const GET = withAdminAuth(async () => {
  const codes = await prisma.promoCode.findMany({
    orderBy: { createdAt: "desc" },
  });
  return NextResponse.json(codes);
});

export const POST = withAdminAuth(async (req) => {
  try {
    const body = await req.json();
    const parsed = createSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid data", details: parsed.error.flatten() },
        { status: 400 }
      );
    }
    const data = parsed.data;

    const existing = await prisma.promoCode.findUnique({ where: { code: data.code } });
    if (existing) {
      return NextResponse.json({ error: "Code already exists" }, { status: 409 });
    }

    const promo = await prisma.promoCode.create({
      data: {
        code: data.code,
        discountType: data.discountType,
        discountValue: data.discountValue,
        minOrderUsd: data.minOrderUsd,
        maxUses: data.maxUses,
        expiresAt: data.expiresAt ? new Date(data.expiresAt) : null,
        active: data.active,
      },
    });

    return NextResponse.json(promo, { status: 201 });
  } catch {
    return NextResponse.json({ error: "Server error" }, { status: 500 });
  }
});
