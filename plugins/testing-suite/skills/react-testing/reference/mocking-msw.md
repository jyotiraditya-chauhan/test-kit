# Network Mocking with MSW

Table of contents:
- [Why the network boundary, not the module](#why-the-network-boundary-not-the-module)
- [Basic handler pattern](#basic-handler-pattern)
- [The explicit anti-pattern](#the-explicit-anti-pattern)

## Why the network boundary, not the module

Mock Service Worker (MSW) intercepts HTTP requests at the network boundary
(a Node request interceptor in tests) rather than mocking `fetch`/`axios` at
the module level. This means the component under test is exercised through
its real data-fetching code path — the same handlers work in tests, local
dev, and Storybook. This is the concrete implementation of "mock at the true
I/O boundary, not the function," and is the default mocking approach for
this skill.

## Basic handler pattern

```ts
import { http, HttpResponse } from 'msw';
import { setupServer } from 'msw/node';

const server = setupServer(
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({ id: params.id, name: 'Ada' });
  }),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

Override a handler per-test for an error-path case:

```ts
test('shows an error message when the fetch fails', async () => {
  server.use(
    http.get('/api/users/:id', () => HttpResponse.json({ message: 'not found' }, { status: 404 })),
  );
  render(<UserProfile id="1" />);
  expect(await screen.findByText(/not found/i)).toBeInTheDocument();
});
```

## The explicit anti-pattern

Mocking the database, the API, the auth layer, AND the cache all in one test
reduces the test to "asserting that my mocks return what I told them to
return" — meaningless. Mock only the network boundary with MSW; let
everything else in the component (state, effects, rendering) run for real.
