"use client";

import { useState, useMemo } from "react";
import { useOpenCEX } from "@/lib/opencex/store";
import { fmtPrice, fmtQty } from "@/lib/opencex/format";
import { ASSET_METADATA } from "@/lib/opencex/seed";
import { ArrowDownUp, Settings2, Zap, Info } from "lucide-react";
import { toast } from "sonner";

export function SwapView() {
  const balances = useOpenCEX((s) => s.balances);
  const tickers = useOpenCEX((s) => s.tickers);
  const pairs = useOpenCEX((s) => s.pairs);
  const placeOrder = useOpenCEX((s) => s.placeOrder);
  const pushEvent = useOpenCEX((s) => s.pushEvent);

  const assets = Array.from(new Set([...balances.map((b) => b.asset), ...Object.keys(ASSET_METADATA)]));
  const [fromAsset, setFromAsset] = useState("USDT");
  const [toAsset, setToAsset] = useState("BTC");
  const [fromAmount, setFromAmount] = useState("");
  const [slippage, setSlippage] = useState(0.5);

  const fromBalance = balances.find((b) => b.asset === fromAsset)?.free ?? 0;
  const toBalance = balances.find((b) => b.asset === toAsset)?.free ?? 0;

  // Find price via direct or inverse pair
  const { price, route } = useMemo(() => {
    const direct = pairs.find((p) => p.base === toAsset && p.quote === fromAsset);
    if (direct && tickers[direct.symbol]) {
      return { price: tickers[direct.symbol].lastPrice, route: `${fromAsset} → ${toAsset} (direct)` };
    }
    const inverse = pairs.find((p) => p.base === fromAsset && p.quote === toAsset);
    if (inverse && tickers[inverse.symbol]) {
      return { price: 1 / tickers[inverse.symbol].lastPrice, route: `${fromAsset} → ${toAsset} (inverse)` };
    }
    // Bridge via USDT
    if (fromAsset !== "USDT" && toAsset !== "USDT") {
      const fromUsd = tickers[`${fromAsset}/USDT`]?.lastPrice ?? (fromAsset === "USDT" ? 1 : 0);
      const toUsd = tickers[`${toAsset}/USDT`]?.lastPrice ?? (toAsset === "USDT" ? 1 : 0);
      if (fromUsd && toUsd) {
        return { price: fromUsd / toUsd, route: `${fromAsset} → USDT → ${toAsset}` };
      }
    }
    return { price: 0, route: "No route" };
  }, [fromAsset, toAsset, pairs, tickers]);

  const fromValue = parseFloat(fromAmount) || 0;
  const expectedOut = price ? fromValue * price : 0;
  const minReceived = expectedOut * (1 - slippage / 100);

  const swap = () => {
    if (!fromValue || fromValue <= 0) {
      toast.error("Enter an amount to swap");
      return;
    }
    if (fromValue > fromBalance) {
      toast.error(`Insufficient ${fromAsset} balance`);
      return;
    }
    if (fromAsset === toAsset) {
      toast.error("Cannot swap same asset");
      return;
    }

    // Execute as a market order via the matching engine
    let pairSym: string | null = null;
    let side: "BUY" | "SELL" | null = null;
    const direct = pairs.find((p) => p.base === toAsset && p.quote === fromAsset);
    const inverse = pairs.find((p) => p.base === fromAsset && p.quote === toAsset);

    if (direct) {
      pairSym = direct.symbol;
      side = "BUY";
    } else if (inverse) {
      pairSym = inverse.symbol;
      side = "SELL";
    } else if (fromAsset === "USDT") {
      const p = pairs.find((x) => x.base === toAsset);
      if (p) { pairSym = p.symbol; side = "BUY"; }
    } else if (toAsset === "USDT") {
      const p = pairs.find((x) => x.base === fromAsset);
      if (p) { pairSym = p.symbol; side = "SELL"; }
    }

    if (!pairSym || !side) {
      toast.error("No liquidity route for this pair");
      return;
    }

    const res = placeOrder({
      pair: pairSym,
      side,
      type: "MARKET",
      price: null,
      qty: side === "SELL" ? fromValue : fromValue / price,
    });

    if (!res.ok) {
      toast.error(res.reason ?? "Swap failed");
      return;
    }

    pushEvent("trades.executed", { type: "swap", from: fromAsset, to: toAsset, amount: fromValue, route });
    toast.success("Swap executed", {
      description: `${fmtQty(fromValue, 6)} ${fromAsset} → ${fmtQty(expectedOut, 8)} ${toAsset}`,
    });
    setFromAmount("");
  };

  const flip = () => {
    setFromAsset(toAsset);
    setToAsset(fromAsset);
    setFromAmount("");
  };

  return (
    <div className="p-3 md:p-4 flex flex-col items-center">
      <div className="w-full max-w-xl space-y-3 md:space-y-4">
        <div className="text-center">
          <h2 className="text-lg md:text-xl font-semibold">Swap</h2>
          <p className="text-xs text-secondary mt-1">Simple spot convert · routed through the CLOB for best price</p>
        </div>

        {/* Settings */}
        <div className="flex items-center justify-end gap-2 flex-wrap">
          <Settings2 className="w-3.5 h-3.5 text-secondary" />
          <span className="text-[11px] text-secondary">Slippage</span>
          <div className="flex gap-1">
            {[0.1, 0.5, 1.0].map((v) => (
              <button
                key={v}
                onClick={() => setSlippage(v)}
                className={`px-2 py-0.5 text-[11px] rounded ${
                  slippage === v ? "bg-success text-success-foreground" : "bg-elevated/60 text-secondary hover:bg-elevated"
                }`}
              >
                {v}%
              </button>
            ))}
          </div>
        </div>

        {/* From */}
        <div className="bg-card border border-border rounded-lg p-3 md:p-4 space-y-2">
          <div className="flex justify-between text-[11px] text-secondary">
            <span>From</span>
            <span className="truncate ml-2">Balance: <span className="tabular text-foreground">{fmtQty(fromBalance, 6)} {fromAsset}</span></span>
          </div>
          <div className="flex gap-2">
            <input
              type="number"
              inputMode="decimal"
              value={fromAmount}
              onChange={(e) => setFromAmount(e.target.value)}
              placeholder="0.00"
              className="flex-1 min-w-0 bg-transparent text-xl md:text-2xl font-semibold tabular outline-none"
            />
            <AssetPicker value={fromAsset} onChange={setFromAsset} assets={assets} />
          </div>
          <div className="flex gap-1">
            {[25, 50, 75, 100].map((p) => (
              <button
                key={p}
                onClick={() => setFromAmount(((fromBalance * p) / 100).toFixed(6))}
                className="text-[10px] px-2 py-0.5 bg-elevated/60 hover:bg-elevated rounded"
              >
                {p}%
              </button>
            ))}
          </div>
        </div>

        {/* Flip */}
        <div className="flex justify-center -my-2 relative z-10">
          <button
            onClick={flip}
            className="w-10 h-10 rounded-full bg-card border border-border hover:bg-elevated flex items-center justify-center"
          >
            <ArrowDownUp className="w-4 h-4" />
          </button>
        </div>

        {/* To */}
        <div className="bg-card border border-border rounded-lg p-3 md:p-4 space-y-2">
          <div className="flex justify-between text-[11px] text-secondary">
            <span>To (estimated)</span>
            <span className="truncate ml-2">Balance: <span className="tabular text-foreground">{fmtQty(toBalance, 6)} {toAsset}</span></span>
          </div>
          <div className="flex gap-2">
            <input
              type="text"
              value={expectedOut ? expectedOut.toFixed(8) : ""}
              placeholder="0.00"
              readOnly
              className="flex-1 min-w-0 bg-transparent text-xl md:text-2xl font-semibold tabular outline-none text-secondary"
            />
            <AssetPicker value={toAsset} onChange={setToAsset} assets={assets} />
          </div>
        </div>

        {/* Details */}
        <div className="bg-elevated/40 border border-border rounded-lg p-3 space-y-1.5 text-[11px]">
          <Row label="Rate" value={`1 ${fromAsset} = ${fmtPrice(price, 8)} ${toAsset}`} />
          <Row label="Route" value={route} />
          <Row label="Min received" value={`${fmtQty(minReceived, 8)} ${toAsset}`} sub={`(${slippage}% slippage)`} />
          <Row label="Fee" value="0.1% · taker" />
          <div className="flex items-start gap-1.5 pt-1.5 border-t border-border mt-2 text-secondary">
            <Info className="w-3 h-3 mt-0.5 shrink-0" />
            <span>Swaps route through the matching engine as market orders. Final fill depends on order book depth at execution time.</span>
          </div>
        </div>

        <button
          onClick={swap}
          disabled={!fromValue || fromValue > fromBalance}
          className="w-full py-3 rounded-lg bg-success hover:bg-success disabled:opacity-50 text-black font-semibold flex items-center justify-center gap-2"
        >
          <Zap className="w-4 h-4" />
          {fromValue > fromBalance ? `Insufficient ${fromAsset}` : `Swap ${fromAsset} → ${toAsset}`}
        </button>
      </div>
    </div>
  );
}

function AssetPicker({ value, onChange, assets }: { value: string; onChange: (v: string) => void; assets: string[] }) {
  return (
    <select
      value={value}
      onChange={(e) => onChange(e.target.value)}
      className="bg-elevated/60 hover:bg-elevated border border-border rounded-lg px-2 md:px-3 py-2 text-sm font-medium cursor-pointer shrink-0 max-w-[110px]"
    >
      {assets.map((a) => (
        <option key={a} value={a}>{a}</option>
      ))}
    </select>
  );
}

function Row({ label, value, sub }: { label: string; value: string; sub?: string }) {
  return (
    <div className="flex justify-between">
      <span className="text-secondary">{label}</span>
      <span className="tabular text-foreground">
        {value} {sub && <span className="text-secondary ml-1">{sub}</span>}
      </span>
    </div>
  );
}
