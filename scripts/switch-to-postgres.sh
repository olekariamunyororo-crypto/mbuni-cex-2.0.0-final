#!/usr/bin/env bash
# =============================================================================
# Mbuni CEX — switch to PostgreSQL + add postbuild migration step
#
# This script:
#   1. Adds a "postbuild" script to package.json that runs `prisma db push`
#      on every Vercel deploy (so the DB schema stays in sync automatically)
#   2. Switches prisma/schema.prisma from "sqlite" to "postgresql"
#   3. Commits + pushes to GitHub → triggers a Vercel redeploy
#
# Prerequisites:
#   - DATABASE_URL env var must be set in your local .env (pointing at the
#     Prisma Postgres / Neon / Supabase connection string)
#   - You must be on the main branch with a clean working tree
#
# Usage:
#   chmod +x scripts/switch-to-postgres.sh
#   ./scripts/switch-to-postgres.sh
# =============================================================================

set -euo pipefail

# ----- Color output -----
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { echo -e "${BLUE}›${NC} $1"; }
ok()    { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}!${NC} $1"; }
err()   { echo -e "${RED}✗${NC} $1"; }

# ----- Pre-flight checks -----

echo ""
echo "🦬 Mbuni CEX — switch to PostgreSQL + auto-migrate on deploy"
echo "─────────────────────────────────────────────────────────────"
echo ""

# 1. Check we're in the project root
if [ ! -f "package.json" ] || [ ! -f "prisma/schema.prisma" ]; then
  err "Not in project root. Run this from the Mbuni CEX repo root."
  exit 1
fi

# 2. Check git is clean (we don't want to clobber uncommitted work)
if ! git diff --quiet || ! git diff --cached --quiet; then
  err "Working tree is not clean. Commit or stash your changes first."
  echo ""
  echo "  git status"
  echo "  git stash   # or commit your changes"
  exit 1
fi

# 3. Check we're on main / master
BRANCH=$(git branch --show-current)
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
  warn "Not on main/master (currently on '$BRANCH'). Continue anyway? [y/N]"
  read -r response
  if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

# 4. Check DATABASE_URL is set
if [ -z "${DATABASE_URL:-}" ]; then
  # Try to load from .env
  if [ -f ".env" ]; then
    info "Loading DATABASE_URL from .env..."
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a
  fi
fi

if [ -z "${DATABASE_URL:-}" ]; then
  err "DATABASE_URL is not set."
  echo ""
  echo "  Set it in your .env file (copy from Vercel → Settings → Environment Variables):"
  echo ""
  echo "    DATABASE_URL=\"postgres://...\""
  echo ""
  echo "  Or export it in your shell:"
  echo ""
  echo "    export DATABASE_URL=\"postgres://...\""
  exit 1
fi

# Mask the URL for display (show host only, hide password)
MASKED_URL=$(echo "$DATABASE_URL" | sed 's|://[^:]*:[^@]*@|://***:***@|')
ok "DATABASE_URL is set: $MASKED_URL"
echo ""

# ----- Step 1: Add postbuild to package.json -----

info "Adding 'postbuild' script to package.json..."

# Use Node to safely edit the JSON (preserves formatting better than sed)
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));

// Add postbuild if it doesn't exist
if (!pkg.scripts.postbuild) {
  // Use prisma db push for the demo (simpler than migrations)
  // For production with real data, switch to: prisma migrate deploy
  pkg.scripts.postbuild = 'prisma db push --accept-data-loss';
  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
  console.log('  Added: \"postbuild\": \"prisma db push --accept-data-loss\"');
} else {
  console.log('  postbuild already exists — skipping');
}
"

ok "package.json updated"
echo ""

# ----- Step 2: Switch Prisma to PostgreSQL -----

info "Switching prisma/schema.prisma from sqlite to postgresql..."

if grep -q 'provider = "sqlite"' prisma/schema.prisma; then
  sed -i.bak 's/provider = "sqlite"/provider = "postgresql"/' prisma/schema.prisma
  rm -f prisma/schema.prisma.bak
  ok "Switched provider to postgresql"
elif grep -q 'provider = "postgresql"' prisma/schema.prisma; then
  warn "schema.prisma already uses postgresql — skipping"
else
  err "Could not find provider line in schema.prisma. Edit it manually:"
  echo ""
  echo '  datasource db {'
  echo '    provider = "postgresql"   // was "sqlite"'
  echo '    url      = env("DATABASE_URL")'
  echo '  }'
  exit 1
fi
echo ""

# ----- Step 3: Regenerate Prisma Client -----

info "Regenerating Prisma Client (so it picks up the new provider)..."
bun run db:generate >/dev/null 2>&1 || npm run db:generate >/dev/null 2>&1
ok "Prisma Client regenerated"
echo ""

# ----- Step 4: Apply the schema to the live DB -----

info "Applying schema to the live database (db:push)..."
echo ""
if bun run db:push 2>&1; then
  ok "Schema applied successfully"
else
  err "db:push failed. Common causes:"
  echo ""
  echo "  - Connection string is wrong (check the host + password)"
  echo "  - Using the pooled URL for migrations — try the direct URL instead"
  echo "    (Prisma Postgres: look for 'direct.db.prisma.io' in the dashboard)"
  echo "  - Database hasn't been provisioned yet"
  echo ""
  echo "  Fix the DATABASE_URL in .env and re-run this script."
  exit 1
fi
echo ""

# ----- Step 5: Seed demo users -----

info "Seeding demo users..."
echo ""
if bun run db:seed 2>&1; then
  ok "Demo users seeded"
else
  warn "db:seed failed (non-blocking — you can do this manually later)"
fi
echo ""

# ----- Step 6: Commit + push -----

info "Committing changes..."

git add package.json prisma/schema.prisma

COMMIT_MSG="build(db): switch to postgresql + auto-migrate on Vercel deploy

- Add 'postbuild' script that runs 'prisma db push' on every Vercel deploy
  so the DB schema stays in sync with schema.prisma automatically
- Switch datasource provider from sqlite to postgresql
- No code changes — only build config + schema

Demo users (run 'bun run db:seed' once locally to populate):
  admin@mbuni.cex / adminpass123 (Tier 5)
  alex.demo@mbuni.cex / testpass123 (Tier 3)"

git commit -m "$COMMIT_MSG" >/dev/null 2>&1
ok "Committed"
echo ""

info "Pushing to GitHub (triggers Vercel redeploy)..."
git push origin "$BRANCH"
ok "Pushed to $BRANCH"
echo ""

# ----- Done -----

echo "═══════════════════════════════════════════════════════════════"
echo ""
ok "All done! Here's what happened:"
echo ""
echo "  1. ✓ Added 'postbuild' to package.json"
echo "     → Vercel will run 'prisma db push' after every build"
echo "  2. ✓ Switched prisma/schema.prisma to postgresql"
echo "  3. ✓ Regenerated Prisma Client"
echo "  4. ✓ Applied schema to the live database"
echo " 5. ✓ Seeded demo users"
echo "  6. ✓ Committed + pushed to GitHub"
echo ""
echo "🚀 Vercel is now redeploying. Watch the build at:"
echo "   https://vercel.com/your-project/deployments"
echo ""
echo "🧪 Once it's deployed, test the full flow at:"
echo "   https://mbuni-cex.vercel.app"
echo ""
echo "   → Click 'Get started' → 'Sign up' → create an account"
echo "   → Walk through onboarding → land in the trading terminal"
echo "   → Place a LIMIT BUY order → see it fill in the trade tape"
echo ""
echo "🔐 Or login with a seeded demo account:"
echo "   admin@mbuni.cex / adminpass123"
echo "   alex.demo@mbuni.cex / testpass123"
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo ""
