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

Writes unit and HTTP-level integration tests for Node backend APIs,
using Supertest against the app instance directly — never a real listening
port — with real Request/Response behavior and none of the flakiness of
standing up an actual server process. **Writing the test files is the
deliverable.** Running the suite and verifying it — including the
fault-injection self-check — is a separate, optional step this skill
offers but never runs without being asked. See
[Step 6](#step-6--report-what-was-written-then-offer-to-verify).

## Progress checklist

Copy this into your response and check items off as you go:

```
- [ ] 1. Detect stack (scripts/detect_stack.sh)
- [ ] 2. Audit project structure and existing test conventions
- [ ] 3. Ask the user what to test (layer + scope) — do not assume
- [ ] 4. State the test plan explicitly
- [ ] 5. Generate tests following AAA, boundary-only mocking
- [ ] 6. Report what was written; offer to run + verify — do not run yet
- [ ] 7. Only if asked: run tests, fault-injection self-check, report results
```

## Step 1 — Detect stack

Run `scripts/detect_stack.sh` from the project root. It confirms this is a
Node backend project (Express/Fastify/Koa/NestJS) and reports the existing
test runner, Supertest, testcontainers, and contract-testing tools already
present, plus a check for `.listen()` calls outside test files — a common
port-binding footgun under parallel test workers.

If a test runner or HTTP-testing library is already in use, follow it even
if a different tool is this skill's default recommendation. Never introduce a second,
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

If the confirmed scope is large — the whole API, a big feature, more
routes/files than fit comfortably in one pass — say so and propose a
prioritized, batched plan instead of attempting to generate everything at
once. State the first batch, confirm it, then continue rather than
silently truncating or silently attempting all of it in one shot.

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
- Comments are the exception, not the default. Start each generated file
  with one short header comment stating what the file covers (e.g.
  `// Tests for POST /api/orders: auth, validation, and the data-write
  happy path.`) — this is the only comment every file gets. Beyond that,
  add an inline comment only when the reason for a specific setup value
  or edge case genuinely isn't obvious from the test name and code
  itself, never to narrate what a line does. Most files should end up
  with just the header and zero or one inline comments total.
- Before reporting anything, re-read every assertion you just wrote and
  flag or strengthen any that don't check a specific value, status, or
  state — a bare `.not.toThrow()`, a test that only confirms a response
  came back without checking its shape, a snapshot with no accompanying
  explicit assertion. This costs nothing (no execution required, just
  rereading what was just generated) and is the highest-leverage check
  against the failure mode this plugin exists to prevent. Note in Step 6
  if anything was strengthened during this pass.

## Step 6 — Report what was written, then offer to verify

This step always happens, and on its own it completes the task. List the
file(s) written or edited, and for each test summarize in one line what it
covers (happy path / boundary / error path / interaction). Note any
assertion strengthened during the Step 5 self-review. Do **not** run
the tests yet and do **not** claim anything passed — nothing has been
executed.

Then offer, in the same message, without running anything automatically:
*"Want me to run these and verify them — including a fault-injection check
on the business-logic tests — before you review them?"*

If the user doesn't ask for verification (here or in a later message), the
task is complete. Never silently run the suite anyway, and never present a
pass/fail claim for tests that were not actually executed.

## Step 7 — Only if the user asks: run and verify

Do this only when the user explicitly asks you to run, verify, or check
the tests — in this turn or a follow-up one.

1. Run the new test(s) against the real implementation at least twice in a
   row (three times for anything touching timing, randomness, or async
   state) to catch non-determinism empirically before considering it
   green — not just once. A test that's red against correct code is a
   wrong test — fix the test, do not change working code to satisfy it.
2. For every business-logic or critical-path test: run the fault-injection
   self-check in [reference/verification.md](reference/verification.md)
   exactly as written — mandatory within this verification pass, not
   optional. Any test that stays green against deliberately broken code
   must be rewritten before being counted as passing coverage.
3. Check for accidental non-determinism: a real network call to a
   third-party service, an `app.listen()` introduced by the new test, an
   unseeded random ID, order-dependence from shared database state. Fix in
   place before presenting the result.
4. Report specifically: which layer(s) were run, which edge cases were
   covered, what was intentionally left out of scope and why, whether any
   test was flagged and rewritten, and the coverage delta if measurable
   (target ~70-80% line coverage with high branch coverage on critical
   paths, not a blanket 90%+). Never claim "fully tested" or "all done"
   without this detail.

## Reference

- Supertest + Jest/Vitest patterns, runner choice: [reference/supertest-patterns.md](reference/supertest-patterns.md)
- Test isolation: shared DB state and port-binding conflicts: [reference/test-isolation.md](reference/test-isolation.md)
- Testcontainers, contract testing, coverage targets: [reference/testcontainers-and-contracts.md](reference/testcontainers-and-contracts.md)
- Fault-injection self-check procedure — run only if the user asks for verification, follow verbatim when you do: [reference/verification.md](reference/verification.md)

## Scripts

Run `scripts/detect_stack.sh` from the project root before generating any
test — it confirms the backend framework and prints the detected test
runner, Supertest/testcontainers/contract-testing tools, and flags any
`.listen()` call outside a test file.
