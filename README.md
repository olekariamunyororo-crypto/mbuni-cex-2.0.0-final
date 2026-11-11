# Mbuni CEX 2.0.0 Final

[![CI/CD](https://github.com/olekariamunyororo-crypto/mbuni-cex-2.0.0-final/actions/workflows/ci-cd.yml/badge.svg?branch=main)](https://github.com/olekariamunyororo-crypto/mbuni-cex-2.0.0-final/actions/workflows/ci-cd.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-Policy-blue)](SECURITY.md)
[![Next.js](https://img.shields.io/badge/Next.js-16-black?logo=next.js)](https://nextjs.org/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-blue?logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![Prisma](https://img.shields.io/badge/Prisma-6-2D3748?logo=prisma&logoColor=white)](https://www.prisma.io/)
[![Bun](https://img.shields.io/badge/Bun-1.x-fbf0df?logo=bun)](https://bun.sh/)

**Repository:** [olekariamunyororo-crypto/mbuni-cex-2.0.0-final](https://github.com/olekariamunyororo-crypto/mbuni-cex-2.0.0-final)

A modern spot cryptocurrency exchange stack: **Rust** matching engine, **Go** microservices (wallet, trading, compliance, marketdata), and a **Next.js 16 + Bun** frontend with Kraken-inspired tempered glass UI. **Mbuni** is Swahili for “ostrich.”

![Mbuni CEX](public/ostrich.svg)

---

## Table of contents

1. [Overview](#overview)
2. [Tech stack](#tech-stack)
3. [Quick start](#quick-start)
4. [Environment variables](#environment-variables)
5. [Database](#database)
6. [Scripts](#scripts)
7. [Project structure](#project-structure)
8. [Auth & onboarding](#auth--onboarding)
9. [Analytics (Mixpanel)](#analytics-mixpanel)
10. [Code graph (Graphify)](#code-graph-graphify)
11. [Security lessons](#security-lessons)
12. [Deployment](#deployment)
13. [Testing](#testing)
14. [Security](#security)
15. [License](#license)

---

## Overview

- **Matching engine** — price-time priority; LIMIT, MARKET, IOC, FOK, POST_ONLY. TS reference: `src/lib/opencex/engine.ts`. Production-shaped Rust under `engine/`.
- **Go services** — `services/wallet`, `services/trading`, `services/compliance`, `services/marketdata`.
- **CLOB terminal** — order book, tape, candlesticks, order entry, open orders.
- **Swap** — multi-hop spot convert with slippage control.
- **Wallet** — balances, deposits, withdrawals, address whitelist (time-lock design documented for prod).
- **Admin** — health, users, risk, pairs, fees, event stream.
- **Auth** — splash, welcome carousel, NextAuth + bcrypt, multi-step onboarding / KYC-style flow.
- **UI** — tempered glass (grey glassmorphism), mobile bottom nav, desktop layouts.
- **Analytics** — Mixpanel catalog + client (`src/lib/analytics`).
- **Docs** — design system, incident→control map, Mixpanel guide under `docs/`.

---

## Tech stack

| Layer | Technology |
|-------|------------|
| App | Next.js 16 (App Router), TypeScript 5 |
| UI | Tailwind, shadcn/ui, Framer Motion, Lucide |
| Auth | NextAuth.js v4 (Credentials, JWT) |
| DB | Prisma 6 + SQLite (dev) / PostgreSQL (prod) |
| State | Zustand + session |
| Analytics | Mixpanel (`mixpanel-browser`, EU host supported) |
| Services | Go HTTP services + NATS-oriented events |
| Engine | Rust (`engine/`) + TS mirror |
| Tooling | Bun, Vitest, Playwright, ESLint, Husky |
| Optional | Graphify (`graphifyy`) code knowledge graph |

---

## Quick start

```bash
git clone https://github.com/olekariamunyororo-crypto/mbuni-cex-2.0.0-final.git
cd mbuni-cex-2.0.0-final
bun install
cp .env.example .env
# Edit .env — set NEXTAUTH_SECRET (openssl rand -base64 32)
bun run db:push
bun run db:seed    # optional demo users
bun run dev        # http://localhost:3000
```

**Demo accounts** (after seed):

| Email | Password | Tier |
|-------|----------|------|
| `admin@mbuni.cex` | `adminpass123` | 5 |
| `alex.demo@mbuni.cex` | `testpass123` | 3 |
| `bobby.trader@example.com` | `testpass123` | 2 |
| `carol.newbie@example.com` | `testpass123` | 0 |

Also: `just dev` / `make dev` if you use just/make.

---

## Environment variables

```bash
DATABASE_URL=file:./db/custom.db
# Production: postgresql://user:pass@host:5432/mbuni_cex?schema=public

NEXTAUTH_SECRET=replace-with-a-strong-random-string-min-32-chars
NEXTAUTH_URL=http://localhost:3000

# Optional Mixpanel (never commit real tokens)
# NEXT_PUBLIC_MIXPANEL_TOKEN=
# NEXT_PUBLIC_MIXPANEL_API_HOST=https://api-eu.mixpanel.com
```

See `.env.example`. **Do not commit `.env`.**

---

## Database

Prisma schema: `prisma/schema.prisma` (`User`, NextAuth tables, `Onboarding`, …).

```bash
bun run db:push          # apply schema (dev)
bun run db:generate      # regenerate client
bun run db:migrate       # named migrations
bun run db:migrate:deploy
bun run db:seed
bunx tsx scripts/check-db.ts
```

For PostgreSQL in production, set `provider = "postgresql"` in the schema and use a Postgres `DATABASE_URL`.

---

## Scripts

| Script | Purpose |
|--------|---------|
| `bun run dev` | Dev server :3000 |
| `bun run build` / `start` | Production build & run |
| `bun run lint` | ESLint |
| `bun run db:*` | Prisma push / migrate / seed |
| `bun run test:unit` | Vitest |
| `bun run test:e2e` | Playwright |
| `bun run test` | Unit + e2e |

---

## Project structure

```
mbuni-cex-2.0.0-final/
├── prisma/
├── public/                 # assets, crypto icons, ostrich logo
├── scripts/
├── src/
│   ├── app/                # App Router + API routes
│   ├── components/opencex/ # trading UI, auth, nav
│   ├── components/ui/      # shadcn primitives
│   ├── lib/
│   │   ├── analytics/      # Mixpanel events + client
│   │   ├── auth/
│   │   ├── db.ts
│   │   └── opencex/        # engine, store, seed, types
│   └── hooks/
├── services/               # Go: wallet, trading, compliance, marketdata
├── engine/                 # Rust matching engine
├── docs/
│   ├── design-system.md
│   ├── lessons.md          # incident → control map
│   └── mixpanel.md
├── .github/workflows/      # CI, security, engine, services, release
├── .graphifyignore
├── docker-compose.yml
└── README.md
```

---

## Auth & onboarding

Flow (orchestrated by `src/app/page.tsx`):

**Splash → session check → Welcome / Auth → Onboarding → App**

Persisted: `User`, `Onboarding`, JWT (userId, email, onboardingComplete, tier, kycStatus).

---

## Analytics (Mixpanel)

Guide: [`docs/mixpanel.md`](docs/mixpanel.md).

```bash
bun add mixpanel-browser
```

```ts
import { track, identifyUser, AnalyticsEvents } from "@/lib/analytics";

await identifyUser(user.id, { email: user.email });
await track(AnalyticsEvents.SIGN_UP_COMPLETED, { method: "credentials" });
await track(AnalyticsEvents.KYC_SUBMITTED);
await track(AnalyticsEvents.FIRST_TRADE_COMPLETED, { pair: "BTC/USDT" });
```

**Onboarding funnel** (exact names):

1. `Sign Up Completed`
2. `KYC Submitted`
3. `First Trade Completed`

EU-hosted projects need `NEXT_PUBLIC_MIXPANEL_API_HOST=https://api-eu.mixpanel.com`.

---

## Code graph (Graphify)

Optional local AST graph (no LLM key for basic build):

```bash
pip3 install graphifyy -i https://pypi.org/simple/
export PATH="$HOME/.local/bin:$PATH"
graphify update . --no-cluster
graphify explain "requestWithdrawal"
graphify path "requestWithdrawal" "getBalances"
```

Output: `graphify-out/` (gitignored). Hosted: [app.graphify.com](https://app.graphify.com).

---

## Security lessons

[`docs/lessons.md`](docs/lessons.md) maps public lessons from large-exchange operational incidents to Mbuni controls: whitelist time-locks, ledger free/locked/pending, velocity limits, separated signing, compliance gates. Defensive notes only. See also [`SECURITY.md`](SECURITY.md).

---

## Deployment

### Vercel

1. Import this GitHub repo in Vercel.
2. Set `NEXTAUTH_SECRET`, `NEXTAUTH_URL`, `DATABASE_URL` (Postgres recommended).
3. Optional: Mixpanel public env vars.
4. Deploy. Run migrations / `db:push` against prod DB as needed.

### Docker

```bash
docker compose up -d --build
```

### Render / K8s

See `render.yaml` and `infra/` for Render and Helm-oriented layouts.

**Production checklist (high level):** strong secrets, HTTPS `NEXTAUTH_URL`, Postgres, withdraw limits / whitelist, no keys in the client, rate limits, backups. See `SECURITY.md`.

---

## Testing

```bash
bun run test:unit
bunx playwright install   # first time
bun run test:e2e
bun run test
```

---

## Security

- Report vulnerabilities per [`SECURITY.md`](SECURITY.md).
- Never commit `.env`, private keys, or Mixpanel secrets.
- Withdrawal and custody controls: see `docs/lessons.md` and wallet service TODOs.

---

## License

MIT — see [LICENSE](LICENSE).

---

**Changelog:** [CHANGELOG.md](CHANGELOG.md) · **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)
