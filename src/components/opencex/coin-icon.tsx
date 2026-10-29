"use client";

import { useState } from "react";
import { ASSET_METADATA } from "@/lib/opencex/seed";

// Real logos live in /public/crypto/<symbol>.svg (see LICENSES.md there).
const LOGOS = new Set([
  "BTC", "ETH", "USDT", "SOL", "BNB", "XRP", "DOGE", "MATIC", "AVAX", "LINK", "ADA", "ARB", "OP", "TON",
]);

interface CoinIconProps {
  asset: string;
  /** Pixel size (square). */
  size?: number;
  className?: string;
}

/**
 * Round coin logo. Falls back to the coloured letter badge for assets without
 * a bundled logo, or if the image fails to load.
 */
export function CoinIcon({ asset, size = 24, className = "" }: CoinIconProps) {
  const [failed, setFailed] = useState(false);
  const sym = asset.toUpperCase();

  if (LOGOS.has(sym) && !failed) {
    return (
      <img
        src={`/crypto/${sym.toLowerCase()}.svg`}
        alt={`${sym} logo`}
        width={size}
        height={size}
        loading="lazy"
        decoding="async"
        draggable={false}
        onError={() => setFailed(true)}
        className={`rounded-full shrink-0 bg-white/5 ${className}`}
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <span
      aria-label={`${sym} logo`}
      className={`rounded-full shrink-0 inline-flex items-center justify-center font-bold text-white ${className}`}
      style={{
        width: size,
        height: size,
        fontSize: Math.max(8, Math.round(size * 0.38)),
        background: ASSET_METADATA[sym]?.color ?? "#666",
      }}
    >
      {sym.slice(0, 2)}
    </span>
  );
}
