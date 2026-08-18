# testKit

A Claude Code plugin marketplace hosting **testing-suite** — five
platform-specific skills that generate unit, widget/component, golden/
snapshot, and integration tests for Flutter, React, Next.js, Swift/SwiftUI,
and Node/Express projects.

Every skill in this marketplace follows the same discipline: detect the
project's actual stack and conventions, ask what to test rather than
assuming, plan before generating, mock only at true I/O boundaries, and run
a mandatory fault-injection self-check (deliberately break the code under
test, confirm the new test catches it, then revert) before reporting
coverage back honestly. See
[plugins/testing-suite/README.md](plugins/testing-suite/README.md) for the
full operational flow.

## Quickstart

Inside Claude Code:

```
/plugin marketplace add jyotiraditya-chauhan/testKit
/plugin install testing-suite@testkit-marketplace
```

Then, in any project, just ask Claude to write tests — the matching skill
triggers automatically based on your stack (`pubspec.yaml`, `package.json`,
`.xcodeproj`, etc.), or invoke one directly:

```
/testing-suite:flutter-testing
/testing-suite:react-testing
/testing-suite:nextjs-testing
/testing-suite:swift-testing
/testing-suite:node-testing
```

## Skills

- **flutter-testing** — Flutter unit, widget, golden, and integration
  tests. Detects BLoC/Riverpod/Provider/GetX and selects the matching test
  harness; includes Firebase-fake guidance (`fake_cloud_firestore`,
  `firebase_auth_mocks`).
- **react-testing** — Plain React (Vite/CRA, non-Next) tests with Vitest/
  Jest, React Testing Library, and MSW for network-boundary mocking.
- **nextjs-testing** — Next.js tests split between Vitest (Server Actions,
  schema validation, sync components) and Playwright (async Server
  Components, auth, checkout) — Vitest cannot render an async Server
  Component, so this skill routes around that gap deliberately.
- **swift-testing** — Swift/SwiftUI unit, view-model, and snapshot tests.
  Defaults to Swift Testing (`@Test`/`#expect`), tests the view model
  directly since SwiftUI has no public view-tree introspection, and uses
  `swift-snapshot-testing` for actual visual verification.
- **node-testing** — Node backend APIs (Express/Fastify/Koa/NestJS): unit
  tests for pure logic, Supertest-based HTTP tests against the app
  instance directly (never a listening port), and testcontainers-backed
  tests for real database behavior.

## Repository layout

```
.claude-plugin/
  marketplace.json          # this marketplace's catalog
plugins/
  testing-suite/
    .claude-plugin/
      plugin.json            # plugin manifest
    skills/
      flutter-testing/
      react-testing/
      nextjs-testing/
      swift-testing/
      node-testing/
    README.md
README.md                    # this file
```

## Validation

```
claude plugin validate ./plugins/testing-suite
claude plugin validate .
```

Both are expected to pass with zero warnings.
