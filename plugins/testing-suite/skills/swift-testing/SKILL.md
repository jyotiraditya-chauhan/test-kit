---
name: swift-testing
description: Generates unit, view-model, and snapshot tests for Swift/SwiftUI iOS and macOS projects, using Swift Testing (@Test/#expect) for new code and XCTest where it already exists. Tests the ObservableObject/@Observable view model directly rather than trying to introspect a SwiftUI view's private tree. Use when the user asks to write Swift or SwiftUI tests, test a ViewModel/@Observable class, or mentions .xcodeproj, Package.swift, XCTest, Swift Testing, @Test, or swift-snapshot-testing.
license: MIT
compatibility: Requires Xcode / the Swift toolchain (xcodebuild or swift test) available. Requires a .xcodeproj, .xcworkspace, or Package.swift.
metadata:
  platform: swift
  report-source: testing-methodologies-deep-research-report.txt Part 5 and Part 8
allowed-tools: Read, Write, Edit, Grep, Glob, Bash
paths:
  - "**/*.swift"
  - "Package.swift"
---

# Swift / SwiftUI Testing

Writes unit, view-model, and snapshot tests for Swift/SwiftUI projects.
The central pattern: SwiftUI has no public view-tree introspection, so
business logic is tested via the view model, not the view — see
[reference/view-model-testing.md](reference/view-model-testing.md) before
generating anything against a view file directly. **Writing the test files
is the deliverable.** Running the suite and verifying it — including the
fault-injection self-check — is a separate, optional step this skill
offers but never runs without being asked. See
[Step 6](#step-6--report-what-was-written-then-offer-to-verify).

## Progress checklist

Copy this into your response and check items off as you go:

```
- [ ] 1. Detect stack + existing test framework (scripts/detect_stack.sh)
- [ ] 2. Audit project structure and existing conventions
- [ ] 3. Ask the user what to test (layer + scope) — do not assume
- [ ] 4. State the test plan explicitly
- [ ] 5. Generate tests following AAA, boundary-only mocking/fakes
- [ ] 6. Report what was written; offer to run + verify — do not run yet
- [ ] 7. Only if asked: run tests, fault-injection self-check, report results
```

## Step 1 — Detect stack

Run `scripts/detect_stack.sh` from the project root. It confirms this is a
Swift project (`.xcodeproj`/`.xcworkspace`/`Package.swift`) and reports
whether Swift Testing (`@Test`), XCTest, or both are already in use, plus
`swift-snapshot-testing`, `ViewInspector`, and Core Data/SwiftData
presence.

If a test framework is already in use, follow it even if a different tool
is this skill's default recommendation (Swift Testing for new code). Never generate
an `XCTAssert*` call inside a `@Test` function or vice versa — see
[reference/swift-testing-vs-xctest.md](reference/swift-testing-vs-xctest.md);
the two frameworks are not cross-compatible and a misplaced assertion
silently never registers as a failure.

## Step 2 — Audit project structure

Before writing anything:
- Classify the target: a plain type/service (fully testable in isolation)
  vs a view model (`ObservableObject`/`@Observable` — test this directly,
  never the view) vs a SwiftUI view itself (needs extraction or
  `ViewInspector` — see
  [reference/view-model-testing.md](reference/view-model-testing.md)) vs
  UI automation/performance (XCTest-only, Swift Testing does not cover
  these — see
  [reference/swift-testing-vs-xctest.md](reference/swift-testing-vs-xctest.md)).
- Match the existing test target/file naming convention.
- Flag critical paths — authentication, payment/billing, any data-write
  operation — for elevated rigor even if the user's request was narrower.
  State this flag out loud; do not silently expand scope.
- **Known gap, say so rather than guessing**: this skill does not have
  reliable, researched guidance on testing on-device AI features built on
  Apple's Foundation Models framework. If asked to test one, say plainly
  that this is an under-researched area rather than presenting invented
  conventions as established practice.

## Step 3 — Ask the user what to test (never assume)

Ask a single message with two questions before generating anything:

1. **Layer**: unit/view-model tests only / snapshot tests only / UI
   automation (XCTest) / a mix appropriate to what's being tested.
2. **Scope**: does the user want the whole app tested, one feature/screen
   tested end-to-end, or just specific file(s)/type(s)? Do not assume — ask
   explicitly and wait for the answer. If the user's original request
   already named specific files or a feature, confirm that scope back to
   them rather than silently re-asking, but still confirm it.

Only skip re-asking if the user's original request already unambiguously
answered both questions.

## Step 4 — State the plan before generating

State explicitly: which layer(s), which type(s)/file(s) are in scope,
whether an extraction (view logic → view model) is being proposed and why,
what will be faked vs exercised for real (in-memory Core Data/SwiftData
store, not the real on-disk store; mock only true I/O boundaries), and the
specific edge cases planned. This is the checkpoint for the user to
redirect before any code exists.

## Step 5 — Generate

- Follow the project's existing naming and setup patterns from Step 1-2.
- Structure every test as Arrange/Act/Assert, one Act per test.
- Every unit under test gets at minimum: one happy-path case, one boundary/
  empty case, one error-path case — unless the user scoped it narrower.
- Prefer Swift Testing (`@Test`/`#expect`) for new tests; match XCTest only
  where the project already uses it for that target.
- View-model testing pattern: [reference/view-model-testing.md](reference/view-model-testing.md).
- Snapshot tests and in-memory persistence: [reference/snapshot-and-persistence.md](reference/snapshot-and-persistence.md)
  — scope snapshots to small, stable components, not full screens.
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
2. For every business-logic or critical-path test (view models,
   authentication, payment logic): run the fault-injection self-check in
   [reference/verification.md](reference/verification.md) exactly as
   written — mandatory within this verification pass, not optional. Any
   test that stays green against deliberately broken code must be
   rewritten before being counted as passing coverage.
3. Check for accidental non-determinism: real network calls, an on-disk
   store instead of an in-memory one, unpinned simulator/locale/timezone
   affecting a snapshot, order-dependence on other tests. Fix in place.
4. Report specifically: which layer(s) were run, which edge cases were
   covered, what was intentionally left out of scope and why, whether any
   test was flagged and rewritten, and the coverage delta if measurable.
   Never claim "fully tested" or "all done" without this detail.

## Reference

- Swift Testing vs XCTest, translation table, coexistence rules: [reference/swift-testing-vs-xctest.md](reference/swift-testing-vs-xctest.md)
- View-model-first testing pattern, ViewInspector as secondary, async/Combine: [reference/view-model-testing.md](reference/view-model-testing.md)
- swift-snapshot-testing usage and scope, in-memory Core Data/SwiftData: [reference/snapshot-and-persistence.md](reference/snapshot-and-persistence.md)
- Fault-injection self-check procedure — run only if the user asks for verification, follow verbatim when you do: [reference/verification.md](reference/verification.md)

## Scripts

Run `scripts/detect_stack.sh` from the project root before generating any
test — it confirms the Swift project type and prints which test framework,
snapshot library, and persistence layer are already in use.
