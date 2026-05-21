"use client";

import Image from "next/image";
import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function AdminLoginPage() {
  const router = useRouter();

  const [step, setStep] = useState<"login" | "2fa">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [code, setCode] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [banned, setBanned] = useState(false);
  const [lockedUntil, setLockedUntil] = useState<Date | null>(null);
  const [countdown, setCountdown] = useState<string>("");

  // ✅ Countdown timer សម្រាប់ lock 5 នាទី
  useEffect(() => {
    if (!lockedUntil) { setCountdown(""); return; }

    const interval = setInterval(() => {
      const diff = lockedUntil.getTime() - Date.now();
      if (diff <= 0) {
        setLockedUntil(null);
        setError(null);
        setCountdown("");
        clearInterval(interval);
        return;
      }
      const m = Math.floor(diff / 60000);
      const s = Math.floor((diff % 60000) / 1000);
      setCountdown(`${m}:${s.toString().padStart(2, "0")}`);
    }, 1000);

    return () => clearInterval(interval);
  }, [lockedUntil]);

  // ✅ ពេល refresh page → restore 2FA step + check lock (login & 2FA)
  useEffect(() => {
    // Step 1: Check 2FA session via httpOnly cookie (server reads it)
    fetch("/api/admin/auth/2fa")
      .then((r) => r.json())
      .then((data) => {
        if (data.step === "2fa") {
          setStep("2fa");
          if (data.locked && data.forever) {
            setBanned(true);
            setError("កូដ 2FA ខុស ២ លើក Lock ជាអចិន្ត្រៃយ៍ សូមទាក់ទង owner។");
          } else if (data.locked && data.lockedUntil) {
            setLockedUntil(new Date(data.lockedUntil));
            setError("កូដ 2FA ខុស លើកទី១ Lock 5 នាទី សូមរង់ចាំ។");
          }
          return; // Stop here — we're in 2FA step
        }

        // Step 2: Check login lock via saved email
        const savedEmail = localStorage.getItem("admin_login_email");
        if (!savedEmail) return;
        setEmail(savedEmail);

        fetch(`/api/admin/auth?email=${encodeURIComponent(savedEmail)}`)
          .then((r) => r.json())
          .then((loginData) => {
            if (!loginData.locked) return;
            if (loginData.forever) {
              setBanned(true);
              setError("គណនីត្រូវបាន lock ជាអចិន្ត្រៃយ៍។ សូមទាក់ទង owner។");
            } else if (loginData.lockedUntil) {
              setLockedUntil(new Date(loginData.lockedUntil));
              setError("password ខុស លើកទី១ Lock 5 នាទី សូមរង់ចាំ។");
            }
          })
          .catch(() => {});
      })
      .catch(() => {});
  }, []);

  const isLocked = banned || !!lockedUntil;

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    if (isLocked || loading) return;

    setError(null);
    setLoading(true);

    // ✅ Save email ដើម្បីប្រើ check lock ពេល refresh
    localStorage.setItem("admin_login_email", email.trim());

    try {
      const res = await fetch("/api/admin/auth", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: email.trim(), password }),
      });

      const data = await res.json().catch(() => ({}));

      if (res.status === 403) {
        setBanned(true);
        setError(data.error || "គណនីត្រូវបាន lock ជាអចិន្ត្រៃយ៍");
        return;
      }

      if (res.status === 429) {
        if (data.lockedUntil) setLockedUntil(new Date(data.lockedUntil));
        setError(data.error || "Lock បណ្ដោះអាសន្ន។ សូមរង់ចាំ។");
        return;
      }

      if (!res.ok) {
        throw new Error(data.error || "មានបញ្ហាក្នុងការចូល");
      }

      if (data.requires2FA) {
        setStep("2fa");
        setCode("");
        setError(null);
        return;
      }

      localStorage.removeItem("admin_login_email");
      router.push("/admin");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "មានបញ្ហាក្នុងការចូល");
    } finally {
      setLoading(false);
    }
  }

  async function handleVerify2FA(e: React.FormEvent) {
    e.preventDefault();
    if (banned || loading) return;

    setError(null);
    setLoading(true);

    try {
      const res = await fetch("/api/admin/auth/2fa", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ code: code.trim() }),
      });

      const data = await res.json().catch(() => ({}));
      const message = data.error || data.message || "";

      if (res.status === 403) {
        setBanned(true);
        setError(message || "គណនីត្រូវបាន lock ជាអចិន្ត្រៃយ៍");
        return;
      }

      if (res.status === 429) {
        if (data.lockedUntil) setLockedUntil(new Date(data.lockedUntil));
        setError(message || "កូដ 2FA ខុស លើកទី១ Lock 5 នាទី សូមរង់ចាំ។");
        return;
      }

      if (res.status === 401) {
        setError(message || "លេខកូដ 2FA មិនត្រឹមត្រូវ");
        const lowerMessage = String(message).toLowerCase();
        if (lowerMessage.includes("expired") || lowerMessage.includes("session")) {
          setStep("login");
          setPassword("");
          setCode("");
        }
        return;
      }

      if (!res.ok) {
        throw new Error(message || "លេខកូដ 2FA មិនត្រឹមត្រូវ");
      }

      localStorage.removeItem("admin_login_email");
      router.push("/admin");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "លេខកូដ 2FA មិនត្រឹមត្រូវ");
    } finally {
      setLoading(false);
    }
  }

  async function handleBackToLogin() {
    if (loading) return;
    setStep("login");
    setPassword("");
    setCode("");
    setError(null);
    setBanned(false);
    setLockedUntil(null);
    try {
      await fetch("/api/admin/auth", { method: "DELETE", credentials: "include" });
    } catch { }
  }

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Kantumruy+Pro:wght@300;400;500;600&display=swap');

        * { box-sizing: border-box; }

        .login-root {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          padding: 1.5rem;
          font-family: 'Kantumruy Pro', sans-serif;
          position: relative;
          overflow: hidden;
          background: #fce8f0;
        }

        .login-root::before {
          content: '';
          position: fixed;
          inset: 0;
          background:
            radial-gradient(ellipse 55% 55% at 20% 25%, #f9b8d0 0%, transparent 65%),
            radial-gradient(ellipse 50% 50% at 80% 75%, #f9b8d0 0%, transparent 65%),
            radial-gradient(ellipse 70% 70% at 50% 50%, #fde0eb 0%, transparent 70%);
          pointer-events: none;
          z-index: 0;
        }

        .deco {
          position: fixed;
          opacity: 0.18;
          color: #e91e63;
          pointer-events: none;
          z-index: 0;
          animation: floatY 6s ease-in-out infinite alternate;
        }

        .deco svg { display: block; }

        .deco-gamepad  { top: 6%;  left: 7%;  font-size: 2.5rem; animation-delay: 0s; }
        .deco-diamond  { top: 7%;  right: 6%; font-size: 2rem;   animation-delay: -2s; }
        .deco-star     { top: 38%; right: 3%; font-size: 1.6rem; animation-delay: -1s; }
        .deco-flower   { bottom: 8%; right: 5%; font-size: 2.2rem; animation-delay: -3s; }
        .deco-bolt     { bottom: 18%; left: 9%; font-size: 2rem; animation-delay: -1.5s; }
        .deco-circle   { top: 42%; left: 3%;  font-size: 1.4rem; animation-delay: -4s; }
        .deco-heart    { bottom: 35%; right: 10%; font-size: 1.2rem; animation-delay: -2.5s; }
        .deco-crown    { top: 20%; left: 20%; font-size: 1rem; animation-delay: -0.5s; }

        @keyframes floatY {
          from { transform: translateY(0px) rotate(0deg); }
          to   { transform: translateY(-18px) rotate(8deg); }
        }

        .card-wrap {
          position: relative;
          z-index: 1;
          width: 100%;
          max-width: 420px;
          animation: fadeUp 0.65s cubic-bezier(0.16, 1, 0.3, 1) both;
        }

        @keyframes fadeUp {
          from { opacity: 0; transform: translateY(30px); }
          to   { opacity: 1; transform: translateY(0); }
        }

        .logo-wrap {
          display: flex;
          justify-content: center;
          margin-bottom: 1.75rem;
        }

        .logo-img {
          width: 76px;
          height: 76px;
          object-fit: contain;
          border-radius: 50%;
          background: white;
          padding: 6px;
          box-shadow: 0 6px 28px rgba(233, 30, 99, 0.22);
        }

        .glass-card {
          background: rgba(255, 255, 255, 0.65);
          backdrop-filter: blur(28px);
          -webkit-backdrop-filter: blur(28px);
          border: 1.5px solid rgba(255, 255, 255, 0.85);
          border-radius: 28px;
          padding: 2.5rem 2.25rem 2.25rem;
          box-shadow:
            0 12px 48px rgba(233, 30, 99, 0.13),
            0 2px 0 rgba(255,255,255,0.95) inset;
        }

        .card-heading {
          font-size: 1.5rem;
          font-weight: 600;
          color: #c2185b;
          margin: 0 0 0.3rem;
          text-align: center;
        }

        .card-sub {
          font-size: 0.875rem;
          color: #ad5f80;
          text-align: center;
          margin: 0 0 2rem;
          font-weight: 300;
          line-height: 1.6;
        }

        .field-group { margin-bottom: 1.2rem; }

        .field-label {
          display: block;
          font-size: 0.8rem;
          font-weight: 500;
          color: #b06080;
          margin-bottom: 0.45rem;
        }

        .field-wrap { position: relative; }

        .field-input {
          width: 100%;
          height: 48px;
          padding: 0 1rem;
          background: rgba(255,255,255,0.75);
          border: 1.5px solid rgba(233, 30, 99, 0.18);
          border-radius: 14px;
          font-family: 'Kantumruy Pro', sans-serif;
          font-size: 0.9rem;
          color: #2d0a18;
          outline: none;
          transition: border-color 0.2s, box-shadow 0.2s, background 0.2s;
        }

        .field-input::placeholder { color: #d4a0b5; }

        .field-input:focus {
          border-color: #e91e63;
          background: #fff;
          box-shadow: 0 0 0 3px rgba(233, 30, 99, 0.13);
        }

        .field-input.has-toggle { padding-right: 3rem; }

        .field-input:disabled {
          opacity: 0.45;
          cursor: not-allowed;
          background: rgba(220,220,220,0.5);
        }

        .toggle-btn {
          position: absolute;
          right: 0;
          top: 0;
          height: 48px;
          width: 46px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: none;
          border: none;
          cursor: pointer;
          color: #c088a0;
          transition: color 0.2s;
          padding: 0;
        }

        .toggle-btn:hover { color: #e91e63; }
        .toggle-btn:disabled { cursor: not-allowed; opacity: 0.4; }

        .error-box {
          display: flex;
          align-items: flex-start;
          gap: 0.6rem;
          border-radius: 12px;
          padding: 0.75rem 1rem;
          margin-bottom: 1.2rem;
          font-size: 0.82rem;
          line-height: 1.6;
        }

        .error-box.normal {
          background: rgba(244, 67, 54, 0.07);
          border: 1px solid rgba(244, 67, 54, 0.25);
          color: #b71c1c;
        }

        .error-box.banned {
          background: rgba(60, 0, 0, 0.06);
          border: 1px solid rgba(120, 0, 0, 0.28);
          color: #7f0000;
        }

        .countdown {
          font-size: 1.1rem;
          font-weight: 600;
          color: #c2185b;
        }

        .submit-btn {
          width: 100%;
          height: 50px;
          background: linear-gradient(135deg, #f06292 0%, #e91e63 50%, #c2185b 100%);
          border: none;
          border-radius: 50px;
          font-family: 'Kantumruy Pro', sans-serif;
          font-size: 1rem;
          font-weight: 500;
          color: white;
          cursor: pointer;
          transition: transform 0.15s, box-shadow 0.15s, opacity 0.15s;
          box-shadow: 0 6px 20px rgba(233, 30, 99, 0.4);
          margin-top: 0.5rem;
          position: relative;
          overflow: hidden;
        }

        .submit-btn::after {
          content: '';
          position: absolute;
          inset: 0;
          background: linear-gradient(135deg, rgba(255,255,255,0.15) 0%, transparent 55%);
          pointer-events: none;
        }

        .submit-btn:hover:not(:disabled) {
          transform: translateY(-2px);
          box-shadow: 0 10px 28px rgba(233, 30, 99, 0.45);
        }

        .submit-btn:active:not(:disabled) { transform: translateY(0); }

        .submit-btn:disabled {
          opacity: 0.38;
          cursor: not-allowed;
          filter: grayscale(40%);
          box-shadow: none;
          transform: none;
        }

        .secondary-btn {
          margin-top: 0.75rem;
          background: rgba(255,255,255,0.65);
          color: #c2185b;
          box-shadow: none;
          border: 1px solid rgba(233, 30, 99, 0.25);
        }

        .spinner {
          display: inline-block;
          width: 16px;
          height: 16px;
          border: 2px solid rgba(255,255,255,0.4);
          border-top-color: white;
          border-radius: 50%;
          animation: spin 0.7s linear infinite;
          vertical-align: middle;
          margin-right: 8px;
        }

        @keyframes spin { to { transform: rotate(360deg); } }

        .back-link {
          display: block;
          text-align: center;
          margin-top: 1.4rem;
          font-size: 0.82rem;
          color: #c06080;
          text-decoration: none;
          transition: color 0.2s;
        }

        .back-link:hover { color: #e91e63; }
      `}</style>

      <div className="login-root">
        <span className="deco deco-gamepad">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="currentColor">
            <path d="M17 4H7a5 5 0 0 0-5 5v6a5 5 0 0 0 5 5h10a5 5 0 0 0 5-5V9a5 5 0 0 0-5-5zm-7 8H8v2H6v-2H4v-2h2V8h2v2h2v2zm4 1a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm2-3a1 1 0 1 1 0-2 1 1 0 0 1 0 2z" />
          </svg>
        </span>

        <span className="deco deco-diamond">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor">
            <path d="m12 2 4 6H8L12 2zm8 6-4 10H8L4 8h16zm-8 8 4-8H8l4 8z" />
          </svg>
        </span>

        <span className="deco deco-star">
          <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 17.27 18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z" />
          </svg>
        </span>

        <span className="deco deco-flower">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 22a4 4 0 0 1-4-4c0-1.1.45-2.1 1.17-2.83A4 4 0 0 1 8 12a4 4 0 0 1 1.17-2.83A4 4 0 0 1 12 2a4 4 0 0 1 2.83 6.83A4 4 0 0 1 16 12a4 4 0 0 1-1.17 2.83A4.002 4.002 0 0 1 16 18a4 4 0 0 1-4 4z" />
          </svg>
        </span>

        <span className="deco deco-bolt">
          <svg width="30" height="30" viewBox="0 0 24 24" fill="currentColor">
            <path d="M13 2 4.5 13.5H11L10 22l9.5-11.5H13L13 2z" />
          </svg>
        </span>

        <span className="deco deco-circle">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <circle cx="12" cy="12" r="9" />
          </svg>
        </span>

        <span className="deco deco-heart">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z" />
          </svg>
        </span>

        <span className="deco deco-crown">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <path d="M2 19h20v2H2v-2zm2-3 3-8 5 4 5-4 3 8H4z" />
          </svg>
        </span>

        <div className="card-wrap">
          <Link href="/" className="logo-wrap">
            <Image
              src="https://i.ibb.co/ycPxxz8h/IMG-20260515-100429.png"
              alt="TopUpJASMIN Logo"
              width={76}
              height={76}
              className="logo-img"
              priority
            />
          </Link>

          <div className="glass-card">
            <h1 className="card-heading">
              {step === "login" ? "🌸 ចូលគណនីអ្នកគ្រប់គ្រង" : "🔐 បញ្ជាក់កូដ 2FA"}
            </h1>

            <p className="card-sub">
              {step === "login"
                ? "សូមបញ្ចូលព័ត៌មានរបស់អ្នក ដើម្បីចូលគ្រប់គ្រង"
                : "Password ត្រឹមត្រូវហើយ។ សូមបញ្ចូលកូដ 2FA ដើម្បីបញ្ជាក់"}
            </p>

            {step === "login" ? (
              <form onSubmit={handleLogin}>
                <div className="field-group">
                  <label className="field-label">អ៊ីមែល</label>
                  <div className="field-wrap">
                    <input
                      type="email"
                      className="field-input"
                      placeholder="admin@example.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      required
                      autoFocus
                      disabled={isLocked || loading}
                    />
                  </div>
                </div>

                <div className="field-group">
                  <label className="field-label">លេខសម្ងាត់</label>
                  <div className="field-wrap">
                    <input
                      type={showPassword ? "text" : "password"}
                      className="field-input has-toggle"
                      placeholder="••••••••••"
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      required
                      disabled={isLocked || loading}
                    />
                    <button
                      type="button"
                      className="toggle-btn"
                      onClick={() => setShowPassword(!showPassword)}
                      disabled={isLocked || loading}
                    >
                      {showPassword ? (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94" />
                          <path d="M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19" />
                          <line x1="1" y1="1" x2="23" y2="23" />
                        </svg>
                      ) : (
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                          <circle cx="12" cy="12" r="3" />
                        </svg>
                      )}
                    </button>
                  </div>
                </div>

                {error && (
                  <div className={`error-box ${banned ? "banned" : "normal"}`}>
                    <svg style={{ flexShrink: 0, marginTop: "2px" }} width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="10" />
                      <line x1="12" y1="8" x2="12" y2="12" />
                      <line x1="12" y1="16" x2="12.01" y2="16" />
                    </svg>
                    <span>
                      {error}
                      {countdown && <> &nbsp;<span className="countdown">⏱ {countdown}</span></>}
                    </span>
                  </div>
                )}

                <button type="submit" className="submit-btn" disabled={loading || isLocked}>
                  {loading ? (
                    <><span className="spinner" />កំពុងពិនិត្យ…</>
                  ) : banned ? (
                    "🔒 គណនីត្រូវបានផ្អាកជាអចិន្ត្រៃយ៍"
                  ) : lockedUntil ? (
                    `⏳ Lock ${countdown}`
                  ) : (
                    "🔑 ចូលគណនី"
                  )}
                </button>
              </form>
            ) : (
              <form onSubmit={handleVerify2FA}>
                <div className="field-group">
                  <label className="field-label">កូដ 2FA</label>
                  <div className="field-wrap">
                    <input
                      type="text"
                      inputMode="numeric"
                      autoComplete="one-time-code"
                      className="field-input"
                      placeholder="បញ្ចូលកូដ 2FA"
                      value={code}
                      onChange={(e) => setCode(e.target.value)}
                      required
                      autoFocus
                      disabled={banned || loading}
                    />
                  </div>
                </div>

                {error && (
                  <div className={`error-box ${banned ? "banned" : "normal"}`}>
                    <svg style={{ flexShrink: 0, marginTop: "2px" }} width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <circle cx="12" cy="12" r="10" />
                      <line x1="12" y1="8" x2="12" y2="12" />
                      <line x1="12" y1="16" x2="12.01" y2="16" />
                    </svg>
                    {error}
                  </div>
                )}

                <button type="submit" className="submit-btn" disabled={loading || banned}>
                  {loading ? (
                    <><span className="spinner" />កំពុងបញ្ជាក់…</>
                  ) : banned ? (
                    "🔒 គណនីត្រូវបាន lock ជាអចិន្ត្រៃយ៍"
                  ) : (
                    "✅ បញ្ជាក់ 2FA"
                  )}
                </button>

                <button
                  type="button"
                  className="submit-btn secondary-btn"
                  disabled={loading}
                  onClick={handleBackToLogin}
                >
                  ← ត្រឡប់ទៅ Login
                </button>
              </form>
            )}
          </div>

          <Link href="/" className="back-link">← ត្រឡប់ទៅទំព័រដើម</Link>
        </div>
      </div>
    </>
  );
}