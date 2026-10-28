#!/usr/bin/env bash
# Mbuni CEX — apply the updated design system. Run from the project root: bash apply-design-system.sh
set -euo pipefail
[ -f package.json ] && [ -d src/app ] || { echo "Run from the project root"; exit 1; }
w(){ mkdir -p "$(dirname "$1")"; [ -f "$1" ] && [ ! -f "$1.orig" ] && cp "$1" "$1.orig"; cat > "$1"; echo "  wrote $1"; }

w 'src/app/globals.css' <<'MBUNI_DS_EOF'
@import "tailwindcss";
@import "tw-animate-css";

@custom-variant dark (&:is(.dark *));

@theme inline {
  /* ═══════════════════════════════════════════════════════════
     Mbuni CEX 2.0.0 — "Tempered Glass" Design System
     Frosted glass · gradient mesh · neon accents · liquid depth
     ═══════════════════════════════════════════════════════════ */

  /* Brand & actions — lime is BRAND (logo, active nav, success, upticks); purple CTA is the action color */
  --color-primary: #a3e635;
  --color-accent: #a3e635;
  --color-primary-hover: #bef264;
  --color-primary-soft: rgba(163, 230, 53, 0.14);
  --color-primary-muted: rgba(163, 230, 53, 0.08);
  --color-accent-soft: rgba(163, 230, 53, 0.14);
  --color-cta: #7f66ff;
  --color-cta-hover: #9580ff;
  --color-cta-soft: rgba(127, 102, 255, 0.14);
  --color-gold: #e0a23a;

  /* Surfaces — Tempered Glass */
  --color-bg: #07080c;
  --color-surface: rgba(20, 22, 31, 0.72);
  --color-surface-solid: #14161f;
  --color-elevated: rgba(26, 29, 42, 0.78);
  --color-elevated-solid: #1a1d2a;
  --color-elevated-pro: rgba(30, 34, 48, 0.82);
  --color-glass-highlight: rgba(255, 255, 255, 0.06);
  --color-glass-border: rgba(255, 255, 255, 0.09);
  --color-overlay: rgba(7, 8, 12, 0.68);
  --color-disabled: rgba(255, 255, 255, 0.25);
  /* Legacy names kept so existing classes keep working */
  --color-solid: var(--color-surface-solid);
  --color-solid-elevated: var(--color-elevated-solid);

  /* Text */
  --color-secondary: #9ca3af;
  --color-tertiary: #6b7280;
  --color-muted: #8e8e93;

  /* Lines & dividers */
  --color-line: rgba(255, 255, 255, 0.08);
  --color-divider: rgba(255, 255, 255, 0.06);
  --color-line-bright: rgba(255, 255, 255, 0.12);

  /* Semantic — green/lime = up/success only, red = down/error/sell only */
  --color-success: #a3e635;
  --color-success-soft: rgba(163, 230, 53, 0.12);
  --color-danger: #ff5c5c;
  --color-danger-soft: rgba(255, 92, 92, 0.12);
  --color-warning: #ff9f0a;
  --color-warning-soft: rgba(255, 159, 10, 0.12);
  --color-focus: #a3e635;

  /* Neon glows */
  --color-glow-primary: rgba(163, 230, 53, 0.35);
  --color-glow-cta: rgba(127, 102, 255, 0.4);
  --color-glow-danger: rgba(255, 92, 92, 0.3);

  /* Asset colors */
  --color-btc: #f7931a;
  --color-eth: #627eea;
  --color-usdt: #26a17b;
  --color-sol: #9945ff;
  --color-bnb: #f3ba2f;
  --color-link: #2a5ada;
  --color-ada: #0033ad;

  /* Legacy aliases */
  --color-background: var(--color-bg);
  --color-foreground: #ffffff;
  --color-card: var(--color-surface-solid);
  --color-card-foreground: #ffffff;
  --color-popover: var(--color-elevated-solid);
  --color-popover-foreground: #ffffff;
  --color-primary-foreground: #07080c;
  --color-secondary-foreground: #ffffff;
  --color-muted-foreground: var(--color-secondary);
  --color-accent-foreground: #ffffff;
  --color-destructive: var(--color-danger);
  --color-border: var(--color-line);
  --color-input: rgba(255, 255, 255, 0.04);
  --color-ring: var(--color-focus);
  --color-up: var(--color-success);
  --color-down: var(--color-danger);

  --color-chart-1: var(--color-primary);
  --color-chart-2: var(--color-danger);
  --color-chart-3: var(--color-gold);
  --color-chart-4: var(--color-cta);
  --color-chart-5: #9945ff;

  --color-sidebar: rgba(7, 8, 12, 0.7);
  --color-sidebar-foreground: #ffffff;
  --color-sidebar-primary: var(--color-primary);
  --color-sidebar-primary-foreground: #07080c;
  --color-sidebar-accent: rgba(255, 255, 255, 0.04);
  --color-sidebar-accent-foreground: #ffffff;
  --color-sidebar-border: var(--color-line);
  --color-sidebar-ring: var(--color-primary);

  --radius: 0.75rem;
  --radius-sm: calc(var(--radius) - 4px);
  --radius-md: calc(var(--radius) - 2px);
  --radius-lg: var(--radius);
  --radius-xl: calc(var(--radius) + 4px);
}

:root {
  color-scheme: dark;
}

/* ═══════════════════════════════════════════════════════════
   BASE LAYER
   ═══════════════════════════════════════════════════════════ */

@layer base {
  * {
    @apply border-border outline-ring/50;
  }

  html, body {
    background: var(--color-bg);
    color: #ffffff;
    font-family: "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
    font-feature-settings: "tnum" 1, "cv02" 1, "ss01" 1;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
    overflow-x: hidden;
  }

  /* Gradient mesh background — the foundation of tempered glass */
  body::before {
    content: "";
    position: fixed;
    inset: 0;
    z-index: -1;
    background:
      radial-gradient(ellipse 80% 50% at 20% 0%, rgba(127, 102, 255, 0.08), transparent 50%),
      radial-gradient(ellipse 60% 40% at 80% 20%, rgba(163, 230, 53, 0.06), transparent 50%),
      radial-gradient(ellipse 50% 60% at 50% 100%, rgba(99, 69, 255, 0.05), transparent 50%),
      var(--color-bg);
  }

  .tnum, .tabular {
    font-variant-numeric: tabular-nums;
  }
  .tnum-tight {
    font-variant-numeric: tabular-nums;
    letter-spacing: -0.01em;
  }

  :focus-visible {
    outline: 2px solid var(--color-focus);
    outline-offset: 2px;
  }
  input:focus-visible { outline: none; }
  button, a, input, [role="button"], [role="tab"] {
    touch-action: manipulation;
  }

  /* Custom scrollbars — minimal, glassy */
  ::-webkit-scrollbar { width: 6px; height: 6px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.08);
    border-radius: 3px;
  }
  ::-webkit-scrollbar-thumb:hover { background: rgba(255, 255, 255, 0.15); }
}

/* ═══════════════════════════════════════════════════════════
   GLASS UTILITIES — the core of the design language
   ═══════════════════════════════════════════════════════════ */

@layer components {
  /* ── Glass levels (design-system §3). Keep opacity 0.65–0.85; pair translucency with blur;
        avoid stacking more than 2–3 heavy blur layers. ── */
  .glass {
    background: var(--color-surface);
    backdrop-filter: blur(24px);
    -webkit-backdrop-filter: blur(24px);
    border: 1px solid var(--color-glass-border);
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.45), inset 0 1px 0 var(--color-glass-highlight);
  }
  .glass-raised {
    background: var(--color-elevated);
    backdrop-filter: blur(24px);
    -webkit-backdrop-filter: blur(24px);
    border: 1px solid var(--color-glass-border);
    box-shadow: 0 12px 40px rgba(0, 0, 0, 0.5), inset 0 1px 0 var(--color-glass-highlight);
  }
  .glass-pro {
    background: var(--color-elevated-pro);
    backdrop-filter: blur(40px);
    -webkit-backdrop-filter: blur(40px);
    border: 1px solid var(--color-glass-border);
    box-shadow: 0 16px 48px rgba(0, 0, 0, 0.55), inset 0 1px 0 var(--color-glass-highlight);
  }
  .glass-soft {
    background: color-mix(in srgb, var(--color-surface) 60%, transparent);
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
    border: 1px solid rgba(255, 255, 255, 0.05);
    box-shadow: 0 4px 24px rgba(0, 0, 0, 0.35);
  }
  /* Performance-critical lists: no blur */
  .glass-solid {
    background: var(--color-surface-solid);
    border: 1px solid var(--color-glass-border);
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.35);
  }
  .tab-bar-glass {
    background: color-mix(in srgb, var(--color-bg) 80%, transparent);
    backdrop-filter: blur(40px);
    -webkit-backdrop-filter: blur(40px);
    border-top: 1px solid rgba(255, 255, 255, 0.05);
  }

  /* Stronger glass — more opaque, deeper blur */
  /* Legacy alias → .glass-pro values */
  .glass-strong {
    background: var(--color-elevated-pro);
    backdrop-filter: blur(40px);
    -webkit-backdrop-filter: blur(40px);
    border: 1px solid var(--color-glass-border);
    box-shadow: 0 16px 48px rgba(0, 0, 0, 0.55), inset 0 1px 0 var(--color-glass-highlight);
  }

  /* Light glass — barely there, for overlays */
  .glass-light {
    background: rgba(255, 255, 255, 0.03);
    backdrop-filter: blur(12px) saturate(1.2);
    -webkit-backdrop-filter: blur(12px) saturate(1.2);
    border: 1px solid rgba(255, 255, 255, 0.05);
  }

  /* Glass card — the primary container */
  .glass-card {
    background: var(--color-surface);
    backdrop-filter: blur(24px);
    -webkit-backdrop-filter: blur(24px);
    border: 1px solid var(--color-glass-border);
    border-radius: 1.5rem; /* rounded-3xl */
    box-shadow:
      0 8px 32px rgba(0, 0, 0, 0.45),
      inset 0 1px 0 var(--color-glass-highlight);
    transition: border-color 0.2s ease, box-shadow 0.2s ease;
  }

  .glass-card:hover {
    border-color: rgba(255, 255, 255, 0.1);
    box-shadow:
      0 12px 40px rgba(0, 0, 0, 0.5),
      inset 0 1px 0 rgba(255, 255, 255, 0.08);
  }

  /* Glass input — frosted text fields */
  .glass-input {
    background: rgba(255, 255, 255, 0.03);
    backdrop-filter: blur(8px);
    -webkit-backdrop-filter: blur(8px);
    border: 1px solid rgba(255, 255, 255, 0.06);
    border-radius: 0.75rem;
    transition: all 0.2s ease;
  }

  .glass-input:focus-within {
    border-color: var(--color-primary);
    box-shadow: 0 0 0 3px rgba(163, 230, 53, 0.1);
    background: rgba(255, 255, 255, 0.05);
  }

  /* Neon button — CTA with glow */
  .btn-cta {
    background: linear-gradient(135deg, #7f66ff, #9580ff);
    color: white;
    border-radius: 0.875rem;
    font-weight: 600;
    box-shadow:
      0 4px 20px rgba(127, 102, 255, 0.35),
      inset 0 1px 0 rgba(255, 255, 255, 0.15);
    transition: all 0.2s ease;
  }

  .btn-cta:hover {
    box-shadow:
      0 6px 28px rgba(127, 102, 255, 0.5),
      inset 0 1px 0 rgba(255, 255, 255, 0.2);
    transform: translateY(-1px);
  }

  .btn-cta:active {
    transform: scale(0.98); /* press state: 0.97–0.98 */
  }
  .btn-cta:disabled, .btn-buy:disabled, .btn-sell:disabled {
    opacity: 0.4;
    pointer-events: none;
  }

  /* Buy button — lime with glow */
  /* NOTE: design-system says lime is not the primary button; .btn-buy is the semantic BUY (up) action only. */
  .btn-buy {
    background: linear-gradient(135deg, #a3e635, #84cc16);
    color: #07080c;
    border-radius: 0.875rem;
    font-weight: 700;
    box-shadow:
      0 4px 20px rgba(163, 230, 53, 0.25),
      inset 0 1px 0 rgba(255, 255, 255, 0.2);
    transition: all 0.2s ease;
  }

  .btn-buy:hover {
    box-shadow:
      0 6px 28px rgba(163, 230, 53, 0.4),
      inset 0 1px 0 rgba(255, 255, 255, 0.25);
    transform: translateY(-1px);
  }

  /* Sell button — red with glow */
  .btn-sell {
    background: linear-gradient(135deg, #ff5c5c, #ef4444);
    color: white;
    border-radius: 0.875rem;
    font-weight: 700;
    box-shadow:
      0 4px 20px rgba(255, 92, 92, 0.25),
      inset 0 1px 0 rgba(255, 255, 255, 0.15);
    transition: all 0.2s ease;
  }

  .btn-sell:hover {
    box-shadow:
      0 6px 28px rgba(255, 92, 92, 0.4),
      inset 0 1px 0 rgba(255, 255, 255, 0.2);
    transform: translateY(-1px);
  }

  /* Glass chip / badge */
  .glass-chip {
    background: rgba(255, 255, 255, 0.05);
    backdrop-filter: blur(8px);
    -webkit-backdrop-filter: blur(8px);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 9999px;
  }

  /* Neon text glow */
  .text-glow-primary {
    text-shadow: 0 0 20px rgba(163, 230, 53, 0.4);
  }
  .text-glow-cta {
    text-shadow: 0 0 20px rgba(127, 102, 255, 0.4);
  }

  /* Top border highlight — the "tempered glass edge" */
  .glass-edge {
    position: relative;
  }
  .glass-edge::before {
    content: "";
    position: absolute;
    top: 0;
    left: 10%;
    right: 10%;
    height: 1px;
    background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.15), transparent);
    border-radius: 1px;
  }
}

/* ═══════════════════════════════════════════════════════════
   ANIMATIONS
   ═══════════════════════════════════════════════════════════ */

@keyframes pulse-live {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}
.live-dot { animation: pulse-live 1.6s ease-in-out infinite; }

@keyframes flash-up {
  0% { background-color: rgba(163, 230, 53, 0.15); }
  100% { background-color: transparent; }
}
@keyframes flash-down {
  0% { background-color: rgba(255, 92, 92, 0.15); }
  100% { background-color: transparent; }
}
.flash-up { animation: flash-up 0.5s ease-out; }
.flash-down { animation: flash-down 0.5s ease-out; }

/* Shimmer — for loading states */
@keyframes shimmer {
  0% { background-position: -200% 0; }
  100% { background-position: 200% 0; }
}
.shimmer {
  background: linear-gradient(90deg,
    rgba(255, 255, 255, 0.02) 25%,
    rgba(255, 255, 255, 0.08) 50%,
    rgba(255, 255, 255, 0.02) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

/* Float — subtle floating animation for glass elements */
@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-4px); }
}
.float { animation: float 4s ease-in-out infinite; }

/* Hide scrollbar */
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
MBUNI_DS_EOF
w 'src/app/layout.tsx' <<'MBUNI_DS_EOF'
import type { Metadata, Viewport } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Toaster } from "@/components/ui/toaster";
import { Providers } from "@/components/opencex/providers";

const inter = Inter({
  variable: "--font-sans",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700", "800"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "Mbuni CEX 2.0 — Spot Cryptocurrency Exchange",
  description: "Mbuni CEX 2.0 — A modern, high-performance spot cryptocurrency exchange. Rust matching engine, Go services, React frontend.",
  icons: { icon: "/ostrich.svg" },
};

export const viewport: Viewport = {
  themeColor: "#07080c",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className="dark" suppressHydrationWarning>
      <body className={`${inter.variable} antialiased`}>
        <Providers>{children}</Providers>
        <Toaster />
      </body>
    </html>
  );
}
MBUNI_DS_EOF
w 'docs/design-system.md' <<'MBUNI_DS_EOF'
# Mbuni Design System

Mobile-first crypto wallet & exchange UI for **Mbuni**.  
Source of truth in the app: `src/app/globals.css` (Tailwind v4 `@theme`) and shared UI under `src/components/ui/`.

**Stack:** React · TypeScript · Tailwind CSS v4 · Inter · Lucide · Framer Motion (selective)  
**Theme:** Dark only — **Tempered Glass**  
**Brand:** Lime ostrich mascot + purple CTAs (Galvorn-inspired actions)

---

## 1. Principles

1. **Lime is brand, not the button.** `#a3e635` is reserved for logo, active nav, success states, upticks, and soft washes. Primary *actions* always use purple CTA (`#7f66ff`).
2. **Tempered glass depth.** Surfaces are translucent, softly blurred, and layered. Every card, sheet, and panel should feel like frosted glass floating above a deep dark void — never flat or muddy.
3. **Progressive density.** Default to calm, simple glass surfaces for newcomers. Unlock denser pro layouts (order book, multi-pane trade, advanced tickets) via mode toggle or user activity.
4. **Numbers first.** Every price, balance, percentage, and fee uses tabular numbers (`.tnum`). Visual hierarchy remains crystal clear even through glass.
5. **Trust through restraint.** Green/lime = up / success only. Red = down / error / sell only. Glass should enhance calm confidence, not distract.
6. **Mobile phone shell.** Content sits in a centered column (`max-w-md`). Trade screen may widen on larger viewports (`md:max-w-5xl`).
7. **Dense but breathable finance UI.** 52px primary controls for touch, clear hierarchy, generous safe-area handling.
8. **No light theme** in tokens today — `color-scheme: dark` only.
9. **Motion sparingly & smoothly.** Prefer soft scale + opacity. Avoid page-exit animations that can leave the tree non-interactive.
10. **Safe by default.** Every irreversible action shows exact amount, network/fee, recipient, and clear confirmation language.
11. **AI as quiet co-pilot.** AI insight cards use the softest glass treatment and never compete with primary numbers or CTAs.
12. **Progressive disclosure.** One focused question or action per screen in onboarding and forms. Never overwhelm.
13. **Clear action hierarchy.** Primary = solid white or purple CTA. Secondary = dark glass pills. Tertiary = text links.

---

## 2. Color tokens

Defined in `src/app/globals.css` as CSS variables under `@theme`. Tailwind maps them to utilities like `bg-bg`, `text-primary`, `border-line`.

### Brand & actions

| Token | CSS variable | Value | Usage |
|-------|--------------|-------|--------|
| Primary / Accent | `--color-primary`, `--color-accent` | `#a3e635` | Logo, active tab, success, chart up, positive % |
| Primary hover | `--color-primary-hover` | `#bef264` | Lime hover states |
| Primary soft | `--color-primary-soft` | `rgba(163, 230, 53, 0.14)` | Lime washes, selected chips |
| Primary muted | `--color-primary-muted` | `rgba(163, 230, 53, 0.08)` | Very soft lime backgrounds |
| CTA | `--color-cta` | `#7f66ff` | Primary action buttons (purple) |
| CTA hover | `--color-cta-hover` | `#9580ff` | Primary button hover |
| CTA soft | `--color-cta-soft` | `rgba(127, 102, 255, 0.14)` | Purple soft backgrounds |
| Gold | `--color-gold` | `#e0a23a` | Premium / membership accents (use sparingly) |

### Surfaces & text (Tempered Glass system)

| Token | CSS variable | Value | Usage |
|-------|--------------|-------|--------|
| Background | `--color-bg` | `#07080c` | Deepest app canvas |
| Surface | `--color-surface` | `rgba(20, 22, 31, 0.72)` | Standard glass cards |
| Surface solid | `--color-surface-solid` | `#14161f` | Fallback / non-blur contexts |
| Elevated | `--color-elevated` | `rgba(26, 29, 42, 0.78)` | Raised glass panels |
| Elevated solid | `--color-elevated-solid` | `#1a1d2a` | Solid fallback |
| Elevated Pro | `--color-elevated-pro` | `rgba(30, 34, 48, 0.82)` | Denser pro-mode glass |
| Glass highlight | `--color-glass-highlight` | `rgba(255, 255, 255, 0.06)` | Top edge / inner glow |
| Glass border | `--color-glass-border` | `rgba(255, 255, 255, 0.09)` | Soft glass edge |
| Secondary | `--color-secondary` | `#9ca3af` | Labels, secondary body |
| Tertiary | `--color-tertiary` | `#6b7280` | Hints, captions |
| Muted | `--color-muted` | `#8e8e93` | Inactive tab icons |
| Line | `--color-line` | `rgba(255, 255, 255, 0.08)` | Standard borders |
| Divider | `--color-divider` | `rgba(255, 255, 255, 0.06)` | List row separators |
| Overlay | `--color-overlay` | `rgba(7, 8, 12, 0.68)` | Modal / sheet scrim |
| Disabled | `--color-disabled` | `rgba(255, 255, 255, 0.25)` | Disabled text / icons |

### Semantic

| Token | CSS variable | Value | Usage |
|-------|--------------|-------|--------|
| Success | `--color-success` | `#a3e635` | Same as brand lime |
| Success soft | `--color-success-soft` | `rgba(163, 230, 53, 0.12)` | Soft success backgrounds |
| Danger | `--color-danger` | `#ff5c5c` | Sell, errors, down % |
| Danger soft | `--color-danger-soft` | `rgba(255, 92, 92, 0.12)` | Soft danger backgrounds |
| Warning | `--color-warning` | `#ff9f0a` | Pending, alerts |
| Warning soft | `--color-warning-soft` | `rgba(255, 159, 10, 0.12)` | Soft warning backgrounds |
| Focus | `--color-focus` | `#a3e635` | Explicit focus rings |

### Asset colors

| Asset | CSS variable | Value |
|-------|--------------|-------|
| BTC | `--color-btc` | `#f7931a` |
| ETH | `--color-eth` | `#627eea` |
| USDT | `--color-usdt` | `#26a17b` |
| SOL | `--color-sol` | `#9945ff` |
| BNB | `--color-bnb` | `#f3ba2f` |
| LINK | `--color-link` | `#2a5ada` |
| ADA | `--color-ada` | `#0033ad` |

### Meta

| Key | Value |
|-----|--------|
| `theme-color` (HTML) | `#07080c` |

---

## 3. Tempered Glass System

The core visual language of Mbuni is **dark tempered glass** — translucent, softly blurred surfaces with subtle borders and depth.

### Glass levels

| Level | Class | Background | Blur | Border | Shadow | Use case |
|-------|-------|------------|------|--------|--------|----------|
| Base | `.glass` | `bg-surface` | `backdrop-blur-xl` | `border-glass-border` | Soft outer | Standard cards |
| Raised | `.glass-raised` | `bg-elevated` | `backdrop-blur-xl` | `border-glass-border` | Medium | Floating panels, sheets |
| Pro | `.glass-pro` | `bg-elevated-pro` | `backdrop-blur-2xl` | `border-glass-border` | Stronger | Order book, dense trade panels |
| Soft | `.glass-soft` | `bg-surface/60` | `backdrop-blur-lg` | very subtle | Light | AI cards, secondary info |
| Solid fallback | `.glass-solid` | solid surface | none | standard | Soft | Performance-critical lists |

### Recommended CSS utilities

```css
/* Core glass */
.glass {
  @apply bg-surface border border-[var(--color-glass-border)]
    backdrop-blur-xl
    shadow-[0_8px_32px_rgba(0,0,0,0.45),inset_0_1px_0_var(--color-glass-highlight)];
}

.glass-raised {
  @apply bg-elevated border border-[var(--color-glass-border)]
    backdrop-blur-xl
    shadow-[0_12px_40px_rgba(0,0,0,0.5),inset_0_1px_0_var(--color-glass-highlight)];
}

.glass-pro {
  @apply bg-elevated-pro border border-[var(--color-glass-border)]
    backdrop-blur-2xl
    shadow-[0_16px_48px_rgba(0,0,0,0.55),inset_0_1px_0_var(--color-glass-highlight)];
}

.glass-soft {
  @apply bg-surface/60 border border-white/5
    backdrop-blur-lg
    shadow-[0_4px_24px_rgba(0,0,0,0.35)];
}

/* Smooth tab bar */
.tab-bar-glass {
  @apply bg-bg/80 backdrop-blur-2xl border-t border-white/5;
}
```

### Glass rules for smoothness

- Always pair translucent backgrounds with `backdrop-blur-xl` or higher.
- Use a very subtle **inset top highlight** (`inset 0 1px 0 rgba(255,255,255,0.06)`) for the tempered edge.
- Prefer `border-[var(--color-glass-border)]` over hard white borders.
- Keep opacity in the 0.65–0.85 range — too transparent becomes noisy, too opaque loses the glass feel.
- On long lists or performance-sensitive screens, fall back to solid surfaces (`.glass-solid`).
- Avoid stacking more than 2–3 heavy blur layers.

---

## 4. Typography

| Property | Value |
|----------|--------|
| Family | Inter (weights 400, 500, 600, 700, 800) |
| CSS | `--font-sans: "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif` |
| Body default | White, antialiased on `bg-bg` |
| Numeric | Class `.tnum` → `font-variant-numeric: tabular-nums` |
| Tight numeric | Class `.tnum-tight` → tabular-nums + slight negative tracking |

### Type scale

| Role | Typical classes | Notes |
|------|-----------------|-------|
| Screen title | `text-[28px] font-bold tracking-tight` | |
| Hero balance / large price | `text-[32px]–[40px] font-bold tracking-tight tnum` | High impact |
| Section title | `text-[17px] font-bold tracking-tight` | |
| Row / card title | `text-[14px]`–`text-[15px] font-semibold` | |
| Asset row price | `text-[15px] font-semibold tnum` | Consistent column alignment |
| Asset row % | `text-[13px] font-medium tnum` | |
| Label | `text-[13px]`–`text-[14px] font-medium text-secondary` | |
| Caption / meta / fees | `text-[11px]`–`text-[12px] text-tertiary` | |
| Form input | `text-[16px]` | Avoids iOS zoom |
| Button (lg) | `text-[16px] font-semibold` | |
| Button (md) | `text-[15px] font-semibold` | |
| Button (sm) | `text-[13px] font-semibold` | Dense toolbars |
| Tab label | `text-[10px] font-medium` | |

---

## 5. Spacing, radius, layout

### Spacing

| Pattern | Value |
|---------|--------|
| Page horizontal padding | `px-5` (~20px) |
| Section vertical gaps | `mt-6` / `mt-7` |
| List row vertical | `py-3` / `py-3.5` |
| Card internal padding | `p-4` (dense) / `p-5` (hero) |
| Bottom clearance above tab bar | `pb-[calc(5.5rem+env(safe-area-inset-bottom))]` |

### Radius

| Element | Value |
|---------|--------|
| Cards / glass panels | `rounded-3xl` (24px) |
| Inputs | `rounded-xl` |
| Primary buttons (lg) | `rounded-[14px]` / `rounded-full` for CTAs |
| Buttons (md / sm) | `rounded-xl` / `rounded-full` |
| Chips / pills | `rounded-full` |
| Icon wells | `rounded-2xl` / `rounded-full` |
| Bottom sheets | `rounded-t-3xl` |

### Layout shell

- Outer: centered flex, deep black letterbox (`bg-bg`).
- Inner: `max-w-md` phone column.
- Trade screen: may expand to `md:max-w-5xl` with side-by-side chart + order book.
- Tab bar: fixed bottom, high z-index, glass treatment (`.tab-bar-glass`).

---

## 6. Components

### 6.1 Buttons

| Variant | Style | Usage |
|---------|-------|-------|
| **Primary** | Solid white or purple (`bg-cta`), full-width, `rounded-full` or `rounded-[14px]`, 52px height | Main actions (Buy, Continue, Create account) |
| **Secondary** | Dark glass pill (`bg-surface` + border), white text | Add money, Buy assets, secondary actions |
| **Tertiary** | Text only / underline | “Continue with email”, “Manage watchlist” |
| **Destructive** | Red text or soft red background | Sell, Withdraw, Delete |
| **Icon** | Circular glass well | Close, back, more |

**Rules**
- Primary buttons are always high-contrast (white or purple).
- Disabled state: 40% opacity + no pointer events.
- Press state: subtle scale (0.97–0.98).

### 6.2 Bottom Sheets & Action Menus

Strong pattern from real apps:

- Dark glass raised panel (`glass-raised`)
- Soft top handle bar
- Clear list of actions with icon + title + short description
- Full-width items with generous touch targets (`py-4`)

Example structure:
```
Create an order
├── Recurring Buy
└── Custom Order
```

or

```
Buy / Recurring buy / Sell / Convert / Perps
```

### 6.3 Asset Rows

Standard pattern used across Home, Watchlist, Explore, Categories:

```
[Icon]  Asset Name          $Price
        Ticker              ↑ / ↓ %
```

- Icon: 32–40px rounded
- Name: `font-semibold text-[15px]`
- Ticker: `text-tertiary text-[13px]`
- Price + %: right-aligned, tabular numbers
- % color: lime (up) / red (down)

### 6.4 Section Headers

```
Section Title                    →  (optional “See all” / arrow)
Subtitle or short description
```

- Title: `text-[17px] font-bold`
- Optional trailing action on the right

### 6.5 Horizontal Category / Promo Cards

Used heavily in Explore:

- Rounded glass cards (`rounded-3xl`)
- Strong visual (3D illustration or icon stack)
- Short title + one-line description
- Primary CTA button at bottom (“Get started”, “Trade now”)

### 6.6 Progress / Onboarding Steps

Vertical timeline style:

```
✓  Create your account          Completed
02 Verify your identity         Current
03 Make your first trade
```

- Completed = lime check + green text
- Current = bold white
- Upcoming = muted

### 6.7 Form Fields

- Dark glass input (`bg-surface` + soft border)
- Large touch target (min 52px)
- Label above or floating
- Clear error state with red border + helper text
- Country / state selectors as full-width tappable rows

### 6.8 Tabs

**Top-level content tabs** (Watchlist / Crypto / xStocks / Perps):
- Pill or underline style
- Active: lime accent or white text + underline
- Inactive: muted

**Bottom navigation**:
- 5 items max
- Center action button (`+`) is elevated and prominent
- Active icon + label in lime or white
- Glass background with top border

### 6.9 Balance Hero

```
Welcome, {Name}
$0.00                    ← large, bold, tabular
[Add money]  [Buy assets]
```

- Extremely high visual hierarchy on the balance number
- Two secondary action pills directly below

### 6.10 Feature / Discover List

Clean list used in More / Discover more:

```
[Icon]  Title
        Short description
```

- Icon on the left (colored or monochrome)
- Chevron on the right for navigation
- Soft dividers between rows

---

## 7. Key Patterns Extracted from 2026 Crypto Apps

These patterns are now first-class in the Mbuni system:

| Pattern | Implementation Guidance |
|---------|--------------------------|
| **Progressive onboarding** | One question / step per screen. Clear progress indicator. |
| **Zero-balance state** | Large balance + strong “Add money” / “Buy assets” CTAs + verification nudge. |
| **Dual-speed UI** | Simple mode (cards, promos) vs Pro mode (dense lists, order book). |
| **Category discovery** | Horizontal scroll of themed cards (AI, DeFi, Memecoins, Layer 2, RWA…). |
| **Hot / Trending modules** | Side-by-side cards for Trending vs Most Bought / Most Sold. |
| **Action sheet hierarchy** | Buy → Recurring → Sell → Convert → Advanced (Perps). |
| **High-contrast primary CTA** | White or purple solid buttons against pure black. |
| **Soft glass lists** | Dark cards with subtle borders and generous spacing. |
| **Asset row consistency** | Icon + Name/Ticker left, Price + % right, always tabular. |
| **Feature discovery** | “Discover more” list with icons + short descriptions. |

---

## 8. Do / Don’t

**Do**
- Keep primary numbers large and tabular.
- Use tempered glass for cards and sheets.
- Make the center `+` action highly visible.
- Prefer progressive disclosure in forms and onboarding.
- Use lime strictly for positive / brand moments.
- Keep secondary actions as dark glass pills.

**Don’t**
- Use lime as the primary button color.
- Overcrowd screens with too many competing CTAs.
- Skip confirmation steps for irreversible actions.
- Mix too many different card styles on one screen.
- Use pure white borders or heavy shadows that break the glass feel.
- Animate in ways that block interaction.

---

## 9. File Reference

- Tokens & base styles → `src/app/globals.css` (`@theme`)
- Shared components → `src/components/ui/`
- This document → living source of truth for design decisions

---

*Last updated: October 2026 — patterns refined from real 2026 Kraken mobile app analysis + original NovaTrade / Mbuni case study principles.*
MBUNI_DS_EOF
