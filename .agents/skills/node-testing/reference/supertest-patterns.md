# Supertest + Jest/Vitest Patterns

Table of contents:
- [The standard pattern](#the-standard-pattern)
- [Never call .listen() for tests](#never-call-listen-for-tests)
- [Runner choice](#runner-choice)

## The standard pattern

Supertest wraps an Express (or Fastify/Koa/NestJS) app **instance**
directly and simulates HTTP internally without binding a real network port
or requiring `app.listen()` anywhere in source code. This gives real
Request/Response object behavior with none of the flakiness or slowness of
standing up an actual server process.

```js
import request from 'supertest';
import { app } from '../../src/app.js';

describe('GET /api/users', () => {
  it('returns a list of users', async () => {
    const res = await request(app).get('/api/users');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  it('returns 401 without an auth token', async () => {
    const res = await request(app).get('/api/users/me');
    expect(res.status).toBe(401);
  });
});
```

## Never call .listen() for tests

Import and pass the raw `app` export to `request()`. Never call
`app.listen()` in a test file, and never structure source code so that the
exported app has already started listening as a side effect of import.
`scripts/detect_stack.sh` flags `.listen(` calls outside test files so you
can confirm they're the app's own bootstrap entrypoint, not something a
test triggers. See [test-isolation.md](test-isolation.md) for why this
matters under parallel test workers.

## Runner choice

Vitest for new ESM/TypeScript projects, Jest remains completely fine for
existing suites, same logic as the frontend skills. As of Node 22 LTS,
Node's own built-in test runner (`node:test`) is also stable and
TAP-compliant, a viable lightweight option for small services/libraries
where minimizing dependencies matters, though its mocking ecosystem is
thinner than Jest/Vitest's. Match whatever the project already uses; see
Step 1 of SKILL.md.
