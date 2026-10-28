"use client";

import { Home, TrendingUp, ArrowLeftRight, Wallet, Clock, Plus, LogOut, Network, X } from "lucide-react";
import { signOut } from "next-auth/react";
import type { ViewKey } from "@/app/page";
import { useOpenCEX } from "@/lib/opencex/store";
import { fmtUSD } from "@/lib/opencex/format";
import { OstrichLogo } from "@/components/opencex/ostrich-logo";
import { LayoutDashboard, ShieldCheck } from "lucide-react";
import { useState } from "react";
import { Drawer, DrawerContent, DrawerHeader, DrawerTitle, DrawerDescription } from "@/components/ui/drawer";

interface NavItem { key: ViewKey; label: string; short: string; icon: React.ComponentType<{ className?: string }>; }

// Kraken-style: Home, Explore, [+] FAB, Portfolio, More
const PRIMARY: NavItem[] = [
  { key: "trading", label: "Home", short: "Home", icon: Home },
  { key: "markets", label: "Explore", short: "Explore", icon: TrendingUp },
  { key: "wallet", label: "Portfolio", short: "Portfolio", icon: Wallet },
];
const MORE_ITEMS: NavItem[] = [
  { key: "swap", label: "Convert", short: "Convert", icon: ArrowLeftRight },
  { key: "admin", label: "Activity", short: "Activity", icon: Clock },
  { key: "architecture", label: "System", short: "System", icon: Network },
];

interface SessionUserLike { email?: string | null; name?: string | null; onboardingComplete?: boolean; tier?: number; kycStatus?: string; }

export function Sidebar({ view, onChange, onLogout, sessionUser }: { view: ViewKey; onChange: (v: ViewKey) => void; onLogout?: () => void; sessionUser?: SessionUserLike; }) {
  const balances = useOpenCEX((s) => s.balances);
  const totalUSD = balances.reduce((s, b) => s + b.usdValue, 0);
  const [confirmLogout, setConfirmLogout] = useState(false);

  const handleLogout = () => {
    if (!confirmLogout) { setConfirmLogout(true); setTimeout(() => setConfirmLogout(false), 3000); return; }
    signOut({ redirect: false }).then(() => onLogout?.());
  };

  const displayName = sessionUser?.name || sessionUser?.email?.split("@")[0] || "alex.trader";
  const initials = displayName.slice(0, 2).toUpperCase();
  const tier = sessionUser?.tier ?? 3;
  const ALL_ITEMS = [...PRIMARY, ...MORE_ITEMS];

  return (
    <aside className="w-60 shrink-0 flex flex-col" style={{ background: "#0b0b0d" }}>
      {/* Logo */}
      <div className="h-14 flex items-center gap-2 px-4" style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
        <div className="w-8 h-8 rounded-xl flex items-center justify-center text-success" style={{ background: "#1c1c1e" }}>
          <OstrichLogo className="w-7 h-7" />
        </div>
        <div className="flex flex-col leading-tight">
          <span className="font-bold text-sm text-white">Mbuni CEX</span>
          <span className="text-[10px] text-muted">2.0</span>
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 p-2 space-y-0.5">
        {ALL_ITEMS.map((item) => {
          const Icon = item.icon;
          const active = view === item.key;
          return (
            <button key={item.key} onClick={() => onChange(item.key)}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-colors ${
                active ? "text-white" : "text-muted hover:text-white"
              }`}
              style={active ? { background: "rgba(255,255,255,0.06)" } : {}}>
              <Icon className="w-5 h-5 shrink-0" />
              <span className="font-medium">{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Portfolio card */}
      <div className="p-3">
        <div className="kr-card p-4">
          <div className="text-[10px] text-muted uppercase tracking-wider">Portfolio</div>
          <div className="text-lg font-bold tabular text-white mt-0.5">{fmtUSD(totalUSD)}</div>
          <div className="text-[10px] text-success mt-0.5">+2.4% 24h</div>
        </div>
      </div>

      {/* User */}
      <div className="flex items-center gap-2 px-4 py-3" style={{ borderTop: "1px solid rgba(255,255,255,0.04)" }}>
        <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white" style={{ background: "linear-gradient(135deg, #7f66ff, #9580ff)" }}>
          {initials}
        </div>
        <div className="flex-1 min-w-0">
          <div className="text-xs font-medium text-white truncate">{displayName}</div>
          <div className="text-[10px] text-muted">Tier {tier} · KYC</div>
        </div>
        <button onClick={handleLogout}
          className={`p-1.5 rounded-lg transition-colors ${confirmLogout ? "bg-danger text-white" : "text-muted hover:text-danger"}`}>
          <LogOut className="w-3.5 h-3.5" />
        </button>
      </div>
    </aside>
  );
}

// Mobile nav — Kraken-style solid tab bar with center FAB
export function MobileNav({ view, onChange, onLogout, sessionUser }: { view: ViewKey; onChange: (v: ViewKey) => void; onLogout?: () => void; sessionUser?: { email?: string | null; name?: string | null; tier?: number }; }) {
  const [moreOpen, setMoreOpen] = useState(false);
  const balances = useOpenCEX((s) => s.balances);
  const totalUSD = balances.reduce((s, b) => s + b.usdValue, 0);
  const displayName = sessionUser?.name || sessionUser?.email?.split("@")[0] || "alex.trader";
  const initials = displayName.slice(0, 2).toUpperCase();
  const tier = sessionUser?.tier ?? 3;

  const select = (v: ViewKey) => { onChange(v); setMoreOpen(false); };

  return (
    <>
      {/* Kraken-style: solid dark tab bar, no blur, center FAB */}
      <nav className="md:hidden fixed bottom-0 inset-x-0 z-40" style={{ background: "#0b0b0d", borderTop: "1px solid rgba(255,255,255,0.04)", paddingBottom: "env(safe-area-inset-bottom)" }}>
        <div className="grid grid-cols-5 h-16">
          {PRIMARY.slice(0, 2).map((item) => {
            const Icon = item.icon;
            const active = view === item.key;
            return (
              <button key={item.key} onClick={() => select(item.key)}
                className={`flex flex-col items-center justify-center gap-1 ${active ? "text-white" : "text-muted"}`}>
                <Icon className={`w-5 h-5 ${active ? "stroke-[2.2]" : "stroke-[1.5]"}`} />
                <span className="text-[9px] font-medium">{item.short}</span>
              </button>
            );
          })}

          {/* Center FAB — Kraken's signature white + button */}
          <button onClick={() => select("swap")}
            className="flex items-center justify-center">
            <div className="w-12 h-12 rounded-full flex items-center justify-center" style={{ background: "#fff" }}>
              <Plus className="w-6 h-6 text-black" strokeWidth={2.5} />
            </div>
          </button>

          {PRIMARY.slice(2).map((item) => {
            const Icon = item.icon;
            const active = view === item.key;
            return (
              <button key={item.key} onClick={() => select(item.key)}
                className={`flex flex-col items-center justify-center gap-1 ${active ? "text-white" : "text-muted"}`}>
                <Icon className={`w-5 h-5 ${active ? "stroke-[2.2]" : "stroke-[1.5]"}`} />
                <span className="text-[9px] font-medium">{item.short}</span>
              </button>
            );
          })}

          {/* More button */}
          <button onClick={() => setMoreOpen(true)}
            className={`flex flex-col items-center justify-center gap-1 ${MORE_ITEMS.some(m => m.key === view) ? "text-white" : "text-muted"}`}>
            <LayoutDashboard className="w-5 h-5 stroke-[1.5]" />
            <span className="text-[9px] font-medium">More</span>
          </button>
        </div>
      </nav>

      {/* More drawer */}
      <Drawer open={moreOpen} onOpenChange={setMoreOpen}>
        <DrawerContent className="text-white" style={{ background: "#1c1c1e" }}>
          <DrawerHeader className="text-left">
            <DrawerTitle className="flex items-center justify-between text-white">
              <span>More</span>
              <button onClick={() => setMoreOpen(false)} className="p-1.5 rounded-full text-muted hover:text-white" style={{ background: "#2c2c2e" }}>
                <X className="w-4 h-4" />
              </button>
            </DrawerTitle>
            <DrawerDescription className="text-muted">Portfolio & settings</DrawerDescription>
          </DrawerHeader>

          <div className="px-4 pb-6 space-y-4">
            <div className="kr-card p-4">
              <div className="text-[11px] text-muted">Portfolio Value</div>
              <div className="text-2xl font-bold tabular text-white mt-0.5">{fmtUSD(totalUSD)}</div>
              <div className="text-[12px] text-success mt-0.5">+2.4% 24h</div>
            </div>

            <div className="space-y-0.5">
              {MORE_ITEMS.map((item) => {
                const Icon = item.icon;
                const active = view === item.key;
                return (
                  <button key={item.key} onClick={() => select(item.key)}
                    className={`w-full flex items-center gap-3 px-3 py-3 rounded-xl text-sm ${active ? "text-white" : "text-muted hover:text-white"}`}
                    style={active ? { background: "rgba(255,255,255,0.06)" } : {}}>
                    <Icon className="w-5 h-5" />
                    <span className="font-medium">{item.label}</span>
                  </button>
                );
              })}
            </div>

            <div className="flex items-center gap-2 px-1 pt-3" style={{ borderTop: "1px solid rgba(255,255,255,0.04)" }}>
              <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white" style={{ background: "linear-gradient(135deg, #7f66ff, #9580ff)" }}>
                {initials}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-xs font-medium text-white truncate">{displayName}</div>
                <div className="text-[10px] text-muted">Tier {tier} · Verified</div>
              </div>
              <button onClick={() => signOut({ redirect: false }).then(() => { setMoreOpen(false); onLogout?.(); })}
                className="p-2 rounded-full text-muted hover:text-danger" style={{ background: "#2c2c2e" }}>
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        </DrawerContent>
      </Drawer>
    </>
  );
}
