#!/usr/bin/env bash
set -euo pipefail
cd /data/data/com.termux/files/home/mbuni-cex-2.0.0-final
[ -f package.json ] || { echo "Not in project root"; exit 1; }

# Append AI Studio glass theme overrides
if ! grep -q 'AI Studio glass match' src/app/globals.css 2>/dev/null; then
  cat >> src/app/globals.css << 'CSS'

/* ========== AI Studio glass match ========== */
:root {
  --background: #0e1016;
  --bg: #0e1016;
  --color-bg: #0e1016;
  --elevated: rgba(22, 24, 32, 0.72);
  --color-elevated: rgba(22, 24, 32, 0.72);
  --card: rgba(24, 26, 36, 0.65);
  --color-card: rgba(24, 26, 36, 0.65);
  --border: rgba(255, 255, 255, 0.07);
  --color-border: rgba(255, 255, 255, 0.07);
  --color-glass-border: rgba(255, 255, 255, 0.08);
  --input: rgba(18, 20, 28, 0.8);
}

html, body, .bg-bg, .bg-background {
  background-color: #0e1016 !important;
  background: #0e1016 !important;
}

/* Tempered glass surfaces */
.glass-raised,
.glass-strong,
.glass-edge {
  background: rgba(22, 24, 34, 0.72) !important;
  backdrop-filter: blur(28px) saturate(1.5) !important;
  -webkit-backdrop-filter: blur(28px) saturate(1.5) !important;
  border: 1px solid rgba(255, 255, 255, 0.08) !important;
  box-shadow:
    0 8px 32px rgba(0, 0, 0, 0.35),
    inset 0 1px 0 rgba(255, 255, 255, 0.06) !important;
}

.tab-bar-glass,
.glass-strong {
  background: rgba(14, 16, 24, 0.88) !important;
  backdrop-filter: blur(30px) saturate(1.6) !important;
  -webkit-backdrop-filter: blur(30px) saturate(1.6) !important;
  border: 1px solid rgba(255, 255, 255, 0.07) !important;
}

/* Soften hard white rings on cards / segments */
[class*="border-white"],
[class*="border-border"],
.border,
.rounded-2xl,
.rounded-3xl {
  border-color: rgba(255, 255, 255, 0.07) !important;
}

/* Elevated panels */
.bg-elevated, .bg-card {
  background: rgba(22, 24, 34, 0.7) !important;
  backdrop-filter: blur(20px) !important;
  -webkit-backdrop-filter: blur(20px) !important;
}

/* Top bar / pills — soft glass not pure black */
.bg-black, .bg-\[\#000\], .bg-\[\#0a0a0a\] {
  background: rgba(16, 18, 26, 0.85) !important;
}
CSS
  echo "patched globals.css"
fi

# Soften explicit border utilities in key components
for f in \
  src/components/ui/BalanceHero.tsx \
  src/components/opencex/views/trading.tsx \
  src/components/opencex/mobile-nav.tsx \
  src/components/opencex/top-bar.tsx \
  src/components/opencex/pair-selector.tsx
do
  [ -f "$f" ] || continue
  sed -i \
    -e 's/border-white\/20/border-white\/10/g' \
    -e 's/border-white\/15/border-white\/8/g' \
    -e 's/border-white\/10/border-white\/6/g' \
    -e 's/bg-black\/90/bg-black\/50/g' \
    -e 's/bg-black\/80/bg-black\/40/g' \
    -e 's/bg-\[#000\]/bg-\[#12141c\]/g' \
    -e 's/bg-\[#0a0a0a\]/bg-\[#12141c\]/g' \
    "$f"
  echo "softened $f"
done

# Content clears bottom nav
for f in src/components/opencex/views/*.tsx; do
  [ -f "$f" ] || continue
  sed -i 's/pb-16 md:pb-0/pb-28 md:pb-0/g; s/pb-20 md:pb-0/pb-28 md:pb-0/g' "$f"
done

[ -f src/components/opencex/mobile-nav.tsx ] && \
  sed -i 's/z-40 px-3 pb-3/z-50 px-3 pb-3/g' src/components/opencex/mobile-nav.tsx

echo "Restarting..."
set -a
[ -f .env ] && . ./.env
set +a
pkill -f "next dev" 2>/dev/null || true
rm -rf .next
bun run dev
