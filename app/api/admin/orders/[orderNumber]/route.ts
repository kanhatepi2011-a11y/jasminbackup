import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";

import { writeAuditForAdmin } from "@/lib/audit";
import { notifyTelegram, escapeHtml } from "@/lib/telegram";
import { createAdminNotification } from "@/lib/adminNotifications";
import { revalidateAdminChange } from "@/lib/adminRevalidate";
import { NextResponse } from "next/server";
import { z } from "zod";
import { withAdminAuth } from "@/lib/withAdminAuth";

const statusSchema = z.enum([
  "PENDING",
  "PAID",
  "PROCESSING",
  "DELIVERED",
  "COMPLETED",
  "FAILED",
  "REFUNDED",
  "CANCELLED",
]);

const updateSchema = z.object({
  status: statusSchema.optional(),
  deliveryNote: z.string().max(2000).optional(),
  failureReason: z.string().max(2000).optional(),
  adminNote: z.string().max(2000).optional(),
});

function normalizeStatus(status?: string) {
  if (!status) return undefined;
  return status === "COMPLETED" ? "DELIVERED" : status;
}

export const GET = withAdminAuth(
  async (_req, { params }: { params: Promise<{ orderNumber: string }> }) => {
    const { orderNumber } = await params;
    const order = await prisma.order.findUnique({
      where: { orderNumber },
      include: {
        game: true,
        product: true,
        promoCode: true,
      },
    });
    if (!order) return NextResponse.json({ error: "Not found" }, { status: 404 });
    return NextResponse.json(order);
  },
  { permission: "orders.read" }
);

export const PATCH = withAdminAuth(
  async (req, { params }: { params: Promise<{ orderNumber: string }> }, admin) => {
    const { orderNumber } = await params;
    const body = await req.json().catch(() => ({}));
    const parsed = updateSchema.safeParse(body);
    if (!parsed.success) {
      return NextResponse.json(
        { error: "Invalid body", details: parsed.error.flatten() },
        { status: 400 }
      );
    }

    const order = await prisma.order.findUnique({
      where: { orderNumber },
      include: { game: { select: { slug: true, name: true } }, product: { select: { name: true } } },
    });
    if (!order) return NextResponse.json({ error: "Not found" }, { status: 404 });

    const nextStatus = normalizeStatus(parsed.data.status);
    const data: any = {
      ...(parsed.data.deliveryNote !== undefined ? { deliveryNote: parsed.data.deliveryNote } : {}),
      ...(parsed.data.failureReason !== undefined ? { failureReason: parsed.data.failureReason } : {}),
    };

    if (nextStatus) {
      data.status = nextStatus;
      if (nextStatus === "DELIVERED" && !order.deliveredAt) data.deliveredAt = new Date();
      if (nextStatus === "PAID" && !order.paidAt) data.paidAt = new Date();
    }

    const updated = await prisma.order.update({
      where: { id: order.id },
      data,
      include: {
        game: { select: { id: true, name: true, slug: true } },
        product: { select: { id: true, name: true } },
      },
    });

    if (nextStatus && nextStatus !== order.status) {
      await writeAuditForAdmin(admin, req, {
        action: "order.status.update",
        targetType: "order",
        targetId: order.orderNumber,
        details: {
          from: order.status,
          to: nextStatus,
          adminNote: parsed.data.adminNote || null,
        },
      });

      await createAdminNotification({
        type: "order.updated",
        title: "Order status updated",
        message: `${order.orderNumber}: ${order.status} → ${nextStatus}`,
        targetType: "order",
        targetId: order.orderNumber,
      });

      if (nextStatus === "DELIVERED" || nextStatus === "PAID") {
        await notifyTelegram(
          `✅ <b>Order ${escapeHtml(nextStatus)}</b>\n` +
            `#${escapeHtml(order.orderNumber)} — $${order.amountUsd.toFixed(2)}\n` +
            `UID: <code>${escapeHtml(order.playerUid)}</code>`
        );
      }
    } else if (parsed.data.deliveryNote || parsed.data.failureReason || parsed.data.adminNote) {
      await writeAuditForAdmin(admin, req, {
        action: "order.note.update",
        targetType: "order",
        targetId: order.orderNumber,
        details: {
          deliveryNote: parsed.data.deliveryNote || null,
          failureReason: parsed.data.failureReason || null,
          adminNote: parsed.data.adminNote || null,
        },
      });
    }

    revalidateAdminChange("orders", { orderNumber: order.orderNumber });

    return NextResponse.json(updated);
  },
  { permission: "orders.update" }
);
