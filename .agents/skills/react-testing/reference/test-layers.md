# Unit vs Component vs Integration (Trophy Model)

Table of contents:
- [The testing trophy](#the-testing-trophy)
- [Concrete definitions for React](#concrete-definitions-for-react)
- [Recommended distribution](#recommended-distribution)
- [Snapshot testing -- use sparingly](#snapshot-testing----use-sparingly)

## The testing trophy

Bottom to top: static analysis -> unit -> integration (the fat middle) ->
E2E (thin cap). This is the default mental model for React work: most
components in a modern app are integration code (fetch + conditional render
+ error handling + write-back), not meaningfully "units." Pure unit tests of
such a component either become trivial or require so much mocking they stop
resembling how the software is actually used.

## Concrete definitions for React

- **Unit test**: a pure function, such as a pricing calculator, a
  formatter, or a reducer, tested with no rendering at all.
- **Component test**: a rendered component (`<PriceDisplay />`) verified for
  correct rendering and response to prop changes/interaction, via Vitest/
  Jest + RTL (jsdom).
- **Integration test** (trophy sense): a component or small tree exercised
  together with real state management and MSW-mocked network, verifying an
  actual user flow within the page. This is the default unit of testing for
  anything that fetches, renders conditionally, or writes back to a store.

## Recommended distribution

Trophy shape: a static-analysis base, a fat integration-test middle
(component tests exercising real state + MSW-mocked network), a thin unit
layer for pure logic only, a thin E2E cap. For a substantial product,
sources commonly cite roughly 20-30 E2E tests as the working range for
critical journeys, not more. See
[e2e-and-antipatterns.md](e2e-and-antipatterns.md) for why an inverted
pyramid (large E2E suite, thin integration layer) is an expensive mistake.

## Snapshot testing -- use sparingly

Jest/Vitest snapshot tests serialize a component's rendered output and diff
it against a stored file. Avoid large serialized-HTML snapshots: they break
on any styling change whether or not it's meaningful, generate hundreds of
unreviewed lines, and developers get in the habit of blindly
`--update-snapshot` rather than reading the diff. Use snapshots narrowly,
for small and structurally simple output only. For visual verification at
scale, prefer Storybook + Chromatic (purpose-built visual regression
tooling) over repurposed unit-test snapshots. Only introduce that if
the project already uses it or the user asks, since it's a separate tool,
not a default addition.
