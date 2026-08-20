# Async Server Components: The Central Problem

Table of contents:
- [The capability gap](#the-capability-gap)
- [The design rule: extract, don't work around](#the-design-rule-extract-dont-work-around)
- [The Vitest / Playwright split](#the-vitest--playwright-split)

## The capability gap

This is documented in Next.js's own official Vitest testing guide, not just
third-party commentary: **Vitest currently cannot render an async Server
Component.** A synchronous Server Component renders fine under
`@testing-library/react` inside Vitest. The moment a component body contains
`const data = await fetch(...)` (or any other await), rendering it under
Vitest throws. This is a genuine capability gap, not a config problem.
React's Server Component runtime expects an async execution environment
Vitest's test runner does not currently provide. Workarounds (manually
awaiting the async component function, shimming React's internal async
hooks) are brittle and liable to break on every React minor version. Do not
propose them as a real fix.

## The design rule: extract, don't work around

Pull the async data-fetching call OUT of the component body and into a
plain, separately-importable async function. Unit-test that function
directly with Vitest. No rendering is involved at all, it's just an async
function you call and assert on. This sidesteps the capability gap entirely
and is a better architectural pattern regardless (separates data-fetching
from rendering concerns).

```ts
// data/get-user.ts -- plain async function, testable with Vitest directly
export async function getUser(id: string) {
  const res = await fetch(`/api/users/${id}`);
  if (!res.ok) throw new Error('failed to fetch user');
  return res.json();
}
```

```tsx
// app/users/[id]/page.tsx -- the async Server Component itself is now
// thin; Playwright covers this file, Vitest covers get-user.ts directly.
import { getUser } from '@/data/get-user';

// Next.js 15+: params is a Promise, not a plain object -- await it before
// use. This applies to every App Router page/layout, not just this example.
export default async function UserPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const user = await getUser(id);
  return <div>{user.name}</div>;
}
```

If the project has NOT already extracted data-fetching this way, propose the
extraction as part of the test plan (Step 4 of SKILL.md) rather than trying
to test the async component body directly under Vitest, and state clearly why.

## The Vitest / Playwright split

**Vitest (+ RTL) handles:**
- Server Actions, tested as plain async functions (not through a rendered tree)
- Zod (or equivalent) schema validation logic
- Synchronous Server Components and ordinary Client Components
- Any pure logic extracted out of a component, per the rule above

**Playwright handles everything Vitest structurally cannot:**
- Async Server Components (rendered as part of a real page load)
- Auth flows, anything depending on cookies or middleware
- Full checkout/payment redirect flows
- Anything depending on the real Next.js router

Never propose rendering an async Server Component directly under Vitest.
Route it to Playwright, or extract the async logic per the rule above.
