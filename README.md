# testKit

**A Claude Code plugin marketplace for stack-aware, self-verifying test generation.**

`testKit` hosts **testing-suite**, one plugin bundling five platform skills —
Flutter, React, Next.js, Swift/SwiftUI, and Node/Express — that detect a
project's real stack and conventions, ask before assuming what to test, and
prove each generated test actually checks something before calling it done.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Plugin](https://img.shields.io/badge/Claude%20Code-Plugin-5A45FF.svg)](https://code.claude.com/docs/en/plugins)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](plugins/testing-suite/.claude-plugin/plugin.json)
[![Skills](https://img.shields.io/badge/skills-5-informational.svg)](#the-five-skills)

---

## Why this exists

AI-written tests have a specific, well-documented failure shape, and it
isn't "the model can't code." A controlled AST-based comparison of
agent-generated versus human-written tests found agents genuinely *better*
at edge-case breadth — nearly double the boundary-condition variety of
human authors — but measurably weaker on precision: **11.58% of
agent-written assertions were ambiguous or effectively unclassifiable**,
against 1.46% for humans, and agent-generated suites carried a higher
flakiness-candidate rate (0.41 vs 0.30), largely from non-deterministic
file I/O and timing assumptions a human author instinctively avoids.

The sharper problem is invisible to a coverage dashboard. Left to its own
process, an agent writes the implementation first and then writes tests
that confirm what that implementation *already does* — not what it
*should* do. A test built this way can hit 100% line coverage while
asserting nothing: it's a mirror of the bug, not a check against it. A 2026
SmartBear survey of 273 software leaders found 70% already see application
quality degrading as AI accelerates development, and separately, 58% of
developers report trusting AI-generated output without testing it at all —
polish reads as correctness, and it isn't.

Every skill in this plugin is built around the direct countermeasure: plan
before generating, mock only at the true I/O boundary, and — for every
business-logic or critical-path test — run a **fault-injection self-check**
that deliberately breaks the implementation, confirms the new test actually
notices, then reverts the break. A test that stays green against
known-broken code is rewritten, not accepted. See
[The fault-injection self-check](#the-fault-injection-self-check) below.

## Installation

Inside Claude Code:

```
/plugin marketplace add jyotiraditya-chauhan/testKit
/plugin install testing-suite@testkit-marketplace
```

Or non-interactively:

```bash
claude plugin marketplace add jyotiraditya-chauhan/testKit
claude plugin install testing-suite@testkit-marketplace
```

## Usage

Just ask — the matching skill triggers automatically from your project's
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

## The five skills

| Skill | Command | Fires on | Default stack |
|---|---|---|---|
| **flutter-testing** | `/testing-suite:flutter-testing` | `pubspec.yaml` with a `flutter:` SDK dependency | `flutter_test`, `mocktail`, `bloc_test` / `ProviderContainer`, `golden_toolkit` |
| **react-testing** | `/testing-suite:react-testing` | `package.json` with `react`+`react-dom`, no `next` | Vitest/Jest, React Testing Library, MSW |
| **nextjs-testing** | `/testing-suite:nextjs-testing` | `package.json` with `next` | Vitest (Server Actions, sync components) + Playwright (async Server Components, auth, checkout) |
| **swift-testing** | `/testing-suite:swift-testing` | `.xcodeproj` / `.xcworkspace` / `Package.swift` | Swift Testing (`@Test`/`#expect`), XCTest where it already exists, `swift-snapshot-testing` |
| **node-testing** | `/testing-suite:node-testing` | `package.json` with `express`/`fastify`/`koa`/`@nestjs/core` | Supertest against the app instance, Vitest/Jest, testcontainers |

No two skills can plausibly fire on the same request. Each `scripts/detect_stack.sh`
hard-fails and names the correct sibling skill when it detects the wrong
stack — `react-testing` refuses a `next` dependency, `node-testing` refuses
a project with no backend framework, and so on. Verified directly: running
each skill against every other skill's fixture project produces a clean
decline, not a wrong-platform test.

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
6. Self-verify             -> run the new tests, then run the mandatory
                              fault-injection check on business-logic
                              tests (see below).
7. Report honestly         -> what's covered, what's explicitly left out
                              and why, what got rewritten. Never a
                              blanket "fully tested" claim.
```

## The fault-injection self-check

This is the plugin's one non-negotiable, low-freedom procedure — every
`reference/verification.md` states it near-verbatim rather than as a
loose suggestion, because it's the single highest-leverage defense against
the self-confirmation trap described above:

1. Run the new test against the real implementation. Confirm green.
2. Deliberately introduce one small, obvious fault — flip a comparison
   operator, swap a returned literal, skip a guard branch.
3. Re-run the same test. It **must** now fail.
4. If it still passes against broken code, the test is flagged as weak
   and rewritten — never silently counted as passing coverage.
5. Revert the fault. Confirm green again against the real implementation.

Verified for real, not just described: in a live end-to-end run against a
Node/Express fixture, the skill generated a `calculateShippingCost` test
suite, ran the fault-injection check, and reverted cleanly — the
implementation file came back byte-identical to its original, and every
generated assertion checked an exact value (`toBe`, `toBeCloseTo`, a
specific thrown message), not just that a call didn't throw.

## Worked example

**Prompt:** *"Add tests for the calculateShippingCost function in
src/services/shipping.js, it's pure logic."*

**What node-testing does, end to end:**

```js
// src/services/shipping.js (unchanged after the run)
export function calculateShippingCost(weightKg, expedited = false) {
  if (weightKg <= 0) throw new Error('weight must be positive');
  const base = weightKg * 2.5;
  return expedited ? base * 1.5 : base;
}
```

```js
// src/services/shipping.test.js (generated)
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

Happy path, a default-parameter case, a fractional-input boundary, and both
zero and negative error paths — six cases from one function, each tied to
something that would actually break under a regression, confirmed by
deliberately breaking the function and watching the right test fail.

## Repository layout

```
.claude-plugin/
  marketplace.json              # this marketplace's catalog
plugins/
  testing-suite/
    .claude-plugin/
      plugin.json                # plugin manifest (v1.0.0)
    skills/
      flutter-testing/
        SKILL.md
        reference/                # state management, Firebase fakes,
                                   # golden tests, fault-injection
        scripts/detect_stack.sh
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

Validate before committing — both are expected to pass with zero warnings:

```bash
claude plugin validate ./plugins/testing-suite --strict
claude plugin validate . --strict
```

## Research base

This plugin's testing guidance (per-platform tooling, the trophy/pyramid
distribution shapes, mocking-boundary rules, flakiness causes) and its
skill architecture (progressive disclosure, description design,
low-freedom procedures for fragile steps) come from two dedicated research
passes: one covering testing methodology and AI-agent test-generation
failure modes across Flutter, React, Next.js, Swift, and Node; the other
covering Claude Skill/plugin authoring and hosting mechanics straight from
Anthropic's own documentation. Specific findings cited above trace to a
controlled AST-based agent-vs-human test-quality study and a 2026 SmartBear
software-leader survey, both referenced in that research base.

## Version history

- **1.0.0** — Initial release: five platform skills, domain-split
  reference docs, `detect_stack.sh` per platform, `evals/evals.json` per
  skill, fault-injection self-check verified end-to-end.

## License

MIT — see [LICENSE](LICENSE).
