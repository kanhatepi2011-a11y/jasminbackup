"use client";

import { useEffect, useState } from "react";

type AdminSettingsForm = {
  siteName: string;
  exchangeRate: number | string;
  supportTelegram: string | null;
  supportEmail: string | null;
  maintenanceMode: boolean;
  maintenanceMessage: string | null;
  announcement: string | null;
  announcementTone: "info" | "warning" | "promo";
  telegramBotToken: string | null;
  telegramChatId: string | null;
};

const DEFAULT_MAINTENANCE_MESSAGE =
  "server កំពុងមានបញ្ហាសូមរង់ចាំ 30 នាទី";

export default function AdminSettingsPage() {
  const [form, setForm] = useState<AdminSettingsForm | null>(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function loadSettings() {
    try {
      setError(null);

      const res = await fetch("/api/admin/settings", {
        cache: "no-store",
      });

      if (!res.ok) {
        throw new Error("Failed to load settings");
      }

      const data = await res.json();

      setForm({
        siteName: data.siteName || "JASMINTOPUP",
        exchangeRate: data.exchangeRate || 4100,
        supportTelegram: data.supportTelegram || "",
        supportEmail: data.supportEmail || "",
        maintenanceMode: Boolean(data.maintenanceMode),
        maintenanceMessage:
          data.maintenanceMessage || DEFAULT_MAINTENANCE_MESSAGE,
        announcement: data.announcement || "",
        announcementTone: data.announcementTone || "info",
        telegramBotToken: data.telegramBotToken || "",
        telegramChatId: data.telegramChatId || "",
      });
    } catch {
      setError("Cannot load settings. Please refresh the page.");
    }
  }

  useEffect(() => {
    loadSettings();
  }, []);

  async function save(e?: React.FormEvent) {
    e?.preventDefault();

    if (!form) return;

    try {
      setSaving(true);
      setSaved(false);
      setError(null);

      const res = await fetch("/api/admin/settings", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          siteName: form.siteName,
          exchangeRate: Number(form.exchangeRate),
          supportTelegram: form.supportTelegram || null,
          supportEmail: form.supportEmail || null,
          maintenanceMode: form.maintenanceMode,
          maintenanceMessage:
            form.maintenanceMessage || DEFAULT_MAINTENANCE_MESSAGE,
          announcement: form.announcement || null,
          announcementTone: form.announcementTone || "info",
          telegramBotToken: form.telegramBotToken || null,
          telegramChatId: form.telegramChatId || null,
        }),
      });

      if (!res.ok) {
        throw new Error("Failed to save settings");
      }

      const updated = await res.json();

      setForm({
        siteName: updated.siteName || form.siteName,
        exchangeRate: updated.exchangeRate || form.exchangeRate,
        supportTelegram: updated.supportTelegram || "",
        supportEmail: updated.supportEmail || "",
        maintenanceMode: Boolean(updated.maintenanceMode),
        maintenanceMessage:
          updated.maintenanceMessage || DEFAULT_MAINTENANCE_MESSAGE,
        announcement: updated.announcement || "",
        announcementTone: updated.announcementTone || "info",
        telegramBotToken: updated.telegramBotToken || "",
        telegramChatId: updated.telegramChatId || "",
      });

      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      setError("Save failed. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  async function toggleServerStatus() {
    if (!form || saving) return;

    const nextMode = !form.maintenanceMode;

    const nextForm = {
      ...form,
      maintenanceMode: nextMode,
      maintenanceMessage:
        form.maintenanceMessage || DEFAULT_MAINTENANCE_MESSAGE,
    };

    setForm(nextForm);

    try {
      setSaving(true);
      setSaved(false);
      setError(null);

      const res = await fetch("/api/admin/settings", {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          siteName: nextForm.siteName,
          exchangeRate: Number(nextForm.exchangeRate),
          supportTelegram: nextForm.supportTelegram || null,
          supportEmail: nextForm.supportEmail || null,
          maintenanceMode: nextForm.maintenanceMode,
          maintenanceMessage:
            nextForm.maintenanceMessage || DEFAULT_MAINTENANCE_MESSAGE,
          announcement: nextForm.announcement || null,
          announcementTone: nextForm.announcementTone || "info",
          telegramBotToken: nextForm.telegramBotToken || null,
          telegramChatId: nextForm.telegramChatId || null,
        }),
      });

      if (!res.ok) {
        throw new Error("Failed to update server status");
      }

      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {
      setForm(form);
      setError("Cannot update server status. Please try again.");
    } finally {
      setSaving(false);
    }
  }

  if (!form) {
    return (
      <div className="p-8 text-fox-muted">
        {error ? error : "Loading..."}
      </div>
    );
  }

  return (
    <div className="p-8 max-w-2xl">
      <h1 className="font-display text-3xl font-bold mb-2">Settings</h1>
      <p className="text-fox-muted mb-6">Site-wide configuration.</p>

      {error && (
        <div className="mb-4 rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-400">
          {error}
        </div>
      )}

      <div
        className={`mb-6 rounded-2xl border p-5 ${
          form.maintenanceMode
            ? "border-red-500/40 bg-red-500/10"
            : "border-green-500/40 bg-green-500/10"
        }`}
      >
        <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-lg font-bold">
              {form.maintenanceMode ? "Server Closed" : "Server Open"}
            </h2>
            <p className="mt-1 text-sm text-fox-muted">
              {form.maintenanceMode
                ? "Customers will see the maintenance message and cannot use the website."
                : "Customers can use the website normally."}
            </p>
          </div>

          <button
            type="button"
            onClick={toggleServerStatus}
            disabled={saving}
            className={`rounded-xl px-5 py-2 font-semibold text-white disabled:opacity-60 ${
              form.maintenanceMode
                ? "bg-green-600 hover:bg-green-700"
                : "bg-red-600 hover:bg-red-700"
            }`}
          >
            {saving
              ? "Updating..."
              : form.maintenanceMode
                ? "Open Server"
                : "Close Server"}
          </button>
        </div>

        {form.maintenanceMode && (
          <p className="mt-4 rounded-lg bg-black/20 px-3 py-2 text-sm">
            Message:{" "}
            <span className="font-semibold">
              {form.maintenanceMessage || DEFAULT_MAINTENANCE_MESSAGE}
            </span>
          </p>
        )}
      </div>

      <form onSubmit={save} className="card p-6 space-y-5">
        <div>
          <label className="label">Site Name</label>
          <input
            className="input"
            value={form.siteName || ""}
            onChange={(e) =>
              setForm({ ...form, siteName: e.target.value })
            }
          />
        </div>

        <div>
          <label className="label">Exchange Rate (KHR per 1 USD)</label>
          <input
            className="input"
            type="number"
            value={form.exchangeRate || 4100}
            onChange={(e) =>
              setForm({ ...form, exchangeRate: e.target.value })
            }
          />
          <p className="text-xs text-fox-muted mt-1">
            Used to show KHR equivalents alongside USD prices.
          </p>
        </div>

        <div>
          <label className="label">Support Telegram Handle</label>
          <input
            className="input"
            value={form.supportTelegram || ""}
            onChange={(e) =>
              setForm({ ...form, supportTelegram: e.target.value })
            }
            placeholder="@yourhandle"
          />
        </div>

        <div>
          <label className="label">Support Email</label>
          <input
            className="input"
            type="email"
            value={form.supportEmail || ""}
            onChange={(e) =>
              setForm({ ...form, supportEmail: e.target.value })
            }
          />
        </div>

        <div>
          <label className="label">Site-wide Announcement optional</label>
          <textarea
            className="input"
            rows={2}
            value={form.announcement || ""}
            onChange={(e) =>
              setForm({ ...form, announcement: e.target.value })
            }
            placeholder="e.g. Special bonus this weekend!"
          />

          <div className="mt-2 flex gap-2">
            {(["info", "warning", "promo"] as const).map((tone) => (
              <button
                key={tone}
                type="button"
                onClick={() =>
                  setForm({ ...form, announcementTone: tone })
                }
                className={`text-xs px-3 py-1 rounded-full border ${
                  (form.announcementTone || "info") === tone
                    ? "border-fox-primary bg-fox-primary/10 text-fox-primary"
                    : "border-fox-border text-fox-muted"
                }`}
              >
                {tone}
              </button>
            ))}
          </div>
        </div>

        <label className="flex items-center gap-3 p-4 rounded-lg border border-fox-border bg-fox-surface">
          <input
            type="checkbox"
            checked={form.maintenanceMode}
            onChange={(e) =>
              setForm({
                ...form,
                maintenanceMode: e.target.checked,
                maintenanceMessage:
                  form.maintenanceMessage ||
                  DEFAULT_MAINTENANCE_MESSAGE,
              })
            }
          />

          <div className="flex-1">
            <div className="font-medium">Maintenance Mode</div>
            <div className="text-xs text-fox-muted">
              Blocks all new orders. Existing orders still process.
            </div>
          </div>
        </label>

        {form.maintenanceMode && (
          <div>
            <label className="label">
              Maintenance message shown to customers
            </label>
            <input
              className="input"
              value={
                form.maintenanceMessage || DEFAULT_MAINTENANCE_MESSAGE
              }
              onChange={(e) =>
                setForm({
                  ...form,
                  maintenanceMessage: e.target.value,
                })
              }
              placeholder={DEFAULT_MAINTENANCE_MESSAGE}
            />
          </div>
        )}

        <div className="pt-4 border-t border-fox-border">
          <h2 className="font-semibold mb-1">
            Telegram Notifications
          </h2>
          <p className="text-xs text-fox-muted mb-3">
            Get a message when an order is paid or delivered. Leave empty
            to disable.
          </p>

          <div className="grid sm:grid-cols-2 gap-3">
            <div>
              <label className="label">Bot token</label>
              <input
                className="input font-mono text-xs"
                value={form.telegramBotToken || ""}
                onChange={(e) =>
                  setForm({
                    ...form,
                    telegramBotToken: e.target.value,
                  })
                }
                placeholder="123456:ABC-DEF..."
              />
            </div>

            <div>
              <label className="label">Chat ID</label>
              <input
                className="input font-mono text-xs"
                value={form.telegramChatId || ""}
                onChange={(e) =>
                  setForm({
                    ...form,
                    telegramChatId: e.target.value,
                  })
                }
                placeholder="-1001234567890"
              />
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 pt-2">
          <button type="submit" disabled={saving} className="btn-primary">
            {saving ? "Saving..." : "Save Settings"}
          </button>

          {saved && (
            <span className="text-sm text-green-400">✓ Saved</span>
          )}
        </div>
      </form>
    </div>
  );
}