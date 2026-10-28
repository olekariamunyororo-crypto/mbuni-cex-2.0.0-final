"use client";

import { useState, useMemo } from "react";
import { useOpenCEX } from "@/lib/opencex/store";
import { fmtPrice, fmtQty } from "@/lib/opencex/format";
import type { OrderType, Side } from "@/lib/opencex/types";
import { toast } from "sonner";

const ORDER_TYPES: { key: OrderType; label: string; hint: string }[] = [
  { key: "LIMIT", label: "Limit", hint: "Rest on book at price" },
  { key: "MARKET", label: "Market", hint: "Taker at best price" },
  { key: "IOC", label: "IOC", hint: "Immediate-or-Cancel" },
  { key: "FOK", label: "FOK", hint: "Fill-or-Kill" },
  { key: "POST_ONLY", label: "Post", hint: "Maker only · never crosses" },
];

const PERCENTS = [25, 50, 75, 100];

export function OrderEntry({ pair, initialSide, onSubmitted }: { pair: string; initialSide?: Side; onSubmitted?: () => void }) {
  const placeOrder = useOpenCEX((s) => s.placeOrder);
  const balances = useOpenCEX((s) => s.balances);
  const book = useOpenCEX((s) => s.books[pair]);
  const p = useOpenCEX((s) => s.pairs.find((x) => x.symbol === pair));
  const feeSchedules = useOpenCEX((s) => s.feeSchedules);

  const [side, setSide] = useState<Side>(initialSide ?? "BUY");
  const [type, setType] = useState<OrderType>("LIMIT");
  const [price, setPrice] = useState<string>("");
  const [qty, setQty] = useState<string>("");
  const [submitting, setSubmitting] = useState(false);

  const baseAsset = p?.base ?? "";
  const quoteAsset = p?.quote ?? "";

  const baseBalance = balances.find((b) => b.asset === baseAsset)?.free ?? 0;
  const quoteBalance = balances.find((b) => b.asset === quoteAsset)?.free ?? 0;

  const isBuy = side === "BUY";
  const bestPrice = isBuy ? book?.asks[0]?.price : book?.bids[0]?.price;
  const midPrice = book?.midPrice ?? 0;

  // Auto-fill price if empty (for LIMIT/POST_ONLY)
  const effectivePrice = type === "MARKET" ? null : price === "" ? (bestPrice ?? midPrice) : parseFloat(price);
  const effectiveQty = parseFloat(qty) || 0;
  const cost = effectivePrice ? effectivePrice * effectiveQty : 0;

  const availableForOrder = isBuy ? quoteBalance : baseBalance;
  const maxQty = isBuy
    ? effectivePrice && effectivePrice > 0
      ? quoteBalance / effectivePrice
      : 0
    : baseBalance;

  // Use Tier 3 fee schedule for this demo user
  const tier = feeSchedules[3] ?? feeSchedules[0];
  const isMaker = type === "LIMIT" || type === "POST_ONLY";
  const feeBps = isMaker ? tier.makerFee : tier.takerFee;
  const fee = (cost * feeBps) / 10000;

  const submit = () => {
    if (submitting) return;
    if (type !== "MARKET" && (!effectivePrice || effectivePrice <= 0)) {
      toast.error("Enter a valid price");
      return;
    }
    if (!effectiveQty || effectiveQty <= 0) {
      toast.error("Enter a valid quantity");
      return;
    }
    setSubmitting(true);
    const res = placeOrder({ pair, side, type, price: effectivePrice, qty: effectiveQty });
    setSubmitting(false);
    if (!res.ok) {
      toast.error(res.reason ?? "Order rejected");
      return;
    }
    toast.success(`${side} ${type} order placed`, {
      description: `${fmtQty(effectiveQty, p?.baseDecimals ?? 4)} ${baseAsset} @ ${effectivePrice ? fmtPrice(effectivePrice, p?.priceDecimals ?? 2) : "market"}`,
    });
    setQty("");
    onSubmitted?.();
  };

  const setPercent = (pct: number) => {
    const q = (maxQty * pct) / 100;
    setQty(q.toFixed(p?.baseDecimals ?? 4));
  };

  if (!p) return null;

  return (
    <div className="flex flex-col h-full">
      <div className="px-3 py-2 border-b border-border">
        <span className="text-xs font-semibold uppercase tracking-wider text-secondary">Place Order</span>
      </div>

      {/* Side toggle */}
      <div className="grid grid-cols-2 gap-1 p-3 pb-2">
        <button
          onClick={() => setSide("BUY")}
          className={`py-1.5 rounded text-sm font-semibold transition-colors ${
            isBuy ? "bg-success text-black" : "bg-elevated/60 text-secondary hover:bg-elevated"
          }`}
        >
          Buy {baseAsset}
        </button>
        <button
          onClick={() => setSide("SELL")}
          className={`py-1.5 rounded text-sm font-semibold transition-colors ${
            !isBuy ? "bg-danger text-white" : "bg-elevated/60 text-secondary hover:bg-elevated"
          }`}
        >
          Sell {baseAsset}
        </button>
      </div>

      {/* Order type tabs */}
      <div className="px-3 pb-2 flex flex-wrap gap-1">
        {ORDER_TYPES.map((t) => (
          <button
            key={t.key}
            onClick={() => setType(t.key)}
            title={t.hint}
            className={`px-2 py-0.5 text-[11px] rounded ${
              type === t.key ? "bg-success text-success-foreground" : "bg-elevated/60 text-secondary hover:bg-elevated"
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="px-3 space-y-2">
        {/* Available */}
        <div className="flex items-center justify-between text-[11px]">
          <span className="text-secondary">Available</span>
          <span className="tabular">{fmtQty(isBuy ? quoteBalance : baseBalance, isBuy ? 2 : p.baseDecimals)} {isBuy ? quoteAsset : baseAsset}</span>
        </div>

        {/* Price input (hidden for market) */}
        {type !== "MARKET" && (
          <div>
            <label className="text-[10px] uppercase text-secondary">Price ({quoteAsset})</label>
            <div className="flex items-center gap-1 mt-0.5">
              <input
                type="number"
                value={price}
                onChange={(e) => setPrice(e.target.value)}
                placeholder={bestPrice ? bestPrice.toFixed(p.priceDecimals) : "0.00"}
                step={p.tickSize}
                className="flex-1 bg-input border border-border rounded px-2 py-1.5 text-sm tabular focus:outline-none focus:ring-1 focus:ring-ring"
              />
              <button
                onClick={() => setPrice(bestPrice?.toFixed(p.priceDecimals) ?? "")}
                className="text-[10px] px-2 py-1.5 bg-elevated/60 hover:bg-elevated rounded"
                title="Use best market price"
              >
                Last
              </button>
            </div>
          </div>
        )}

        {/* Quantity */}
        <div>
          <label className="text-[10px] uppercase text-secondary">Amount ({baseAsset})</label>
          <input
            type="number"
            value={qty}
            onChange={(e) => setQty(e.target.value)}
            placeholder="0.00"
            step={p.minQty}
            className="w-full mt-0.5 bg-input border border-border rounded px-2 py-1.5 text-sm tabular focus:outline-none focus:ring-1 focus:ring-ring"
          />
        </div>

        {/* Percent buttons */}
        <div className="grid grid-cols-4 gap-1">
          {PERCENTS.map((pct) => (
            <button
              key={pct}
              onClick={() => setPercent(pct)}
              className="py-0.5 text-[11px] bg-elevated/60 hover:bg-elevated rounded"
            >
              {pct}%
            </button>
          ))}
        </div>

        {/* Total + fee */}
        <div className="space-y-1 pt-1">
          <div className="flex justify-between text-[11px]">
            <span className="text-secondary">Total</span>
            <span className="tabular">{fmtPrice(cost, 2)} {quoteAsset}</span>
          </div>
          <div className="flex justify-between text-[11px]">
            <span className="text-secondary">Est. Fee ({isMaker ? "Maker" : "Taker"} · {feeBps}bps)</span>
            <span className="tabular">{fmtPrice(fee, 2)} {quoteAsset}</span>
          </div>
          <div className="flex justify-between text-[11px]">
            <span className="text-secondary">Max {isBuy ? "Buy" : "Sell"}</span>
            <span className="tabular">{fmtQty(maxQty, p.baseDecimals)} {baseAsset}</span>
          </div>
        </div>
      </div>

      <div className="p-3 mt-auto">
        <button
          onClick={submit}
          disabled={submitting}
          className={`w-full py-2 rounded font-semibold text-sm transition-all disabled:opacity-50 ${
            isBuy
              ? "bg-success hover:bg-success text-black"
              : "bg-danger hover:bg-danger text-white"
          }`}
        >
          {submitting ? "Submitting…" : `${isBuy ? "Buy" : "Sell"} ${baseAsset}`}
        </button>
      </div>
    </div>
  );
}
