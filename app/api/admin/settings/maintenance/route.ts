import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { z } from "zod";

export const dynamic = "force-dynamic";

const bodySchema = z.object({
  maintenanceMode: z.boolean(),
  maintenanceMessage: z.string().min(1).optional(),
});

export async function PATCH(req: Request) {
  try {
    const body = await req.json();
    const data = bodySchema.parse(body);

    const settings = await prisma.settings.upsert({
      where: { id: 1 },
      update: {
        maintenanceMode: data.maintenanceMode,
        maintenanceMessage:
          data.maintenanceMessage ??
          "server កំពុងមានបញ្ហាសូមរង់ចាំ 30 នាទី",
      },
      create: {
        id: 1,
        siteName: "JASMINTOPUP",
        exchangeRate: 4100,
        supportTelegram: "@jasmintopup",
        supportEmail: "support@jasmintopup.com",
        maintenanceMode: data.maintenanceMode,
        maintenanceMessage:
          data.maintenanceMessage ??
          "server កំពុងមានបញ្ហាសូមរង់ចាំ 30 នាទី",
      },
      select: {
        maintenanceMode: true,
        maintenanceMessage: true,
      },
    });

    return NextResponse.json({
      success: true,
      settings,
    });
  } catch (error) {
    return NextResponse.json(
      {
        success: false,
        error: "Failed to update maintenance mode",
      },
      { status: 400 }
    );
  }
}