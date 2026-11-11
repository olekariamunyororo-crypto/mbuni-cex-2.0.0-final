/**
 * Mbuni CEX Mixpanel event catalog
 * Keep names stable — funnels and Lexicon depend on exact strings.
 */

export const AnalyticsEvents = {
  // Acquisition / auth
  PAGE_VIEW: "Page View",
  SIGN_UP_STARTED: "Sign Up Started",
  SIGN_UP_COMPLETED: "Sign Up Completed",
  LOGIN_COMPLETED: "Login Completed",
  LOGOUT: "Logout",

  // KYC / compliance
  KYC_STARTED: "KYC Started",
  KYC_STEP_COMPLETED: "KYC Step Completed",
  KYC_SUBMITTED: "KYC Submitted",
  KYC_APPROVED: "KYC Approved",
  KYC_REJECTED: "KYC Rejected",

  // Trading
  TRADE_VIEWED: "Trade Viewed",
  ORDER_PLACED: "Order Placed",
  ORDER_FILLED: "Order Filled",
  ORDER_CANCELLED: "Order Cancelled",
  FIRST_TRADE_COMPLETED: "First Trade Completed",

  // Wallet
  DEPOSIT_STARTED: "Deposit Started",
  DEPOSIT_COMPLETED: "Deposit Completed",
  WITHDRAW_STARTED: "Withdraw Started",
  WITHDRAW_COMPLETED: "Withdraw Completed",
  WHITELIST_ADDRESS_ADDED: "Whitelist Address Added",
} as const;

export type AnalyticsEventName =
  (typeof AnalyticsEvents)[keyof typeof AnalyticsEvents];

/** Canonical onboarding funnel (signup → KYC → first trade) */
export const ONBOARDING_FUNNEL_STEPS = [
  AnalyticsEvents.SIGN_UP_COMPLETED,
  AnalyticsEvents.KYC_SUBMITTED,
  AnalyticsEvents.FIRST_TRADE_COMPLETED,
] as const;
