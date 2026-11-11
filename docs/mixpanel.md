# Mixpanel — Mbuni CEX

## Projects (connected account)

| ID | Name | Use |
|----|------|-----|
| **4076561** | Ole Karia Munyororo | Primary product analytics for Mbuni |
| 4076563 | Threejs-punk-adam | Separate / experimental |

Both projects are hosted in the **EU** region (`eu.mixpanel.com`).  
MCP tools on `mcp.mixpanel.com` **cannot** read EU project data or tokens. Use the EU dashboard or reconnect via `mcp-eu.mixpanel.com` for live queries and data-quality APIs.

## Env (do not commit secrets)

```bash
# .env.local
NEXT_PUBLIC_MIXPANEL_TOKEN="<project token from Mixpanel → Project Settings>"
NEXT_PUBLIC_MIXPANEL_API_HOST="https://api-eu.mixpanel.com"
```

Get the token: Mixpanel → Project **Ole Karia Munyororo** → Settings → Project Token  
(Requires owner/admin; treat as a credential.)

## Install

```bash
bun add mixpanel-browser
# types optional:
bun add -d @types/mixpanel-browser
```

## Event catalog (canonical names)

| Event | When to fire |
|-------|----------------|
| `Sign Up Completed` | Account created successfully |
| `KYC Started` | User opens KYC flow |
| `KYC Step Completed` | Each KYC step (include `step` prop) |
| `KYC Submitted` | Full KYC package submitted |
| `KYC Approved` / `KYC Rejected` | Compliance decision |
| `First Trade Completed` | First filled order for the user |
| `Order Placed` / `Order Filled` | All orders |
| `Deposit Completed` / `Withdraw Completed` | Wallet lifecycle |

Source of truth: `src/lib/analytics/events.ts`

## Funnel: Signup → KYC → First trade

**Name:** Mbuni Onboarding  
**Window:** 7 days (adjust in UI)  
**Steps (exact event names):**

1. `Sign Up Completed`
2. `KYC Submitted`
3. `First Trade Completed`

Build in Mixpanel UI: **Funnels** → New → add the three steps in order.

## Code usage

```ts
import { track, identifyUser, AnalyticsEvents } from "@/lib/analytics";

await identifyUser(user.id, { email: user.email, kycTier: user.tier });
await track(AnalyticsEvents.SIGN_UP_COMPLETED, { method: "credentials" });
await track(AnalyticsEvents.KYC_SUBMITTED, { country: "KE" });
await track(AnalyticsEvents.FIRST_TRADE_COMPLETED, { pair: "BTC/USDT", side: "BUY" });
```

## Data quality

Live Get-Issues may fail from non-EU MCP. Check in https://eu.mixpanel.com → project → Data Governance / Lexicon Issues.

## Checklist

- [ ] Set `NEXT_PUBLIC_MIXPANEL_TOKEN` + EU `API_HOST` in local and Vercel env
- [ ] `bun add mixpanel-browser`
- [ ] Wire `track` on signup, KYC submit, first trade
- [ ] Create funnel in EU Mixpanel UI
- [ ] Smoke-test events in Live View
