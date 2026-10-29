#!/usr/bin/env bash
set -euo pipefail
cd /data/data/com.termux/files/home/mbuni-cex-2.0.0-final
[ -f package.json ] || { echo "Not in project root"; exit 1; }

if ! grep -q 'Mbuni nav glass fix' src/app/globals.css 2>/dev/null; then
  cat >> src/app/globals.css << 'CSS'

/* Mbuni nav glass fix */
.glass-strong {
  background: rgba(12, 14, 20, 0.92) !important;
  backdrop-filter: blur(24px) saturate(1.6) !important;
  -webkit-backdrop-filter: blur(24px) saturate(1.6) !important;
  border: 1px solid rgba(255, 255, 255, 0.08) !important;
}
.tab-bar-glass {
  background: rgba(10, 12, 18, 0.94) !important;
  backdrop-filter: blur(28px) saturate(1.5) !important;
  -webkit-backdrop-filter: blur(28px) saturate(1.5) !important;
  border-top: 1px solid rgba(255, 255, 255, 0.06) !important;
}
CSS
  echo "patched globals.css"
fi

[ -f src/components/opencex/views/trading.tsx ] && \
  sed -i 's/pb-16 md:pb-0/pb-28 md:pb-0/g; s/pb-20 md:pb-0/pb-28 md:pb-0/g' \
  src/components/opencex/views/trading.tsx && echo "patched trading.tsx"

[ -f src/components/opencex/mobile-nav.tsx ] && \
  sed -i 's/z-40 px-3 pb-3/z-50 px-3 pb-3/g' \
  src/components/opencex/mobile-nav.tsx && echo "patched mobile-nav.tsx"

for f in src/components/opencex/views/markets.tsx \
         src/components/opencex/views/wallet.tsx \
         src/components/opencex/views/swap.tsx; do
  [ -f "$f" ] && sed -i 's/pb-16 md:pb-0/pb-28 md:pb-0/g; s/pb-20 md:pb-0/pb-28 md:pb-0/g' "$f"
done

echo "Restarting..."
set -a
[ -f .env ] && . ./.env
set +a
pkill -f "next dev" 2>/dev/null || true
rm -rf .next
bun run dev
