"use client";

import { useOpenCEX } from "@/lib/opencex/store";
import { fmtPrice, fmtPct, fmtCompact } from "@/lib/opencex/format";
import { ASSET_METADATA } from "@/lib/opencex/seed";
import { Star, TrendingUp, TrendingDown } from "lucide-react";
import { useState } from "react";
import { CoinIcon } from "@/components/opencex/coin-icon";

export function MarketsView({ onOpenTrading }: { onOpenTrading: (pair: string) => void }) {
  const pairs = useOpenCEX((s) => s.pairs);
  const tickers = useOpenCEX((s) => s.tickers);
  const [favorites, setFavorites] = useState<Set<string>>(new Set(["BTC/USDT", "ETH/USDT", "SOL/USDT"]));
  const [tab, setTab] = useState<"all" | "fav" | "gainers" | "losers">("all");

  const rows = pairs
    .map((p) => ({ pair: p, ticker: tickers[p.symbol] }))
    .filter((r) => r.ticker);

  const visible = rows.filter((r) => {
    if (tab === "fav") return favorites.has(r.pair.symbol);
    if (tab === "gainers") return r.ticker!.priceChangePct > 0;
    if (tab === "losers") return r.ticker!.priceChangePct < 0;
    return true;
  });

  const totalVol = rows.reduce((s, r) => s + (r.ticker?.quoteVolume ?? 0), 0);
  const gainers = rows.filter((r) => r.ticker!.priceChangePct > 0).length;
  const losers = rows.filter((r) => r.ticker!.priceChangePct < 0).length;

  const toggleFav = (sym: string) => {
    setFavorites((s) => {
      const n = new Set(s);
      if (n.has(sym)) n.delete(sym);
      else n.add(sym);
      return n;
    });
  };

  return (
    <div className="p-3 md:p-4 space-y-4">
      {/* Stats summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2 md:gap-3">
        <SummaryCard label="Markets" value={String(pairs.length)} sub="active pairs" />
        <SummaryCard label="24h Volume" value={`$${fmtCompact(totalVol)}`} sub="all pairs" />
        <SummaryCard label="Gainers" value={String(gainers)} sub="24h" tone="up" />
        <SummaryCard label="Losers" value={String(losers)} sub="24h" tone="down" />
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-border overflow-x-auto no-scrollbar">
        {(["all", "fav", "gainers", "losers"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-3 py-2 text-xs font-medium border-b-2 transition-colors shrink-0 ${
              tab === t ? "border-primary text-foreground" : "border-transparent text-secondary hover:text-foreground"
            }`}
          >
            {t === "all" ? "All Markets" : t === "fav" ? "★ Favorites" : t === "gainers" ? "Gainers" : "Losers"}
          </button>
        ))}
      </div>

      {/* Markets — desktop table */}
      <div className="hidden md:block bg-card border border-border rounded-md overflow-hidden">
        <div className="grid grid-cols-12 gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border">
          <span className="col-span-1"></span>
          <span className="col-span-3">Pair</span>
          <span className="col-span-2 text-right">Last Price</span>
          <span className="col-span-2 text-right">24h Change</span>
          <span className="col-span-2 text-right">24h High</span>
          <span className="col-span-1 text-right">24h Vol</span>
          <span className="col-span-1 text-right">Trade</span>
        </div>
        <div className="max-h-[calc(100vh-22rem)] overflow-y-auto">
          {visible.map(({ pair, ticker }) => {
            const t = ticker!;
            const isFav = favorites.has(pair.symbol);
            const up = t.priceChangePct >= 0;
            return (
              <button
                key={pair.symbol}
                onClick={() => onOpenTrading(pair.symbol)}
                className="w-full grid grid-cols-12 gap-2 px-4 py-2.5 text-xs items-center hover:bg-elevated/50 border-b border-border/40 tabular"
              >
                <span
                  className="col-span-1"
                  onClick={(e) => {
                    e.stopPropagation();
                    toggleFav(pair.symbol);
                  }}
                >
                  <Star className={`w-3.5 h-3.5 ${isFav ? "fill-gold text-gold" : "text-secondary"}`} />
                </span>
                <span className="col-span-3 flex items-center gap-2">
                  <CoinIcon asset={pair.base} size={20} />
                  <span className="flex flex-col items-start leading-tight">
                    <span className="font-medium text-sm text-foreground">{pair.base}<span className="text-secondary">/{pair.quote}</span></span>
                    <span className="text-[10px] text-secondary">{ASSET_METADATA[pair.base]?.name}</span>
                  </span>
                </span>
                <span className="col-span-2 text-right font-medium">{fmtPrice(t.lastPrice, pair.priceDecimals)}</span>
                <span className={`col-span-2 text-right flex items-center justify-end gap-1 ${up ? "text-primary" : "text-danger"}`}>
                  {up ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                  {fmtPct(t.priceChangePct)}
                </span>
                <span className="col-span-2 text-right text-secondary">{fmtPrice(t.high, pair.priceDecimals)}</span>
                <span className="col-span-1 text-right text-secondary">{fmtCompact(t.volume)}</span>
                <span className="col-span-1 text-right">
                  <span className="text-[10px] px-2 py-0.5 rounded bg-primary/10 text-primary">Trade</span>
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Markets — mobile card list */}
      <div className="md:hidden space-y-2">
        {visible.map(({ pair, ticker }) => {
          const t = ticker!;
          const isFav = favorites.has(pair.symbol);
          const up = t.priceChangePct >= 0;
          return (
            <button
              key={pair.symbol}
              onClick={() => onOpenTrading(pair.symbol)}
              className="w-full bg-card border border-border rounded-md p-3 text-left active:bg-elevated/50"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleFav(pair.symbol);
                    }}
                    className="p-1 -ml-1"
                  >
                    <Star className={`w-3.5 h-3.5 ${isFav ? "fill-gold text-gold" : "text-secondary"}`} />
                  </span>
                  <CoinIcon asset={pair.base} size={28} />
                  <div className="flex flex-col leading-tight">
                    <span className="font-semibold text-sm">{pair.base}<span className="text-secondary font-normal">/{pair.quote}</span></span>
                    <span className="text-[10px] text-secondary">{ASSET_METADATA[pair.base]?.name}</span>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-semibold tabular">{fmtPrice(t.lastPrice, pair.priceDecimals)}</div>
                  <div className={`text-xs tabular flex items-center justify-end gap-0.5 ${up ? "text-primary" : "text-danger"}`}>
                    {up ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                    {fmtPct(t.priceChangePct)}
                  </div>
                </div>
              </div>
              <div className="flex justify-between mt-2 pt-2 border-t border-border/40 text-[10px] text-secondary tabular">
                <span>H: <span className="text-foreground">{fmtPrice(t.high, pair.priceDecimals)}</span></span>
                <span>L: <span className="text-foreground">{fmtPrice(t.low, pair.priceDecimals)}</span></span>
                <span>Vol: <span className="text-foreground">{fmtCompact(t.quoteVolume)} USDT</span></span>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function SummaryCard({ label, value, sub, tone }: { label: string; value: string; sub: string; tone?: "up" | "down" }) {
  const color = tone === "up" ? "text-primary" : tone === "down" ? "text-danger" : "text-foreground";
  return (
    <div className="bg-card border border-border rounded-md p-3 md:p-4">
      <div className="text-[10px] uppercase text-secondary tracking-wider">{label}</div>
      <div className={`text-lg md:text-2xl font-bold tabular mt-1 ${color}`}>{value}</div>
      <div className="text-[11px] text-secondary mt-0.5">{sub}</div>
    </div>
  );
}
