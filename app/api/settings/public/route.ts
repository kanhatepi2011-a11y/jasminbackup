import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";

export const dynamic = "force-dynamic";

export async function GET() {
  try {
    const settings = await prisma.settings.findUnique({
      where: { id: 1 },
      select: {
        maintenanceMode: true,
        maintenanceMessage: true,
      },
    });

    return NextResponse.json({
      maintenanceMode: settings?.maintenanceMode ?? false,
      maintenanceMessage:
        settings?.maintenanceMessage ??
        "server កំពុងមានបញ្ហាសូមរង់ចាំ 30 នាទី",
    });
  } catch {
    return NextResponse.json({
      maintenanceMode: false,
      maintenanceMessage: "",
    });
  }
}