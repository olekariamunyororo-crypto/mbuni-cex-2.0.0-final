"use client";

import { useState } from "react";
import { Home, TrendingUp, ArrowLeftRight, Wallet, Clock, X, LogOut, Network } from "lucide-react";
import { signOut } from "next-auth/react";
import type { ViewKey } from "@/app/page";
import { useOpenCEX } from "@/lib/opencex/store";
import { fmtUSD } from "@/lib/opencex/format";
import { Drawer, DrawerContent, DrawerHeader, DrawerTitle, DrawerDescription } from "@/components/ui/drawer";

interface NavItem {
  key: ViewKey;
  label: string;
  short: string;
  icon: React.ComponentType<{ className?: string }>;
}

const PRIMARY: NavItem[] = [
  { key: "trading", label: "Home", short: "Home", icon: Home },
  { key: "markets", label: "Market", short: "Market", icon: TrendingUp },
  { key: "swap", label: "Trade", short: "Trade", icon: ArrowLeftRight },
  { key: "wallet", label: "Assets", short: "Assets", icon: Wallet },
  { key: "admin", label: "History", short: "History", icon: Clock },
];

const SECONDARY: NavItem[] = [
  { key: "architecture", label: "Architecture", short: "Arch", icon: Network },
];

export function MobileNav({
  view,
  onChange,
  onLogout,
  sessionUser,
}: {
  view: ViewKey;
  onChange: (v: ViewKey) => void;
  onLogout?: () => void;
  sessionUser?: { email?: string | null; name?: string | null; tier?: number };
}) {
  const [moreOpen, setMoreOpen] = useState(false);
  const balances = useOpenCEX((s) => s.balances);
  const totalUSD = balances.reduce((s, b) => s + b.usdValue, 0);

  const select = (v: ViewKey) => {
    onChange(v);
    setMoreOpen(false);
  };

  const displayName = sessionUser?.name || sessionUser?.email?.split("@")[0] || "alex.trader";
  const initials = displayName.slice(0, 2).toUpperCase();
  const tier = sessionUser?.tier ?? 3;

  return (
    <>
      {/* Floating glass tab bar */}
      <nav className="md:hidden fixed bottom-0 inset-x-0 z-40 px-3 pb-3" style={{ paddingBottom: "max(0.75rem, env(safe-area-inset-bottom))" }}>
        <div className="kr-card rounded-2xl px-2 py-2 flex items-center justify-between glass-edge">
          {PRIMARY.map((item) => {
            const Icon = item.icon;
            const active = view === item.key;
            return (
              <button
                key={item.key}
                onClick={() => select(item.key)}
                className={`flex flex-col items-center justify-center gap-0.5 px-2 py-1.5 rounded-xl transition-all flex-1 ${
                  active ? "text-success" : "text-muted"
                }`}
                style={active ? {
                  background: "rgba(163, 230, 53, 0.08)",
                  boxShadow: "inset 0 1px 0 rgba(163, 230, 53, 0.06)",
                } : {}}
              >
                <Icon className={`w-5 h-5 ${active ? "stroke-[2.4]" : "stroke-[1.8]"}`} />
                <span className={`text-[9px] ${active ? "font-semibold" : ""}`}>{item.short}</span>
              </button>
            );
          })}
        </div>
      </nav>

      {/* More drawer */}
      <Drawer open={moreOpen} onOpenChange={setMoreOpen}>
        <DrawerContent className="kr-card text-white" style={{ background: "rgba(20, 22, 31, 0.9)" }}>
          <DrawerHeader className="text-left">
            <DrawerTitle className="flex items-center justify-between text-white">
              <span>More</span>
              <button onClick={() => setMoreOpen(false)} className="p-1.5 rounded-lg text-muted hover:text-foreground">
                <X className="w-4 h-4" />
              </button>
            </DrawerTitle>
            <DrawerDescription className="text-muted">System views · portfolio summary</DrawerDescription>
          </DrawerHeader>

          <div className="px-4 pb-6 space-y-4">
            <div className="kr-card p-4">
              <div className="text-[11px] text-muted font-medium">Portfolio Value</div>
              <div className="text-2xl font-bold tnum mt-0.5">{fmtUSD(totalUSD)}</div>
              <div className="text-[12px] text-success mt-0.5">+2.4% 24h</div>
            </div>

            <div className="space-y-1">
              {SECONDARY.map((item) => {
                const Icon = item.icon;
                const active = view === item.key;
                return (
                  <button
                    key={item.key}
                    onClick={() => select(item.key)}
                    className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-all ${
                      active ? "text-success" : "text-muted hover:text-foreground"
                    }`}
                    style={active ? { background: "rgba(163, 230, 53, 0.06)" } : {}}
                  >
                    <Icon className="w-4 h-4" />
                    <span className="font-medium">{item.label}</span>
                  </button>
                );
              })}
            </div>

            <div className="flex items-center gap-2 px-1 pt-2" style={{ borderTop: "1px solid rgba(255,255,255,0.04)" }}>
              <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white" style={{ background: "linear-gradient(135deg, #7f66ff, #9580ff)" }}>
                {initials}
              </div>
              <div className="flex-1 min-w-0">
                <div className="text-xs font-medium truncate">{displayName}</div>
                <div className="text-[10px] text-muted">Tier {tier} · Verified</div>
              </div>
              <button
                onClick={() => signOut({ redirect: false }).then(() => { setMoreOpen(false); onLogout?.(); })}
                className="p-2 rounded-lg text-muted hover:text-danger"
              >
                <LogOut className="w-4 h-4" />
              </button>
            </div>
          </div>
        </DrawerContent>
      </Drawer>
    </>
  );
}
