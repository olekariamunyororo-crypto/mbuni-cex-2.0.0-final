import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  poweredByHeader: false,
  // Type errors must fail the build — `ignoreBuildErrors: true` used to hide them.
  reactStrictMode: false,
};

export default nextConfig;
