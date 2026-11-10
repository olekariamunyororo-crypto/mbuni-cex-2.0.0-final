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
Or via MCP `Run-Query` with `report_type: "funnels"` once EU MCP is available.

Example report shape:

```json
{
  "name": "Mbuni Onboarding",
  "metrics": [
    { "eventName": "Sign Up Completed" },
    { "eventName": "KYC Submitted" },
    { "eventName": "First Trade Completed" }
  ],
  "chartType": "steps",
  "dateRange": {
    "type": "relative",
    "range": { "unit": "day", "value": 30 }
  }
}
```

## Code usage

```ts
import { track, identifyUser, AnalyticsEvents } from "@/lib/analytics";

// after login / session load
await identifyUser(user.id, { email: user.email, kycTier: user.tier });

// signup success
await track(AnalyticsEvents.SIGN_UP_COMPLETED, { method: "credentials" });

// KYC submit
await track(AnalyticsEvents.KYC_SUBMITTED, { country: "KE" });

// first fill only
await track(AnalyticsEvents.FIRST_TRADE_COMPLETED, {
  pair: "BTC/USDT",
  side: "BUY",
});
```

Call `initMixpanel()` once from a client root (e.g. providers) or rely on lazy init inside `track`.

## Data quality (item 4)

Live **Get-Issues** failed from this connector because projects are EU-only:

> Regional access restriction: project is on `eu.mixpanel.com`; MCP is `mcp.mixpanel.com`. Use `mcp-eu.mixpanel.com`.

**Do this in the EU dashboard:**

1. Open https://eu.mixpanel.com → project **Ole Karia Munyororo**
2. **Data Governance** / Lexicon → Issues (or Data Quality)
3. Review: type mismatches, unexpected values, volume drops, unimplemented events
4. After shipping tracking, confirm the three funnel events appear within minutes of test actions

## Checklist

- [ ] Set `NEXT_PUBLIC_MIXPANEL_TOKEN` + EU `API_HOST` in local and Vercel env
- [ ] `bun add mixpanel-browser`
- [ ] Wire `track` on signup, KYC submit, first trade
- [ ] Create funnel in EU Mixpanel UI
- [ ] Smoke-test events in Live View
- [ ] Re-run data-quality review after 24–48h of traffic
