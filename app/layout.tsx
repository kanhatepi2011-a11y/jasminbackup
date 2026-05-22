import type { Metadata } from "next";
import "./globals.css";
import { prisma } from "@/lib/prisma";
import { CurrencyProvider } from "@/lib/currency";
import RouteProgress from "@/components/RouteProgress";
import AnnouncementBar from "@/components/AnnouncementBar";
import MaintenanceGate from "@/components/MaintenanceGate";

export const metadata: Metadata = {
  title: "JASMINTOPUP",
  description:
    "Top up Mobile Legends, Free Fire, PUBG Mobile and more. Instant delivery, secure KHQR payment. 24/7 service in Cambodia.",
  keywords: [
    "top up",
    "mobile legends diamonds",
    "free fire diamonds",
    "pubg uc",
    "ABA Pay",
    "KHQR",
    "Cambodia top up",
    "JASMINTOPUP",
  ],
  openGraph: {
    title: "JASMINTOPUP",
    description: "Instant game top-ups with KHQR",
    type: "website",
  },
};

export default async function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const settings = await prisma.settings
    .findUnique({
      where: { id: 1 },
      select: {
        exchangeRate: true,
      },
    })
    .catch(() => null);

  const exchangeRate = settings?.exchangeRate ?? 4100;

  return (
    <html lang="en">
      <body>
        <RouteProgress />

        <CurrencyProvider exchangeRate={exchangeRate}>
          <AnnouncementBar />
          <MaintenanceGate />
          {children}
        </CurrencyProvider>
      </body>
    </html>
  );
}