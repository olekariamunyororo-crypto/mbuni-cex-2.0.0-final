import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { estimateBuyCost, useOpenCEX } from "./store";

const PAIR = "BTC/USDT";
const bal = (asset: string) => useOpenCEX.getState().balances.find((b) => b.asset === asset)!;

function fresh() {
  const s = useOpenCEX.getState();
  if (s.engineInterval) clearInterval(s.engineInterval);
  useOpenCEX.setState({ started: false, engineInterval: null, orders: [], trades: [] });
  useOpenCEX.getState().init();
  // stop the bot ticker so tests are deterministic
  const i = useOpenCEX.getState().engineInterval;
  if (i) clearInterval(i);
  useOpenCEX.setState({ engineInterval: null });
}

describe("store settlement", () => {
  beforeEach(fresh);
  afterAll(() => {
    const i = useOpenCEX.getState().engineInterval;
    if (i) clearInterval(i);
  });

  it("MARKET buy debits quote and credits base", () => {
    const usdt0 = bal("USDT").free, btc0 = bal("BTC").free;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "MARKET", price: null, qty: 0.01 });
    expect(r.ok).toBe(true);
    expect(r.order!.status).toBe("FILLED");
    expect(bal("USDT").free).toBeLessThan(usdt0 - 100); // ~0.01 BTC ≈ $800 paid
    expect(bal("BTC").free).toBeCloseTo(btc0 + 0.01, 8);
    expect(bal("USDT").locked).toBe(4200); // untouched
  });

  it("LIMIT buy that crosses pays the FILL price, not the limit price", () => {
    const ask = useOpenCEX.getState().books[PAIR].asks[0].price;
    const usdt0 = bal("USDT").free;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "LIMIT", price: ask + 500, qty: 0.01 });
    expect(r.order!.status).toBe("FILLED");
    expect(usdt0 - bal("USDT").free).toBeCloseTo(0.01 * ask, 4);
  });

  it("FOK that cannot fill (CANCELLED) locks nothing", () => {
    const top = useOpenCEX.getState().books[PAIR].asks[0];
    const before = { f: bal("USDT").free, l: bal("USDT").locked };
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "FOK", price: top.price, qty: top.qty + 1 });
    expect(r.order!.status).toBe("CANCELLED");
    expect(bal("USDT").free).toBe(before.f);
    expect(bal("USDT").locked).toBe(before.l);
  });

  it("IOC partial fill does not lock the cancelled remainder", () => {
    const top = useOpenCEX.getState().books[PAIR].asks[0];
    const l0 = bal("USDT").locked;
    const f0 = bal("USDT").free;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "IOC", price: top.price, qty: top.qty + 1 });
    expect(r.order!.status).toBe("PARTIALLY_FILLED");
    expect(bal("USDT").locked).toBe(l0);
    expect(f0 - bal("USDT").free).toBeCloseTo(top.qty * top.price, 4);
  });

  it("resting LIMIT locks funds and cancel releases them", () => {
    const l0 = bal("USDT").locked, f0 = bal("USDT").free;
    const px = useOpenCEX.getState().books[PAIR].bids[0].price - 100; // well below the book → rests
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "LIMIT", price: px, qty: 0.1 });
    expect(r.order!.status).toBe("NEW");
    expect(bal("USDT").locked).toBeCloseTo(l0 + px * 0.1, 4);
    useOpenCEX.getState().cancelOrder(r.order!.id);
    expect(bal("USDT").locked).toBeCloseTo(l0, 4);
    expect(bal("USDT").free).toBeCloseTo(f0, 4);
  });

  it("when another trader fills the user's resting order, balances and order status settle", () => {
    const px = useOpenCEX.getState().books[PAIR].bids[0].price - 100;
    const r = useOpenCEX.getState().placeOrder({ pair: PAIR, side: "BUY", type: "LIMIT", price: px, qty: 0.1 });
    const l1 = bal("USDT").locked, btc1 = bal("BTC").free;
    const eng = useOpenCEX.getState().engines[PAIR];
    eng.placeOrder({ pair: PAIR, side: "SELL", type: "MARKET", price: null, qty: 100, userId: "someone-else" }); // sweeps the whole bid side
    const o = useOpenCEX.getState().orders.find((x) => x.id === r.order!.id)!;
    expect(o.status).toBe("FILLED");
    expect(o.remainingQty).toBe(0);
    expect(bal("USDT").locked).toBeCloseTo(l1 - px * 0.1, 4);
    expect(bal("BTC").free).toBeCloseTo(btc1 + 0.1, 8);
  });

  it("estimateBuyCost walks levels and extrapolates", () => {
    expect(estimateBuyCost([{ price: 10, qty: 1 }, { price: 11, qty: 1 }], 1.5)).toBeCloseTo(10 + 5.5);
    expect(estimateBuyCost([{ price: 10, qty: 1 }], 3)).toBeCloseTo(30);
  });
});
