# Testcontainers and Contract Testing

Table of contents:
- [Testcontainers for realistic integration tests](#testcontainers-for-realistic-integration-tests)
- [Contract testing](#contract-testing)
- [Coverage targets](#coverage-targets)

## Testcontainers for realistic integration tests

For integration tests that need to be honest about real database behavior
(not just an in-memory fake), `testcontainers` spins up a real, disposable
database (Postgres, MongoDB, etc.) in a Docker container scoped to the test
run, then tears it down:

```js
import { PostgreSqlContainer } from '@testcontainers/postgresql';

let container;
beforeAll(async () => {
  container = await new PostgreSqlContainer().start();
  process.env.DATABASE_URL = container.getConnectionUri();
});
afterAll(async () => container.stop());
```

testcontainers v12+ defaults to waiting on the image's Docker healthcheck
when one exists, falling back to port-listening only if the image
doesn't define one -- no action needed for most images. If a project
pins an image with no healthcheck and needs the old behavior explicitly,
`.withWaitStrategy(Wait.forListeningPorts())` before `.start()` restores
it.

Most teams over-invest effort in the E2E layer and under-invest in this
specific testcontainers-backed integration layer. Actively recommend it
for anything genuinely database-behavior-dependent (a real query, a real
index constraint, a real migration), rather than defaulting to either
"fake everything" or reaching for full E2E.

## Contract testing

For verifying that an API's actual request/response shape matches what
consumers (a frontend, or another service) expect, without running the
full consumer: Pact (consumer-driven contracts, with a Pact Broker for
sharing contracts between teams/repos) or direct OpenAPI-spec validation
(Schemathesis, which generates and runs property-based test cases from a
published OpenAPI schema) that asserts real responses conform to it. Only
propose this if the project already has cross-repo/external consumers,
or the user explicitly asks. It's a separate concern from ordinary route
testing, not a default addition to every test plan.

## Coverage targets

Target roughly 70-80% line coverage with deliberately HIGH branch coverage
specifically on the highest-risk paths: authentication, billing/payment,
and any data-write path. Pushing coverage past ~90% on a whole codebase has
steeply diminishing returns and often means testing trivial getters/setters
instead of directing effort at meaningful integration tests on paths that
actually matter. Coverage percentage is not a substitute for the
fault-injection self-check in [verification.md](verification.md). A test
suite can hit these coverage numbers while still asserting nothing
meaningful.
