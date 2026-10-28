"use client";

import { useEffect, useState } from "react";
import { Search, Bell, LogOut } from "lucide-react";
import { signOut } from "next-auth/react";
import type { ViewKey } from "@/app/page";
import { useOpenCEX } from "@/lib/opencex/store";
import { fmtPrice, fmtPct } from "@/lib/opencex/format";

const VIEW_TITLES: Record<ViewKey, { title: string; short: string }> = {
  trading: { title: "Markets", short: "Markets" },
  markets: { title: "Explore", short: "Explore" },
  swap: { title: "Convert", short: "Convert" },
  wallet: { title: "Portfolio", short: "Portfolio" },
  admin: { title: "Activity", short: "Activity" },
  architecture: { title: "System", short: "System" },
};

interface SessionUserLike {
  email?: string | null; name?: string | null; onboardingComplete?: boolean; tier?: number; kycStatus?: string;
}

export function TopBar({ view, sessionUser, onLogout }: { view: ViewKey; sessionUser?: SessionUserLike; onLogout?: () => void; }) {
  const activePair = useOpenCEX((s) => s.activePair);
  const tickers = useOpenCEX((s) => s.tickers);
  const feedConnected = useOpenCEX((s) => s.feedConnected);
  const liveMode = useOpenCEX((s) => s.liveMode);
  const meta = VIEW_TITLES[view];
  const ticker = tickers[activePair];
  const [now, setNow] = useState("");
  useEffect(() => {
    const tick = () => setNow(new Date().toLocaleTimeString("en-US", { hour12: false }));
    tick();
    const i = setInterval(tick, 1000);
    return () => clearInterval(i);
  }, []);

  return (
    <header className="h-14 shrink-0 flex items-center px-4 gap-3" style={{ background: "#000", borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
      <div className="flex flex-col leading-tight">
        <h1 className="text-lg font-bold text-white">{meta.title}</h1>
      </div>

      <div className="flex-1" />

      {/* Ticker — mobile compact */}
      {view === "trading" && ticker && (
        <div className="flex items-center gap-2 px-3 py-1.5 kr-chip">
          <span className="text-xs text-secondary">{activePair}</span>
          <span className="text-sm font-bold tabular text-white">{fmtPrice(ticker.lastPrice, 2)}</span>
          <span className={`text-xs tabular ${ticker.priceChangePct >= 0 ? "text-success" : "text-danger"}`}>
            {fmtPct(ticker.priceChangePct)}
          </span>
        </div>
      )}

      {/* Live indicator */}
      <div className="flex items-center gap-1.5 px-2.5 py-1 kr-chip">
        <span className="relative flex h-1.5 w-1.5">
          {feedConnected ? (
            <>
              <span className="absolute inline-flex h-full w-full rounded-full bg-success opacity-60 live-dot" />
              <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-success" />
            </>
          ) : (
            <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-warning" />
          )}
        </span>
        <span className="text-[10px] text-secondary hidden sm:inline">
          {liveMode && feedConnected ? "LIVE" : "DEMO"}
        </span>
      </div>

      <button className="p-2 rounded-full text-muted hover:text-white" style={{ background: "#1c1c1e" }}>
        <Search className="w-4 h-4" />
      </button>
      <button className="p-2 rounded-full text-muted hover:text-white relative" style={{ background: "#1c1c1e" }}>
        <Bell className="w-4 h-4" />
        <span className="absolute top-1.5 right-1.5 w-1.5 h-1.5 bg-danger rounded-full" />
      </button>
      <button onClick={() => signOut({ redirect: false }).then(() => onLogout?.())}
        className="md:hidden p-2 rounded-full text-muted hover:text-danger" style={{ background: "#1c1c1e" }}>
        <LogOut className="w-4 h-4" />
      </button>
    </header>
  );
}
