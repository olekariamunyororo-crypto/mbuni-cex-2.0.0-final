"use client";

import { useEffect, useRef, useState } from "react";
import { motion } from "framer-motion";
import { Cpu } from "lucide-react";
import * as THREE from "three";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { MeshoptDecoder } from "three/examples/jsm/libs/meshopt_decoder.module.js";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";
import { OstrichLogo } from "@/components/opencex/ostrich-logo";
import { fitCameraDistance, thinnestAxis } from "@/lib/opencex/coin-scene";

const MODEL_URL = "/models/bitcoin.glb";
const MIN_SHOW_MS = 3600; // always show the spin at least this long
const LOAD_TIMEOUT_MS = 8000; // give up on the model and fall back to the logo tile
const SPIN_RAD_PER_SEC = 1.2; // one full turn ≈ 5.2 s
const SPIN_RAMP_MS = 1800; // ease the spin in from rest

type CoinStatus = "loading" | "ready" | "failed";

/**
 * Splash: a slowly spinning 3D Bitcoin (Three.js) over the Tempered Glass backdrop.
 * Falls back to the original logo tile if WebGL or the model is unavailable.
 */
export function SplashScreen({ onDone }: { onDone: () => void }) {
  const [progress, setProgress] = useState(0);
  const [status, setStatus] = useState<CoinStatus>("loading");
  const mountRef = useRef<HTMLDivElement | null>(null);
  const loadProgressRef = useRef(0); // 0..1 real download progress
  const readyAtRef = useRef<number | null>(null);

  // ── Three.js scene ──
  useEffect(() => {
    const mount = mountRef.current;
    if (!mount) return;

    let renderer: THREE.WebGLRenderer;
    try {
      renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, powerPreference: "high-performance" });
    } catch {
      queueMicrotask(() => setStatus("failed")); // no WebGL → logo fallback
      return;
    }
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = 1.05;
    renderer.setClearColor(0x000000, 0);
    renderer.domElement.style.cssText = "width:100%;height:100%;display:block;outline:none";
    mount.appendChild(renderer.domElement);

    const scene = new THREE.Scene();
    // Procedural studio reflections — no HDR file to download, and gold needs something to reflect.
    const pmrem = new THREE.PMREMGenerator(renderer);
    const envTex = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;
    scene.environment = envTex;
    scene.environmentIntensity = 1.1;

    // Brand rim lights: lime right, violet left
    const rimLime = new THREE.DirectionalLight(0xa3e635, 1.4);
    rimLime.position.set(3, 1.5, 2);
    const rimViolet = new THREE.DirectionalLight(0x7f66ff, 1.6);
    rimViolet.position.set(-3, -0.5, 2);
    const key = new THREE.DirectionalLight(0xffffff, 1.2);
    key.position.set(0, 3, 4);
    scene.add(rimLime, rimViolet, key);

    const camera = new THREE.PerspectiveCamera(35, 1, 0.01, 100);
    camera.position.set(0, 0, 6);

    const spin = new THREE.Group(); // rotates about the vertical axis
    const tilt = new THREE.Group(); // fixed slight tilt so the face catches light
    tilt.rotation.x = -0.1;
    tilt.add(spin);
    scene.add(tilt);

    const reduceMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
    let disposed = false;
    let raf = 0;
    let modelReady = false;
    const clock = new THREE.Clock();

    const resize = () => {
      const w = mount.clientWidth || 1;
      const h = mount.clientHeight || 1;
      renderer.setSize(w, h, false);
      camera.aspect = w / h;
      if (modelReady) {
        camera.position.z = fitCameraDistance(1, camera.fov, camera.aspect);
      }
      camera.updateProjectionMatrix();
    };
    const ro = new ResizeObserver(resize);
    ro.observe(mount);
    resize();

    const loader = new GLTFLoader();
    loader.setMeshoptDecoder(MeshoptDecoder);
    const timeout = setTimeout(() => { if (!modelReady && !disposed) setStatus("failed"); }, LOAD_TIMEOUT_MS);

    loader.load(
      MODEL_URL,
      (gltf) => {
        if (disposed) return;
        const holder = gltf.scene;

        // Stand the coin up if the file has it lying down, then centre + normalise to radius 1.
        const size0 = new THREE.Box3().setFromObject(holder).getSize(new THREE.Vector3());
        const thin = thinnestAxis(size0);
        const wrapper = new THREE.Group();
        wrapper.add(holder);
        if (thin === "y") wrapper.rotation.x = Math.PI / 2;
        else if (thin === "x") wrapper.rotation.y = Math.PI / 2;
        wrapper.updateMatrixWorld(true);

        const box = new THREE.Box3().setFromObject(wrapper);
        const center = box.getCenter(new THREE.Vector3());
        const radius = box.getBoundingSphere(new THREE.Sphere()).radius || 1;
        holder.position.sub(center);
        wrapper.scale.setScalar(1 / radius);
        wrapper.updateMatrixWorld(true);

        holder.traverse((o) => {
          const mesh = o as THREE.Mesh;
          if (mesh.isMesh) {
            const m = mesh.material as THREE.MeshStandardMaterial;
            m.envMapIntensity = 1.2;
            if (m.map) m.map.anisotropy = renderer.capabilities.getMaxAnisotropy();
          }
        });

        spin.add(wrapper);
        modelReady = true;
        camera.position.z = fitCameraDistance(1, camera.fov, camera.aspect);
        camera.updateProjectionMatrix();
        clock.start();
        clearTimeout(timeout);
        readyAtRef.current = performance.now();
        setStatus("ready");
      },
      (e) => { if (e.lengthComputable) loadProgressRef.current = e.loaded / e.total; },
      () => { if (!disposed) { clearTimeout(timeout); setStatus("failed"); } },
    );

    const tick = () => {
      raf = requestAnimationFrame(tick);
      if (!modelReady) return;
      const t = clock.getElapsedTime();
      const speed = reduceMotion ? SPIN_RAD_PER_SEC * 0.25 : SPIN_RAD_PER_SEC;
      // Angular velocity eases in quadratically over the ramp, then stays constant; angle is its integral.
      const r = SPIN_RAMP_MS / 1000;
      const angle = t < r ? (speed * r * (t / r) ** 3) / 3 : (speed * r) / 3 + speed * (t - r);
      const eased = Math.min(1, t / r);
      spin.rotation.y = angle;
      tilt.position.y = reduceMotion ? 0 : Math.sin(t * 0.8) * 0.03 * eased;
      renderer.render(scene, camera);
    };
    tick();

    return () => {
      disposed = true;
      clearTimeout(timeout);
      cancelAnimationFrame(raf);
      ro.disconnect();
      scene.traverse((o) => {
        const mesh = o as THREE.Mesh;
        if (mesh.isMesh) {
          mesh.geometry.dispose();
          const mats = Array.isArray(mesh.material) ? mesh.material : [mesh.material];
          for (const m of mats) {
            for (const v of Object.values(m)) if (v instanceof THREE.Texture) v.dispose();
            m.dispose();
          }
        }
      });
      envTex.dispose();
      pmrem.dispose();
      renderer.dispose();
      renderer.forceContextLoss();
      renderer.domElement.remove();
    };
  }, []);

  // ── Progress + timing: real download progress while loading, then run out the minimum show time ──
  useEffect(() => {
    if (status === "loading") {
      const id = setInterval(() => setProgress(Math.min(60, loadProgressRef.current * 60)), 50);
      return () => clearInterval(id);
    }
    const from = readyAtRef.current ?? performance.now();
    const start = performance.now();
    const base = status === "failed" ? 0 : 60;
    const duration = status === "failed" ? 1800 : Math.max(900, MIN_SHOW_MS - (start - from) - 0);
    const id = setInterval(() => {
      const p = Math.min(1, (performance.now() - start) / duration);
      setProgress(base + (100 - base) * p);
      if (p >= 1) {
        clearInterval(id);
        setTimeout(onDone, 300);
      }
    }, 16);
    return () => clearInterval(id);
  }, [status, onDone]);

  return (
    <motion.div
      className="fixed inset-0 z-[100] flex flex-col items-center justify-center overflow-hidden"
      style={{ background: "var(--color-bg)" }}
      exit={{ opacity: 0, scale: 1.05 }}
      transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
    >
      {/* Gradient mesh — animated orbs */}
      <motion.div
        className="absolute w-[500px] h-[500px] rounded-full blur-[120px]"
        style={{ background: "radial-gradient(circle, rgba(127, 102, 255, 0.15), transparent 70%)" }}
        initial={{ scale: 0.5, opacity: 0, x: "-20%" }}
        animate={{ scale: 1.2, opacity: 1, x: "0%" }}
        transition={{ duration: 2, ease: "easeOut" }}
      />
      <motion.div
        className="absolute w-[400px] h-[400px] rounded-full blur-[100px]"
        style={{ background: "radial-gradient(circle, rgba(163, 230, 53, 0.1), transparent 70%)" }}
        initial={{ scale: 0.3, opacity: 0, x: "30%", y: "20%" }}
        animate={{ scale: 1, opacity: 1, x: "10%", y: "0%" }}
        transition={{ duration: 2.5, ease: "easeOut" }}
      />

      <div className="relative z-10 flex flex-col items-center">
        {/* 3D coin (or logo fallback) */}
        <div className="relative w-[min(70vw,300px)] h-[min(70vw,300px)] flex items-center justify-center">
          <div
            className="absolute inset-[12%] rounded-full blur-3xl"
            style={{ background: "radial-gradient(circle, rgba(247, 147, 26, 0.28), rgba(163, 230, 53, 0.08) 60%, transparent 75%)" }}
          />
          {status !== "failed" ? (
            <motion.div
              ref={mountRef}
              className="absolute inset-0"
              initial={{ opacity: 0, scale: 0.85 }}
              animate={{ opacity: status === "ready" ? 1 : 0, scale: status === "ready" ? 1 : 0.85 }}
              transition={{ duration: 0.9, ease: [0.16, 1, 0.3, 1] }}
              aria-label="Rotating 3D Bitcoin"
              role="img"
            />
          ) : (
            <div className="glass-strong relative w-24 h-24 rounded-[1.75rem] flex items-center justify-center text-primary">
              <OstrichLogo className="w-20 h-20" />
            </div>
          )}
        </div>

        {/* Wordmark */}
        <motion.h1
          className="relative mt-4 text-3xl font-bold tracking-tight"
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4, duration: 0.6 }}
        >
          Mbuni CEX
          <span className="ml-2 text-primary text-glow-primary">2.0</span>
        </motion.h1>

        <motion.p
          className="relative mt-2 text-sm text-secondary font-medium"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6, duration: 0.6 }}
        >
          Spot Cryptocurrency Exchange · Rust · Go · React
        </motion.p>

        {/* Liquid loading bar */}
        <div className="relative mt-8 w-56 h-1 rounded-full overflow-hidden" style={{ background: "rgba(255,255,255,0.04)" }}>
          <div
            className="absolute inset-y-0 left-0 rounded-full"
            style={{
              width: `${progress}%`,
              background: "linear-gradient(90deg, #a3e635, #7f66ff)",
              boxShadow: "0 0 12px rgba(163, 230, 53, 0.4)",
            }}
          />
        </div>
        <div className="relative mt-3 text-[10px] text-tertiary tabular w-56 flex justify-between">
          <span className="flex items-center gap-1">
            <Cpu className="w-3 h-3" /> {status === "loading" ? "Loading assets" : "Initializing engine"}
          </span>
          <span>{Math.round(progress)}%</span>
        </div>
      </div>

      {/* Footer + model attribution (CC BY-NC 4.0 requires credit) */}
      <motion.div
        className="absolute bottom-5 px-6 text-center text-[10px] text-tertiary/60 leading-relaxed"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1, duration: 0.6 }}
      >
        © 2026 Mbuni CEX · Tempered Glass UI
        <br />
        3D model “Bitcoin – Free Model” by FranciscoDugarte · CC BY-NC 4.0
      </motion.div>
    </motion.div>
  );
}
