---
name: react-native-testing
description: Generates unit, component, and E2E-flow tests for React Native projects, both Expo (managed or bare) and plain React Native CLI, using Jest (jest-expo or the react-native preset) with React Native Testing Library, plus Maestro or Detox for E2E. Use when the user asks to test a React Native screen, component, or hook, mentions Expo, expo-router, jest-expo, React Native Testing Library, Maestro, or Detox, or has a package.json declaring react-native. For a web React app without react-native, use react-testing instead; for Flutter, use flutter-testing.
license: MIT
compatibility: Requires Node.js and the project's existing package manager. Requires a package.json declaring react-native.
metadata:
  platform: react-native
  report-source: independent research (Expo/expo-router/jest-expo official docs, Maestro and Detox official docs) conducted for this skill, no corresponding section in testing-methodologies-deep-research-report.txt
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
paths:
  - "**/*.tsx"
  - "**/*.jsx"
  - "app/**"
  - "package.json"
---

# React Native Testing

Writes unit, component, and E2E-flow tests for React Native projects,
covering Expo (managed and bare) and plain React Native CLI in one skill,
branching on whichever is actually detected. **Writing the test files is
the deliverable.** Running the suite and verifying it — including the
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
React Native project (the script errors out and points to `react-testing`
if `react-native` isn't declared), identifies which of the three workflows
applies — Expo managed, Expo bare, or plain React Native CLI — and reports
the existing test runner preset, React Native Testing Library (RNTL),
state-management library, expo-router presence, E2E tooling, and test file
convention already in use.

The workflow determines the correct Jest preset: `jest-expo` for both Expo
managed and Expo bare, the plain `react-native` preset for RN CLI without
Expo. Never mix these up, and never introduce a second, competing test
runner into a project that already picked one.

## Step 2 — Audit project structure

Before writing anything:
- Classify the target: a pure function (formatter, selector, hook logic
  with no native calls) vs a screen/component that renders and handles
  user interaction vs a native-module-touching piece of code (camera,
  location, clipboard, notifications). See
  [reference/component-testing.md](reference/component-testing.md) and
  [reference/native-module-mocking.md](reference/native-module-mocking.md).
- If `expo-router` is present, check whether the target is a route file
  under `app/`. Route-level behavior (navigation, params, deep links)
  needs `expo-router/testing-library`, not a plain component render — see
  [reference/expo-router-testing.md](reference/expo-router-testing.md).
  Never place a test file inside `app/` itself; expo-router treats every
  file there as a route.
- Match the existing test file convention (`__tests__/` vs co-located
  `*-test.tsx`/`*.test.tsx`) from Step 1.
- Identify the state-management library in use (Zustand, Redux Toolkit,
  Jotai, MobX, or none) from Step 1 — see
  [reference/state-management.md](reference/state-management.md) for how
  to set up or bypass a real store per library.
- Flag critical paths — authentication, payment, any data-write operation
  — for elevated rigor even if the user's request was narrower. State this
  flag out loud; do not silently expand scope.

## Step 3 — Ask the user what to test (never assume)

Ask a single message with two questions before generating anything:

1. **Layer**: unit tests only (pure logic/hooks) / component tests
   (RNTL, rendering + interaction) / route-level tests via
   `expo-router/testing-library` (only relevant if expo-router is present)
   / an E2E flow (Maestro or Detox) / a mix appropriate to what's being
   tested.
2. **Scope**: does the user want the whole app tested, one screen/feature
   tested end-to-end, or just specific file(s)/component(s)? Do not assume
   "the whole app" or "just this file" — ask explicitly and wait for the
   answer. If the user's original request already named specific files or
   a feature, confirm that scope back to them rather than silently
   re-asking, but still confirm it.

Only skip re-asking if the user's original request already unambiguously
answered both questions.

## Step 4 — State the plan before generating

State explicitly: which layer(s), which file(s)/screen(s) are in scope,
what will be mocked vs exercised for real (mock only true boundaries —
a native module, a network call — never a same-layer collaborator or the
state store itself unless the layer is a pure-logic unit test), and the
specific edge cases planned (loading/empty state, error state, permission-
denied for a native module, boundary props). This is the checkpoint for
the user to redirect before any code exists.

If the confirmed scope is large — the whole app, a big feature, more
screens/files than fit comfortably in one pass — say so and propose a
prioritized, batched plan instead of attempting to generate everything at
once. State the first batch, confirm it, then continue rather than
silently truncating or silently attempting all of it in one shot.

## Step 5 — Generate

- Follow the project's existing import style, naming, and setup/fixture
  patterns from Step 1-2.
- Structure every test as Arrange/Act/Assert, one Act per test.
- Every unit under test gets at minimum: one happy-path case, one boundary/
  empty case, one error-path case — unless the user scoped it narrower.
- Component rendering and interaction: see
  [reference/component-testing.md](reference/component-testing.md) — query
  by accessible role/text/testID, never by implementation detail, and
  always `waitFor`/`findBy*` around async state instead of a raw
  `setTimeout`.
- Native module mocking: see
  [reference/native-module-mocking.md](reference/native-module-mocking.md)
  — mock at the native-module boundary only, matching `jest-expo`'s
  auto-mocks where they exist and writing a fake in `mocks/` when they
  don't.
- Route-level tests: see
  [reference/expo-router-testing.md](reference/expo-router-testing.md).
- State management setup: see
  [reference/state-management.md](reference/state-management.md).
- E2E flows: see
  [reference/e2e-maestro-and-detox.md](reference/e2e-maestro-and-detox.md)
  — default to Maestro when no E2E tool is already present, since it needs
  no in-repo package install; use Detox instead if the project already has
  it configured or the user asks for tighter JS-thread synchronization.
- Keep comments in generated test code minimal — at most one short comment
  per test, only where the reason for a specific setup value or edge case
  isn't obvious from the test name and code itself. Do not narrate what
  each line does.
- Before reporting anything, re-read every assertion you just wrote and
  flag or strengthen any that don't check a specific value, prop, or
  state — a bare "renders without crashing" test with no content
  assertion, a native-module mock check that only confirms it was called
  without checking with what, a snapshot with no accompanying explicit
  assertion. This costs nothing (no execution required, just rereading
  what was just generated) and is the highest-leverage check against the
  failure mode this plugin exists to prevent. Note in Step 6 if anything
  was strengthened during this pass.

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
3. Check for accidental non-determinism: an unawaited async state update, a
   real native-module call that should have been mocked, a raw
   `setTimeout` instead of `waitFor`/`findBy*`, order-dependence on other
   tests. Fix in place before presenting the result.
4. Report specifically: which layer(s) were run, which edge cases were
   covered, what was intentionally left out of scope and why, whether any
   test was flagged and rewritten, and the coverage delta if measurable.
   Never claim "fully tested" or "all done" without this detail.

## Reference

- Component rendering, queries, interaction: [reference/component-testing.md](reference/component-testing.md)
- Native module and Expo SDK mocking: [reference/native-module-mocking.md](reference/native-module-mocking.md)
- expo-router route-level testing: [reference/expo-router-testing.md](reference/expo-router-testing.md)
- Maestro and Detox E2E testing: [reference/e2e-maestro-and-detox.md](reference/e2e-maestro-and-detox.md)
- State management setup per library: [reference/state-management.md](reference/state-management.md)
- Fault-injection self-check procedure — run only if the user asks for verification, follow verbatim when you do: [reference/verification.md](reference/verification.md)

## Scripts

Run `scripts/detect_stack.sh` from the project root before generating any
test — it confirms this is a React Native project, identifies the workflow
(Expo managed / Expo bare / plain RN CLI), and prints the detected test
runner preset, RNTL, state-management library, expo-router presence, and
E2E tooling.
