---
name: node-testing
description: Generates unit and HTTP-level integration tests for Node backend APIs (Express, Fastify, Koa, NestJS) using Supertest against the app instance directly, with Vitest, Jest, or node:test. Use when the user asks to test a route handler, controller, middleware, or Express/Fastify app, or mentions Supertest, app.listen, testcontainers, or a package.json with express/fastify/koa but no frontend framework. For a React or Next.js frontend in the same repo, use react-testing or nextjs-testing instead.
license: MIT
compatibility: Requires Node.js and the project's existing package manager. Requires a package.json declaring express, fastify, koa, or @nestjs/core.
metadata:
  platform: node-express
  report-source: testing-methodologies-deep-research-report.txt Part 6 and Part 8
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
paths:
  - "**/*.route.js"
  - "**/*.route.ts"
  - "**/routes/**"
  - "**/controllers/**"
---

# Node / Express Testing

Generates unit and HTTP-level integration tests for Node backend APIs,
using Supertest against the app instance directly — never a real listening
port — with real Request/Response behavior and none of the flakiness of
standing up an actual server process.

## Progress checklist

Copy this into your response and check items off as you go:

```
- [ ] 1. Detect stack (scripts/detect_stack.sh)
- [ ] 2. Audit project structure and existing test conventions
- [ ] 3. Ask the user what to test (layer + scope) — do not assume
- [ ] 4. State the test plan explicitly
- [ ] 5. Generate tests following AAA, boundary-only mocking
- [ ] 6. Run tests; fault-injection self-check on business-logic tests
- [ ] 7. Report back honestly: covered, not covered, anything rewritten
```

## Step 1 — Detect stack

Run `scripts/detect_stack.sh` from the project root. It confirms this is a
Node backend project (Express/Fastify/Koa/NestJS) and reports the existing
test runner, Supertest, testcontainers, and contract-testing tools already
present, plus a check for `.listen()` calls outside test files — a common
port-binding footgun under parallel test workers.

If a test runner or HTTP-testing library is already in use, follow it even
if a different tool is this skill's 2026 default. Never introduce a second,
competing test runner into a project that already picked one.

## Step 2 — Audit project structure

Before writing anything:
- Classify the target: pure logic (a service/utility function, no
  Express-specific objects involved) vs a route handler/controller
  (needs Supertest, exercising real request/response) vs middleware.
- Match the existing test file convention (`__tests__/` vs co-located
  `*.test.ts`) from Step 1.
- Flag critical paths — authentication, payment/billing, any data-write
  operation — for elevated rigor and deliberately high branch coverage,
  even if the user's request was narrower. State this flag out loud; do
  not silently expand scope.

## Step 3 — Ask the user what to test (never assume)

Ask a single message with two questions before generating anything:

1. **Layer**: unit tests only (pure logic/services) / HTTP-level
   integration tests via Supertest / testcontainers-backed integration
   tests against a real disposable database / a mix appropriate to what's
   being tested.
2. **Scope**: does the user want the whole API tested, one route/feature
   tested end-to-end, or just specific file(s)/handler(s)? Do not assume —
   ask explicitly and wait for the answer. If the user's original request
   already named specific files or a feature, confirm that scope back to
   them rather than silently re-asking, but still confirm it.

Only skip re-asking if the user's original request already unambiguously
answered both questions.

## Step 4 — State the plan before generating

State explicitly: which layer(s), which route(s)/function(s) are in scope,
what will be mocked/faked vs exercised for real (mock only the true I/O
boundary — an external paid API, a third-party service; use the real app
instance and, where the plan calls for it, a real disposable
testcontainers database rather than mocking the database layer itself),
and the specific edge cases planned (missing/invalid input, auth failure,
not-found, a data-write's boundary conditions). This is the checkpoint for
the user to redirect before any code exists.

## Step 5 — Generate

- Follow the project's existing import style, naming, and fixture/setup
  patterns from Step 1-2.
- Structure every test as Arrange/Act/Assert, one Act per test.
- Every unit under test gets at minimum: one happy-path case, one boundary/
  invalid-input case, one error-path case — unless the user scoped it
  narrower.
- Use Supertest against the app instance directly; never call
  `app.listen()` in a test. See
  [reference/supertest-patterns.md](reference/supertest-patterns.md).
- Isolate test data per test (transaction rollback or a fresh test
  database) — see
  [reference/test-isolation.md](reference/test-isolation.md) for the two
  most common flakiness causes in this layer.
- For anything genuinely database-behavior-dependent, prefer a
  testcontainers-backed test over mocking the database; see
  [reference/testcontainers-and-contracts.md](reference/testcontainers-and-contracts.md).
- Keep comments in generated test code minimal — at most one short comment
  per test, only where the reason for a specific setup value or edge case
  isn't obvious from the test name and code itself. Do not narrate what
  each line does.

## Step 6 — Self-verification (mandatory)

1. Run the new test(s) against the real implementation. Confirm green. A
   test that's red against correct code is a wrong test — fix the test, do
   not change working code to satisfy it.
2. For every business-logic or critical-path test: run the fault-injection
   self-check in [reference/verification.md](reference/verification.md)
   exactly as written. Any test that stays green against deliberately
   broken code must be rewritten before being counted as passing coverage.
3. Check for accidental non-determinism: a real network call to a
   third-party service, an `app.listen()` introduced by the new test, an
   unseeded random ID, order-dependence from shared database state. Fix in
   place before presenting the result.

## Step 7 — Report back

Summarize specifically: which layer(s) were tested, which edge cases were
covered, what was intentionally left out of scope and why, whether any test
was flagged and rewritten during Step 6, and the coverage delta if
measurable (target ~70-80% line coverage with high branch coverage on
critical paths, not a blanket 90%+). Never claim "fully tested" or "all
done" without this detail.

## Reference

- Supertest + Jest/Vitest patterns, runner choice: [reference/supertest-patterns.md](reference/supertest-patterns.md)
- Test isolation: shared DB state and port-binding conflicts: [reference/test-isolation.md](reference/test-isolation.md)
- Testcontainers, contract testing, coverage targets: [reference/testcontainers-and-contracts.md](reference/testcontainers-and-contracts.md)
- Fault-injection self-check procedure (mandatory, follow verbatim): [reference/verification.md](reference/verification.md)

## Scripts

Run `scripts/detect_stack.sh` from the project root before generating any
test — it confirms the backend framework and prints the detected test
runner, Supertest/testcontainers/contract-testing tools, and flags any
`.listen()` call outside a test file.
