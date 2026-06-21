import { NextRequest } from "next/server";
import { prisma } from "@/lib/prisma";
import {
  API_CACHE_DYNAMIC,
  publicRateLimit,
  rejectSuspiciousQuery,
  safeJson,
} from "@/lib/apiSecurity";

export const dynamic = "force-dynamic";

export async function GET(req: NextRequest) {
  const suspicious = rejectSuspiciousQuery(req);
  if (suspicious) return suspicious;

  const limited = publicRateLimit(req, "api-settings-public", {
    limit: 120,
    windowMs: 60_000,
  });
  if (limited) return limited;

  try {
    const settings = await prisma.settings.findUnique({
      where: { id: 1 },
      select: {
        siteName: true,
        exchangeRate: true,
        supportTelegram: true,
        supportEmail: true,
        maintenanceMode: true,
        maintenanceMessage: true,
        announcement: true,
        announcementTone: true,
        logoUrl: true,
        logoText: true,
        logoTagline: true,
        updatedAt: true,
      },
    });

    return safeJson(
      {
        siteName: settings?.siteName ?? "JASMIN TOPUP",
        exchangeRate: settings?.exchangeRate ?? 4100,
        supportTelegram: settings?.supportTelegram ?? "@jasmintopup",
        supportEmail: settings?.supportEmail ?? null,
        maintenanceMode: settings?.maintenanceMode ?? false,
        maintenanceMessage:
          settings?.maintenanceMessage ??
          "Server កំពុងថែទាំបណ្តោះអាសន្ន។ សូមរង់ចាំប្រហែល 30 នាទី។",
        announcement: settings?.announcement ?? null,
        announcementTone: settings?.announcementTone ?? "info",
        logoUrl: settings?.logoUrl ?? "/jasmintopup-logo.png",
        logoText: settings?.logoText ?? "JASMINTOPUP",
        logoTagline: settings?.logoTagline ?? "Instant · Secure · 24/7",
        updatedAt: settings?.updatedAt?.toISOString() ?? null,
      },
      undefined,
      API_CACHE_DYNAMIC
    );
  } catch {
    return safeJson(
      {
        siteName: "JASMIN TOPUP",
        exchangeRate: 4100,
        supportTelegram: "@jasmintopup",
        supportEmail: null,
        maintenanceMode: false,
        maintenanceMessage: "",
        announcement: null,
        announcementTone: "info",
        logoUrl: "/jasmintopup-logo.png",
        logoText: "JASMINTOPUP",
        logoTagline: "Instant · Secure · 24/7",
        updatedAt: null,
      },
      undefined,
      API_CACHE_DYNAMIC
    );
  }
}
