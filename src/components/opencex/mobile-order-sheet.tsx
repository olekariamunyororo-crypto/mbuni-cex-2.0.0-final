"use client";

import { useState } from "react";
import { OrderEntry } from "@/components/opencex/order-entry";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetDescription } from "@/components/ui/sheet";
import type { Side } from "@/lib/opencex/types";

/**
 * Floating Buy / Sell buttons shown on mobile (≤ md) inside the trading view.
 * Tapping either opens a bottom sheet containing the OrderEntry panel
 * pre-set to the chosen side.
 */
export function MobileOrderSheet({ pair }: { pair: string }) {
  const [open, setOpen] = useState(false);
  const [side, setSide] = useState<Side>("BUY");

  const openWith = (s: Side) => {
    setSide(s);
    setOpen(true);
  };

  return (
    <>
      {/* Floating action bar above bottom nav */}
      <div className="md:hidden fixed bottom-14 inset-x-0 z-30 px-3 pb-2 pt-1 bg-gradient-to-t from-background via-background/90 to-transparent pointer-events-none">
        <div className="grid grid-cols-2 gap-2 pointer-events-auto">
          <button
            onClick={() => openWith("BUY")}
            className="py-2.5 rounded-lg bg-success hover:bg-success text-black font-semibold text-sm shadow-lg shadow-emerald-500/20"
          >
            Buy
          </button>
          <button
            onClick={() => openWith("SELL")}
            className="py-2.5 rounded-lg bg-danger hover:bg-danger text-white font-semibold text-sm shadow-lg shadow-red-500/20"
          >
            Sell
          </button>
        </div>
      </div>

      {/* Bottom sheet with order entry — keyed by side so it remounts with the chosen side */}
      <Sheet open={open} onOpenChange={setOpen}>
        <SheetContent side="bottom" className="h-[80vh] p-0 bg-card border-border" >
          <SheetHeader className="px-3 py-2 border-b border-border">
            <SheetTitle className="text-sm flex items-center gap-2">
              <span
                className={`px-2 py-0.5 rounded text-xs ${side === "BUY" ? "bg-success/15 text-success" : "bg-danger/15 text-danger"}`}
              >
                {side === "BUY" ? "Buy" : "Sell"} {pair.split("/")[0]}
              </span>
              <span className="text-secondary text-xs">{pair}</span>
            </SheetTitle>
            <SheetDescription className="text-[11px]">
              Order entry · all types (Limit / Market / IOC / FOK / Post)
            </SheetDescription>
          </SheetHeader>
          <div className="h-[calc(80vh-3.5rem)] overflow-y-auto">
            <OrderEntry key={side} pair={pair} initialSide={side} onSubmitted={() => setOpen(false)} />
          </div>
        </SheetContent>
      </Sheet>
    </>
  );
}
