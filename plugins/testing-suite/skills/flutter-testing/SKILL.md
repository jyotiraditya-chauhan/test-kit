---
name: flutter-testing
description: Generates unit, widget, golden, and integration tests for Flutter projects, detecting whether BLoC, Riverpod, Provider, or GetX is in use from pubspec.yaml before writing any business-logic test. Use when the user asks to write Flutter tests, add test coverage to a widget/bloc/provider/repository, test a .dart file, or mentions pubspec.yaml, flutter_test, mocktail, bloc_test, or golden tests.
license: MIT
compatibility: Requires the Flutter SDK (flutter command) available on PATH. Requires a pubspec.yaml declaring a flutter sdk dependency.
metadata:
  platform: flutter
  report-source: testing-methodologies-deep-research-report.txt Part 2 and Part 8
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
paths:
  - "**/*.dart"
  - "pubspec.yaml"
---

# Flutter Testing

Generates unit, widget, golden, and integration tests that match this
project's existing state-management, mocking, and directory conventions,
then verifies every business-logic test actually asserts something
meaningful before reporting it as done.

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
  `lib/` file-for-file already?).
- Flag critical paths — authentication, payment/billing, any data-write
  operation, anything touching an external paid/rate-limited service — for
  elevated rigor (more edge cases, mandatory fault-injection check) even if
  the user's request was narrower. State this flag out loud; do not
  silently expand scope beyond what was asked.

## Step 3 — Ask the user what to test (never assume)

Ask a single message with two questions before generating anything:

1. **Layer**: unit tests only (pure logic) / widget tests only (UI) /
   integration tests / golden tests / a full mix appropriate to what's
   being tested.
2. **Scope**: does the user want the whole app tested, one feature/module
   tested end-to-end, or just specific file(s)/function(s)? Do not assume
   "the whole app" or "just this file" — ask explicitly and wait for the
   answer. If the user already named specific files or a feature in their
   original request, confirm that scope back to them rather than silently
   re-asking, but still confirm it.

Only skip re-asking if the user's original request already unambiguously
answered both questions.

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
- Golden tests: see [reference/golden-tests.md](reference/golden-tests.md)
  before writing one — scope to design-system primitives, not full screens.
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
3. Check for accidental non-determinism in what was just generated: real
   file I/O, real network calls, unseeded randomness, `Future.delayed`
   instead of `pumpAndSettle`, order-dependence on other tests. Fix in
   place before presenting the result.

## Step 7 — Report back

Summarize specifically: which layer(s) were tested, which edge cases were
covered, what was intentionally left out of scope and why, whether any test
was flagged and rewritten during Step 6, and the coverage delta if
measurable. Never claim "fully tested" or "all done" without this detail —
an overclaimed suite creates false confidence, which is worse than no test.

## Reference

- State management harness patterns (BLoC/Riverpod/Provider/GetX): [reference/state-management.md](reference/state-management.md)
- Firebase fakes (fake_cloud_firestore, firebase_auth_mocks): [reference/firebase.md](reference/firebase.md)
- Golden test scope and flakiness fixes: [reference/golden-tests.md](reference/golden-tests.md)
- Fault-injection self-check procedure (mandatory, follow verbatim): [reference/verification.md](reference/verification.md)

## Scripts

Run `scripts/detect_stack.sh` from the project root before generating any
test — it prints the detected state-management package, mocking library,
golden helper, Firebase fakes, and existing `test/` convention.
