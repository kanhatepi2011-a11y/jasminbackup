import type { NextConfig } from "next";

const isProduction = process.env.NODE_ENV === "production";

function buildCspHeader(): string {
  const scriptSrc = isProduction
    ? "'self' 'strict-dynamic'"
    : "'self' 'unsafe-inline' 'unsafe-eval'";

  return [
    "default-src 'self'",
    `script-src ${scriptSrc}`,
    "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com",
    "font-src 'self' data: https://fonts.gstatic.com",
    "img-src 'self' data: blob: https://i.ibb.co https://api.qrserver.com https://img.freepik.com https://res.cloudinary.com https://*.cloudinary.com",
    "connect-src 'self'",
    "frame-ancestors 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "object-src 'none'",
    isProduction ? "upgrade-insecure-requests" : "",
  ]
    .filter(Boolean)
    .join("; ");
}

const nextConfig: NextConfig = {
  serverExternalPackages: ["pdfkit", "fontkit"],
  poweredByHeader: false,
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "i.ibb.co" },
      { protocol: "https", hostname: "api.qrserver.com" },
      { protocol: "https", hostname: "img.freepik.com" },
      { protocol: "https", hostname: "res.cloudinary.com" },
    ],
  },
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "Content-Security-Policy", value: buildCspHeader() },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
          { key: "Strict-Transport-Security", value: "max-age=63072000; includeSubDomains; preload" },
        ],
      },
    ];
  },
};

export default nextConfig;