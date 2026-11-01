# Lessons Learned: Binance ~$6.3B Heist → Mbuni CEX Controls

**Incident:** Late October 2026 — largest known cryptocurrency theft on record (~$6.3–6.4B).  
**Scope of this doc:** Map public, high-level lessons to **concrete controls** in Mbuni CEX wallet, trading, compliance, and ops — not attack methodology.

Related:

- Repo: [mbuni-cex-2.0.0-final](https://github.com/olekariamunyororo-crypto/mbuni-cex-2.0.0-final)
- Security policy: [`SECURITY.md`](../SECURITY.md)
- Design system: [`docs/design-system.md`](./design-system.md)
- Services: `services/wallet`, `services/trading`, `services/compliance`, Rust `engine/`

---

## 1. Summary of the incident (context only)

| Fact | Detail |
|------|--------|
| **When** | ~29 October 2026; bulk of value moved in ~20–30 minutes |
| **What** | Operational / hot-wallet and **signing–withdrawal authorization** path on Binance infrastructure across ~10 chains |
| **Scale** | ~$6.3–6.4B (analytics + exchange estimates); ~4× prior record (Bybit ~$1.5B, 2025) |
| **Attribution (third-party)** | TRM Labs / Chainalysis → North Korea–linked **TraderTraitor** |
| **Mitigations after** | ~$3B stablecoin freezes by issuers; exchange reserved corporate funds / SAFU-style coverage; user balances made whole |
| **Exchange finding (public)** | Initial focus on compromised DevOps path; later “additional points of breach”; no evidence of broad wallet private-key leak reported |

**Takeaway for Mbuni:** Design for **compromise of operational authorization**, not only “stolen cold keys.” Minimize outbound velocity, separate signing from API, enforce whitelist and ledger integrity.

---

## 2. Lesson → control map

### 2.1 Hot-wallet / signing path is the crown jewel

| Lesson | Mbuni control | Where |
|--------|----------------|--------|
| Attackers abused **authorization of withdrawals**, not necessarily leaked cold keys | **Never** put full signing authority on a single engineer laptop or one process | `services/wallet` |
| Speed of drain mattered | **Hard caps**: max per-tx, per-hour, per-day, per-asset on hot wallets | `requestWithdrawal` + policy table |
| One compromised path → many chains | **Separate signer roles per chain / asset class**; no universal “sign anything” service | Wallet + future custody module |

**Concrete design**

- **Withdrawal pipeline** (wallet service):

  ```text
  validate user
    → whitelist check
    → balance lock
    → risk score
    → multi-party approve (if over threshold)
    → enqueue sign job
    → broadcast
    → reconcile
  ```

- **Signing** lives in a **separate process** (or HSM/MPC), not inside the HTTP handler that accepts `POST /withdraw`.
- HTTP layer only creates a **pending withdrawal intent**; signer only sees **approved, policy-checked jobs**.

---

### 2.2 Address whitelist + time-lock

Binance-style “send anywhere fast” amplifies damage. Mbuni already exposes whitelist endpoints — enforce them fully.

| Lesson | Mbuni control |
|--------|----------------|
| New destinations should be slow | **24h (or configurable) time-lock** after `POST /api/wallet/whitelist` before first use |
| Only known addresses | Withdrawals **reject** if `to_address` ∉ active whitelist for that user + chain |
| Admin override is a risk | Override requires **dual control** + audit log |

**Data model (illustrative)**

```text
whitelist:
  user_id, chain, address, label, created_at, active_after, status

withdraw:
  only if now >= active_after AND status = APPROVED
```

Aligns with delivery work on wallet deposits / withdrawals / whitelist (e.g. Linear-style **THR-26**).

**Code surface today**

- `GET/POST /api/wallet/whitelist`
- `POST /api/wallet/withdraw` — currently TODO: validate, check whitelist, check balance, create record, publish to NATS

---

### 2.3 Pre-trade and pre-withdraw balance integrity

Trading service already documents the intended flow:

> validate balance → reserve → engine → settle

| Lesson | Mbuni control |
|--------|----------------|
| Unauthorized outs empty operational balances | **Single ledger**: free / locked / pending_withdraw |
| Race conditions enable double-spend | **Atomic reserve** in Postgres (`SELECT … FOR UPDATE` or ledger entries) before engine or chain send |
| Fills without settlement break truth | Engine fill → **NATS event** → wallet/ledger consumer **must** settle or reverse lock |

**Trading (`PlaceOrderHandler` in `services/trading`)**

1. Authenticate user from JWT (not hard-coded `demo_user`)
2. Risk limits (position, notional, order rate)
3. Reserve balance
4. gRPC to Rust matching engine
5. On reject/cancel: release reserve

**Wallet (`requestWithdrawal`)**

1. Same ledger: move free → `pending_withdraw`
2. Only after on-chain confirm (or explicit fail): finalize or refund

---

### 2.4 Anomaly detection / velocity (the 20-minute drain)

| Lesson | Mbuni control |
|--------|----------------|
| Most value left in ~20–30 minutes | **Circuit breakers**: if cumulative withdrawals > X USD in Y minutes → pause outbound, page on-call |
| Multi-chain parallel drain | Aggregate **cross-chain** velocity, not only per-chain |
| Ops lag | Real-time metrics: withdrawal count, USD out, unique destinations, failed auth |

**Concrete**

- Wallet publishes `wallet.withdraw.requested` / `.broadcast` / `.confirmed` on NATS
- Small **risk sidecar** or rules in compliance service: thresholds in config, not hard-coded
- Admin UI: “outbound paused” flag (ties to existing admin / health views)

---

### 2.5 Stablecoin / issuer freeze cooperation

Issuers froze on the order of half of freezable stolen stablecoins in the Binance case.

| Lesson | Mbuni control |
|--------|----------------|
| Freezable assets reduce residual loss | Prefer **custody + travel-rule-ready** flows for USDT/USDC; maintain issuer contact / blacklist feed |
| Non-freezable assets need stricter limits | **Lower hot limits** for BTC/ETH vs freezable stables |
| Compliance service exists | Hook `services/compliance` to **sanctions / address risk** before withdraw broadcast |

Do **not** depend on freezes; treat them as **backstop**, not primary control.

---

### 2.6 Least privilege for humans and machines

| Lesson | Mbuni control |
|--------|----------------|
| Compromised DevOps laptop → service container | **No long-lived cloud keys** on laptops; short-lived OIDC/workload identity for prod |
| “Additional points of breach” | Assume **lateral movement**: segment wallet-signer network from general CI/CD |
| Single engineer path | **Maker–checker** for policy changes, limit increases, whitelist emergency unlock |

**For Mbuni (demo → production)**

- CI deploys images; **does not** hold withdrawal keys
- Signer keys only in secret manager / HSM; access logged
- Production withdraw pause via break-glass with two approvers

---

### 2.7 Reserves, proof, and user trust

| Lesson | Mbuni control |
|--------|----------------|
| Users need confidence fast | **SAFU-style reserve** account in ledger (even if small in demo) |
| Opacity hurts | Periodic **proof-of-reserves** style snapshot (admin + public endpoint later) |
| Withdrawal freeze is expected | Document pause conditions and SLA to resume in `SECURITY.md` and ops runbook |

---

## 3. Map onto current Mbuni code surface

| Component | Status today | Priority controls to implement |
|-----------|--------------|--------------------------------|
| `services/wallet` withdraw / whitelist | Stubs + TODOs | Whitelist time-lock, balance lock, policy limits, async sign queue |
| `services/trading` place order | Simulated fill | JWT user, pre-trade reserve, engine gRPC, settle on NATS |
| `services/compliance` | Demo auto-approve | Gate high-risk withdraw; address screening hook |
| Rust `engine` | Matching / risk comments | Keep **pre-trade risk** at trading layer; engine stays pure matching where possible |
| Frontend wallet / admin | Glass UI | Surface whitelist status, pending withdraw, “outbound paused” |
| Infra | Docker / future K8s | Network policies: API → wallet → signer (one-way), no laptop → prod signer |

---

## 4. Suggested implementation order

Matches Asana **Mbuni CEX 2.0** / Linear delivery themes (wallet, trading gRPC, compliance, infra):

1. **Ledger model** (free / locked / pending) in Postgres — shared by trading + wallet  
2. **Whitelist + 24h lock** on `POST /whitelist` and enforce on `POST /withdraw`  
3. **Per-asset / per-user / global velocity limits** + kill switch  
4. **Decouple HTTP withdraw from signing** (job queue)  
5. **Compliance gate** on withdraw  
6. **Alerts + admin pause**  
7. Reserve / PoR narrative for production  

---

## 5. What *not* to take as a “lesson”

- Do not treat “one laptop” as the full story — assume multi-stage compromise.  
- Do not rely only on “we’ll refund users” — that is post-loss; design to **minimize outbound** first.  
- Do not put production withdrawal keys in the same runtime as the public Next.js app or generic API pods.  
- Do not document or implement attacker techniques; this file is **defensive control mapping only**.

---

## 6. API / event checklist (implementation aid)

### Wallet service (`services/wallet`)

| Endpoint / event | Required behavior |
|------------------|-------------------|
| `POST /api/wallet/whitelist` | Create pending entry; set `active_after = now + lock_period`; audit log |
| `GET /api/wallet/whitelist` | List only own addresses; show `active_after` / status |
| `POST /api/wallet/withdraw` | Authn; whitelist; ledger lock; risk limits; enqueue sign job; NATS event |
| `GET /api/wallet/withdrawals` | User history + status machine: `PENDING` → `APPROVED` → `BROADCAST` → `CONFIRMED` / `FAILED` |
| NATS `wallet.withdraw.*` | Consumed by risk, compliance, admin metrics |

### Trading service (`services/trading`)

| Handler | Required behavior |
|---------|-------------------|
| `PlaceOrderHandler` | JWT user; risk limits; atomic reserve; gRPC engine; NATS `orders.*` / `trades.*` |
| Cancel / reject paths | Always release reserve |
| `GetBalancesHandler` | Read from shared ledger, not a second source of truth |

### Compliance (`services/compliance`)

| Concern | Required behavior |
|---------|-------------------|
| Withdraw gate | Block or hold if address / user risk high |
| KYC / AML | Already sketched; wire real status before high-value outbound |
| Audit | Immutable log of policy decisions |

---

## 7. References (public reporting)

High-level public coverage of the October 2026 incident (for product/security context only):

- Industry and press estimates of scale, freezes, and North Korea–linked attribution (TRM Labs, Chainalysis)
- Exchange statements on user coverage, reserved funds, and investigation scope

Update this section if official post-mortems publish durable technical findings that change control priorities.

---

## 8. Document history

| Date | Change |
|------|--------|
| 2026-11-01 | Initial lessons map from Binance ~$6.3B heist → Mbuni wallet/trading/compliance controls |

---

*Defensive security documentation for Mbuni CEX 2.0. Not a vulnerability disclosure or exploit guide.*
