// Mbuni CEX — Signup endpoint
// POST /api/signup  { email, password, name? }
// Creates a User with bcrypt-hashed password and returns success.
import { NextResponse } from "next/server";
import bcrypt from "bcryptjs";
import { db } from "@/lib/db";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => null);
    if (!body || typeof body !== "object") {
      return NextResponse.json({ ok: false, error: "Invalid request body" }, { status: 400 });
    }
    const email = String(body.email ?? "").toLowerCase().trim();
    const password = String(body.password ?? "");
    const name = body.name ? String(body.name).trim().slice(0, 80) || null : null;

    if (!email || email.length > 254 || !EMAIL_RE.test(email)) {
      return NextResponse.json({ ok: false, error: "Valid email required" }, { status: 400 });
    }
    if (password.length < 8) {
      return NextResponse.json({ ok: false, error: "Password must be ≥ 8 characters" }, { status: 400 });
    }
    // bcrypt only hashes the first 72 bytes; a cap also bounds CPU per request.
    if (Buffer.byteLength(password, "utf8") > 72) {
      return NextResponse.json({ ok: false, error: "Password must be at most 72 bytes" }, { status: 400 });
    }

    const existing = await db.user.findUnique({ where: { email }, select: { id: true } });
    if (existing) {
      return NextResponse.json({ ok: false, error: "Email already registered" }, { status: 409 });
    }

    const passwordHash = await bcrypt.hash(password, 10);
    try {
      const user = await db.user.create({
        data: { email, name, passwordHash, kycStatus: "NONE", tier: 0 },
      });
      return NextResponse.json({ ok: true, userId: user.id, email: user.email });
    } catch (e) {
      // Two concurrent signups can both pass the findUnique above.
      if ((e as { code?: string }).code === "P2002") {
        return NextResponse.json({ ok: false, error: "Email already registered" }, { status: 409 });
      }
      throw e;
    }
  } catch (e) {
    // Never leak internal/DB error text to the client.
    console.error("[signup] failed:", e);
    return NextResponse.json({ ok: false, error: "Could not create account" }, { status: 500 });
  }
}
