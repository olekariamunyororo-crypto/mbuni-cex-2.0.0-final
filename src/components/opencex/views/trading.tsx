"use client";

import { useOpenCEX } from "@/lib/opencex/store";
import { useBinanceFeed } from "@/lib/opencex/use-binance-feed";
import { OrderBook } from "@/components/opencex/order-book";
import { TradeTape } from "@/components/opencex/trade-tape";
import { PriceChart } from "@/components/opencex/price-chart";
import { OrderEntry } from "@/components/opencex/order-entry";
import { OpenOrders } from "@/components/opencex/open-orders";
import { PairSelector } from "@/components/opencex/pair-selector";
import { MobileOrderSheet } from "@/components/opencex/mobile-order-sheet";
import { fmtPrice, fmtPct, fmtCompact } from "@/lib/opencex/format";
import { useState } from "react";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { BookOpen, Receipt, ListOrdered } from "lucide-react";

type MobileTab = "book" | "trades" | "orders";

export function TradingView() {
  useBinanceFeed();
  const activePair = useOpenCEX((s) => s.activePair);
  const ticker = useOpenCEX((s) => s.tickers[activePair]);
  const [showOpen, setShowOpen] = useState(true);
  const [mobileTab, setMobileTab] = useState<MobileTab>("book");

  return (
    <div className="flex flex-col h-[calc(100vh-3.5rem)]">
      {/* Pair selector + ticker */}
      <div className="px-3 py-2 flex items-center gap-3 flex-wrap" style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
        <PairSelector />
        {ticker && (
          <div className="hidden lg:flex items-center gap-5 text-xs">
            <Stat label="Last" value={fmtPrice(ticker.lastPrice, 2)} />
            <Stat label="24h" value={fmtPct(ticker.priceChangePct)} tone={ticker.priceChangePct >= 0 ? "up" : "down"} />
            <Stat label="High" value={fmtPrice(ticker.high, 2)} />
            <Stat label="Low" value={fmtPrice(ticker.low, 2)} />
            <Stat label="Vol" value={fmtCompact(ticker.volume)} suffix={activePair.split("/")[0]} />
          </div>
        )}
        <div className="hidden lg:flex flex-1" />
        <button onClick={() => setShowOpen(!showOpen)} className="hidden lg:block text-[11px] text-muted hover:text-white">
          {showOpen ? "Hide" : "Show"} orders
        </button>
      </div>

      {/* Mobile ticker */}
      {ticker && (
        <div className="lg:hidden px-3 py-1.5 flex items-center gap-4 overflow-x-auto no-scrollbar" style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
          <Stat label="24h" value={fmtPct(ticker.priceChangePct)} tone={ticker.priceChangePct >= 0 ? "up" : "down"} compact />
          <Stat label="H" value={fmtPrice(ticker.high, 2)} compact />
          <Stat label="L" value={fmtPrice(ticker.low, 2)} compact />
          <Stat label="Vol" value={fmtCompact(ticker.quoteVolume)} compact suffix="USDT" />
        </div>
      )}

      {/* Desktop — solid panels, no glass */}
      <div className="hidden md:grid md:grid-cols-12 flex-1 gap-px min-h-0" style={{ background: "rgba(255,255,255,0.04)" }}>
        <div className="col-span-3 overflow-hidden" style={{ background: "#000" }}>
          <OrderBook pair={activePair} />
        </div>
        <div className="col-span-6 flex flex-col overflow-hidden" style={{ background: "#000" }}>
          <div className="flex-1 min-h-0"><PriceChart pair={activePair} /></div>
          {showOpen && <div className="h-56 overflow-hidden" style={{ borderTop: "1px solid rgba(255,255,255,0.04)" }}><OpenOrders pair={activePair} /></div>}
        </div>
        <div className="col-span-3 flex flex-col overflow-hidden" style={{ background: "#000" }}>
          <div className="h-1/2 overflow-hidden" style={{ borderBottom: "1px solid rgba(255,255,255,0.04)" }}><TradeTape pair={activePair} /></div>
          <div className="h-1/2 overflow-hidden"><OrderEntry pair={activePair} /></div>
        </div>
      </div>

      {/* Mobile */}
      <div className="md:hidden flex-1 flex flex-col min-h-0 px-2 pb-2">
        <div className="h-[42vh] min-h-[260px] overflow-hidden mb-1" style={{ background: "#000", borderRadius: "1rem" }}>
          <PriceChart pair={activePair} />
        </div>
        <div className="flex-1 overflow-hidden" style={{ background: "#000", borderRadius: "1rem" }}>
          <Tabs value={mobileTab} onValueChange={(v) => setMobileTab(v as MobileTab)} className="h-full flex flex-col">
            <TabsList className="grid grid-cols-3 rounded-none h-10" style={{ background: "transparent", borderBottom: "1px solid rgba(255,255,255,0.04)" }}>
              <TabsTrigger value="book" className="text-xs gap-1 data-[state=active]:text-white data-[state=active]:bg-transparent"><BookOpen className="w-3.5 h-3.5" /> Book</TabsTrigger>
              <TabsTrigger value="trades" className="text-xs gap-1 data-[state=active]:text-white data-[state=active]:bg-transparent"><Receipt className="w-3.5 h-3.5" /> Trades</TabsTrigger>
              <TabsTrigger value="orders" className="text-xs gap-1 data-[state=active]:text-white data-[state=active]:bg-transparent"><ListOrdered className="w-3.5 h-3.5" /> Orders</TabsTrigger>
            </TabsList>
            <TabsContent value="book" className="flex-1 mt-0 overflow-hidden min-h-0"><OrderBook pair={activePair} /></TabsContent>
            <TabsContent value="trades" className="flex-1 mt-0 overflow-hidden min-h-0"><TradeTape pair={activePair} /></TabsContent>
            <TabsContent value="orders" className="flex-1 mt-0 overflow-hidden min-h-0"><OpenOrders pair={activePair} /></TabsContent>
          </Tabs>
        </div>
      </div>

      <MobileOrderSheet pair={activePair} />
    </div>
  );
}

function Stat({ label, value, tone, suffix, compact }: { label: string; value: string; tone?: "up" | "down"; suffix?: string; compact?: boolean }) {
  const color = tone === "up" ? "text-success" : tone === "down" ? "text-danger" : "text-white";
  return (
    <div className={`flex ${compact ? "flex-row items-baseline gap-1" : "flex-col"} leading-tight shrink-0`}>
      <span className="text-[10px] text-muted uppercase">{label}</span>
      <span className={`${compact ? "text-xs" : "text-xs"} font-medium tabular ${color}`}>
        {value}{suffix && <span className="text-muted ml-1">{suffix}</span>}
      </span>
    </div>
  );
}
