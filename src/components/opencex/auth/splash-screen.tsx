"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { OstrichLogo } from "@/components/opencex/ostrich-logo";

export function SplashScreen({ onDone }: { onDone: () => void }) {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const start = Date.now();
    const duration = 1800;
    const interval = setInterval(() => {
      const elapsed = Date.now() - start;
      const p = Math.min(100, (elapsed / duration) * 100);
      setProgress(p);
      if (p >= 100) { clearInterval(interval); setTimeout(onDone, 200); }
    }, 16);
    return () => clearInterval(interval);
  }, [onDone]);

  return (
    <motion.div
      className="fixed inset-0 z-[100] flex flex-col items-center justify-center"
      style={{ background: "#000" }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.4 }}
    >
      {/* Floating coin icons (Kraken-style 3D feel via CSS) */}
      <motion.div
        className="absolute w-12 h-12 rounded-full flex items-center justify-center text-[10px] font-bold text-white"
        style={{ background: "#f7931a", top: "15%", left: "15%", boxShadow: "0 8px 32px rgba(247,147,26,0.3)" }}
        animate={{ y: [0, -12, 0], rotate: [0, 5, 0] }}
        transition={{ duration: 3, repeat: Infinity, ease: "easeInOut" }}
      >₿</motion.div>
      <motion.div
        className="absolute w-10 h-10 rounded-full flex items-center justify-center text-[9px] font-bold text-white"
        style={{ background: "#627eea", top: "20%", right: "20%", boxShadow: "0 8px 32px rgba(98,126,234,0.3)" }}
        animate={{ y: [0, 10, 0], rotate: [0, -5, 0] }}
        transition={{ duration: 3.5, repeat: Infinity, ease: "easeInOut", delay: 0.5 }}
      >Ξ</motion.div>
      <motion.div
        className="absolute w-8 h-8 rounded-full flex items-center justify-center text-[8px] font-bold text-white"
        style={{ background: "#9945ff", bottom: "25%", left: "25%", boxShadow: "0 8px 24px rgba(153,69,255,0.3)" }}
        animate={{ y: [0, -8, 0], rotate: [0, 8, 0] }}
        transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut", delay: 1 }}
      ><span className="text-[8px] font-bold text-white">◎</span></motion.div>

      {/* Logo */}
      <motion.div
        initial={{ scale: 0.7, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="relative z-10 flex flex-col items-center"
      >
        <div className="w-20 h-20 rounded-2xl flex items-center justify-center text-success" style={{ background: "#1c1c1e" }}>
          <OstrichLogo className="w-16 h-16" />
        </div>

        <h1 className="mt-6 text-2xl font-bold tracking-tight text-white">
          Mbuni CEX <span className="text-success">2.0</span>
        </h1>
        <p className="mt-1 text-xs text-secondary">Spot Cryptocurrency Exchange</p>

        {/* Loading bar — minimal, thin */}
        <div className="mt-8 w-48 h-0.5 rounded-full overflow-hidden" style={{ background: "#1c1c1e" }}>
          <motion.div
            className="h-full rounded-full"
            style={{ width: `${progress}%`, background: "#a3e635" }}
          />
        </div>
        <div className="mt-2 text-[10px] text-muted tabular">{Math.round(progress)}%</div>
      </motion.div>

      <div className="absolute bottom-6 text-[10px] text-muted">© 2026 Mbuni CEX</div>
    </motion.div>
  );
}
