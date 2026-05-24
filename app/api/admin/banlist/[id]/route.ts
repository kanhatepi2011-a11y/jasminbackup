import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";

import { writeAudit } from "@/lib/audit";
import { NextResponse } from "next/server";
import { withAdminAuth } from "@/lib/withAdminAuth";

export const DELETE = withAdminAuth(async (
  _req,
  { params }: { params: Promise<{ id: string }> }
) => {
  const { id } = await params;
  await prisma.blockedIdentity.delete({ where: { id: id } });
  await writeAudit({ action: "banlist.remove", targetType: "banlist", targetId: id });
  return NextResponse.json({ ok: true });
});
