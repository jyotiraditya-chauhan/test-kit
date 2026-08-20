# Fault-Injection Self-Check

Run this procedure only when the user has asked you to run or verify the
tests (SKILL.md Step 7). It is never triggered automatically just because
tests were generated. Once triggered, it is a mandatory, low-freedom
procedure: follow it exactly, in this order, for every business-logic or
critical-path test (auth, payment, any data-write path) in scope. Do not
skip steps, do not substitute your own variation, do not summarize it away.

Why this exists: code coverage measures which lines executed, not whether
the test actually verifies anything. It is common for a generated test to
hit 100% line coverage while asserting nothing meaningful. This procedure
is a lightweight, single-test-scoped approximation of mutation testing that
catches that failure mode in seconds, with no extra tooling.

## Procedure

1. Run the new test against the real, unmodified implementation. Confirm
   it is GREEN. If it is red against correct code, the test itself is
   wrong. Fix the test now, do not touch the implementation to satisfy a
   bad test.

2. Open the implementation file (component, hook, or store action) the
   test targets. Introduce exactly ONE small, obvious fault, chosen from
   this list, in the specific line(s) the new test is meant to cover:
   - Flip a comparison operator (`>` to `>=`, `===` to `!==`, `&&` to `||`).
   - Change a returned literal, default prop, or state value (`true` to
     `false`, a default count of `0` to `1`).
   - Skip an early-return/guard branch (comment it out or invert its
     condition), e.g. a permission check or a validation early-return.
   - For a native-module delegation, change the argument passed to the
     mocked call (e.g. pass the wrong string to `setStringAsync`).

3. Re-run the exact same new test (not the whole suite, just this test):
   `jest <path> -t "<test name>"` or the project's Vitest equivalent.

4. Confirm it now FAILS (goes RED). This is the required outcome.
   - If it fails: the test is verifying real behavior. Proceed to step 5.
   - If it still PASSES against the deliberately broken code: the test is
     flagged as weak. Do not count it as passing coverage. Rewrite the
     assertion to check the actual value/prop/call, and restart this
     procedure from step 1 for the rewritten test.

5. Revert the deliberate fault immediately. Restore the implementation
   file to its exact original state. Re-run the test once more to confirm
   it is GREEN again against the real, correct implementation.

6. Record which tests were fault-injection-checked and whether any were
   rewritten, for the final report back to the user.

## Non-negotiable rules

- Never run this procedure unless the user asked for verification. Writing
  the test is the deliverable on its own; this is an add-on, not a
  default.
- Never leave the deliberate fault in the implementation file. Step 5 is
  not optional.
- Never delete or disable a test to make it pass. A test that fails against
  correct code gets fixed, not removed. A test that passes against broken
  code gets rewritten, not accepted.
- Apply this to screens/components with real logic, native-module
  delegation, and state-store actions on critical paths always. For
  trivial presentational components with no branching logic, it is
  optional. Note in the final report if it was skipped and why.
- This procedure is JS/TS-level only. It does not extend to Maestro/Detox
  E2E flows — those are verified by simply running the flow and confirming
  it passes against the real app; fault-injecting a full native build for
  a single E2E assertion is out of scope for this skill.
