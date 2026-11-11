/**
 * Client-side Mixpanel wrapper for Mbuni CEX.
 *
 * Token: set NEXT_PUBLIC_MIXPANEL_TOKEN (never commit the real value).
 * EU projects: also set NEXT_PUBLIC_MIXPANEL_API_HOST=https://api-eu.mixpanel.com
 *
 * Project ids (connected account):
 * - 4076561 "Ole Karia Munyororo" (default for product analytics)
 * - 4076563 "Threejs-punk-adam"
 */

import type { AnalyticsEventName } from "./events";

type Props = Record<string, string | number | boolean | null | undefined>;

const TOKEN = process.env.NEXT_PUBLIC_MIXPANEL_TOKEN ?? "";
const API_HOST =
  process.env.NEXT_PUBLIC_MIXPANEL_API_HOST ?? "https://api-eu.mixpanel.com";

let initialized = false;

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

export async function initMixpanel(): Promise<void> {
  if (!isBrowser() || initialized || !TOKEN) return;

  try {
    const mixpanel = (await import("mixpanel-browser")).default;
    mixpanel.init(TOKEN, {
      api_host: API_HOST,
      persistence: "localStorage",
      track_pageview: false,
      ignore_dnt: false,
    });
    initialized = true;
  } catch (err) {
    console.warn("[analytics] Mixpanel init failed", err);
  }
}

export async function identifyUser(
  userId: string,
  traits?: Props
): Promise<void> {
  if (!TOKEN) return;
  await initMixpanel();
  if (!isBrowser() || !initialized) return;

  const mixpanel = (await import("mixpanel-browser")).default;
  mixpanel.identify(userId);
  if (traits && Object.keys(traits).length > 0) {
    mixpanel.people.set(traits);
  }
}

export async function track(
  event: AnalyticsEventName | string,
  properties?: Props
): Promise<void> {
  if (!TOKEN) return;
  await initMixpanel();
  if (!isBrowser() || !initialized) return;

  const mixpanel = (await import("mixpanel-browser")).default;
  mixpanel.track(event, {
    app: "mbuni-cex",
    ...properties,
  });
}

export async function resetAnalytics(): Promise<void> {
  if (!TOKEN || !isBrowser()) return;
  try {
    const mixpanel = (await import("mixpanel-browser")).default;
    mixpanel.reset();
    initialized = false;
  } catch {
    /* ignore */
  }
}
