"use client";

import { useOpenCEX } from "@/lib/opencex/store";
import { fmtQty, fmtUSD, fmtDateTime, shortAddr, shortHash } from "@/lib/opencex/format";
import { ASSET_METADATA, CHAINS } from "@/lib/opencex/seed";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowDownToLine, ArrowUpFromLine, Shield, Plus, Copy, Check } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import type { Deposit, Withdrawal } from "@/lib/opencex/types";
import { CoinIcon } from "@/components/opencex/coin-icon";

export function WalletView() {
  const balances = useOpenCEX((s) => s.balances);
  const deposits = useOpenCEX((s) => s.deposits);
  const withdrawals = useOpenCEX((s) => s.withdrawals);
  const whitelist = useOpenCEX((s) => s.whitelist);
  const pairs = useOpenCEX((s) => s.pairs);

  const totalUSD = balances.reduce((s, b) => s + b.usdValue, 0);
  const totalLocked = balances.reduce((s, b) => s + b.locked * (getUSDPrice(b.asset, pairs) ?? 0), 0);

  return (
    <div className="p-3 md:p-4 space-y-4">
      {/* Portfolio summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2 md:gap-3">
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Total Balance</div>
          <div className="text-lg md:text-2xl font-bold tabular mt-1">{fmtUSD(totalUSD)}</div>
          <div className="text-[11px] text-primary mt-0.5">+2.4% 24h</div>
        </Card>
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Locked</div>
          <div className="text-lg md:text-2xl font-bold tabular mt-1">{fmtUSD(totalLocked)}</div>
          <div className="text-[11px] text-secondary mt-0.5">{balances.filter((b) => b.locked > 0).length} assets</div>
        </Card>
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Available</div>
          <div className="text-lg md:text-2xl font-bold tabular mt-1">{fmtUSD(totalUSD - totalLocked)}</div>
          <div className="text-[11px] text-secondary mt-0.5">For trading & withdrawal</div>
        </Card>
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Custody Mode</div>
          <div className="text-lg md:text-2xl font-bold mt-1">Hybrid</div>
          <div className="text-[11px] text-secondary mt-0.5">HSM · Passkey · Whitelist</div>
        </Card>
      </div>

      <Tabs defaultValue="balances">
        <TabsList className="flex w-auto overflow-x-auto no-scrollbar">
          <TabsTrigger value="balances">Balances</TabsTrigger>
          <TabsTrigger value="deposits">Deposits</TabsTrigger>
          <TabsTrigger value="withdrawals">Withdrawals</TabsTrigger>
          <TabsTrigger value="whitelist">Whitelist</TabsTrigger>
        </TabsList>

        <TabsContent value="balances" className="mt-3">
          {/* Desktop table */}
          <Card className="overflow-hidden hidden md:block">
            <div className="grid grid-cols-12 gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border">
              <span className="col-span-3">Asset</span>
              <span className="col-span-3 text-right">Total</span>
              <span className="col-span-2 text-right">Available</span>
              <span className="col-span-2 text-right">Locked</span>
              <span className="col-span-1 text-right">USD Value</span>
              <span className="col-span-1 text-right">Action</span>
            </div>
            <div className="max-h-[60vh] overflow-y-auto">
              {balances.map((b) => {
                const meta = ASSET_METADATA[b.asset];
                return (
                  <div key={b.asset} className="grid grid-cols-12 gap-2 px-4 py-2.5 text-xs items-center border-b border-border/40 tabular hover:bg-elevated/40">
                    <span className="col-span-3 flex items-center gap-2">
                      <CoinIcon asset={b.asset} size={28} />
                      <span className="flex flex-col leading-tight">
                        <span className="font-medium text-sm">{b.asset}</span>
                        <span className="text-[10px] text-secondary">{meta?.name}</span>
                      </span>
                    </span>
                    <span className="col-span-3 text-right font-medium">{fmtQty(b.free + b.locked, 6)} {b.asset}</span>
                    <span className="col-span-2 text-right">{fmtQty(b.free, 6)}</span>
                    <span className="col-span-2 text-right text-gold">{fmtQty(b.locked, 6)}</span>
                    <span className="col-span-1 text-right text-secondary">{fmtUSD(b.usdValue)}</span>
                    <span className="col-span-1 flex justify-end gap-1">
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-7 px-2 text-[11px] text-primary hover:text-primary-hover"
                        onClick={() => toast.info(`Deposit ${b.asset}`, { description: `Generate ${meta?.chains[0] ?? "chain"} address` })}
                      >
                        <ArrowDownToLine className="w-3 h-3" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-7 px-2 text-[11px] text-danger hover:text-danger"
                        onClick={() => toast.info(`Withdraw ${b.asset}`)}
                      >
                        <ArrowUpFromLine className="w-3 h-3" />
                      </Button>
                    </span>
                  </div>
                );
              })}
            </div>
          </Card>

          {/* Mobile card list */}
          <div className="md:hidden space-y-2">
            {balances.map((b) => {
              const meta = ASSET_METADATA[b.asset];
              return (
                <Card key={b.asset} className="p-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <CoinIcon asset={b.asset} size={32} />
                      <div className="flex flex-col leading-tight">
                        <span className="font-medium text-sm">{b.asset}</span>
                        <span className="text-[10px] text-secondary">{meta?.name}</span>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-semibold tabular">{fmtUSD(b.usdValue)}</div>
                      <div className="text-[10px] text-secondary tabular">{fmtQty(b.free + b.locked, 6)} {b.asset}</div>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 mt-3 pt-2 border-t border-border/40 text-[11px]">
                    <div>
                      <div className="text-[10px] text-secondary uppercase">Available</div>
                      <div className="tabular">{fmtQty(b.free, 6)} {b.asset}</div>
                    </div>
                    <div className="text-right">
                      <div className="text-[10px] text-secondary uppercase">Locked</div>
                      <div className="tabular text-gold">{fmtQty(b.locked, 6)} {b.asset}</div>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 mt-2">
                    <Button
                      size="sm"
                      variant="outline"
                      className="h-8 text-[11px] text-primary border-primary/30 hover:bg-primary/10"
                      onClick={() => toast.info(`Deposit ${b.asset}`, { description: `Generate ${meta?.chains[0] ?? "chain"} address` })}
                    >
                      <ArrowDownToLine className="w-3 h-3 mr-1" /> Deposit
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="h-8 text-[11px] text-danger border-danger/30 hover:bg-danger/10"
                      onClick={() => toast.info(`Withdraw ${b.asset}`)}
                    >
                      <ArrowUpFromLine className="w-3 h-3 mr-1" /> Withdraw
                    </Button>
                  </div>
                </Card>
              );
            })}
          </div>
        </TabsContent>

        <TabsContent value="deposits" className="mt-3">
          <Card className="overflow-hidden">
            <TxTable
              rows={deposits}
              columns={[
                { key: "timestamp", label: "Time", render: (d: Deposit) => fmtDateTime(d.timestamp) },
                { key: "asset", label: "Asset", render: (d: Deposit) => d.asset },
                { key: "chain", label: "Chain", render: (d: Deposit) => d.chain },
                { key: "amount", label: "Amount", right: true, render: (d: Deposit) => `${fmtQty(d.amount, 6)} ${d.asset}` },
                { key: "address", label: "Address", render: (d: Deposit) => shortAddr(d.address) },
                { key: "txHash", label: "Tx Hash", render: (d: Deposit) => shortHash(d.txHash) },
                { key: "confirmations", label: "Conf.", right: true, render: (d: Deposit) => `${d.confirmations}/${d.requiredConfirmations}` },
                { key: "status", label: "Status", render: (d: Deposit) => <StatusBadge status={d.status} /> },
              ]}
            />
          </Card>
        </TabsContent>

        <TabsContent value="withdrawals" className="mt-3">
          <Card className="overflow-hidden">
            <TxTable
              rows={withdrawals}
              columns={[
                { key: "timestamp", label: "Time", render: (w: Withdrawal) => fmtDateTime(w.timestamp) },
                { key: "asset", label: "Asset", render: (w: Withdrawal) => w.asset },
                { key: "chain", label: "Chain", render: (w: Withdrawal) => w.chain },
                { key: "amount", label: "Amount", right: true, render: (w: Withdrawal) => `${fmtQty(w.amount, 6)} ${w.asset}` },
                { key: "fee", label: "Fee", right: true, render: (w: Withdrawal) => `${fmtQty(w.fee, 6)} ${w.asset}` },
                { key: "address", label: "Address", render: (w: Withdrawal) => shortAddr(w.address) },
                { key: "txHash", label: "Tx Hash", render: (w: Withdrawal) => w.txHash ? shortHash(w.txHash) : "—" },
                { key: "status", label: "Status", render: (w: Withdrawal) => <StatusBadge status={w.status} /> },
              ]}
            />
          </Card>
        </TabsContent>

        <TabsContent value="whitelist" className="mt-3">
          <WhitelistPanel whitelist={whitelist} />
        </TabsContent>
      </Tabs>

      {/* Chains info */}
      <Card className="p-4">
        <div className="flex items-center gap-2 mb-3">
          <Shield className="w-4 h-4 text-primary" />
          <span className="text-sm font-semibold">Supported Chains & Confirmation Requirements</span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
          {CHAINS.map((c) => (
            <div key={c.id} className="bg-elevated/40 rounded p-2">
              <div className="text-xs font-medium">{c.name}</div>
              <div className="text-[10px] text-secondary mt-0.5">
                {c.confirmations} confs · {fmtUSD(c.withdrawalFeeUSD)} fee
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function getUSDPrice(asset: string, pairs: any[]) {
  if (asset === "USDT") return 1;
  const p = pairs.find((x) => x.symbol === `${asset}/USDT`);
  return p ? null : null; // simplified — uses balance.usdValue elsewhere
}

function WhitelistPanel({ whitelist }: { whitelist: ReturnType<typeof useOpenCEX.getState>["whitelist"] }) {
  const addWhitelist = useOpenCEX((s) => s.addWhitelist);
  const [adding, setAdding] = useState(false);
  const [form, setForm] = useState({ asset: "BTC", chain: "Bitcoin", address: "", label: "" });

  return (
    <Card className="overflow-hidden">
      <div className="flex items-center justify-between px-4 py-2 border-b border-border">
        <div className="flex items-center gap-2">
          <Shield className="w-4 h-4 text-primary" />
          <span className="text-sm font-semibold">Whitelisted Withdrawal Addresses</span>
        </div>
        <Button size="sm" variant="outline" onClick={() => setAdding(!adding)}>
          <Plus className="w-3 h-3 mr-1" /> Add Address
        </Button>
      </div>

      {adding && (
        <div className="p-3 bg-elevated/40 border-b border-border grid grid-cols-1 md:grid-cols-5 gap-2">
          <select
            value={form.asset}
            onChange={(e) => setForm({ ...form, asset: e.target.value })}
            className="bg-input border border-border rounded px-2 py-1.5 text-xs"
          >
            {Object.keys(ASSET_METADATA).map((a) => <option key={a} value={a}>{a}</option>)}
          </select>
          <select
            value={form.chain}
            onChange={(e) => setForm({ ...form, chain: e.target.value })}
            className="bg-input border border-border rounded px-2 py-1.5 text-xs"
          >
            {CHAINS.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
          </select>
          <input
            placeholder="0x... or bc1q..."
            value={form.address}
            onChange={(e) => setForm({ ...form, address: e.target.value })}
            className="bg-input border border-border rounded px-2 py-1.5 text-xs md:col-span-2"
          />
          <div className="flex gap-1">
            <input
              placeholder="Label"
              value={form.label}
              onChange={(e) => setForm({ ...form, label: e.target.value })}
              className="flex-1 bg-input border border-border rounded px-2 py-1.5 text-xs"
            />
            <Button
              size="sm"
              onClick={() => {
                if (!form.address || !form.label) {
                  toast.error("Address and label required");
                  return;
                }
                addWhitelist(form);
                toast.success("Address added — 24h time-lock active");
                setAdding(false);
                setForm({ asset: "BTC", chain: "Bitcoin", address: "", label: "" });
              }}
            >
              Save
            </Button>
          </div>
        </div>
      )}

      <div className="overflow-x-auto no-scrollbar">
        <div style={{ minWidth: "640px" }}>
          <div className="grid grid-cols-12 gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border">
            <span className="col-span-2">Asset</span>
            <span className="col-span-2">Chain</span>
            <span className="col-span-4">Address</span>
            <span className="col-span-2">Label</span>
            <span className="col-span-1">Time-lock</span>
            <span className="col-span-1">Added</span>
          </div>
          <div>
            {whitelist.map((w) => (
              <div key={w.id} className="grid grid-cols-12 gap-2 px-4 py-2 text-xs items-center border-b border-border/40 tabular hover:bg-elevated/40">
                <span className="col-span-2 font-medium">{w.asset}</span>
                <span className="col-span-2 text-secondary">{w.chain}</span>
                <span className="col-span-4 font-mono text-[11px]">{shortAddr(w.address, 10, 8)}</span>
                <span className="col-span-2 text-secondary">{w.label}</span>
                <span className="col-span-1 text-gold">{w.timeLockHours}h</span>
                <span className="col-span-1 text-secondary text-[10px]">{new Date(w.addedAt).toLocaleDateString()}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Card>
  );
}

interface Column<T> {
  key: string;
  label: string;
  right?: boolean;
  render: (row: T) => React.ReactNode;
}

function TxTable<T extends { id: string; timestamp: number }>({ rows, columns }: { rows: T[]; columns: Column<T>[] }) {
  // Min width so the table can horizontally scroll on mobile
  const minRowWidth = Math.max(columns.length * 110, 600);
  return (
    <div>
      <div className="overflow-x-auto no-scrollbar">
        <div style={{ minWidth: `${minRowWidth}px` }}>
          <div className="grid gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border" style={{ gridTemplateColumns: `repeat(${columns.length}, minmax(0, 1fr))` }}>
            {columns.map((c) => (
              <span key={c.key} className={c.right ? "text-right" : ""}>{c.label}</span>
            ))}
          </div>
          <div className="max-h-[60vh] overflow-y-auto">
            {rows.length === 0 && <div className="px-4 py-8 text-center text-xs text-secondary">No records</div>}
            {rows.map((row) => (
              <div
                key={row.id}
                className="grid gap-2 px-4 py-2 text-xs items-center border-b border-border/40 tabular hover:bg-elevated/40"
                style={{ gridTemplateColumns: `repeat(${columns.length}, minmax(0, 1fr))` }}
              >
                {columns.map((c) => (
                  <span key={c.key} className={c.right ? "text-right" : ""}>{c.render(row)}</span>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colorMap: Record<string, string> = {
    PENDING: "bg-yellow-500/15 text-gold",
    CONFIRMED: "bg-blue-500/15 text-blue-400",
    CREDITED: "bg-primary/15 text-primary",
    APPROVED: "bg-blue-500/15 text-blue-400",
    PROCESSING: "bg-purple-500/15 text-purple-400",
    COMPLETED: "bg-primary/15 text-primary",
    REJECTED: "bg-danger/15 text-danger",
  };
  return (
    <span className={`px-1.5 py-0.5 rounded text-[10px] font-medium ${colorMap[status] ?? "bg-elevated text-secondary"}`}>
      {status}
    </span>
  );
}
