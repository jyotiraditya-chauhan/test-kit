# Recommended Distribution and CI Gating

Table of contents:
- [Recommended shape](#recommended-shape)
- [CI gating](#ci-gating)

## Recommended shape

For a Flutter app with a meaningful amount of business logic, aim for a
closer-to-classic-pyramid shape rather than an even split:

- **~60-70% unit** — fast, cheap, the base of the pyramid.
- **~20-25% widget** — the UI layer, still runs with no real device.
- **~10% integration** — expensive, reserved for critical flows.
- **~5% golden** — visual regression on design-system primitives.

This is closer to a classic pyramid than React tends to get, which tracks
with Flutter's widget layer being cheaper and faster to test in true
isolation than a typical React component. Treat these numbers as a shape
to aim for when the user hasn't specified scope, not a hard quota — always
defer to what the user actually asked for in Step 3 of SKILL.md.

## CI gating

Unit and widget tests need no real device and should run on Linux CI
runners (cheapest). iOS-specific integration tests require macOS runners,
which are materially more expensive on most CI providers — reserve macOS
runner minutes for the smallest possible set of true device-dependent
tests, and run everything else (unit, widget, golden, Android integration
tests) on Linux.

Suggested gating, if the user asks about CI structure:
- **Every PR (fast, blocking)**: unit + widget + golden.
- **Merge-to-main or nightly (slow, not blocking every PR)**: integration
  tests.

This skill does not generate CI configuration by default — only propose a
CI pipeline change if the user explicitly asks for one.
