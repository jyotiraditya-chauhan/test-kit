# Testing procedure (test-kit, portable fragment)

This section is a condensed, tool-agnostic version of test-kit's testing
procedure, for coding assistants that read a static `AGENTS.md` (or
`CONVENTIONS.md`, `.windsurfrules`, `GEMINI.md`, etc.) instead of an
auto-triggered skills system. Copy everything below this line into your
project's own instructions file.

**Before this is useful, copy the `.agents/skills/` directory from
[test-kit](https://github.com/jyotiraditya-chauhan/test-kit) into your
project root.** The links below point into those folders
(`.agents/skills/<platform>-testing/reference/...`) for the real
per-platform depth — mocking patterns, state-management harnesses, E2E
setup, and so on. Without that directory present, this fragment is just
the outline; the substance lives in the linked reference files.

If your tool auto-discovers skill folders on its own (Codex, Cursor,
opencode, and others that read `.agents/skills/`, `.cursor/skills/`, or
`.claude/skills/`), you don't need this fragment at all — just copy the
skill folders and it will trigger on its own from each `SKILL.md`'s
description. This fragment exists for tools that don't have that.

---

## When a testing request comes in for this project

Detect which platform applies from the project's own files, then follow
that platform's full procedure in `.agents/skills/<platform>-testing/`:

| Signal in the project | Platform | Reference folder |
|---|---|---|
| `pubspec.yaml` with a `flutter:` SDK dependency | Flutter | `.agents/skills/flutter-testing/` |
| `package.json` with `react`+`react-dom`, no `next`, no `react-native` | React (web) | `.agents/skills/react-testing/` |
| `package.json` with `next` | Next.js | `.agents/skills/nextjs-testing/` |
| `package.json` with `react-native` (Expo managed, Expo bare, or plain RN CLI) | React Native | `.agents/skills/react-native-testing/` |
| `.xcodeproj` / `.xcworkspace` / `Package.swift` | Swift/SwiftUI | `.agents/skills/swift-testing/` |
| `package.json` with `express`/`fastify`/`koa`/`@nestjs/core` | Node backend | `.agents/skills/node-testing/` |

Each of those folders has its own `SKILL.md` with the full step-by-step
procedure and a `reference/` directory with the deep per-topic guidance
(mocking boundaries, state-management harnesses, E2E setup, fault
injection). Read the matching `SKILL.md` in full before generating
anything — the summary below is not a substitute for it.

## The seven-step procedure, in brief

1. **Detect the stack.** Run the matching skill's `scripts/detect_stack.sh`
   from the project root. It reports the existing test runner, mocking
   library, and file convention already in use — always follow what's
   already there over any default.
2. **Audit the project.** Classify the target as pure logic, UI, or
   data-access. Flag critical paths (auth, payment, any data-write) for
   elevated rigor.
3. **Ask, don't assume.** One message, two questions, before generating
   anything: which layer (unit/widget/component/integration/etc.), and
   what scope (whole app, one feature, or specific files).
4. **State the plan.** What's in scope, what's mocked vs. real (boundary
   only — never mock a same-layer collaborator), and the specific edge
   cases planned. If the scope is large, propose a batched plan and
   confirm the first batch rather than attempting everything at once.
5. **Generate.** AAA structure, boundary-only mocking, matching the
   project's existing style, minimal comments. Before reporting, re-read
   every assertion just written and strengthen anything that doesn't
   check a specific value or state — this is the single most important
   step for avoiding tests that pass without checking anything.
6. **Report, then offer.** List what was written and what each test
   covers. Nothing is run. Offer to run and verify — don't do it
   unprompted.
7. **Only if asked, run and verify.** Run each new test at least twice in
   a row to catch non-determinism empirically, then run the mandatory
   fault-injection self-check on business-logic tests: deliberately break
   the implementation, confirm the test goes red, revert the break,
   report honestly what was covered.

Writing correct test files is the deliverable. Running and verifying them
is available on request, never automatic — this applies regardless of
which CLI or tool is reading this file.
