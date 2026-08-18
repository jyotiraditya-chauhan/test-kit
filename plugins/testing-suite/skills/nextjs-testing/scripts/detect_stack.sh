#!/usr/bin/env bash
# Detects a Next.js project and, critically, whether it uses the App
# Router or the Pages Router -- this changes the entire test strategy
# (see reference/async-server-components.md). Run from the project root.
set -euo pipefail

if [[ ! -f "package.json" ]]; then
  echo "ERROR: package.json not found in $(pwd). Run this from the project root." >&2
  exit 1
fi

if ! grep -q '"next"' package.json; then
  echo "ERROR: package.json does not declare 'next'. This does not look like a Next.js project -- if it's plain React, use react-testing instead." >&2
  exit 1
fi

echo "== Next.js project confirmed =="

echo ""
echo "== Router =="
HAS_APP_DIR=false
HAS_PAGES_DIR=false
[[ -d "app" ]] && HAS_APP_DIR=true
[[ -d "src/app" ]] && HAS_APP_DIR=true
[[ -d "pages" ]] && HAS_PAGES_DIR=true
[[ -d "src/pages" ]] && HAS_PAGES_DIR=true

if [[ "$HAS_APP_DIR" == true ]]; then
  echo "  APP ROUTER detected (app/ directory present)."
  echo "  Async Server Components in this router CANNOT be rendered under Vitest --"
  echo "  see reference/async-server-components.md before testing any component that awaits data."
fi
if [[ "$HAS_PAGES_DIR" == true ]]; then
  echo "  PAGES ROUTER detected (pages/ directory present)."
fi
if [[ "$HAS_APP_DIR" == false && "$HAS_PAGES_DIR" == false ]]; then
  echo "  WARNING: neither app/ nor pages/ found. Confirm the router structure before proceeding."
fi

echo ""
echo "== Test runner =="
if [[ -f "vitest.config.ts" || -f "vitest.config.js" || -f "vitest.config.mjs" ]]; then
  echo "  FOUND: Vitest config"
elif [[ -f "jest.config.js" || -f "jest.config.ts" ]] || grep -q '"jest"' package.json; then
  echo "  FOUND: Jest config"
else
  echo "  no unit/component test runner config found"
fi

echo ""
echo "== E2E =="
grep -q '"@playwright/test"' package.json && echo "  FOUND: Playwright"
grep -q '"cypress"' package.json && echo "  FOUND: Cypress"

echo ""
echo "== RTL / MSW =="
grep -q '"@testing-library/react"' package.json && echo "  FOUND: @testing-library/react"
grep -q '"msw"' package.json && echo "  FOUND: msw"

echo ""
echo "== Schema validation =="
grep -q '"zod"' package.json && echo "  FOUND: zod"
