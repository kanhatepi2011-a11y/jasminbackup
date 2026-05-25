import { prisma } from "@/lib/prisma";
export const dynamic = "force-dynamic";

import { writeAudit } from "@/lib/audit";
import { NextResponse, NextRequest } from "next/server";
import { withAdminAuth } from "@/lib/withAdminAuth";

export const DELETE = withAdminAuth(async (
  _req: NextRequest,
  context: any
) => {
  const { id } = await context.params;
  await prisma.blockedIdentity.delete({ where: { id } });
  await writeAudit({ action: "banlist.remove", targetType: "banlist", targetId: id });
  return NextResponse.json({ ok: true });
});