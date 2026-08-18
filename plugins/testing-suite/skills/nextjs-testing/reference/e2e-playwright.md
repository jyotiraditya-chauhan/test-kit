# Playwright E2E for Next.js

Table of contents:
- [When Playwright is required, not optional](#when-playwright-is-required-not-optional)
- [Representative distribution](#representative-distribution)

## When Playwright is required, not optional

Per `async-server-components.md`, Playwright is not just "the E2E tool" for
a Next.js App Router project. It's the only way to exercise an async
Server Component's actual rendered output, since Vitest structurally
cannot render one. Reserve it for:
- Async Server Components as rendered in a real page load
- Auth flows, anything depending on cookies or middleware
- Full checkout/payment redirect flows (e.g. Stripe)
- Anything depending on the real Next.js router

Do not generate a Playwright test for something a Vitest unit test on an
extracted function, or a route-handler test, would cover just as well.
Same inverted-pyramid caution as plain React (see the `react-testing`
skill's `e2e-and-antipatterns.md` if that skill is also installed).

## Representative distribution

A representative real-world split for a SaaS-style Next.js project: dozens
of Vitest unit/integration tests covering Server Actions, schema
validation, and extracted data-access functions, plus roughly 20-30
Playwright E2E tests covering the paths where a failure would directly cost
the business money (auth, checkout, core workflows). Treat this as a shape
to aim for, not a hard quota. Scope to what the user actually asked for in
Step 3 of SKILL.md.
