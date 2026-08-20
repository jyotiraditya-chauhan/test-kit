---
name: react-testing
description: Generates unit, component, and integration tests for plain React web projects (Vite, Create React App, or any non-Next.js React app) using Vitest or Jest with React Testing Library and MSW for network mocking. Use when the user asks to test a React component or hook, mentions .tsx/.jsx files, Vitest, Jest, React Testing Library, RTL, or MSW, in a project whose package.json has react and react-dom but not next or react-native. For Next.js projects (an app/ or pages/ directory, next.config.*), use nextjs-testing instead. For React Native/Expo projects, use react-native-testing instead.
license: MIT
compatibility: Requires Node.js and the project's existing package manager (npm/pnpm/yarn). Requires a package.json declaring react and react-dom without next.
metadata:
  platform: react
  report-source: testing-methodologies-deep-research-report.txt Part 3 and Part 8
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "package.json"
---

# React Testing

Writes unit, component, and integration tests for plain React (non-Next)
projects, following the testing trophy model: a fat integration-test middle
using real state + MSW-mocked network, a thin unit layer for pure logic
only, and a small curated E2E layer. **Writing the test files is the
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
- [ ] 5. Generate tests following AAA, boundary-only (MSW) mocking
- [ ] 6. Report what was written; offer to run + verify — do not run yet
- [ ] 7. Only if asked: run tests, fault-injection self-check, report results
```

## Step 1 — Detect stack

Run `scripts/detect_stack.sh` from the project root. It confirms this is a
plain React web project (not Next.js, not React Native — the script errors
out and points to `nextjs-testing` if `next` is present, or
`react-native-testing` if `react-native` is present), and reports the
existing test runner (Vitest/Jest), RTL/user-event, MSW, Playwright/Cypress,
and test file convention (co-located `*.test.tsx` vs `__tests__/`).

If a test runner or mocking library is already in use, follow it even if a
different tool is this skill's default recommendation. Never introduce a second,
competing test runner into a project that already picked one.

## Step 2 — Audit project structure

Before writing anything:
- Classify the target: a pure function (formatter, calculator, reducer) vs
  a component that fetches/renders/handles-errors vs a custom hook. Most
  components in a modern app are integration code, not meaningful "units" —
  default to a component/integration test for anything that renders,
  reserve pure unit tests for genuinely pure logic. See
  [reference/test-layers.md](reference/test-layers.md).
- Match the existing test file convention exactly (co-located vs
  `__tests__/`) from Step 1.
- Flag critical paths — authentication, payment/billing, any data-write
  operation — for elevated rigor even if the user's request was narrower.
  State this flag out loud; do not silently expand scope.

## Step 3 — Ask the user what to test (never assume)

Ask a single message with two questions before generating anything:

1. **Layer**: unit tests only (pure logic) / component tests only /
   integration tests (component + real state + MSW network) / a mix
   appropriate to what's being tested.
2. **Scope**: does the user want the whole app tested, one feature/module
   tested end-to-end, or just specific file(s)/component(s)? Do not assume
   "the whole app" or "just this file" — ask explicitly and wait for the
   answer. If the user's original request already named specific files or
   a feature, confirm that scope back to them rather than silently
   re-asking, but still confirm it.

Only skip re-asking if the user's original request already unambiguously
answered both questions.

## Step 4 — State the plan before generating

State explicitly: which layer(s), which file(s)/component(s) are in scope,
what will be mocked vs exercised for real (MSW at the network boundary
only — never mock a pure function or a same-layer collaborator), and the
specific edge cases planned (empty/loading state, error state, boundary
props). This is the checkpoint for the user to redirect before code exists.

If the confirmed scope is large — the whole app, a big feature, more
components/files than fit comfortably in one pass — say so and propose a
prioritized, batched plan instead of attempting to generate everything at
once. State the first batch, confirm it, then continue rather than
silently truncating or silently attempting all of it in one shot.

## Step 5 — Generate

- Follow the project's existing import style, naming, and setup/fixture
  patterns from Step 1-2.
- Structure every test as Arrange/Act/Assert, one Act per test.
- Every unit under test gets at minimum: one happy-path case, one boundary/
  empty case, one error-path case — unless the user scoped it narrower.
- Query priority and `user-event` usage: see
  [reference/testing-library.md](reference/testing-library.md).
- Network mocking: see [reference/mocking-msw.md](reference/mocking-msw.md)
  — mock only at the network boundary via MSW, never at the module level.
- Do not generate an E2E/Playwright test for something a component or
  integration test covers just as well; see
  [reference/e2e-and-antipatterns.md](reference/e2e-and-antipatterns.md).
- Comments are the exception, not the default. Start each generated file
  with one short header comment stating what the file covers (e.g.
  `// Tests for LoginForm: submit happy path, validation errors, loading
  state.`) — this is the only comment every file gets. Beyond that, add
  an inline comment only when the reason for a specific setup value or
  edge case genuinely isn't obvious from the test name and code itself,
  never to narrate what a line does. Most files should end up with just
  the header and zero or one inline comments total.
- Before reporting anything, re-read every assertion you just wrote and
  flag or strengthen any that don't check a specific value, string, or
  state — a bare `.not.toThrow()`, a test that only confirms a component
  rendered without checking its content, a snapshot with no accompanying
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
3. Check for accidental non-determinism: real network calls not routed
   through MSW, unseeded randomness, `setTimeout`-based waits instead of
   RTL's `findBy`/`waitFor`, order-dependence on other tests. Fix in place.
4. Report specifically: which layer(s) were run, which edge cases were
   covered, what was intentionally left out of scope and why, whether any
   test was flagged and rewritten, and the coverage delta if measurable.
   Never claim "fully tested" or "all done" without this detail.

## Reference

- RTL query priority, user-event, testing hooks: [reference/testing-library.md](reference/testing-library.md)
- MSW network-boundary mocking: [reference/mocking-msw.md](reference/mocking-msw.md)
- Unit vs component vs integration, distribution shape, snapshot caution: [reference/test-layers.md](reference/test-layers.md)
- Playwright/Cypress and explicit anti-patterns: [reference/e2e-and-antipatterns.md](reference/e2e-and-antipatterns.md)
- Fault-injection self-check procedure — run only if the user asks for verification, follow verbatim when you do: [reference/verification.md](reference/verification.md)

## Scripts

Run `scripts/detect_stack.sh` from the project root before generating any
test — it confirms this is a plain React (not Next.js) project and prints
the detected test runner, RTL, MSW, and E2E tooling.
