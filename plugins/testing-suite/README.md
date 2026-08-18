# testing-suite

A Claude Code plugin that bundles five platform-specific test-generation
skills. Each skill detects the project's stack and existing test
conventions, asks what to test before generating anything, writes tests
that follow the trophy/pyramid model appropriate to that platform, and
verifies its own output with a mandatory fault-injection self-check before
reporting coverage honestly.

## Skills

| Skill | Namespaced as | Covers |
|---|---|---|
| `flutter-testing` | `/testing-suite:flutter-testing` | Flutter unit, widget, golden, and integration tests. Detects BLoC/Riverpod/Provider/GetX from `pubspec.yaml` and selects the matching harness pattern. |
| `react-testing` | `/testing-suite:react-testing` | Plain React (Vite/CRA, non-Next) unit and component/integration tests with Vitest/Jest, React Testing Library, and MSW for network-boundary mocking. |
| `nextjs-testing` | `/testing-suite:nextjs-testing` | Next.js (App Router or Pages Router) tests, split between Vitest (Server Actions, schema validation, sync components) and Playwright (async Server Components, auth, checkout — the layer Vitest structurally cannot render). |
| `swift-testing` | `/testing-suite:swift-testing` | Swift/SwiftUI unit, view-model, and snapshot tests. Defaults to Swift Testing (`@Test`/`#expect`), keeps XCTest where it already exists, and tests the view model directly since SwiftUI has no public view-tree introspection. |
| `node-testing` | `/testing-suite:node-testing` | Node backend APIs (Express/Fastify/Koa/NestJS) — unit tests for pure logic, Supertest-based HTTP integration tests against the app instance directly, and testcontainers-backed tests for real database behavior. |

Each skill's description leads with concrete trigger terms (framework
names, manifest files, library names) specific to that platform, and each
skill's `scripts/detect_stack.sh` explicitly declines and points to the
correct sibling skill when it detects the wrong stack (e.g. `react-testing`
refuses a project with `next` in `package.json`).

## What every skill does, in order

1. **Detect the stack** — run `scripts/detect_stack.sh`, which fingerprints
   the project's manifest/source files for the framework, state-management
   library, existing test runner, and mocking/snapshot tooling already in
   use. An existing convention always wins over the skill's own default.
2. **Audit project structure** — classify the target code (pure logic vs
   UI vs data-access), match existing naming conventions, and flag
   critical paths (auth, payment, data-writes) for elevated rigor.
3. **Ask what to test** — a single message asking both the test layer
   (unit/widget/integration/etc.) and the scope (whole app, one feature, or
   specific files) before generating anything. This is never assumed.
4. **State the plan** — what's in scope, what's mocked vs real, and the
   specific edge cases planned, before any test code is written.
5. **Generate** — AAA-structured tests, boundary-only mocking/faking,
   matching the project's existing style, with minimal comments.
6. **Self-verify** — run the new tests, then run a mandatory
   fault-injection self-check on business-logic/critical-path tests:
   deliberately break the implementation, confirm the test goes red, revert
   the break. A test that stays green against broken code gets rewritten,
   not accepted.
7. **Report honestly** — what was covered, what was explicitly left out
   and why, and whether any test was flagged and rewritten. Never a blanket
   "fully tested" claim.

## Install

From within Claude Code, add this repository as a marketplace and install
the plugin:

```
/plugin marketplace add jyotiraditya-chauhan/testKit
/plugin install testing-suite@testkit-marketplace
```

## Local development

```
claude --plugin-dir ./plugins/testing-suite
/testing-suite:flutter-testing
/reload-plugins   # after editing any file other than SKILL.md text
```

Validate before committing:

```
claude plugin validate ./plugins/testing-suite
```
