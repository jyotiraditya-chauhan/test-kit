# API Route Handlers, Middleware, and next/navigation Mocking

Table of contents:
- [Route handlers](#route-handlers)
- [Middleware](#middleware)
- [Mocking next/navigation](#mocking-nextnavigation)

## Route handlers

Next.js API route handlers (`route.ts` files) are plain exported functions
— import the handler directly and invoke it with a constructed `Request`
object, verified with Vitest. This does not require the async-Server-
Component workaround from `async-server-components.md`, since it's a plain
function, not a rendered React tree.

```ts
import { GET } from '@/app/api/users/[id]/route';

test('returns 404 for an unknown user', async () => {
  const req = new Request('http://localhost/api/users/unknown');
  const res = await GET(req, { params: { id: 'unknown' } });
  expect(res.status).toBe(404);
});
```

## Middleware

Test the same way — import and invoke the exported `middleware` function
directly with a constructed `NextRequest`, assert on the returned
`NextResponse` (redirect target, headers, status).

## Mocking next/navigation

Components using `useRouter`, `usePathname`, or `useSearchParams` need
these mocked in unit/component tests, since they depend on the real Next.js
runtime context that doesn't exist under a plain Vitest render:

```ts
vi.mock('next/navigation', () => ({
  useRouter: () => ({ push: vi.fn(), replace: vi.fn() }),
  usePathname: () => '/dashboard',
  useSearchParams: () => new URLSearchParams(),
}));
```

Only mock the specific hooks the component under test actually uses — don't
blanket-mock the whole module with unused stubs.
