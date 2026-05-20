"use client";

import { useState } from "react";
import Link from "next/link";
import Image from "next/image";

export default function HoneypotPage() {
  const [_] = useState(false);

  return (
    <>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Kantumruy+Pro:wght@400;700&display=swap');
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
        .hp-root {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          font-family: 'Kantumruy Pro', sans-serif;
          position: relative;
          overflow: hidden;
          background: #fce8f0;
        }
        .hp-root::before {
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
        .deco-gamepad { top: 6%;  left: 7%;  font-size: 2.5rem; animation-delay: 0s; }
        .deco-diamond { top: 7%;  right: 6%; font-size: 2rem;   animation-delay: -2s; }
        .deco-star    { top: 38%; right: 3%; font-size: 1.6rem; animation-delay: -1s; }
        .deco-flower  { bottom: 8%;  right: 5%;  font-size: 2.2rem; animation-delay: -3s; }
        .deco-bolt    { bottom: 18%; left: 9%;   font-size: 2rem;   animation-delay: -1.5s; }
        .deco-circle  { top: 42%;   left: 3%;   font-size: 1.4rem; animation-delay: -4s; }
        .deco-heart   { bottom: 35%; right: 10%; font-size: 1.2rem; animation-delay: -2.5s; }
        .deco-crown   { top: 20%;   left: 20%;  font-size: 1rem;   animation-delay: -0.5s; }
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
          width: 76px; height: 76px;
          object-fit: contain;
          border-radius: 50%;
          background: white;
          padding: 6px;
          box-shadow: 0 6px 28px rgba(233,30,99,0.22);
        }
        .glass-card {
          background: rgba(255,255,255,0.65);
          backdrop-filter: blur(28px);
          -webkit-backdrop-filter: blur(28px);
          border: 1.5px solid rgba(255,255,255,0.85);
          border-radius: 28px;
          padding: 2.5rem 2.25rem 2.25rem;
          box-shadow: 0 12px 48px rgba(233,30,99,0.13), 0 2px 0 rgba(255,255,255,0.95) inset;
          text-align: center;
        }
        .emoji-row {
          font-size: 2.2rem;
          margin-bottom: 1rem;
          animation: bounce 1.5s ease-in-out infinite alternate;
        }
        @keyframes bounce {
          from { transform: translateY(0); }
          to   { transform: translateY(-8px); }
        }
        .big {
          font-size: clamp(3rem, 12vw, 5.5rem);
          font-weight: 700;
          line-height: 1;
          color: #c2185b;
          text-shadow: 0 4px 24px rgba(233,30,99,0.3);
          animation: shake 4s ease-in-out infinite;
        }
        @keyframes shake {
          0%,90%,100% { transform: rotate(0deg); }
          92% { transform: rotate(-2deg); }
          94% { transform: rotate(2deg); }
          96% { transform: rotate(-1deg); }
          98% { transform: rotate(1deg); }
        }
        .sub {
          font-size: 0.95rem;
          color: #ad5f80;
          margin-top: 1rem;
          line-height: 1.8;
        }
        .badge {
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
          margin-top: 1.8rem;
          background: rgba(233,30,99,0.08);
          border: 1px solid rgba(233,30,99,0.25);
          border-radius: 999px;
          padding: 0.45rem 1.1rem;
          font-size: 0.78rem;
          color: #c2185b;
          font-weight: 500;
        }
        .pulse {
          width: 7px; height: 7px;
          border-radius: 50%;
          background: #e91e63;
          animation: pd 1.2s ease-in-out infinite;
        }
        @keyframes pd {
          0%,100% { opacity: 1; transform: scale(1); }
          50%      { opacity: 0.3; transform: scale(0.6); }
        }
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

      <div className="hp-root">

        <span className="deco deco-gamepad">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="currentColor"><path d="M17 4H7a5 5 0 0 0-5 5v6a5 5 0 0 0 5 5h10a5 5 0 0 0 5-5V9a5 5 0 0 0-5-5zm-7 8H8v2H6v-2H4v-2h2V8h2v2h2v2zm4 1a1 1 0 1 1 0-2 1 1 0 0 1 0 2zm2-3a1 1 0 1 1 0-2 1 1 0 0 1 0 2z"/></svg>
        </span>
        <span className="deco deco-diamond">
          <svg width="32" height="32" viewBox="0 0 24 24" fill="currentColor"><path d="m12 2 4 6H8L12 2zm8 6-4 10H8L4 8h16zm-8 8 4-8H8l4 8z"/></svg>
        </span>
        <span className="deco deco-star">
          <svg width="26" height="26" viewBox="0 0 24 24" fill="currentColor"><path d="M12 17.27 18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
        </span>
        <span className="deco deco-flower">
          <svg width="36" height="36" viewBox="0 0 24 24" fill="currentColor"><path d="M12 22a4 4 0 0 1-4-4c0-1.1.45-2.1 1.17-2.83A4 4 0 0 1 8 12a4 4 0 0 1 1.17-2.83A4 4 0 0 1 12 2a4 4 0 0 1 2.83 6.83A4 4 0 0 1 16 12a4 4 0 0 1-1.17 2.83A4.002 4.002 0 0 1 16 18a4 4 0 0 1-4 4z"/></svg>
        </span>
        <span className="deco deco-bolt">
          <svg width="30" height="30" viewBox="0 0 24 24" fill="currentColor"><path d="M13 2 4.5 13.5H11L10 22l9.5-11.5H13L13 2z"/></svg>
        </span>
        <span className="deco deco-circle">
          <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><circle cx="12" cy="12" r="9"/></svg>
        </span>
        <span className="deco deco-heart">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
        </span>
        <span className="deco deco-crown">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M2 19h20v2H2v-2zm2-3 3-8 5 4 5-4 3 8H4z"/></svg>
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
            <div className="emoji-row">🖕😘🖕</div>
            <div className="big">FUCK YOU</div>
            <p className="sub">
              អ្នក hack មែនទេ? 😂<br />
              គ្មានអ្វីនៅទីនេះសម្រាប់អ្នកទេ ប្អូន 🌸
            </p>
            <div className="badge">
              <span className="pulse" />
              IP logged · Session recorded
            </div>
          </div>

          <Link href="/" className="back-link">← ត្រឡប់ទៅទំព័រដើម</Link>
        </div>

      </div>
    </>
  );
}