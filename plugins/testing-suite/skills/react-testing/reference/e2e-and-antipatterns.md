# E2E and Explicit Anti-Patterns

Table of contents:
- [Playwright vs Cypress](#playwright-vs-cypress)
- [What to skip](#what-to-skip)
- [The inverted-pyramid trap](#the-inverted-pyramid-trap)

## Playwright vs Cypress

Default to Playwright for new E2E suites. It has better multi-tab and
multi-context support, is generally less flaky, has first-class TypeScript
support, and a component-testing mode of its own. Cypress remains fully
functional; do not propose migrating a stable, working Cypress suite just
to switch tools.

## What to skip

- Re-testing a third-party UI library's own internals (e.g. asserting that
  shadcn/ui's `<Button>` renders a `<button>` element, since that's already
  tested upstream).
- Snapshot tests that generate hundreds of lines of serialized HTML.
- Tests that only verify TypeScript/prop-type compliance. The compiler
  already guarantees that at build time, so a runtime test adds nothing.

## The inverted-pyramid trap

A large Playwright/E2E suite with a thin unit/integration layer is an
explicitly flagged, expensive mistake. A single 3-second Playwright test
costs as much CI time as roughly 50 Vitest unit tests, and E2E is the most
flake-prone layer by a wide margin. Do not default to generating E2E tests
for something that a component or integration test would cover just as
well. Reserve E2E for the handful of truly critical, revenue-or-trust
journeys (sign-up, checkout, core auth). Roughly 20-30 tests total for a
substantial product is a reasonable working range, not a hard rule.
