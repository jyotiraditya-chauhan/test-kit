---
name: flutter-testing
description: Writes unit, widget, golden, and integration tests for Flutter projects, detecting whether BLoC, Riverpod, Provider, or GetX is in use from pubspec.yaml before writing any business-logic test. Use when the user asks to write Flutter tests, add test coverage to a widget/bloc/provider/repository, test a .dart file, or mentions pubspec.yaml, flutter_test, mocktail, bloc_test, integration_test, or golden tests.
license: MIT
compatibility: Requires the Flutter SDK (flutter command) available on PATH for stack detection and optional test execution. Requires a pubspec.yaml declaring a flutter sdk dependency.
metadata:
  platform: flutter
  report-source: testing-methodologies-deep-research-report.txt Part 2 and Part 8
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
paths:
  - "**/*.dart"
  - "pubspec.yaml"
---

# Flutter Testing

Writes unit, widget, golden, and integration tests that match this
project's existing state-management, mocking, and directory conventions.
**Writing correct, well-structured test files is the deliverable.** Running
the suite and verifying it — including the fault-injection self-check — is
a separate, optional step this skill offers but never runs without being
asked. See [Step 6](#step-6--report-what-was-written-then-offer-to-verify).

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
Flutter project and reports which state-management package, mocking
library, golden-test helper, and Firebase fakes are already declared in
`pubspec.yaml`, plus whether `test/` already exists and mirrors `lib/`.

If a test framework or mocking library is already in use, follow it even if
a different tool is this skill's default recommendation. Never introduce a second,
competing library into a project that already picked one.

## Step 2 — Audit project structure

Before writing anything:
- Classify the target code: pure business logic (services, repositories,
  use-cases) vs UI layer (widgets) vs data-access (Firebase, API clients)
  vs cross-cutting (routing, DI). This decides the test type — don't default
  to a widget test for logic that's dressed up inside a widget file; if the
  architecture allows extracting it into a plain testable class/function,
  say so in the plan (Step 4) rather than testing it in place.
- Confirm the state-management package via [reference/state-management.md](reference/state-management.md)
  and select the matching harness pattern — never generate a BLoC-style test
  for a Riverpod provider or vice versa.
- Match the existing `test/` naming convention exactly (does it mirror
  `lib/` file-for-file already?). `scripts/scaffold_test_file.sh` creates a
  correctly-mirrored, non-destructive stub for a new test file if useful.
- Flag critical paths — authentication, payment/billing, any data-write
  operation, anything touching an external paid/rate-limited service — for
  elevated rigor (more edge cases; these are the tests where, if the user
  opts into verification in Step 7, the fault-injection check is
  mandatory rather than optional) even if the user's request was narrower.
  State this flag out loud; do not silently expand scope beyond what was
  asked.

## Step 3 — Ask the user what to test (never assume)

Ask a single message with two questions before generating anything:

1. **Layer**: unit tests only (pure logic) / widget tests only (UI) /
   integration tests / golden tests / a full mix appropriate to what's
   being tested. See [Which layer, for what](#which-layer-for-what) below.
2. **Scope**: does the user want the whole app tested, one feature/module
   tested end-to-end, or just specific file(s)/function(s)? Do not assume
   "the whole app" or "just this file" — ask explicitly and wait for the
   answer. If the user already named specific files or a feature in their
   original request, confirm that scope back to them rather than silently
   re-asking, but still confirm it.

Only skip re-asking if the user's original request already unambiguously
answered both questions.

### Which layer, for what

| Layer | Use for | Reference |
|---|---|---|
| Unit | Pure Dart logic — services, repositories, use-cases, formatters, validators. No widget tree. | [reference/unit-testing.md](reference/unit-testing.md) |
| Widget | A single widget or small tree — rendering, interaction, layout. | [reference/widget-testing.md](reference/widget-testing.md) |
| Golden | Pixel-level visual regression for small, stable design-system components. | [reference/golden-tests.md](reference/golden-tests.md) |
| Integration | Full app on a real device/emulator — the closest thing Flutter has to E2E. Reserve for critical, revenue-or-trust flows. | [reference/integration-testing.md](reference/integration-testing.md) |

If the user's request doesn't map cleanly to one layer (e.g. "test my
login feature"), default to the mix implied by
[reference/ci-and-distribution.md](reference/ci-and-distribution.md)'s
recommended shape — mostly unit, a solid slice of widget, integration only
for the actual critical path — and say so in the plan (Step 4).

## Step 4 — State the plan before generating

Before writing any test code, state explicitly: which layer(s), which
file(s)/function(s) are in scope, what will be mocked/faked vs exercised
for real (mock only at the true I/O boundary — network, Firebase, device
APIs — never a pure function or cheap same-layer collaborator), and the
specific edge cases planned (null/empty input, boundary values, error/
exception paths). This is the checkpoint for the user to redirect before
any code exists.

## Step 5 — Generate

- Follow the project's existing import style, naming, and fixture/setup
  patterns from Step 1-2 — do not introduce a different personal style.
- Structure every test as Arrange/Act/Assert, one Act per test.
- Every unit under test gets at minimum: one happy-path case, one null/
  empty/boundary case, one error/exception-path case — unless the user
  scoped it narrower in Step 3.
- Mock only at the true I/O boundary. See [reference/state-management.md](reference/state-management.md)
  for the BLoC/Riverpod/Provider harness pattern and
  [reference/firebase.md](reference/firebase.md) for Firebase fakes.
- Unit tests: [reference/unit-testing.md](reference/unit-testing.md).
- Widget tests: [reference/widget-testing.md](reference/widget-testing.md)
  — finder strategy, `pump` vs `pumpAndSettle`, interaction helpers.
- Golden tests: [reference/golden-tests.md](reference/golden-tests.md) —
  scope to design-system primitives, not full screens.
- Integration tests: [reference/integration-testing.md](reference/integration-testing.md)
  — `integration_test` and, for native-OS interactions, Patrol.
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
2. For every business-logic or critical-path test flagged in Step 2: run
   the fault-injection self-check in
   [reference/verification.md](reference/verification.md) exactly as
   written — mandatory within this verification pass, not optional. Any
   test that stays green against deliberately broken code must be
   rewritten before being counted as passing.
3. Check for accidental non-determinism in what was just generated: real
   file I/O, real network calls, unseeded randomness, `Future.delayed`
   instead of `pumpAndSettle`, order-dependence on other tests. Fix in
   place before presenting the result.
4. Report specifically: which layer(s) were run, which edge cases were
   covered, what was intentionally left out of scope and why, whether any
   test was flagged and rewritten, and the coverage delta if measurable.
   Never claim "fully tested" or "all done" without this detail — an
   overclaimed suite creates false confidence, which is worse than no test.

## Reference

- Unit test conventions and mocktail patterns: [reference/unit-testing.md](reference/unit-testing.md)
- Widget test patterns: finders, pump vs pumpAndSettle, interactions: [reference/widget-testing.md](reference/widget-testing.md)
- Golden test scope and flakiness fixes: [reference/golden-tests.md](reference/golden-tests.md)
- Integration tests with integration_test and Patrol: [reference/integration-testing.md](reference/integration-testing.md)
- State management harness patterns (BLoC/Riverpod/Provider/GetX): [reference/state-management.md](reference/state-management.md)
- Firebase fakes (fake_cloud_firestore, firebase_auth_mocks): [reference/firebase.md](reference/firebase.md)
- Recommended test-type distribution and CI gating: [reference/ci-and-distribution.md](reference/ci-and-distribution.md)
- Fault-injection self-check procedure — run only if the user asks for verification, follow verbatim when you do: [reference/verification.md](reference/verification.md)

## Scripts

- `scripts/detect_stack.sh` — run from the project root before generating
  any test. Prints the detected state-management package, mocking library,
  golden helper, Firebase fakes, and existing `test/` convention.
- `scripts/scaffold_test_file.sh <lib/path/to/file.dart>` — creates a
  correctly-mirrored, minimal stub test file under `test/`. Never
  overwrites an existing file. Optional convenience, not required.
