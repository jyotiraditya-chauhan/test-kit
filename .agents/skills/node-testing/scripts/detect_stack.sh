#!/usr/bin/env bash
# Detects a Node/Express (or Fastify/Koa) backend project and its existing
# test runner, HTTP-testing, and isolation conventions. Run from the
# project root.
set -euo pipefail

if [[ ! -f "package.json" ]]; then
  echo "ERROR: package.json not found in $(pwd). Run this from the project root." >&2
  exit 1
fi

HAS_BACKEND_FRAMEWORK=false
for fw in express fastify koa "@nestjs/core"; do
  grep -q "\"${fw}\"" package.json && HAS_BACKEND_FRAMEWORK=true
done

if [[ "$HAS_BACKEND_FRAMEWORK" == false ]]; then
  echo "ERROR: package.json does not declare express, fastify, koa, or @nestjs/core. This does not look like a Node backend project." >&2
  exit 1
fi

if grep -q '"react"' package.json || grep -q '"next"' package.json; then
  echo "NOTE: package.json also declares a frontend framework (react/next). If the request is about frontend code, use react-testing or nextjs-testing instead -- this skill covers only the backend/API layer."
fi

echo "== Node backend project confirmed =="
for fw in express fastify koa "@nestjs/core"; do
  grep -q "\"${fw}\"" package.json && echo "  framework: ${fw}"
done

echo ""
echo "== Test runner =="
if [[ -f "vitest.config.ts" || -f "vitest.config.js" || -f "vitest.config.mjs" ]]; then
  echo "  FOUND: Vitest config"
elif [[ -f "jest.config.js" || -f "jest.config.ts" ]] || grep -q '"jest"' package.json; then
  echo "  FOUND: Jest config"
else
  echo "  no test runner config found -- Node's built-in test runner (node:test) is also a valid lightweight option"
fi

echo ""
echo "== HTTP/API testing =="
grep -q '"supertest"' package.json && echo "  FOUND: supertest"

echo ""
echo "== Realistic integration testing =="
grep -q '"testcontainers"' package.json && echo "  FOUND: testcontainers"

echo ""
echo "== Contract testing =="
grep -q '"@pact-foundation/pact"' package.json && echo "  FOUND: Pact"
grep -q '"dredd"' package.json && echo "  FOUND: Dredd"

echo ""
echo "== Port-binding footgun check =="
# app.listen() called directly in source (not in a test file or the app's
# own entrypoint bootstrap) causes port conflicts under parallel test
# workers; Supertest never needs the app to be listening.
LISTEN_HITS=$(grep -rlE '\.listen\(' --include='*.js' --include='*.ts' . 2>/dev/null | grep -vE 'node_modules/|dist/|build/|\.test\.|\.spec\.|__tests__/' || true)
if [[ -n "$LISTEN_HITS" ]]; then
  echo "  .listen( found outside test files in:"
  echo "$LISTEN_HITS" | sed 's/^/    /'
  echo "  Confirm these are the app's own bootstrap entrypoint (fine) and not"
  echo "  something a test file also calls -- Supertest should receive the raw"
  echo "  app instance, never a listening server, to avoid port conflicts."
else
  echo "  no .listen( calls found outside test files"
fi

echo ""
echo "== Existing test file convention =="
if find . -type d -iname '__tests__' -not -path '*/node_modules/*' 2>/dev/null | grep -q .; then
  echo "  convention: __tests__/ directories"
elif find . -not -path '*/node_modules/*' \( -name '*.test.js' -o -name '*.test.ts' \) 2>/dev/null | grep -q .; then
  echo "  convention: co-located *.test.ts next to source files"
else
  echo "  no existing test files found -- no convention to match yet"
fi
