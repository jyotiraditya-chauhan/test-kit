---
name: nextjs-testing
description: Generates tests for Next.js projects (App Router or Pages Router), splitting work between Vitest for Server Actions/schema validation/sync components and Playwright for async Server Components, auth flows, and checkout. Use when the user asks to test a Next.js page, Server Action, API route handler, or middleware, or mentions next.config, app/ directory, Server Components, or a project whose package.json declares "next". For a React app without "next" in package.json, use react-testing instead.
license: MIT
compatibility: Requires Node.js and the project's existing package manager. Requires a package.json declaring "next".
metadata:
  platform: nextjs
  report-source: testing-methodologies-deep-research-report.txt Part 4 and Part 8
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
paths:
  - "app/**/*.tsx"
  - "app/**/*.ts"
  - "pages/**/*.tsx"
  - "pages/**/*.ts"
  - "next.config.*"
---

# Next.js Testing

Writes tests for Next.js projects, splitting work across a hard boundary:
Vitest for anything that doesn't require rendering an async Server
Component, Playwright for everything that does. Getting this boundary wrong
is the single most common Next.js testing mistake — see
[reference/async-server-components.md](reference/async-server-components.md)
before writing anything. **Writing the test files is the deliverable.**
Running the suite and verifying it — including the fault-injection
self-check — is a separate, optional step this skill offers but never runs
without being asked. See
[Step 6](#step-6--report-what-was-written-then-offer-to-verify).

## Progress checklist

Copy this into your response and check items off as you go:

```
- [ ] 1. Detect stack + router (scripts/detect_stack.sh)
- [ ] 2. Audit project structure; identify Vitest vs Playwright boundary
- [ ] 3. Ask the user what to test (layer + scope) — do not assume
- [ ] 4. State the test plan explicitly
- [ ] 5. Generate tests following AAA, boundary-only mocking
- [ ] 6. Report what was written; offer to run + verify — do not run yet
- [ ] 7. Only if asked: run tests, fault-injection self-check, report results
```

## Step 1 — Detect stack and router

Run `scripts/detect_stack.sh` from the project root. It confirms this is a
Next.js project and reports **App Router vs Pages Router** — this
determines the entire strategy and must be resolved before generating any
component test — plus the existing Vitest/Jest, Playwright/Cypress, RTL,
MSW, and Zod presence.

If a test runner is already in use, follow it even if a different tool is
this skill's default. Never introduce a second, competing test runner.

## Step 2 — Audit project structure

Before writing anything, classify the target and route it correctly:
- **Async Server Component** (contains an `await` in the component body) →
  Vitest cannot render this. Either propose extracting the async data call
  into a plain function (the recommended default — see
  [reference/async-server-components.md](reference/async-server-components.md))
  or route the test to Playwright. Never attempt to render it under Vitest.
- **Synchronous Server Component or Client Component** → Vitest + RTL,
  same as `react-testing`.
- **Server Action** → test as a plain async function with Vitest, not
  through a rendered tree.
- **API route handler (`route.ts`) or middleware** → import the exported
  function directly and invoke with a constructed Request; see
  [reference/api-and-middleware.md](reference/api-and-middleware.md).
- Flag critical paths — authentication, payment/billing, any data-write —
  for elevated rigor even if the user's request was narrower. State this
  flag out loud; do not silently expand scope.

## Step 3 — Ask the user what to test (never assume)

Ask a single message with two questions before generating anything:

1. **Layer**: Vitest unit/integration tests (Server Actions, schema
   validation, sync/client components, route handlers) / Playwright E2E
   (async Server Components, auth, checkout) / both, matched to what's
   being tested.
2. **Scope**: does the user want the whole app tested, one feature/route
   tested end-to-end, or just specific file(s)? Do not assume — ask
   explicitly and wait for the answer. If the user's original request
   already named specific files or a feature, confirm that scope back to
   them rather than silently re-asking, but still confirm it.

Only skip re-asking if the user's original request already unambiguously
answered both questions.

## Step 4 — State the plan before generating

State explicitly: which layer(s) (Vitest and/or Playwright), which file(s)
are in scope, whether an extraction (per Step 2) is being proposed and why,
what will be mocked (network via MSW if present, `next/navigation` hooks
actually used — see
[reference/api-and-middleware.md](reference/api-and-middleware.md)) vs
exercised for real, and the specific edge cases planned. This is the
checkpoint for the user to redirect before any code exists.

## Step 5 — Generate

- Follow the project's existing import style, naming, and setup patterns.
- Structure every test as Arrange/Act/Assert, one Act per test.
- Every unit under test gets at minimum: one happy-path case, one boundary/
  empty case, one error-path case — unless the user scoped it narrower.
- Never render an async Server Component under Vitest. See
  [reference/async-server-components.md](reference/async-server-components.md).
- For E2E work, see
  [reference/e2e-playwright.md](reference/e2e-playwright.md) — don't
  generate a Playwright test for something a Vitest test on an extracted
  function would cover just as well.
- Keep comments in generated test code minimal — at most one short comment
  per test, only where the reason for a specific setup value or edge case
  isn't obvious from the test name and code itself. Do not narrate what
  each line does.

## Step 6 — Report what was written, then offer to verify

This step always happens, and on its own it completes the task. List the
file(s) written or edited, and for each test summarize in one line what it
covers (happy path / boundary / error path / interaction). Do **not** run
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

1. Run the new test(s) against the real implementation. Confirm green. A
   test that's red against correct code is a wrong test — fix the test, do
   not change working code to satisfy it.
2. For every business-logic or critical-path test (Server Actions, route
   handlers, extracted data functions): run the fault-injection self-check
   in [reference/verification.md](reference/verification.md) exactly as
   written — mandatory within this verification pass, not optional. Any
   test that stays green against deliberately broken code must be
   rewritten before being counted as passing coverage.
3. Check for accidental non-determinism: real network calls not mocked,
   unseeded randomness, order-dependence, a Playwright test relying on
   arbitrary waits instead of the page's real ready signal. Fix in place.
4. Report specifically: which layer(s) were run (Vitest and/or Playwright),
   which edge cases were covered, what was intentionally left out of scope
   and why, whether any test was flagged and rewritten, and the coverage
   delta if measurable. Never claim "fully tested" or "all done" without
   this detail.

## Reference

- Async Server Component gap, extraction rule, Vitest/Playwright boundary: [reference/async-server-components.md](reference/async-server-components.md)
- API route handlers, middleware, next/navigation mocking: [reference/api-and-middleware.md](reference/api-and-middleware.md)
- Playwright E2E scope and representative distribution: [reference/e2e-playwright.md](reference/e2e-playwright.md)
- Fault-injection self-check procedure — run only if the user asks for verification, follow verbatim when you do: [reference/verification.md](reference/verification.md)

## Scripts

Run `scripts/detect_stack.sh` from the project root before generating any
test — it confirms Next.js, reports App Router vs Pages Router, and prints
the detected test runner, E2E tool, RTL/MSW, and Zod presence.
