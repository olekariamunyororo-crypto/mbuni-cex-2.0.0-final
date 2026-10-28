// Mbuni CEX — KYC/AML verification endpoint
// POST /api/kyc  { documentType, documentNumber, fullName, dob, address, city, country }
// GET  /api/kyc  → returns current user's KYC status
import { NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth/config";
import { db } from "@/lib/db";

// ---------------------------------------------------------------------------
// DEMO MODE
// Real verification must come from a provider (Sumsub / Onfido) via a signed
// webhook. The self-approval below exists only so the UI flow can be demoed.
//   - ON by default in `next dev` / tests
//   - OFF by default in production; requires an explicit KYC_DEMO_AUTO_APPROVE=true
// A production deployment must NEVER enable it: it lets any user self-verify.
// ---------------------------------------------------------------------------
const DEMO_AUTO_APPROVE =
  process.env.KYC_DEMO_AUTO_APPROVE === "true" ||
  (process.env.KYC_DEMO_AUTO_APPROVE !== "false" && process.env.NODE_ENV !== "production");

// Placeholder name screen — NOT a real sanctions check. Replace with a
// Scorechain / Chainalysis KYT / Sumsub AML call before launch.
const FLAGGED_NAME_FRAGMENTS = ["sanctioned", "terrorist", "criminal", "fraud", "laundering"];

function amlScreening(name: string): { passed: boolean; reason?: string } {
  const lower = name.toLowerCase();
  for (const s of FLAGGED_NAME_FRAGMENTS) {
    if (lower.includes(s)) {
      return { passed: false, reason: "AML flag: name matches sanctioned entity pattern" };
    }
  }
  // NOTE: the previous version also rejected ~13% of applicants at random
  // (Math.random() risk score) and burned one of their 3 attempts each time.
  return { passed: true };
}

function maskDocumentNumber(n: string | null): string | null {
  if (!n) return null;
  return "•".repeat(Math.max(0, n.length - 4)) + n.slice(-4);
}

function validAdultDob(dob: string): boolean {
  const d = new Date(dob);
  if (Number.isNaN(d.getTime())) return false;
  const now = new Date();
  const eighteen = new Date(now.getFullYear() - 18, now.getMonth(), now.getDate());
  return d <= eighteen && d.getFullYear() >= 1900;
}

export async function GET() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    return NextResponse.json({ ok: false, error: "Unauthorized" }, { status: 401 });
  }
  const user = await db.user.findUnique({
    where: { id: session.user.id },
    select: {
      kycStatus: true,
      kycDocumentType: true,
      kycDocumentNumber: true,
      kycSubmittedAt: true,
      kycVerifiedAt: true,
      kycRejectReason: true,
      kycAttemptCount: true,
    },
  });
  if (!user) {
    return NextResponse.json({ ok: false, error: "User not found" }, { status: 404 });
  }
  // Never send the full ID number back to the browser.
  return NextResponse.json({
    ok: true,
    kyc: { ...user, kycDocumentNumber: maskDocumentNumber(user.kycDocumentNumber) },
  });
}

export async function POST(req: Request) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) {
    return NextResponse.json({ ok: false, error: "Unauthorized" }, { status: 401 });
  }
  const userId = session.user.id;

  try {
    const body = await req.json().catch(() => ({}));
    const documentType = String(body.documentType ?? "");
    const documentNumber = String(body.documentNumber ?? "").trim();
    const fullName = String(body.fullName ?? "").trim();
    const dob = String(body.dob ?? "");
    const address = String(body.address ?? "").trim();

    if (!["NATIONAL_ID", "PASSPORT", "DRIVERS_LICENSE"].includes(documentType)) {
      return NextResponse.json({ ok: false, error: "Valid document type required" }, { status: 400 });
    }
    if (documentNumber.length < 4 || documentNumber.length > 40) {
      return NextResponse.json({ ok: false, error: "Valid document number required" }, { status: 400 });
    }
    if (fullName.length < 3 || fullName.length > 120) {
      return NextResponse.json({ ok: false, error: "Full name required" }, { status: 400 });
    }
    if (!dob || !validAdultDob(dob)) {
      return NextResponse.json({ ok: false, error: "A valid date of birth (18+) is required" }, { status: 400 });
    }
    if (!address || address.length > 300) {
      return NextResponse.json({ ok: false, error: "Address required" }, { status: 400 });
    }

    const existingUser = await db.user.findUnique({
      where: { id: userId },
      select: { kycAttemptCount: true, kycStatus: true },
    });
    if (!existingUser) {
      return NextResponse.json({ ok: false, error: "User not found" }, { status: 404 });
    }
    if (existingUser.kycStatus === "VERIFIED") {
      // A verified identity must not be overwritable through this endpoint.
      return NextResponse.json({ ok: false, error: "Account is already verified" }, { status: 409 });
    }
    if (existingUser.kycAttemptCount >= 3 && existingUser.kycStatus === "REJECTED") {
      return NextResponse.json({ ok: false, error: "Maximum KYC attempts exceeded. Contact support." }, { status: 429 });
    }

    const amlResult = amlScreening(fullName);
    if (!amlResult.passed) {
      await db.user.update({
        where: { id: userId },
        data: {
          kycStatus: "REJECTED",
          kycRejectReason: amlResult.reason,
          kycAttemptCount: { increment: 1 },
          kycDocumentType: documentType,
          kycDocumentNumber: documentNumber,
          kycSubmittedAt: new Date(),
        },
      });
      return NextResponse.json({ ok: false, status: "REJECTED", reason: amlResult.reason });
    }

    await db.user.update({
      where: { id: userId },
      data: {
        kycStatus: "PENDING",
        kycDocumentType: documentType,
        kycDocumentNumber: documentNumber,
        kycSubmittedAt: new Date(),
        kycRejectReason: null,
        kycAttemptCount: { increment: 1 },
      },
    });

    if (DEMO_AUTO_APPROVE) {
      if (process.env.NODE_ENV === "production") {
        console.warn("[kyc] KYC_DEMO_AUTO_APPROVE is enabled in production — every user can self-verify!");
      }
      setTimeout(async () => {
        try {
          // Only approve if it is still PENDING (e.g. an admin may have rejected it meanwhile).
          const res = await db.user.updateMany({
            where: { id: userId, kycStatus: "PENDING" },
            data: { kycStatus: "VERIFIED", kycVerifiedAt: new Date() },
          });
          if (res.count > 0) {
            await db.user.updateMany({ where: { id: userId, tier: { lt: 1 } }, data: { tier: 1 } });
          }
        } catch (e) {
          console.error("[kyc] demo auto-approve failed:", e);
        }
      }, 4000);
    }

    return NextResponse.json({
      ok: true,
      status: "PENDING",
      message: "KYC submitted. Documents under review.",
    });
  } catch (e) {
    console.error("[kyc] submit failed:", e);
    return NextResponse.json({ ok: false, error: "Could not process KYC submission" }, { status: 500 });
  }
}
