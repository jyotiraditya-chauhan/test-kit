# Test Isolation: The Most Common Source of Pain

Table of contents:
- [Shared database state](#shared-database-state)
- [Port binding conflicts](#port-binding-conflicts)

Two specific, recurring footguns cause the majority of flaky Node/Express
test suites.

## Shared database state

Test A inserts a row, test B assumes an empty table — fails
unpredictably depending on execution order or parallel-worker scheduling.
Fix: isolate each test's data. Two acceptable patterns:
- Wrap each test in a transaction that's rolled back in `afterEach`.
- Use a fresh in-memory or disposable test database per test file (see
  [testcontainers-and-contracts.md](testcontainers-and-contracts.md) for
  the realistic-database version of this).

Never assume a table is empty at the start of a test without either
asserting that explicitly or guaranteeing it via isolation — an assumption
that happens to hold today breaks the moment tests run in parallel or in a
different order.

## Port binding conflicts

If source code calls `app.listen()` directly anywhere instead of only ever
passing the raw app instance to Supertest, multiple parallel test workers
can collide on the same port. Supertest is explicitly designed so tests
never need to call `.listen()` themselves — see
[supertest-patterns.md](supertest-patterns.md). If `scripts/detect_stack.sh`
flags a `.listen(` call outside a test file, confirm it's the app's actual
production bootstrap entrypoint (fine) and not something imported by a test.
