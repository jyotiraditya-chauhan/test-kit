#!/usr/bin/env bash
# Detects a plain React project (not Next.js) plus its existing test
# runner, RTL, mocking, and E2E conventions. Run from the project root.
set -euo pipefail

if [[ ! -f "package.json" ]]; then
  echo "ERROR: package.json not found in $(pwd). Run this from the project root." >&2
  exit 1
fi

if ! grep -q '"react"' package.json || ! grep -q '"react-dom"' package.json; then
  echo "ERROR: package.json does not declare both react and react-dom. This does not look like a React project." >&2
  exit 1
fi

if grep -q '"next"' package.json; then
  echo "ERROR: package.json declares 'next' as a dependency. This is a Next.js project -- use the nextjs-testing skill instead, not react-testing." >&2
  exit 1
fi

echo "== Plain React project confirmed (react + react-dom, no next) =="

echo ""
echo "== Test runner =="
HAS_VITEST_CONFIG=false
[[ -f "vitest.config.ts" || -f "vitest.config.js" || -f "vitest.config.mjs" ]] && HAS_VITEST_CONFIG=true
if [[ "$HAS_VITEST_CONFIG" == false && -f "vite.config.ts" ]] && grep -q "test:" vite.config.ts 2>/dev/null; then
  HAS_VITEST_CONFIG=true
fi
HAS_JEST_CONFIG=false
[[ -f "jest.config.js" || -f "jest.config.ts" ]] && HAS_JEST_CONFIG=true
grep -q '"jest"' package.json 2>/dev/null && HAS_JEST_CONFIG=true

if [[ "$HAS_VITEST_CONFIG" == true ]]; then
  echo "  FOUND: Vitest config"
elif [[ "$HAS_JEST_CONFIG" == true ]]; then
  echo "  FOUND: Jest config"
else
  echo "  no test runner config found -- ask the user or check package.json 'test' script"
fi

echo ""
echo "== React Testing Library =="
grep -q '"@testing-library/react"' package.json && echo "  FOUND: @testing-library/react"
grep -q '"@testing-library/user-event"' package.json && echo "  FOUND: @testing-library/user-event"

echo ""
echo "== Network mocking =="
grep -q '"msw"' package.json && echo "  FOUND: msw (Mock Service Worker)"

echo ""
echo "== E2E =="
grep -q '"@playwright/test"' package.json && echo "  FOUND: Playwright"
grep -q '"cypress"' package.json && echo "  FOUND: Cypress"

echo ""
echo "== Visual regression =="
grep -q '"@storybook' package.json && echo "  FOUND: Storybook"
grep -q '"chromatic"' package.json && echo "  FOUND: Chromatic"

echo ""
echo "== Existing test file convention =="
if find src -type d -name '__tests__' 2>/dev/null | grep -q .; then
  echo "  convention: __tests__/ directories"
elif find src -name '*.test.tsx' -o -name '*.test.ts' -o -name '*.test.jsx' 2>/dev/null | grep -q .; then
  echo "  convention: co-located *.test.tsx next to source files"
else
  echo "  no existing test files found -- no convention to match yet, pick co-located *.test.tsx as default"
fi
