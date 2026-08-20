# testing-suite

A Claude Code plugin that bundles six platform-specific test-writing
skills. Each skill detects the project's stack and existing test
conventions, asks what to test before generating anything, and writes
tests that follow the trophy/pyramid model appropriate to that platform.
**Writing the test files is the deliverable.** Running them and verifying
them with a fault-injection self-check is available on request, never
automatic.

## Skills

| Skill | Namespaced as | Covers |
|---|---|---|
| `flutter-testing` | `/testing-suite:flutter-testing` | Flutter unit, widget, golden, and integration tests, each a first-class layer with its own reference doc. Detects BLoC/Riverpod/Provider/GetX from `pubspec.yaml` and selects the matching harness pattern. |
| `react-testing` | `/testing-suite:react-testing` | Plain React (Vite/CRA, non-Next, non-React-Native) unit and component/integration tests with Vitest/Jest, React Testing Library, and MSW for network-boundary mocking. |
| `nextjs-testing` | `/testing-suite:nextjs-testing` | Next.js (App Router or Pages Router) tests, split between Vitest (Server Actions, schema validation, sync components) and Playwright (async Server Components, auth, checkout, the layer Vitest structurally cannot render). |
| `react-native-testing` | `/testing-suite:react-native-testing` | React Native tests across Expo (managed or bare) and plain React Native CLI, one skill branching on the detected workflow. Jest (`jest-expo` or the `react-native` preset) with React Native Testing Library, `expo-router/testing-library` for route-level tests, and Maestro (default) or Detox for E2E flows. |
| `swift-testing` | `/testing-suite:swift-testing` | Swift/SwiftUI unit, view-model, and snapshot tests. Defaults to Swift Testing (`@Test`/`#expect`), keeps XCTest where it already exists, and tests the view model directly since SwiftUI has no public view-tree introspection. |
| `node-testing` | `/testing-suite:node-testing` | Node backend APIs (Express/Fastify/Koa/NestJS): unit tests for pure logic, Supertest-based HTTP integration tests against the app instance directly, and testcontainers-backed tests for real database behavior. |

Each skill's description leads with concrete trigger terms (framework
names, manifest files, library names) specific to that platform. Each
skill's `scripts/detect_stack.sh` also explicitly declines and points to
the correct sibling skill when it detects the wrong stack. `react-testing`,
for example, refuses a project with `next` or `react-native` in
`package.json`.

## What every skill does, in order

1. **Detect the stack.** Run `scripts/detect_stack.sh`, which fingerprints
   the project's manifest and source files for the framework,
   state-management library, existing test runner, and mocking/snapshot
   tooling already in use. An existing convention always wins over the
   skill's own default.
2. **Audit project structure.** Classify the target code as pure logic,
   UI, or data-access, match existing naming conventions, and flag
   critical paths (auth, payment, data-writes) for elevated rigor.
3. **Ask what to test.** One message, asking both the test layer
   (unit/widget/integration/etc.) and the scope (whole app, one feature,
   or specific files) before generating anything. This is never assumed.
4. **State the plan.** What's in scope, what's mocked vs real, and the
   specific edge cases planned, before any test code is written. For a
   large scope, proposes a batched plan and confirms the first batch
   rather than attempting everything in one pass.
5. **Generate.** AAA-structured tests, boundary-only mocking or faking,
   matching the project's existing style. Comments are the exception, not
   the default: one short header comment per file stating what it covers,
   inline comments only when genuinely necessary. Then a free self-review:
   every assertion just written gets re-read and strengthened if it
   doesn't check a specific value or state -- this
   runs on every request, no execution required.
6. **Report, then offer.** List what was written and what each test
   covers, plus anything strengthened in the Step 5 self-review. Nothing
   is run yet, and nothing is claimed to pass or fail. Offer to run and
   verify, don't do it unprompted.
7. **Only if asked, run and verify.** Run each new test at least twice to
   catch non-determinism empirically, then run the mandatory
   fault-injection self-check on business-logic and critical-path tests:
   deliberately break the implementation, confirm the test goes red,
   revert the break, and report honestly what was covered, what was left
   out, and whether any test was flagged and rewritten. Never a blanket
   "fully tested" claim. `reference/verification.md` also points to a
   real mutation-testing tool for projects that want more rigor than
   this built-in check.

## Install

From within Claude Code, add this repository as a marketplace and install
the plugin:

```
/plugin marketplace add jyotiraditya-chauhan/test-kit
/plugin install testing-suite@test-kit-marketplace
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

## Flutter goes deeper than the rest

`flutter-testing` has a dedicated reference doc for each layer (unit,
widget, golden, and integration), plus cross-cutting docs for state
management, Firebase fakes, and CI/distribution shape, and a second
script (`scaffold_test_file.sh`) for mirroring `lib/` into `test/`. See
the root README's [Flutter, in depth](../../README.md#flutter-in-depth)
section for the full breakdown.

## Works beyond Claude Code

These skills use the same `SKILL.md` folder convention Codex CLI, Cursor,
and opencode now read natively. They're vendored at `.agents/skills/` in
the repository root (kept in sync by `scripts/sync-portable-skills.sh`)
for tools that read that path directly, plus a condensed
`portable/AGENTS.md` fragment for tools with no skills system at all
(Aider, Windsurf, Zed, Gemini CLI, Amp). See the root README's
[Works beyond Claude Code](../../README.md#works-beyond-claude-code)
section for the full compatibility table and setup steps.

## Kept current, not just written once

A dedicated currency-audit pass periodically re-checks every platform's
tooling and code syntax against that ecosystem's own current
documentation, and corrects real drift (a discontinued package, a
changed API signature) while leaving what's still accurate untouched.
See the root README's [Version history](../../README.md#version-history),
2.3.0 entry, for the most recent pass and exactly what it changed.

## Why "ask, don't assume" and fault-injection matter

Left unconstrained, an AI agent tends to write tests that confirm what
its own implementation already does, rather than what it should do. That
kind of suite can hit 100% coverage while asserting nothing. See the root
README's [Why this exists](../../README.md#why-this-exists) section for
the research behind that concern, and a live, end-to-end proof that the
fault-injection self-check actually catches it.

## License

MIT. See [LICENSE](../../LICENSE) in the repository root.
