import Image from "next/image";
import Link from "next/link";
import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { getCurrentAdmin } from "@/lib/auth";

const ADMIN_COOKIE_NAME = "admin_token";
const ADMIN_LOGIN_PATH  = process.env.ADMIN_LOGIN_PATH || "/admin/sophallogin";

export default async function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const admin = await getCurrentAdmin();

  if (!admin) {
    // If a token cookie exists but getCurrentAdmin() returned null, the token is
    // invalid (expired JWT, or admin disabled/deleted in DB). We redirect to
    // the login page. Middleware is the fast first layer; this is the DB-backed
    // second layer that catches disabled accounts with still-valid JWTs.
    //
    // Note: cookies() is read-only in Server Components, so we cannot delete
    // the stale cookie here. It will either expire naturally (8h max-age) or
    // be explicitly cleared when the user clicks Logout. Security is guaranteed
    // because every protected page re-calls getCurrentAdmin() which checks the DB.
    const cookieStore = await cookies();
    const hasToken = !!cookieStore.get(ADMIN_COOKIE_NAME)?.value;

    if (hasToken) {
      // Had a (now-invalid) token — redirect to login so they can re-authenticate.
      redirect(ADMIN_LOGIN_PATH);
    }

    // No token at all — this is the login page or honeypot (middleware routed
    // them here deliberately). Render children without the admin sidebar.
    return <>{children}</>;
  }

  return (
    <div className="min-h-screen flex">
      <aside className="w-60 border-r border-fox-border bg-fox-surface flex flex-col">
        <Link href="/admin" className="p-6 border-b border-fox-border">
          <div className="flex items-center gap-2">
            <Image
              src="https://i.ibb.co/ycPxxz8h/IMG-20260515-100429.png"
              alt="TopUpJASMIN Logo"
              width={40}
              height={40}
              className="h-10 w-auto object-contain"
              priority
            />
            <div>
              <div className="font-display font-bold text-sm">
                JASMIN<span className="text-fox-primary">TOPUP</span>
              </div>
              <div className="text-[10px] text-fox-muted uppercase tracking-widest">
                Admin Panel
              </div>
            </div>
          </div>
        </Link>

        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {[
            { href: "/admin",            label: "Dashboard",   icon: "📊" },
            { href: "/admin/orders",     label: "Orders",      icon: "📦" },
            { href: "/admin/games",      label: "Games",       icon: "🎮" },
            { href: "/admin/products",   label: "Products",    icon: "💎" },
            { href: "/admin/promo-codes",label: "Promo Codes", icon: "🏷️" },
            { href: "/admin/banners",    label: "Banners",     icon: "🖼️" },
            { href: "/admin/faqs",       label: "FAQ",         icon: "❓" },
            { href: "/admin/blog",       label: "Blog",        icon: "📝" },
            { href: "/admin/customers",  label: "Customers",   icon: "👥" },
            { href: "/admin/banlist",    label: "Banlist",     icon: "🚫" },
            { href: "/admin/audit-logs", label: "Audit Log",   icon: "📜" },
            { href: "/admin/settings",   label: "Settings",    icon: "⚙️" },
          ].map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-fox-text/80 hover:bg-fox-card hover:text-fox-primary transition-colors"
            >
              <span>{item.icon}</span>
              {item.label}
            </Link>
          ))}
        </nav>

        <div className="p-4 border-t border-fox-border">
          <div className="text-xs text-fox-muted mb-1">Signed in as</div>
          <div className="text-sm font-medium mb-3 truncate">{admin.email}</div>
          {/* LogoutButton is a client component that calls DELETE /api/admin/auth */}
          <LogoutButtonImport />
        </div>
      </aside>

      <main className="flex-1 overflow-auto">{children}</main>
    </div>
  );
}

// Lazy import wrapper so we don't break the server component
import LogoutButton from "@/components/LogoutButton";
function LogoutButtonImport() {
  return <LogoutButton />;
}
