"use client";

import { useEffect, useState } from "react";

type MaintenanceState = {
  maintenanceMode: boolean;
  maintenanceMessage: string;
};

export default function MaintenanceGate() {
  const [state, setState] = useState<MaintenanceState>({
    maintenanceMode: false,
    maintenanceMessage: "",
  });

  useEffect(() => {
    async function checkMaintenance() {
      try {
        const res = await fetch("/api/settings/public", {
          cache: "no-store",
        });

        const data = await res.json();

        setState({
          maintenanceMode: Boolean(data.maintenanceMode),
          maintenanceMessage:
            data.maintenanceMessage ||
            "server កំពុងមានបញ្ហាសូមរង់ចាំ 30 នាទី",
        });
      } catch {
        setState({
          maintenanceMode: false,
          maintenanceMessage: "",
        });
      }
    }

    checkMaintenance();
  }, []);

  if (!state.maintenanceMode) return null;

  return (
    <div className="fixed inset-0 z-[99999] flex items-center justify-center bg-black/80 px-4 backdrop-blur-sm">
      <div className="max-w-md rounded-2xl bg-white p-6 text-center shadow-2xl">
        <div className="mb-4 text-5xl">⚠️</div>

        <h1 className="mb-3 text-2xl font-bold text-red-600">
          Server កំពុងមានបញ្ហា
        </h1>

        <p className="text-base font-medium text-gray-700">
          {state.maintenanceMessage}
        </p>

        <p className="mt-4 text-sm text-gray-500">
          សូមត្រឡប់មកវិញនៅពេលក្រោយ។ អរគុណ!
        </p>
      </div>
    </div>
  );
}