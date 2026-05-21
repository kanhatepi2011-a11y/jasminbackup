"use client";

import { useState, useEffect, useRef } from "react";
import Link from "next/link";
import Image from "next/image";

const rude_lines = [
  "អ្នកគិតថាខ្លួនឆ្លាតមែនទេ? 🤡 បើខ្លួនឆ្លាតពិតមែន ត្រូវដឹងថាកន្លែងនេះមិនមែនសម្រាប់ស្ទះ!",
  "IP របស់អ្នកត្រូវបានកត់ត្រារួចហើយ 📡 ចែករំលែកទៅម្តាយអ្នកដែរ?",
  "Hacker ណាចង់ hack server ខ្ញុំ? 😂 ក្ដាមធ្នូរ! Server ខ្ញុំ free tier ណា!",
  "ច្បាស់ណាស់ — ជីវិតអ្នកគ្មានអ្វីគួរធ្វើ ក្រៅពីព្យាយាម hack គេ? 😘",
  "ស្វែងរក admin ឃើញហើយ ម្ចាស់ admin នៅផ្ទះ ញញឹម😁",
];

export default function HoneypotPage() {
  const [lineIdx, setLineIdx] = useState(0);
  const [glitch, setGlitch] = useState(false);
  const [particles, setParticles] = useState<{id:number;x:number;y:number;size:number;delay:number;dur:number}[]>([]);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    // Generate floating particles
    setParticles(Array.from({length: 24}, (_, i) => ({
      id: i,
      x: Math.random() * 100,
      y: Math.random() * 100,
      size: 4 + Math.random() * 8,
      delay: Math.random() * 6,
      dur: 5 + Math.random() * 5,
    })));

    // Cycle rude lines
    intervalRef.current = setInterval(() => {
      setGlitch(true);
      setTimeout(() => {
        setLineIdx(i => (i + 1) % rude_lines.length);
        setGlitch(false);
      }, 300);
    }, 3500);

    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, []);

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Kantumruy+Pro:wght@300;400;600;700&family=Black+Ops+One&family=Space+Mono:wght@700&display=swap');

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        .fy-root {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          font-family: 'Kantumruy Pro', sans-serif;
          position: relative;
          overflow: hidden;
          background: #0d0010;
        }

        /* Animated dark mesh background */
        .fy-bg {
          position: fixed;
          inset: 0;
          z-index: 0;
          background:
            radial-gradient(ellipse 60% 50% at 15% 20%, rgba(180,0,80,0.35) 0%, transparent 70%),
            radial-gradient(ellipse 50% 60% at 85% 80%, rgba(120,0,160,0.3) 0%, transparent 70%),
            radial-gradient(ellipse 40% 40% at 50% 50%, rgba(200,0,100,0.12) 0%, transparent 70%),
            #0d0010;
          animation: bgShift 8s ease-in-out infinite alternate;
        }

        @keyframes bgShift {
          from { filter: hue-rotate(0deg); }
          to   { filter: hue-rotate(25deg); }
        }

        /* Scanlines overlay */
        .fy-scan {
          position: fixed;
          inset: 0;
          z-index: 1;
          background: repeating-linear-gradient(
            0deg,
            transparent,
            transparent 3px,
            rgba(0,0,0,0.08) 3px,
            rgba(0,0,0,0.08) 4px
          );
          pointer-events: none;
        }

        /* Floating particles */
        .fy-particle {
          position: fixed;
          border-radius: 50%;
          background: rgba(233,30,99,0.6);
          pointer-events: none;
          z-index: 1;
          animation: particleFloat var(--dur) ease-in-out var(--delay) infinite alternate;
          box-shadow: 0 0 10px rgba(233,30,99,0.8);
        }

        @keyframes particleFloat {
          from { transform: translateY(0) scale(1); opacity: 0.4; }
          to   { transform: translateY(-40px) scale(1.4); opacity: 0.9; }
        }

        /* Main card */
        .fy-wrap {
          position: relative;
          z-index: 10;
          width: 100%;
          max-width: 500px;
          padding: 1.5rem;
          animation: cardIn 0.8s cubic-bezier(0.16,1,0.3,1) both;
        }

        @keyframes cardIn {
          from { opacity: 0; transform: scale(0.85) translateY(30px); }
          to   { opacity: 1; transform: scale(1) translateY(0); }
        }

        .fy-logo {
          display: flex;
          justify-content: center;
          margin-bottom: 1.5rem;
        }

        .fy-logo img {
          width: 72px; height: 72px;
          border-radius: 50%;
          border: 2px solid rgba(233,30,99,0.6);
          box-shadow: 0 0 24px rgba(233,30,99,0.5), 0 0 48px rgba(233,30,99,0.2);
          animation: logoPulse 2.5s ease-in-out infinite;
        }

        @keyframes logoPulse {
          0%,100% { box-shadow: 0 0 24px rgba(233,30,99,0.5), 0 0 48px rgba(233,30,99,0.2); }
          50%      { box-shadow: 0 0 36px rgba(233,30,99,0.9), 0 0 72px rgba(233,30,99,0.4); }
        }

        .fy-card {
          background: rgba(20,0,15,0.75);
          backdrop-filter: blur(32px);
          -webkit-backdrop-filter: blur(32px);
          border: 1.5px solid rgba(233,30,99,0.3);
          border-radius: 24px;
          padding: 2.5rem 2rem;
          text-align: center;
          box-shadow:
            0 0 0 1px rgba(233,30,99,0.08) inset,
            0 24px 64px rgba(0,0,0,0.6),
            0 0 80px rgba(180,0,80,0.15);
        }

        .fy-emoji {
          font-size: 2.5rem;
          margin-bottom: 1rem;
          animation: emojiSpin 6s ease-in-out infinite;
          display: block;
        }

        @keyframes emojiSpin {
          0%,100% { transform: rotate(0deg) scale(1); }
          25%  { transform: rotate(-8deg) scale(1.1); }
          75%  { transform: rotate(8deg) scale(1.1); }
        }

        /* BIG GLITCH TEXT */
        .fy-big {
          font-family: 'Black Ops One', 'Space Mono', monospace;
          font-size: clamp(3.5rem, 15vw, 6.5rem);
          font-weight: 900;
          line-height: 0.95;
          letter-spacing: -2px;
          color: #ff1a6c;
          text-shadow:
            0 0 20px rgba(255,26,108,0.8),
            0 0 40px rgba(255,26,108,0.4),
            3px 0 0 rgba(0,255,255,0.3),
            -3px 0 0 rgba(255,0,128,0.3);
          position: relative;
          animation: textGlow 2s ease-in-out infinite alternate;
        }

        @keyframes textGlow {
          from { text-shadow: 0 0 20px rgba(255,26,108,0.8), 0 0 40px rgba(255,26,108,0.4), 3px 0 rgba(0,255,255,0.3), -3px 0 rgba(255,0,128,0.3); }
          to   { text-shadow: 0 0 30px rgba(255,26,108,1), 0 0 60px rgba(255,26,108,0.6), 5px 0 rgba(0,255,255,0.5), -5px 0 rgba(255,0,128,0.5); }
        }

        .fy-big.glitch {
          animation: glitchAnim 0.3s steps(2) both;
        }

        @keyframes glitchAnim {
          0%   { transform: translate(0); clip-path: inset(0 0 90% 0); }
          20%  { transform: translate(-4px, 2px); clip-path: inset(30% 0 50% 0); }
          40%  { transform: translate(4px, -2px); clip-path: inset(60% 0 20% 0); }
          60%  { transform: translate(-2px, 1px); clip-path: inset(80% 0 5% 0); }
          80%  { transform: translate(2px, -1px); }
          100% { transform: translate(0); clip-path: inset(0); }
        }

        .fy-sub-label {
          font-family: 'Space Mono', monospace;
          font-size: 0.65rem;
          letter-spacing: 4px;
          color: rgba(255,100,160,0.5);
          text-transform: uppercase;
          margin: 0.75rem 0 1.5rem;
        }

        /* Rotating rude message */
        .fy-msg {
          font-size: 0.92rem;
          color: rgba(255,180,210,0.9);
          line-height: 1.7;
          min-height: 3.5rem;
          transition: opacity 0.3s;
          padding: 0 0.5rem;
        }

        .fy-msg.glitch { opacity: 0; }

        /* Divider */
        .fy-divider {
          width: 60px;
          height: 2px;
          background: linear-gradient(90deg, transparent, #ff1a6c, transparent);
          margin: 1.5rem auto;
          animation: dividerPulse 2s ease-in-out infinite;
        }

        @keyframes dividerPulse {
          0%,100% { width: 60px; opacity: 0.6; }
          50%      { width: 100px; opacity: 1; }
        }

        /* Info badges */
        .fy-badges {
          display: flex;
          flex-direction: column;
          gap: 0.6rem;
          align-items: center;
        }

        .fy-badge {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          background: rgba(255,26,108,0.08);
          border: 1px solid rgba(255,26,108,0.25);
          border-radius: 999px;
          padding: 0.4rem 1rem;
          font-size: 0.75rem;
          color: rgba(255,120,160,0.9);
          font-family: 'Space Mono', monospace;
          letter-spacing: 0.5px;
        }

        .fy-badge.warn {
          background: rgba(255,60,0,0.08);
          border-color: rgba(255,60,0,0.3);
          color: rgba(255,140,80,0.9);
          animation: warnBlink 1.8s ease-in-out infinite;
        }

        @keyframes warnBlink {
          0%,100% { border-color: rgba(255,60,0,0.3); }
          50%      { border-color: rgba(255,60,0,0.8); box-shadow: 0 0 12px rgba(255,60,0,0.3); }
        }

        .dot {
          width: 6px; height: 6px;
          border-radius: 50%;
          background: currentColor;
          animation: dotPulse 1.2s ease-in-out infinite;
        }

        @keyframes dotPulse {
          0%,100% { opacity: 1; transform: scale(1); }
          50%      { opacity: 0.3; transform: scale(0.5); }
        }

        /* Corner decorations */
        .fy-corner {
          position: absolute;
          width: 20px; height: 20px;
          pointer-events: none;
        }
        .fy-corner.tl { top: 12px; left: 12px; border-top: 2px solid rgba(255,26,108,0.5); border-left: 2px solid rgba(255,26,108,0.5); }
        .fy-corner.tr { top: 12px; right: 12px; border-top: 2px solid rgba(255,26,108,0.5); border-right: 2px solid rgba(255,26,108,0.5); }
        .fy-corner.bl { bottom: 12px; left: 12px; border-bottom: 2px solid rgba(255,26,108,0.5); border-left: 2px solid rgba(255,26,108,0.5); }
        .fy-corner.br { bottom: 12px; right: 12px; border-bottom: 2px solid rgba(255,26,108,0.5); border-right: 2px solid rgba(255,26,108,0.5); }

        .fy-back {
          display: block;
          text-align: center;
          margin-top: 1.5rem;
          font-size: 0.8rem;
          color: rgba(255,100,150,0.5);
          text-decoration: none;
          font-family: 'Space Mono', monospace;
          letter-spacing: 1px;
          transition: color 0.2s;
        }
        .fy-back:hover { color: rgba(255,26,108,0.9); }
      `}</style>

      <div className="fy-root">
        <div className="fy-bg" />
        <div className="fy-scan" />

        {/* Floating particles */}
        {particles.map(p => (
          <div
            key={p.id}
            className="fy-particle"
            style={{
              left: `${p.x}%`,
              top: `${p.y}%`,
              width: p.size,
              height: p.size,
              ['--dur' as string]: `${p.dur}s`,
              ['--delay' as string]: `${p.delay}s`,
            }}
          />
        ))}

        <div className="fy-wrap">
          <div className="fy-logo">
            <Link href="/">
              <Image
                src="https://i.ibb.co/ycPxxz8h/IMG-20260515-100429.png"
                alt="JASMIN"
                width={72}
                height={72}
                priority
              />
            </Link>
          </div>

          <div className="fy-card" style={{ position: "relative" }}>
            <div className="fy-corner tl" />
            <div className="fy-corner tr" />
            <div className="fy-corner bl" />
            <div className="fy-corner br" />

            <span className="fy-emoji">🖕😈🖕</span>

            <div className={`fy-big${glitch ? " glitch" : ""}`}>
              FUCK<br />YOU
            </div>

            <p className="fy-sub-label">[ ACCESS DENIED ]</p>

            <p className={`fy-msg${glitch ? " glitch" : ""}`}>
              {rude_lines[lineIdx]}
            </p>

            <div className="fy-divider" />

            <div className="fy-badges">
              <div className="fy-badge">
                <span className="dot" />
                IP logged · Session recorded
              </div>
              <div className="fy-badge warn">
                <span className="dot" />
                ⚠️ រាយការណ៍ទៅអាជ្ញាធរ ក្នុង 24h
              </div>
              <div className="fy-badge">
                <span className="dot" />
                🔐 Protected by JASMIN Security
              </div>
            </div>
          </div>

          <Link href="/" className="fy-back">← ត្រឡប់ទៅទំព័រដើម</Link>
        </div>
      </div>
    </>
  );
}