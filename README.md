# Test-kit

**A Claude Code plugin marketplace for stack-aware test writing.**

`test-kit` hosts **testing-suite**, one plugin bundling five platform skills:
Flutter, React, Next.js, Swift/SwiftUI, and Node/Express. Each one detects a
project's real stack and conventions, asks before assuming what to test, and
writes tests that follow the project's own style. Flutter gets the deepest
coverage of the five. Unit, widget, golden, and integration tests are each
treated as first-class, not an afterthought behind widget tests.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-5A45FF.svg)](https://code.claude.com/docs/en/plugins)
[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](plugins/testing-suite/.claude-plugin/plugin.json)
[![Skills](https://img.shields.io/badge/skills-5-informational.svg)](#the-five-skills)

---

## What this does (and doesn't do)

**This plugin writes test files. That's the deliverable.** Every skill
detects your stack, asks what you want tested, plans, and writes real,
correctly structured test files that match your project's conventions.
Then it stops.

By default it does **not** run your tests, report coverage, or grade your
codebase. If you want a generated suite actually executed and verified,
including the [fault-injection self-check](#the-fault-injection-self-check)
described below, just ask, in the same request or a follow-up. Every skill
offers this after writing tests, but none of them do it unless you say
yes. Nothing runs silently, and no test is ever reported as passing unless
it was actually run.

| | |
|---|---|
| ✅ Writes unit, widget, component, golden/snapshot, and integration tests | ❌ Does not run your CI pipeline or lint your codebase |
| ✅ Matches your existing test framework, mocking library, and file conventions | ❌ Does not silently rewrite or delete your existing tests |
| ✅ Asks which layer and scope before generating anything | ❌ Does not assume "test everything" or "test just this file" |
| ✅ Runs and verifies tests **when you ask it to** | ❌ Does not run `flutter test` / `npm test` / `xcodebuild` on its own |

## Why this exists

AI-written tests fail in a specific, well-documented way, and it isn't
because the model can't code. A controlled study comparing agent-generated
tests to human-written ones (using AST-based analysis, not just eyeballing
the diffs) found agents genuinely better at edge-case breadth: nearly
double the boundary-condition variety of human authors. But they were
measurably weaker on precision. 11.58% of agent-written assertions were
ambiguous or effectively unclassifiable, against 1.46% for humans, and
agent-generated suites carried a higher flakiness-candidate rate (0.41 vs
0.30), mostly from non-deterministic file I/O and timing assumptions a
human author would instinctively avoid.

The sharper problem doesn't show up on a coverage dashboard. Left alone,
an agent tends to write the implementation first, then write tests that
confirm what that implementation *already does*, not what it *should* do.
A test built this way can hit 100% line coverage while asserting nothing.
It's a mirror of the bug, not a check against it. A 2026 SmartBear survey
of 273 software leaders found 70% already see application quality
degrading as AI accelerates development. Separately, 58% of developers
say they trust AI-generated output without testing it at all. Polish
reads as correctness, and it isn't.

Every skill in this plugin is built to push back against that: plan
before generating, mock only at the true I/O boundary, and write strong,
specific assertions. When you ask for verification, it also runs a
**fault-injection self-check** that deliberately breaks the
implementation and confirms the new test actually notices, before
reverting the break. A test that stays green against known-broken code
gets rewritten, not accepted. This check is available on request, not
automatic. See
[What this does (and doesn't do)](#what-this-does-and-doesnt-do) above
and [The fault-injection self-check](#the-fault-injection-self-check)
below.

## Installation

Inside Claude Code:

```
/plugin marketplace add jyotiraditya-chauhan/test-kit
/plugin install testing-suite@test-kit-marketplace
```

Or non-interactively:

```bash
claude plugin marketplace add jyotiraditya-chauhan/test-kit
claude plugin install testing-suite@test-kit-marketplace
```

## Usage

Just ask. The matching skill triggers automatically from your project's
manifest files (`pubspec.yaml`, `package.json`, `.xcodeproj`, `next.config.*`):

```
Write widget tests for my LoginButton widget
Add Supertest coverage for the POST /api/orders route
Test my CheckoutSummary component with RTL
```

Or invoke a skill directly, namespaced under the plugin:

```
/testing-suite:flutter-testing
/testing-suite:react-testing
/testing-suite:nextjs-testing
/testing-suite:swift-testing
/testing-suite:node-testing
```

By default you'll get the test files and a summary of what each test
covers. Add "and run them" or "and verify they work" to the same request
if you also want them executed and fault-injection-checked.

## The five skills

| Skill | Command | Fires on | Default stack |
|---|---|---|---|
| **flutter-testing** | `/testing-suite:flutter-testing` | `pubspec.yaml` with a `flutter:` SDK dependency | `flutter_test`, `mocktail`, `bloc_test` / `ProviderContainer`, `golden_toolkit`, `integration_test` / Patrol |
| **react-testing** | `/testing-suite:react-testing` | `package.json` with `react`+`react-dom`, no `next` | Vitest/Jest, React Testing Library, MSW |
| **nextjs-testing** | `/testing-suite:nextjs-testing` | `package.json` with `next` | Vitest (Server Actions, sync components) + Playwright (async Server Components, auth, checkout) |
| **swift-testing** | `/testing-suite:swift-testing` | `.xcodeproj` / `.xcworkspace` / `Package.swift` | Swift Testing (`@Test`/`#expect`), XCTest where it already exists, `swift-snapshot-testing` |
| **node-testing** | `/testing-suite:node-testing` | `package.json` with `express`/`fastify`/`koa`/`@nestjs/core` | Supertest against the app instance, Vitest/Jest, testcontainers |

No two skills can plausibly fire on the same request. Each
`scripts/detect_stack.sh` hard-fails and names the correct sibling skill
when it detects the wrong stack. `react-testing` refuses a `next`
dependency, `node-testing` refuses a project with no backend framework,
and so on. This was verified directly: running each skill against every
other skill's fixture project produces a clean decline, not a
wrong-platform test.

## Flutter, in depth

Flutter gets the deepest treatment in this plugin. All four test types are
equally first-class, each with its own reference doc, rather than being
folded into a generic "widget testing" default:

| Layer | What it's for | Tooling | Reference |
|---|---|---|---|
| **Unit** | Pure Dart logic: services, repositories, formatters, validators. No widget tree. | `package:test`, `mocktail` | [`reference/unit-testing.md`](plugins/testing-suite/skills/flutter-testing/reference/unit-testing.md) |
| **Widget** | A single widget or small tree: rendering, interaction, layout. | `flutter_test`, `WidgetTester` | [`reference/widget-testing.md`](plugins/testing-suite/skills/flutter-testing/reference/widget-testing.md) |
| **Golden** | Pixel-level visual regression for small, stable design-system components. | `golden_toolkit` / `alchemist` | [`reference/golden-tests.md`](plugins/testing-suite/skills/flutter-testing/reference/golden-tests.md) |
| **Integration** | Full app on a real device or emulator, Flutter's closest thing to E2E. Reserved for critical flows. | `integration_test`, Patrol for native-OS interactions | [`reference/integration-testing.md`](plugins/testing-suite/skills/flutter-testing/reference/integration-testing.md) |

There are also cross-cutting reference docs that apply across all four
layers:

- [`reference/state-management.md`](plugins/testing-suite/skills/flutter-testing/reference/state-management.md): detects BLoC, Riverpod, Provider, or GetX from `pubspec.yaml` and picks the matching harness. A BLoC-style test never gets generated for a Riverpod provider, or vice versa.
- [`reference/firebase.md`](plugins/testing-suite/skills/flutter-testing/reference/firebase.md): `fake_cloud_firestore` and `firebase_auth_mocks` patterns, including security-rules testing and when to reach for the real Firebase emulator instead.
- [`reference/ci-and-distribution.md`](plugins/testing-suite/skills/flutter-testing/reference/ci-and-distribution.md): the recommended ~60/25/10/5 unit/widget/integration/golden shape, and why integration tests alone justify macOS CI runners while everything else can stay on cheaper Linux ones.

Two scripts are specific to Flutter:

- `scripts/detect_stack.sh` confirms the project and reports the
  state-management package, mocking library, golden-test helper, Firebase
  fakes, and existing `test/` convention already in use.
- `scripts/scaffold_test_file.sh lib/path/to/file.dart` is a small,
  deterministic convenience. It creates the correctly mirrored `test/`
  stub file for a given `lib/` source file and never overwrites an
  existing test. It's optional. The skill doesn't require it, it just
  saves a step.

You can ask for any single layer directly ("write unit tests for
`OrderService`", "add a golden test for `ProductCard`", "write an
integration test for the checkout flow") or let the skill propose the
right mix for what you're testing. Left to its own judgment, it defaults
to a pyramid shape: mostly unit, a solid slice of widget, integration
reserved for the genuinely critical path.

## How every skill works

Every skill runs the same seven-step procedure, adapted per platform. This
is the operational backbone documented in each `SKILL.md`:

```
1. Detect the stack       -> scripts/detect_stack.sh fingerprints the
                              manifest and existing test tooling. An
                              existing convention always wins over this
                              skill's own default.
2. Audit the project       -> classify target code (pure logic / UI /
                              data-access), match existing naming, flag
                              critical paths (auth, payment, data-writes).
3. Ask, don't assume       -> one message, two questions: which layer
                              (unit/widget/integration/...), and which
                              scope (whole app, one feature, or specific
                              files). Never inferred silently.
4. State the plan          -> what's in scope, what's mocked vs real, and
                              the specific edge cases, before any code
                              exists. The checkpoint to redirect.
5. Generate                -> AAA structure, boundary-only mocking,
                              matches the project's existing style,
                              minimal comments.
6. Report, then offer      -> list what was written and what each test
                              covers. Nothing is run. Offer to run and
                              verify -- do not do it unless asked.
7. Only if asked           -> run the tests, run the mandatory
                              fault-injection check on business-logic
                              tests, report honestly what's covered.
```

Step 6 is where most requests end, and that's by design. See
[What this does (and doesn't do)](#what-this-does-and-doesnt-do).

## The fault-injection self-check

This only runs when you ask for verification (Step 7 above), but once
triggered, it's the plugin's one non-negotiable, low-freedom procedure.
Every `reference/verification.md` states it almost word for word rather
than as a loose suggestion, because it's the single highest-leverage
defense against the self-confirmation trap described above:

1. Run the new test against the real implementation. Confirm it's green.
2. Deliberately introduce one small, obvious fault: flip a comparison
   operator, swap a returned literal, skip a guard branch.
3. Re-run the same test. It **must** now fail.
4. If it still passes against broken code, the test gets flagged as weak
   and rewritten. It's never silently counted as passing coverage.
5. Revert the fault. Confirm the test is green again against the real
   implementation.

This was verified for real, not just described. In a live end-to-end run
against a Node/Express fixture, the skill generated a
`calculateShippingCost` test suite, ran the fault-injection check on
request, and reverted cleanly. The implementation file came back
byte-identical to its original, and every generated assertion checked an
exact value (`toBe`, `toBeCloseTo`, a specific thrown message), not just
that a call didn't throw.

## Worked example

**Default behavior, just asking for tests:**

**Prompt:** *"Add tests for the calculateShippingCost function in
src/services/shipping.js, it's pure logic."*

```js
// src/services/shipping.test.js (written)
import { describe, it, expect } from 'vitest';
import { calculateShippingCost } from './shipping.js';

describe('calculateShippingCost', () => {
  it('calculates standard cost as weight * 2.5', () => {
    expect(calculateShippingCost(1)).toBe(2.5);
    expect(calculateShippingCost(4)).toBe(10);
  });
  it('applies a 1.5x multiplier when expedited', () => {
    expect(calculateShippingCost(4, true)).toBe(15);
  });
  it('defaults to standard (non-expedited) when the flag is omitted', () => {
    expect(calculateShippingCost(2)).toBe(calculateShippingCost(2, false));
  });
  it('handles fractional weights', () => {
    expect(calculateShippingCost(0.5)).toBeCloseTo(1.25);
  });
  it('throws when weight is zero', () => {
    expect(() => calculateShippingCost(0)).toThrow('weight must be positive');
  });
  it('throws when weight is negative', () => {
    expect(() => calculateShippingCost(-3)).toThrow('weight must be positive');
  });
});
```

> Wrote `src/services/shipping.test.js` with 6 cases: standard cost,
> expedited multiplier, default-flag equivalence, fractional weight, and
> both zero and negative error paths. **Not run yet. Want me to run these
> and verify them before you review them?**

**If you say yes** (here or in a follow-up), Step 7 kicks in for real.
The suite gets executed, the fault-injection check deliberately breaks
`calculateShippingCost` (say, by swapping the `2.5` rate), re-runs the
same tests, confirms they go red, then restores the file to its original
state. That's the proof the suite would actually catch a regression, not
just that it runs.

## Repository layout

```
.claude-plugin/
  marketplace.json              # this marketplace's catalog
plugins/
  testing-suite/
    .claude-plugin/
      plugin.json                # plugin manifest (v2.0.0)
    skills/
      flutter-testing/
        SKILL.md
        reference/                # unit, widget, golden, integration,
                                   # state management, Firebase fakes,
                                   # CI/distribution, fault-injection
        scripts/                  # detect_stack.sh, scaffold_test_file.sh
        evals/evals.json
      react-testing/               # same shape
      nextjs-testing/              # same shape
      swift-testing/               # same shape
      node-testing/                # same shape
    README.md
README.md                          # this file
LICENSE
```

## Local development

```bash
claude --plugin-dir ./plugins/testing-suite
/testing-suite:flutter-testing
/reload-plugins        # after editing anything other than SKILL.md text
```

Validate before committing. Both are expected to pass with zero warnings:

```bash
claude plugin validate ./plugins/testing-suite --strict
claude plugin validate . --strict
```

## FAQ

**Does it run my tests automatically?**
No. It writes them and tells you what each one covers, then offers to run
and verify. It only executes anything if you say yes. See
[What this does (and doesn't do)](#what-this-does-and-doesnt-do).

**Do I need the Flutter SDK, Node, or Xcode installed for it to write tests?**
Not for writing. Stack *detection* (`scripts/detect_stack.sh`) reads your
manifest files and doesn't need the toolchain. You only need the real
toolchain installed if you ask the skill to actually run and verify
tests.

**Will it overwrite my existing tests?**
No. Every skill detects your existing test framework, mocking library,
and file-naming convention first, and matches them instead of
introducing a competing one. `scaffold_test_file.sh` (Flutter) explicitly
refuses to overwrite an existing test file.

**What if I want tests for the whole app, not just one file?**
Say so. Every skill's Step 3 explicitly asks whether you want the whole
app, one feature, or specific files tested. It never assumes either
direction on its own.

**Can I use this outside Claude Code, on claude.ai or the API?**
Not well. These skills need real toolchains (`flutter`, `npm`,
`xcodebuild`) to detect conventions and optionally run tests. That fits
Claude Code's local, CLI-based environment, not the sandboxed,
network-isolated execution environments that claude.ai and the Claude
API's code-execution tool use. See [Research base](#research-base) below.

**Which skill fires if my repo has both a Flutter app and a Node backend?**
Whichever one matches the file you're pointing at. Each skill's `paths`
frontmatter and `scripts/detect_stack.sh` scope it to its own stack's
manifest and file extensions, so a request about a `.dart` file triggers
`flutter-testing` and a request about a route handler triggers
`node-testing`, even in the same monorepo.

## Research base

This plugin's testing guidance (per-platform tooling, the trophy/pyramid
distribution shapes, mocking-boundary rules, flakiness causes) and its
skill architecture (progressive disclosure, description design,
low-freedom procedures for fragile steps) come from two dedicated
research passes. One covers testing methodology and AI-agent
test-generation failure modes across Flutter, React, Next.js, Swift, and
Node. The other covers Claude Skill/plugin authoring and hosting
mechanics straight from Anthropic's own documentation. The specific
findings cited above trace to a controlled AST-based agent-vs-human
test-quality study and a 2026 SmartBear software-leader survey, both
referenced in that research base.

## Version history

- **2.0.0**: Test execution and the fault-injection self-check became
  opt-in instead of automatic. Writing correct test files is each skill's
  deliverable on its own; running and verifying them now happens only on
  request. Also deep-dived Flutter specifically: dedicated reference docs
  for unit, widget, and integration testing (previously only golden
  tests and state management had their own files), a CI/distribution-shape
  doc, and a new `scaffold_test_file.sh` convenience script.
- **1.0.0**: Initial release. Five platform skills, domain-split
  reference docs, `detect_stack.sh` per platform, `evals/evals.json` per
  skill, fault-injection self-check verified end-to-end.

## License

MIT. See [LICENSE](LICENSE).
